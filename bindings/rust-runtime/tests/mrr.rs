// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
#![cfg(feature = "mrr-transport")]
use meta_relational_reasoning as m;
use poo_flow_rust_runtime::{
    SemanticRuntime,
    mrr::{MrrObservationEvidence, ObservationScope},
};
use serde_json::json;
use std::num::NonZeroUsize;
fn bound(label: &str) -> m::CatalogBoundQuery {
    let rid = m::RelationId::from_canonical_bytes("temporal-observation-relation").unwrap();
    let eid = m::EntityId::from_canonical_bytes("temporal-event-type").unwrap();
    let qid = m::QueryId::from_canonical_bytes("original-event-time-query").unwrap();
    let generation = m::GenerationId::from_canonical_bytes(label).unwrap();
    let b = |s| m::Binding::new(s).unwrap();
    let query = m::MetaQueryIr::new(
        qid,
        m::GraphPattern::new(
            m::QueryOperatorId::from_canonical_bytes("graph").unwrap(),
            vec![m::PathPattern::new(
                m::NodePattern::new(b("source"), vec![eid]),
                vec![m::PathSegment::new(
                    m::RelationPattern::new(None, vec![rid], m::Direction::Outgoing, 1, Some(1))
                        .unwrap(),
                    m::NodePattern::new(b("target"), vec![eid]),
                )],
            )],
        )
        .unwrap(),
        vec![],
        m::QueryResult::returning(m::SetQuantifier::All).with_projections(
            ["event", "position"]
                .iter()
                .map(|name| {
                    m::Projection::new(
                        m::QueryOperatorId::from_canonical_bytes(name.as_bytes()).unwrap(),
                        m::Expression::Property {
                            binding: b("source"),
                            key: m::PropertyKey::new(*name).unwrap(),
                        },
                        b(name),
                    )
                })
                .collect(),
        ),
    )
    .unwrap();
    let bundle = m::ReasoningBundle::admit(m::ReasoningBundleDeclaration {
        relations: vec![
            m::RelationSchema::new(
                rid,
                "precedence",
                vec![
                    m::RelationField::new("source", m::ValueSchema::Entity, false).unwrap(),
                    m::RelationField::new("target", m::ValueSchema::Entity, false).unwrap(),
                ],
                vec![],
            )
            .unwrap(),
        ],
        entities: vec![
            m::EntitySchema::new(
                eid,
                "event",
                vec![
                    m::RelationField::new("event", m::ValueSchema::String, false).unwrap(),
                    m::RelationField::new("position", m::ValueSchema::Integer, false).unwrap(),
                ],
            )
            .unwrap(),
        ],
        query_templates: vec![m::QueryTemplate::new(query, vec![])],
        ..Default::default()
    })
    .unwrap();
    let snapshot = m::SemanticSnapshot::admit(
        generation,
        vec![
            m::RevisionBinding::admit(
                m::ExternalRevisionIdentity::new("fixture", "source", label).unwrap(),
                generation,
            )
            .unwrap(),
        ],
    )
    .unwrap();
    m::bind_query_to_catalog(&bundle, qid, &snapshot).unwrap()
}
fn limits() -> m::QueryResultLimits {
    m::QueryResultLimits::new(
        NonZeroUsize::new(128).unwrap(),
        NonZeroUsize::new(256).unwrap(),
    )
}
fn scope() -> ObservationScope {
    ObservationScope {
        source_identity: "source-owner".into(),
        temporal_generation: 7,
        cut: "cut-7".into(),
        projection: "event-times".into(),
        policy: "policy-1".into(),
        clock_domain: "clock".into(),
    }
}
fn candidate(query: &m::CatalogBoundQuery, duplicate: bool) -> m::CandidateQueryResult {
    m::CandidateQueryResult::new(
        m::QueryResultBinding::for_query(query),
        vec![
            m::Binding::new("event").unwrap(),
            m::Binding::new("position").unwrap(),
        ],
        ["build", if duplicate { "build" } else { "deploy" }]
            .iter()
            .enumerate()
            .map(|(i, name)| {
                vec![
                    m::QueryResultValue::scalar(
                        m::ValueSchema::String,
                        m::Value::String((*name).into()),
                    ),
                    m::QueryResultValue::scalar(
                        m::ValueSchema::Integer,
                        m::Value::Integer(i as i64 + 1),
                    ),
                ]
            })
            .collect(),
    )
}
#[test]
fn original_mrr_transport_projects_to_real_native_poo() {
    let query = bound("generation-one");
    let rows = candidate(&query, false);
    let cap = NonZeroUsize::new(16384).unwrap();
    let bytes = m::export_query_result_transport(&query, &rows, limits(), cap).unwrap();
    let evidence = MrrObservationEvidence::verify(&query, &bytes, limits(), cap, scope()).unwrap();
    assert_eq!(evidence.original().candidate(), &rows);
    assert_eq!(
        evidence.original().receipt().binding().generation(),
        query.generation()
    );
    assert_eq!(evidence.correspondence()["temporalGeneration"], 7);
    assert_eq!(
        evidence.correspondence()["mrrGeneration"],
        query.generation().to_string()
    );
    assert_eq!(evidence.correspondence()["sourceAuthenticated"], false);
    let changed = String::from_utf8(bytes.clone())
        .unwrap()
        .replace("deploy", "forged");
    assert!(
        MrrObservationEvidence::verify(&query, changed.as_bytes(), limits(), cap, scope()).is_err()
    );
    assert!(
        MrrObservationEvidence::verify(&bound("generation-two"), &bytes, limits(), cap, scope())
            .is_err()
    );
    assert!(
        MrrObservationEvidence::verify(
            &query,
            &bytes,
            limits(),
            NonZeroUsize::new(1).unwrap(),
            scope()
        )
        .is_err()
    );
    let duplicates =
        m::export_query_result_transport(&query, &candidate(&query, true), limits(), cap).unwrap();
    assert!(MrrObservationEvidence::verify(&query, &duplicates, limits(), cap, scope()).is_err());
    let runtime = SemanticRuntime::open(
        std::env::var("POO_FLOW_SEMANTIC_LIBRARY").unwrap(),
        &std::env::var("POO_FLOW_SEMANTIC_SHA256").unwrap(),
        64,
    )
    .unwrap();
    let model = json!({"identity":"original-mrr-family","mode":"exclusive-explanations","complete":true,
        "domains":[{"identity":"clock","role":"event-time"}],"hypotheses":[
            {"identity":"target","cause":"build","effect":"deploy","constraints":[{"identity":"order","relation":"before","left":"build","right":"deploy"}]},
            {"identity":"alternative","cause":"deploy","effect":"deploy","constraints":[{"identity":"reverse","relation":"before","left":"deploy","right":"build"}]}]});
    let task = json!({"identity":"question","target":"target","limit":false});
    let result = evidence
        .classify(&runtime, model.clone(), task.clone())
        .unwrap();
    assert_eq!(result["classification"], "necessary");
    assert_eq!(result["actionAuthorized"], false);
    assert_eq!(result["sourceAuthenticated"], false);
    let mut forged = model.clone();
    forged["observations"] = json!([]);
    assert!(evidence.classify(&runtime, forged, task.clone()).is_err());
    let mut new_scope = scope();
    new_scope.temporal_generation = 8;
    let newer = MrrObservationEvidence::verify(&query, &bytes, limits(), cap, new_scope).unwrap();
    assert_ne!(
        newer.classify(&runtime, model, task).unwrap()["modelDigest"],
        result["modelDigest"]
    );
    println!("MRR-ORIGINAL-RECEIPT -> HOST-CORRESPONDENCE -> NATIVE-POO verified");
    runtime.close().unwrap();
}
