// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Original GQL -> verified physical root -> MRR Scheme v2 -> native Temporal.
use arrow_array::{Int64Array, RecordBatch, StringArray};
use arrow_schema::{DataType, Field, Schema};
use meta_relational_reasoning as m;
use mrr_data_content::{ContentBlock, ContentCodec, ContentStore, MemoryContentStore};
use mrr_data_core as d;
use poo_flow_rust_runtime::{
    SemanticRuntime, datum,
    mrr::{MrrObservationEvidence, ObservationScope},
};
use sha2::{Digest, Sha256};
use std::{num::NonZeroUsize, sync::Arc};

fn fixture<T, E: std::fmt::Debug>(value: Result<T, E>) -> Result<T, Box<dyn std::error::Error>> {
    value.map_err(|error| format!("fixture admission rejected: {error:?}").into())
}

const SOURCE: &str =
    "MATCH (a:Event)-[:PRECEDES]->(b:Event) RETURN a.event AS event, a.position AS position";
fn ipc(batch: &RecordBatch) -> Vec<u8> {
    let mut bytes = Vec::new();
    {
        let mut writer =
            arrow_ipc::writer::StreamWriter::try_new(&mut bytes, &batch.schema()).unwrap();
        writer.write(batch).unwrap();
        writer.finish().unwrap();
    }
    bytes
}
#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let digest = format!("sha256:{:x}", Sha256::digest(SOURCE.as_bytes()));
    let compiled =
        mrr_property_source::compile_property_source_query("temporal.gql", SOURCE, &digest)?;
    assert_eq!(compiled.compilation().source_digest, digest);
    assert!(
        mrr_property_source::compile_property_source_query("temporal.gql", SOURCE, "sha256:wrong")
            .is_err()
    );
    println!("Original GQL compiled with source receipt; source substitution rejected");
    let event_type = m::EntityId::from_canonical_bytes(b"mrr.frontend.entity-type.v1\0Event")?;
    let rid = m::RelationId::from_canonical_bytes(b"mrr.frontend.relation-type.v1\0PRECEDES")?;
    let entity = fixture(m::EntitySchema::new(
        event_type,
        "Event",
        vec![
            fixture(m::RelationField::new(
                "event",
                m::ValueSchema::String,
                false,
            ))?,
            fixture(m::RelationField::new(
                "position",
                m::ValueSchema::Integer,
                false,
            ))?,
        ],
    ))?;
    let relation = fixture(m::RelationSchema::new(
        rid,
        "PRECEDES",
        vec![
            fixture(m::RelationField::new(
                "source",
                m::ValueSchema::Entity,
                false,
            ))?,
            fixture(m::RelationField::new(
                "target",
                m::ValueSchema::Entity,
                false,
            ))?,
        ],
        vec![],
    ))?;
    let entities = fixture(m::EntityCatalog::admit(vec![entity.clone()]))?;
    let relations = fixture(m::RelationCatalog::admit(vec![relation]))?;
    let generation = m::GenerationId::from_canonical_bytes(b"temporal-physical-generation")?;
    let semantic = fixture(m::SemanticSnapshot::admit(
        generation,
        vec![fixture(m::RevisionBinding::admit(
            fixture(m::ExternalRevisionIdentity::new(
                "qualification",
                "temporal-events",
                "revision-1",
            ))?,
            generation,
        ))?],
    ))?;
    let source = compiled.bind(&relations, &entities, &semantic)?;
    let id = |name: &str| m::EntityId::from_canonical_bytes(name).unwrap().to_string();
    let nodes = RecordBatch::try_new(
        Arc::new(Schema::new(vec![
            Field::new("entity_id", DataType::Utf8, false),
            Field::new("event", DataType::Utf8, false),
            Field::new("position", DataType::Int64, false),
        ])),
        vec![
            Arc::new(StringArray::from(vec![
                id("build"),
                id("deploy"),
                id("end"),
            ])),
            Arc::new(StringArray::from(vec!["build", "deploy", "end"])),
            Arc::new(Int64Array::from(vec![1, 2, 3])),
        ],
    )?;
    let edges = RecordBatch::try_new(
        Arc::new(Schema::new(vec![
            Field::new("source", DataType::Utf8, false),
            Field::new("target", DataType::Utf8, false),
        ])),
        vec![
            Arc::new(StringArray::from(vec![id("build"), id("deploy")])),
            Arc::new(StringArray::from(vec![id("deploy"), id("end")])),
        ],
    )?;
    let node_bytes = ipc(&nodes);
    let edge_bytes = ipc(&edges);
    let coverage = b"bounded three-event fixture inventory";
    let manifest = d::SnapshotManifest::admit(
        d::SnapshotManifestRequest::new(
            semantic.clone(),
            &relations,
            &entities,
            vec![d::RelationDescriptor::new(
                rid,
                2,
                vec![d::BatchDescriptor::new(
                    d::raw_cid(&edge_bytes),
                    2,
                    edge_bytes.len() as u64,
                )?],
            )?],
            d::CoverageDescriptor::new(d::CoverageKind::Complete, d::raw_cid(coverage))?,
        )
        .with_entities(vec![d::EntityDescriptor::new(
            entity,
            3,
            vec![d::BatchDescriptor::new(
                d::raw_cid(&node_bytes),
                3,
                node_bytes.len() as u64,
            )?],
        )?]),
    )?;
    let snapshot = d::SnapshotBlock::encode(manifest)?;
    let store = MemoryContentStore::default();
    for bytes in [&node_bytes[..], &edge_bytes[..], &coverage[..]] {
        store.put(ContentBlock::new(ContentCodec::Raw, bytes))?;
    }
    store.put(ContentBlock::new(ContentCodec::DagCbor, snapshot.bytes()))?;
    let restored = mrr_data_content::restore_snapshot_local(
        &store,
        snapshot.cid(),
        &relations,
        &entities,
        mrr_data_content::SnapshotTransferLimits::new(65536, 8, 1048576, 2097152),
    )
    .await?;
    println!("Exact immutable root and Arrow children restored");
    let limits = m::QueryResultLimits::new(
        NonZeroUsize::new(128).unwrap(),
        NonZeroUsize::new(256).unwrap(),
    );
    let cap = NonZeroUsize::new(1048576).unwrap();
    let handoff = mrr_data_datafusion::execute_restored_property_query_handoff(
        mrr_data_datafusion::RestoredPropertyQuery {
            query: source.query(),
            restored: &restored,
            relation_catalog: &relations,
            entity_catalog: &entities,
            limits: mrr_data_datafusion::PropertyQueryLimits {
                max_input_rows: 128,
                max_input_bytes: 1048576,
                max_join_rows: 128,
                max_output_cells: 256,
                execution_memory_bytes: 16777216,
            },
        },
        limits,
        cap,
    )
    .await?;
    let expected = d::bind_data_query(
        source.query(),
        &snapshot,
        &mrr_data_datafusion::datafusion_engine_profile()?,
    )?;
    let admitted = handoff.verify(&expected, limits, cap)?;
    assert_eq!(admitted.receipt().row_count(), 2);
    assert_eq!(
        &source.admit(admitted.candidate(), limits)?,
        admitted.receipt()
    );
    let alternative_snapshot = d::SnapshotBlock::encode(d::SnapshotManifest::admit(
        d::SnapshotManifestRequest::new(
            semantic.clone(),
            &relations,
            &entities,
            snapshot.manifest().relations().to_vec(),
            d::CoverageDescriptor::new(
                d::CoverageKind::Complete,
                d::raw_cid(b"different inventory declaration"),
            )?,
        )
        .with_entities(snapshot.manifest().entities().to_vec()),
    )?)?;
    let changed_root = d::bind_data_query(
        source.query(),
        &alternative_snapshot,
        &mrr_data_datafusion::datafusion_engine_profile()?,
    )?;
    assert!(handoff.verify(&changed_root, limits, cap).is_err());
    let changed_rows =
        String::from_utf8(handoff.result_bytes().to_vec())?.replace("\"build\"", "\"forge\"");
    assert_ne!(changed_rows.as_bytes(), handoff.result_bytes());
    assert!(
        m::verify_query_result_transport(source.query(), changed_rows.as_bytes(), limits, cap)
            .is_err()
    );
    assert!(
        handoff
            .verify(&expected, limits, NonZeroUsize::new(1).unwrap())
            .is_err()
    );
    let other_text = SOURCE.replace("a.position AS position", "b.position AS position");
    let other_digest = format!("sha256:{:x}", Sha256::digest(other_text.as_bytes()));
    let other = mrr_property_source::compile_property_source_query(
        "other.gql",
        &other_text,
        &other_digest,
    )?
    .bind(&relations, &entities, &semantic)?;
    assert!(
        m::verify_query_result_transport(other.query(), handoff.result_bytes(), limits, cap)
            .is_err()
    );
    let changed_entities = fixture(m::EntityCatalog::admit(vec![fixture(
        m::EntitySchema::new(
            event_type,
            "Event",
            vec![
                fixture(m::RelationField::new(
                    "event",
                    m::ValueSchema::String,
                    false,
                ))?,
                fixture(m::RelationField::new(
                    "position",
                    m::ValueSchema::String,
                    false,
                ))?,
            ],
        ),
    )?]))?;
    let changed_catalog = mrr_property_source::compile_property_source_query(
        "temporal.gql",
        SOURCE,
        &digest,
    )?
    .bind(&relations, &changed_entities, &semantic)?;
    assert!(
        d::bind_data_query(
            changed_catalog.query(),
            &snapshot,
            &mrr_data_datafusion::datafusion_engine_profile()?
        )
        .is_err()
    );
    assert!(
        m::verify_query_result_transport(
            changed_catalog.query(),
            handoff.result_bytes(),
            limits,
            cap
        )
        .is_err()
    );
    println!("Independent root, catalog, row, query and wire-budget substitutions rejected");
    let empty_text = SOURCE.replace(" RETURN", " WHERE a.event = 'absent' RETURN");
    let empty_digest = format!("sha256:{:x}", Sha256::digest(empty_text.as_bytes()));
    let empty_source = mrr_property_source::compile_property_source_query(
        "empty.gql",
        &empty_text,
        &empty_digest,
    )?
    .bind(&relations, &entities, &semantic)?;
    let empty_handoff = mrr_data_datafusion::execute_restored_property_query_handoff(
        mrr_data_datafusion::RestoredPropertyQuery {
            query: empty_source.query(),
            restored: &restored,
            relation_catalog: &relations,
            entity_catalog: &entities,
            limits: mrr_data_datafusion::PropertyQueryLimits {
                max_input_rows: 128,
                max_input_bytes: 1048576,
                max_join_rows: 128,
                max_output_cells: 256,
                execution_memory_bytes: 16777216,
            },
        },
        limits,
        cap,
    )
    .await?;
    assert_eq!(
        m::verify_query_result_transport(
            empty_source.query(),
            empty_handoff.result_bytes(),
            limits,
            cap
        )?
        .receipt()
        .row_count(),
        0
    );
    assert!(
        MrrObservationEvidence::verify_transport(
            empty_source.query(),
            empty_handoff.result_bytes(),
            limits,
            cap,
            ObservationScope {
                source_identity: "qualification:temporal-events:revision-1".into(),
                temporal_generation: 1,
                cut: snapshot.cid().to_string(),
                projection: "event-position.v1".into(),
                policy: "read-only-fixture".into(),
                clock_domain: "clock".into()
            }
        )
        .is_err()
    );
    println!(
        "Physical empty answer is valid MRR transport and rejected by the nonempty Temporal profile"
    );
    let evidence = MrrObservationEvidence::verify_transport(
        source.query(),
        handoff.result_bytes(),
        limits,
        cap,
        ObservationScope {
            source_identity: "qualification:temporal-events:revision-1".into(),
            temporal_generation: 1,
            cut: snapshot.cid().to_string(),
            projection: "event-position.v1".into(),
            policy: "read-only-fixture".into(),
            clock_domain: "clock".into(),
        },
    )?;
    assert_eq!(evidence.original().receipt(), admitted.receipt());
    println!("Physical GQL result and original MRR receipt re-admitted by Temporal receiver");
    let runtime = SemanticRuntime::open(
        std::env::var("POO_FLOW_SEMANTIC_LIBRARY")?,
        &std::env::var("POO_FLOW_SEMANTIC_SHA256")?,
        64,
    )?;
    let model = datum!({"identity":"physical-gql-family","mode":"exclusive-explanations","complete":true,
        "domains":[{"identity":"clock","role":"event-time"}],"hypotheses":[
        {"identity":"target","cause":"build","effect":"deploy","constraints":[{"identity":"order","relation":"before","left":"build","right":"deploy"}]},
        {"identity":"alternative","cause":"deploy","effect":"deploy","constraints":[{"identity":"reverse","relation":"before","left":"deploy","right":"build"}]}]});
    let task = datum!({"identity":"question","target":"target","limit":false});
    let request = evidence.classification_request(model.clone(), task.clone())?;
    let result = evidence.classify(&runtime, model, task)?;
    assert_eq!(result["classification"], "necessary");
    assert_eq!(result["sourceAuthenticated"], false);
    assert_eq!(result["actionAuthorized"], false);
    runtime.close()?;
    if let Some(path) = std::env::var_os("POO_FLOW_PHYSICAL_RECEIPT") {
        let original_transport = poo_flow_rust_runtime::wire::from_slice(handoff.result_bytes())?;
        let hex = |bytes: &[u8]| bytes.iter().map(|b| format!("{b:02x}")).collect::<String>();
        let receipt = datum!({"schema":"poo-flow.temporal-physical-read-only.v1",
            "source":SOURCE,"sourceDigest":digest,"root":snapshot.cid().to_string(),
            "compilationReceipt":{"schema":source.compilation().schema,
                "language":format!("{:?}",source.compilation().language),
                "source_name":source.compilation().source_name.clone(),
                "source_digest":source.compilation().source_digest.clone(),
                "grammar_digest":source.compilation().grammar_digest.clone(),
                "query_id":source.compilation().query_id.to_string()},
            "nativeArtifactSha256":std::env::var("POO_FLOW_SEMANTIC_SHA256")?,
            "mrrPin":"9ee5ace469e7a9319c74b8be0308e9062a47e587",
            "mrrDataPin":"bdc81a1c9f4289cf3c434f3473985e6911340246",
            "mrrGeneration":generation.to_string(),"temporalGeneration":1,
            "nativeResultDigest":hex(admitted.receipt().digest()),
            "originalMrrTransport":original_transport,"temporalRequest":request.clone(),"temporalResult":result.clone(),
            "executionPremise":"trusted-pinned-local-datafusion-executor",
            "sourceAuthenticated":false,"actionAuthorized":false,"coverageVerified":false});
        let mut output = std::fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(path)?;
        std::io::Write::write_all(&mut output, &poo_flow_rust_runtime::wire::to_vec(&receipt)?)?;
    }
    if let Some(path) = std::env::var_os("POO_FLOW_PHYSICAL_ORACLE") {
        let oracle =
            datum!([{"name":"physical-gql-necessary","payload":request,"expected":result}]);
        let mut output = std::fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(path)?;
        std::io::Write::write_all(&mut output, &poo_flow_rust_runtime::wire::to_vec(&oracle)?)?;
    }
    println!("GQL -> PHYSICAL ROOT -> ORIGINAL MRR SCHEME V2 -> NATIVE TEMPORAL OK");
    Ok(())
}
