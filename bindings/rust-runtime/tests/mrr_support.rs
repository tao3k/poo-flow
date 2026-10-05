// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
#![cfg(feature = "mrr-transport")]
use meta_relational_reasoning as m;
use poo_flow_rust_runtime::{
    SemanticRuntime, datum,
    mrr_support::{MrrSupportBinding, MrrSupportProjection},
    wire::{self, Value},
};
fn fixture() -> (Vec<m::Derivation>, Vec<MrrSupportBinding>) {
    let generation = m::GenerationId::from_canonical_bytes("support-generation").unwrap();
    let rule = m::RuleId::from_canonical_bytes("original-rule").unwrap();
    let output = m::FactId::from_canonical_bytes("original-output").unwrap();
    let mut ds = Vec::new();
    let mut bindings = Vec::new();
    for name in ["a", "b"] {
        let id = m::DerivationId::from_canonical_bytes(name).unwrap();
        let fact = m::FactId::from_canonical_bytes(format!("source-{name}")).unwrap();
        let context = m::RelationContext::new(
            generation,
            m::RelationAuthority::Rule(rule),
            m::FactProvenance::Derivation(id),
            m::EvidenceCompleteness::Complete,
            m::FactValidity::Valid,
        )
        .unwrap();
        let out = m::Fact::new(
            output,
            m::RelationId::from_canonical_bytes("claim").unwrap(),
            vec![m::Value::Integer(1)],
            context,
        );
        ds.push(m::Derivation::new(id, rule, generation, out, vec![fact]).unwrap());
        bindings.push(MrrSupportBinding {
            fact,
            subject: name.into(),
            revision: format!("{name}1"),
        });
    }
    (ds, bindings)
}
fn journal() -> Value {
    let rev = |id: &str, subject: &str, time: i32, predecessor: Value| {
        let retract = time > 1;
        datum!({"identity":id,"subject":subject,"operation":if retract {"retract"} else {"assert"},
            "predecessor":predecessor,"admitted":time,
            "validRange":if retract {Value::from(false)} else {datum!([0,10])},
            "content":if retract {Value::from(false)} else {Value::from(id)}})
    };
    datum!({"identity":"journal","admissionDomain":"txn","validDomain":"valid","revisions":vec![
        rev("a1","a",1,false.into()),rev("b1","b",1,false.into()),
        rev("a2","a",2,"a1".into()),rev("b2","b",3,"b1".into())]})
}
#[test]
fn original_mrr_support_identity_and_native_temporal_cuts() {
    let (ds, bindings) = fixture();
    let projection =
        MrrSupportProjection::admit("mrr-supports", "read-only", true, &ds, &bindings).unwrap();
    assert_eq!(projection.originals(), ds.as_slice());
    assert_eq!(
        projection.program()["supports"].as_array().unwrap()[0]["identity"],
        ds[0].id().to_string()
    );
    assert_eq!(
        projection.program()["supports"].as_array().unwrap()[0]["conclusion"],
        ds[0].output().id().to_string()
    );
    let runtime = SemanticRuntime::open(
        std::env::var("POO_FLOW_SEMANTIC_LIBRARY").unwrap(),
        &std::env::var("POO_FLOW_SEMANTIC_SHA256").unwrap(),
        64,
    )
    .unwrap();
    let first = projection
        .evaluate(&runtime, journal(), 1, false.into(), 128)
        .unwrap();
    assert_eq!(
        first["conclusions"].as_array().unwrap()[0]["activeSupports"]
            .as_array()
            .unwrap()
            .len(),
        2
    );
    println!("CASE original MRR identities and two active supports");
    let one = projection
        .evaluate(&runtime, journal(), 2, false.into(), 128)
        .unwrap();
    assert_eq!(
        one["conclusions"].as_array().unwrap()[0]["activeSupports"],
        Value::from(vec![Value::from(ds[1].id().to_string())])
    );
    println!("CASE withdrawal preserves remaining support");
    let none = projection
        .evaluate(&runtime, journal(), 3, false.into(), 128)
        .unwrap();
    assert_eq!(
        none["conclusions"].as_array().unwrap()[0]["status"],
        "unsupported"
    );
    for key in [
        "proofAdmitted",
        "sourceAuthenticated",
        "actionAuthorized",
        "durable",
    ] {
        assert_eq!(none[key], false);
    }
    assert_eq!(
        projection
            .evaluate(&runtime, journal(), 1, false.into(), 128)
            .unwrap(),
        first
    );
    println!("CASE final withdrawal and historical replay");
    let req = datum!({"schema":"poo-flow.temporal-support-request.v1","program":projection.program().clone(),
        "journal":journal(),"asOf":1,"validAt":false,"budget":128});
    if let Ok(path) = std::env::var("POO_FLOW_MRR_SUPPORT_ORACLE") {
        std::fs::write(
            path,
            wire::to_vec(&datum!({"request":req,"expected":first})).unwrap(),
        )
        .unwrap();
    }
    original_mrr_fact_content_parity_and_profile_controls(&runtime);
}
#[test]
fn reject_incomplete_or_ambiguous_host_correspondence() {
    let (ds, b) = fixture();
    assert!(MrrSupportProjection::admit("p", "policy", true, &ds, &b[..1]).is_err());
    let mut duplicate = b.clone();
    duplicate.push(b[0].clone());
    assert!(MrrSupportProjection::admit("p", "policy", true, &ds, &duplicate).is_err());
    let mut extra = b.clone();
    extra.push(MrrSupportBinding {
        fact: m::FactId::from_canonical_bytes("unused").unwrap(),
        subject: "unused".into(),
        revision: "u1".into(),
    });
    assert!(MrrSupportProjection::admit("p", "policy", true, &ds, &extra).is_err());
    assert!(
        MrrSupportProjection::admit("p", "policy", true, &[ds[0].clone(), ds[0].clone()], &b)
            .is_err()
    );
    println!("CASE missing duplicate unused bindings and repeated derivation rejected");
}

fn original_mrr_fact_content_parity_and_profile_controls(runtime: &SemanticRuntime) {
    use poo_flow_rust_runtime::mrr_support::MrrFactProjection;
    let generation = m::GenerationId::from_canonical_bytes("fact-generation").unwrap();
    let source = m::EntityId::from_canonical_bytes("source-owner").unwrap();
    let context = m::RelationContext::new(
        generation,
        m::RelationAuthority::Entity(source),
        m::FactProvenance::Source(source),
        m::EvidenceCompleteness::Complete,
        m::FactValidity::Valid,
    )
    .unwrap();
    let mut fixtures = Vec::new();
    for (name, row, rel) in [
        (
            "a",
            vec![m::Value::Integer(1), m::Value::Integer(2)],
            "edge",
        ),
        (
            "b",
            vec![m::Value::Integer(2), m::Value::Integer(3)],
            "edge",
        ),
        (
            "output",
            vec![m::Value::Integer(1), m::Value::Integer(3)],
            "path",
        ),
    ] {
        let rule = m::RuleId::from_canonical_bytes("path-rule").unwrap();
        let derivation_id = m::DerivationId::from_canonical_bytes("path-derivation").unwrap();
        let fact_context = if name == "output" {
            m::RelationContext::new(
                generation,
                m::RelationAuthority::Rule(rule),
                m::FactProvenance::Derivation(derivation_id),
                m::EvidenceCompleteness::Complete,
                m::FactValidity::Valid,
            )
            .unwrap()
        } else {
            context
        };
        let fact = m::Fact::new(
            m::FactId::from_canonical_bytes(name).unwrap(),
            m::RelationId::from_canonical_bytes(rel).unwrap(),
            row,
            fact_context,
        );
        let projection = MrrFactProjection::admit(&fact, rel).unwrap();
        assert_eq!(projection.original(), &fact);
        let result = projection.verify_content(&runtime).unwrap();
        assert_eq!(result["proofAdmitted"], false);
        let lineage = if name == "output" {
            let supports = vec![
                m::FactId::from_canonical_bytes("a").unwrap(),
                m::FactId::from_canonical_bytes("b").unwrap(),
            ];
            let d = m::Derivation::new(derivation_id, rule, generation, fact.clone(), supports)
                .unwrap();
            datum!({"identity":d.id().to_string(),"rule":d.rule().to_string(),"generation":d.generation().to_string(),
                "output":d.output().id().to_string(),"supports":d.support().iter().map(|f|Value::from(f.to_string())).collect::<Vec<_>>()})
        } else {
            false.into()
        };
        fixtures.push(datum!({"request":projection.payload().clone(),"expected":result,"originalDerivation":lineage}));
        println!("CASE actual MRR fact native content parity {name}");
    }
    let unsupported = m::Fact::new(
        m::FactId::from_canonical_bytes("unsupported").unwrap(),
        m::RelationId::from_canonical_bytes("edge").unwrap(),
        vec![m::Value::String("unmapped".into())],
        context,
    );
    assert!(MrrFactProjection::admit(&unsupported, "edge").is_err());
    let partial = m::Fact::new(
        m::FactId::from_canonical_bytes("partial").unwrap(),
        unsupported.relation(),
        vec![m::Value::Integer(1)],
        m::RelationContext::new(
            generation,
            m::RelationAuthority::Entity(source),
            m::FactProvenance::Source(source),
            m::EvidenceCompleteness::Partial,
            m::FactValidity::Valid,
        )
        .unwrap(),
    );
    assert!(MrrFactProjection::admit(&partial, "edge").is_err());
    if let Ok(path) = std::env::var("POO_FLOW_MRR_FACT_ORACLE") {
        std::fs::write(path, wire::to_vec(&Value::Array(fixtures)).unwrap()).unwrap();
    }
}
