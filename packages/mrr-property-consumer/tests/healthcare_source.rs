// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
//
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

//! Source-bound POO Flow handoff over a verified local and remote property snapshot.
use std::{collections::BTreeMap, num::NonZeroUsize, sync::Mutex};

use meta_relational_reasoning as mrr;
use mrr_data_content::{
    ContentBlock, MemoryContentStore, PropertyEntityRow, PropertyRelationRow,
    PropertySnapshotInput, PropertySnapshotLimits, PropertySnapshotRows, RemoteContentStore,
    RemoteError, RemoteFuture, SnapshotTransferLimits, materialize_property_snapshot,
    publish_snapshot, restore_snapshot,
};
use mrr_data_core::{CoverageDescriptor, CoverageKind, raw_cid};
use mrr_data_datafusion::PropertyQueryLimits;
use mrr_property_source::{PropertySourceExecutionError, PropertySourceQueryError};
use poo_flow_mrr_property_consumer::{RestoredPropertyExecutor, execute_property_source};

const SOURCE_NAME: &str =
    "user-interface/scenarios/healthcare/reasoning/case-profile-relations.gql";
const SOURCE: &str = include_str!(
    "../../lambda-episteme/user-interface/scenarios/healthcare/reasoning/case-profile-relations.gql"
);
const SOURCE_DIGEST: &str =
    "sha256:7a3a88a9ebd24cd738d426c0def633247d1a0fc13e9e37cca13bb23e90ba0c63";

fn entity_type(name: &str) -> mrr::EntityId {
    mrr::EntityId::from_canonical_bytes(format!("mrr.frontend.entity-type.v1\0{name}")).unwrap()
}

fn relation_type(name: &str) -> mrr::RelationId {
    mrr::RelationId::from_canonical_bytes(format!("mrr.frontend.relation-type.v1\0{name}")).unwrap()
}

fn entity(name: &str) -> mrr::EntityId {
    mrr::EntityId::from_canonical_bytes(name).unwrap()
}

fn catalogs() -> (mrr::RelationCatalog, mrr::EntityCatalog) {
    let entities = [
        ("Scenario", "identity"),
        ("Case", "id"),
        ("Profile", "identity"),
    ]
    .into_iter()
    .map(|(kind, property)| {
        mrr::EntitySchema::new(
            entity_type(kind),
            kind,
            vec![mrr::RelationField::new(property, mrr::ValueSchema::String, false).unwrap()],
        )
        .unwrap()
    })
    .collect();
    let relations = ["HAS_CASE", "HAS_EFFECTIVE_PROFILE"]
        .into_iter()
        .map(|name| {
            mrr::RelationSchema::new(
                relation_type(name),
                name,
                vec![
                    mrr::RelationField::new("source", mrr::ValueSchema::Entity, false).unwrap(),
                    mrr::RelationField::new("target", mrr::ValueSchema::Entity, false).unwrap(),
                ],
                Vec::new(),
            )
            .unwrap()
        })
        .collect();
    (
        mrr::RelationCatalog::admit(relations).unwrap(),
        mrr::EntityCatalog::admit(entities).unwrap(),
    )
}

// These rows stand in for accepted Lambda Case receipts; the native export is a
// separate gate. The distractor Scenario makes the GQL predicate observable.
fn projected_rows() -> PropertySnapshotRows {
    let mut rows = PropertySnapshotRows::default();
    for (kind, property, values) in [
        (
            "Scenario",
            "identity",
            vec![("s1", "healthcare"), ("s2", "other")],
        ),
        ("Case", "id", vec![("c1", "case-one"), ("c2", "distractor")]),
        (
            "Profile",
            "identity",
            vec![("p1", "healing"), ("p2", "unrelated")],
        ),
    ] {
        rows.entities.insert(
            entity_type(kind),
            values
                .into_iter()
                .map(|(id, value)| PropertyEntityRow {
                    entity_id: entity(id),
                    properties: BTreeMap::from([(property.to_owned(), Some(value.to_owned()))]),
                })
                .collect(),
        );
    }
    rows.relations.insert(
        relation_type("HAS_CASE"),
        vec![
            PropertyRelationRow {
                source: entity("s1"),
                target: entity("c1"),
            },
            PropertyRelationRow {
                source: entity("s2"),
                target: entity("c2"),
            },
        ],
    );
    rows.relations.insert(
        relation_type("HAS_EFFECTIVE_PROFILE"),
        vec![
            PropertyRelationRow {
                source: entity("c1"),
                target: entity("p1"),
            },
            PropertyRelationRow {
                source: entity("c2"),
                target: entity("p2"),
            },
        ],
    );
    rows
}

fn snapshot() -> mrr::SemanticSnapshot {
    let generation = mrr::GenerationId::from_canonical_bytes("lambda-healthcare-test").unwrap();
    let revision = mrr::RevisionBinding::admit(
        mrr::ExternalRevisionIdentity::new("git", "lambda-episteme", "1421f218").unwrap(),
        generation,
    )
    .unwrap();
    mrr::SemanticSnapshot::admit(generation, vec![revision]).unwrap()
}

#[derive(Default)]
struct Remote(Mutex<BTreeMap<String, Vec<u8>>>);

impl RemoteContentStore for Remote {
    fn get<'a>(&'a self, cid: &'a cid::Cid, limit: usize) -> RemoteFuture<'a, Option<Vec<u8>>> {
        Box::pin(async move {
            let value = self.0.lock().unwrap().get(&cid.to_string()).cloned();
            if value.as_ref().is_some_and(|bytes| bytes.len() > limit) {
                return Err(RemoteError::TooLarge);
            }
            Ok(value)
        })
    }

    fn put<'a>(&'a self, block: ContentBlock<'a>) -> RemoteFuture<'a, ()> {
        Box::pin(async move {
            self.0
                .lock()
                .unwrap()
                .insert(block.cid().to_string(), block.bytes().to_vec());
            Ok(())
        })
    }
}

fn transfer_limits() -> SnapshotTransferLimits {
    SnapshotTransferLimits::new(200_000, 10, 200_000, 1_000_000)
}

fn query_limits() -> PropertyQueryLimits {
    PropertyQueryLimits {
        max_input_rows: 100,
        max_input_bytes: 1_000_000,
        max_join_rows: 100,
        max_output_cells: 300,
        execution_memory_bytes: 16 * 1024 * 1024,
    }
}

fn result_limits() -> mrr::QueryResultLimits {
    mrr::QueryResultLimits::new(
        NonZeroUsize::new(100).unwrap(),
        NonZeroUsize::new(300).unwrap(),
    )
}

#[tokio::test]
async fn original_healthcare_source_reaches_mrr_admission_over_restored_snapshot() {
    let (relations, entities) = catalogs();
    let coverage_bytes = b"complete test projection from two accepted Case receipts";
    let coverage =
        CoverageDescriptor::new(CoverageKind::Complete, raw_cid(coverage_bytes)).unwrap();
    let local = MemoryContentStore::default();
    let rows = projected_rows();
    let materialized = materialize_property_snapshot(
        PropertySnapshotInput {
            semantic_snapshot: snapshot(),
            relation_catalog: &relations,
            entity_catalog: &entities,
            rows: &rows,
            coverage,
            coverage_bytes,
            limits: PropertySnapshotLimits {
                max_rows: 100,
                max_blocks: 10,
                max_block_bytes: 200_000,
                max_total_bytes: 1_000_000,
            },
        },
        &local,
    )
    .await
    .unwrap();
    let remote = Remote::default();
    publish_snapshot(
        &local,
        &remote,
        &materialized.snapshot,
        &relations,
        &entities,
        transfer_limits(),
    )
    .await
    .unwrap();
    let cold_local = MemoryContentStore::default();
    let restored = restore_snapshot(
        &cold_local,
        &remote,
        materialized.snapshot.cid(),
        &relations,
        &entities,
        transfer_limits(),
    )
    .await
    .unwrap();
    let executor = RestoredPropertyExecutor {
        restored: &restored,
        relation_catalog: &relations,
        entity_catalog: &entities,
        limits: query_limits(),
    };
    let result = execute_property_source(
        SOURCE_NAME,
        SOURCE,
        SOURCE_DIGEST,
        &executor,
        result_limits(),
    )
    .await
    .unwrap();
    let scalar = |text: &str| mrr::QueryResultValue::Scalar {
        schema: mrr::ValueSchema::String,
        value: mrr::Value::String(text.into()),
    };
    assert_eq!(result.compilation.source_digest, SOURCE_DIGEST);
    assert_eq!(
        result.candidate.rows(),
        &[vec![
            scalar("healthcare"),
            scalar("case-one"),
            scalar("healing")
        ]],
    );
    let rejected = execute_property_source(
        SOURCE_NAME,
        SOURCE,
        "sha256:wrong",
        &executor,
        result_limits(),
    )
    .await;
    assert!(matches!(
        rejected,
        Err(PropertySourceExecutionError::Semantic(
            PropertySourceQueryError::SourceDigestMismatch
        ))
    ));
}
