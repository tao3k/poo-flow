// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
#![cfg(feature = "mrr-transport")]
use meta_relational_reasoning as m;
use poo_flow_rust_runtime::datum;
use poo_flow_rust_runtime::{
    SemanticRuntime,
    mrr::{MrrObservationEvidence, ObservationScope, SourceRegistrationContext},
};
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
fn original_mrr_values_project_to_real_native_poo() {
    let query = bound("generation-one");
    println!("MRR source query binding reconstructed");
    let rows = candidate(&query, false);
    let cap = NonZeroUsize::new(16384).unwrap();
    let receipt = m::admit_query_result_candidate(&query, &rows, limits()).unwrap();
    let evidence =
        MrrObservationEvidence::verify(&query, &rows, &receipt, limits(), cap, scope()).unwrap();
    let transport = m::export_query_result_transport(&query, &rows, limits(), cap).unwrap();
    let received =
        MrrObservationEvidence::verify_transport(&query, &transport, limits(), cap, scope())
            .unwrap();
    assert_eq!(received.original().candidate(), &rows);
    assert_eq!(received.original().receipt(), &receipt);
    assert_eq!(received.correspondence(), evidence.correspondence());
    println!("Original Scheme v2 candidate and receipt verified");
    assert!(
        MrrObservationEvidence::verify_transport(
            &bound("generation-two"),
            &transport,
            limits(),
            cap,
            scope(),
        )
        .is_err()
    );
    assert!(
        MrrObservationEvidence::verify_transport(&query, b"{}", limits(), cap, scope(),).is_err()
    );
    assert!(
        MrrObservationEvidence::verify_transport(
            &query,
            &transport[..transport.len() - 1],
            limits(),
            cap,
            scope(),
        )
        .is_err()
    );
    let empty = m::CandidateQueryResult::new(
        m::QueryResultBinding::for_query(&query),
        rows.columns().to_vec(),
        vec![],
    );
    let empty_transport = m::export_query_result_transport(&query, &empty, limits(), cap).unwrap();
    assert!(m::verify_query_result_transport(&query, &empty_transport, limits(), cap).is_ok());
    assert!(
        MrrObservationEvidence::verify_transport(&query, &empty_transport, limits(), cap, scope(),)
            .is_err()
    );
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
    let changed = candidate(&query, true);
    assert!(
        MrrObservationEvidence::verify(&query, &changed, &receipt, limits(), cap, scope()).is_err()
    );
    assert!(
        MrrObservationEvidence::verify(
            &bound("generation-two"),
            &rows,
            &receipt,
            limits(),
            cap,
            scope()
        )
        .is_err()
    );
    assert!(
        MrrObservationEvidence::verify(
            &query,
            &rows,
            &receipt,
            limits(),
            NonZeroUsize::new(1).unwrap(),
            scope()
        )
        .is_err()
    );
    let duplicates = candidate(&query, true);
    let duplicate_receipt = m::admit_query_result_candidate(&query, &duplicates, limits()).unwrap();
    assert!(
        MrrObservationEvidence::verify(
            &query,
            &duplicates,
            &duplicate_receipt,
            limits(),
            cap,
            scope()
        )
        .is_err()
    );
    println!("Transport tamper, scope, duplicate and empty controls rejected");
    let runtime = SemanticRuntime::open(
        std::env::var("POO_FLOW_SEMANTIC_LIBRARY").unwrap(),
        &std::env::var("POO_FLOW_SEMANTIC_SHA256").unwrap(),
        64,
    )
    .unwrap();
    let model = datum!({"identity":"original-mrr-family","mode":"exclusive-explanations","complete":true,
        "domains":[{"identity":"clock","role":"event-time"}],"hypotheses":[
            {"identity":"target","cause":"build","effect":"deploy","constraints":[{"identity":"order","relation":"before","left":"build","right":"deploy"}]},
            {"identity":"alternative","cause":"deploy","effect":"deploy","constraints":[{"identity":"reverse","relation":"before","left":"deploy","right":"build"}]}]});
    let task = datum!({"identity":"question","target":"target","limit":false});
    let result = evidence
        .classify(&runtime, model.clone(), task.clone())
        .unwrap();
    assert_eq!(result["classification"], "necessary");
    println!("Native Temporal classified original receipt as necessary");
    assert_eq!(result["actionAuthorized"], false);
    assert_eq!(result["sourceAuthenticated"], false);
    let mut forged = model.clone();
    forged["observations"] = datum!([]);
    assert!(evidence.classify(&runtime, forged, task.clone()).is_err());
    let mut new_scope = scope();
    new_scope.temporal_generation = 8;
    let newer =
        MrrObservationEvidence::verify(&query, &rows, &receipt, limits(), cap, new_scope).unwrap();
    assert_ne!(
        newer
            .classify(&runtime, model.clone(), task.clone())
            .unwrap()["modelDigest"],
        result["modelDigest"]
    );
    let context = || SourceRegistrationContext {
        authority: "fixture-host".into(),
        subject: "deployment".into(),
        scope: "read-only".into(),
    };
    let registered = evidence
        .register_current(&runtime, model.clone(), task.clone(), context())
        .unwrap();
    let historical = registered.admit(&runtime, "deployment-conclusion").unwrap();
    assert_eq!(historical.result()["classification"], "necessary");
    assert_eq!(historical.current(&runtime).unwrap()["status"], "current");
    assert!(
        runtime
            .call("$host.temporal.source.register", &datum!({}))
            .is_err()
    );
    println!("MRR original evidence admitted against the host-registered current source");

    let corrected_query = bound("generation-two");
    let mut corrected_rows = rows.rows().to_vec();
    corrected_rows[0][1] =
        m::QueryResultValue::scalar(m::ValueSchema::Integer, m::Value::Integer(3));
    let corrected = m::CandidateQueryResult::new(
        m::QueryResultBinding::for_query(&corrected_query),
        rows.columns().to_vec(),
        corrected_rows,
    );
    let corrected_transport =
        m::export_query_result_transport(&corrected_query, &corrected, limits(), cap).unwrap();
    let mut corrected_scope = scope();
    corrected_scope.temporal_generation = 8;
    corrected_scope.cut = "cut-8".into();
    let corrected_evidence = MrrObservationEvidence::verify_transport(
        &corrected_query,
        &corrected_transport,
        limits(),
        cap,
        corrected_scope,
    )
    .unwrap();
    let revised_source = corrected_evidence
        .register_current(&runtime, model.clone(), task.clone(), context())
        .unwrap();
    let stale = historical.current(&runtime).unwrap();
    assert_eq!(stale["status"], "stale");
    assert_eq!(stale["sourceAuthenticated"], false);
    assert_eq!(stale["actionAuthorized"], false);
    assert_ne!(stale["originalSourceDigest"], stale["currentSourceDigest"]);
    assert_eq!(historical.result()["classification"], "necessary");
    assert!(registered.admit(&runtime, "stale-admission").is_err());
    assert!(
        evidence
            .register_current(&runtime, model.clone(), task.clone(), context())
            .is_err()
    );
    assert!(
        runtime
            .call(
                "temporal.family.current",
                &datum!({"admissionDigest":"forged"})
            )
            .is_err()
    );
    assert!(
        runtime
            .call(
                "temporal.family.current",
                &datum!({
                    "admissionDigest": &historical.result()["admissionDigest"],
                    "currentSourceDigest": &registered.registration()["sourceDigest"]
                })
            )
            .is_err()
    );
    let revised = revised_source
        .admit(&runtime, "deployment-conclusion-revised")
        .unwrap();
    assert_eq!(revised.result()["classification"], "refuted");
    assert_eq!(revised.current(&runtime).unwrap()["status"], "current");
    assert_ne!(
        historical.result()["admissionDigest"],
        revised.result()["admissionDigest"]
    );
    // Duplicate host delivery is idempotent and cannot restore the old current source.
    let repeated = corrected_evidence
        .register_current(&runtime, model, task, context())
        .unwrap();
    assert_eq!(repeated.registration(), revised_source.registration());
    assert_eq!(historical.current(&runtime).unwrap()["status"], "stale");
    println!("MRR-CORRECTION -> HISTORICAL-STALE -> NATIVE-READMISSION verified");
    for index in 0..126 {
        revised_source
            .admit(&runtime, &format!("history-{index}"))
            .unwrap();
        if (index + 1) % 16 == 0 {
            println!("Native immutable admission entries completed={}", index + 3);
        }
    }
    assert!(revised_source.admit(&runtime, "history-overflow").is_err());
    let repeat = revised_source
        .admit(&runtime, "deployment-conclusion-revised")
        .unwrap();
    assert_eq!(repeat.result(), revised.result());
    assert_eq!(historical.current(&runtime).unwrap()["status"], "stale");
    println!("Native history capacity rejects new entries and preserves idempotent replay");
    println!("MRR-ORIGINAL-RECEIPT -> HOST-CORRESPONDENCE -> NATIVE-POO verified");
    runtime.close().unwrap();
}
