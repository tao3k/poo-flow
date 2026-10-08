// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
#![cfg(feature = "mrr-transport")]
use meta_relational_reasoning as m;
use poo_flow_rust_runtime::{
    SemanticRuntime, datum,
    mrr_support::{MrrSupportBinding, MrrSupportProjection},
    wire::{self, Value},
};
fn catalog() -> m::RelationCatalog {
    m::RelationCatalog::admit(
        [("claim", 1), ("edge", 2), ("path", 2)]
            .into_iter()
            .map(|(name, arity)| {
                m::RelationSchema::new(
                    m::RelationId::from_canonical_bytes(name).unwrap(),
                    name,
                    (0..arity)
                        .map(|i| {
                            m::RelationField::new(format!("col{i}"), m::ValueSchema::Integer, false)
                                .unwrap()
                        })
                        .collect(),
                    vec![],
                )
                .unwrap()
            })
            .collect(),
    )
    .unwrap()
}
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
    let projection = MrrSupportProjection::admit(
        "mrr-supports",
        "read-only",
        true,
        &catalog(),
        &ds,
        &bindings,
    )
    .unwrap();
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
        .evaluate(&runtime, &catalog(), journal(), 1, false.into(), 128)
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
        .evaluate(&runtime, &catalog(), journal(), 2, false.into(), 128)
        .unwrap();
    assert_eq!(
        one["conclusions"].as_array().unwrap()[0]["activeSupports"],
        Value::from(vec![Value::from(ds[1].id().to_string())])
    );
    println!("CASE withdrawal preserves remaining support");
    let none = projection
        .evaluate(&runtime, &catalog(), journal(), 3, false.into(), 128)
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
            .evaluate(&runtime, &catalog(), journal(), 1, false.into(), 128)
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
    catalog_substitution_rejected_before_native_call(&runtime);
}
#[test]
fn reject_incomplete_or_ambiguous_host_correspondence() {
    let (ds, b) = fixture();
    assert!(MrrSupportProjection::admit("p", "policy", true, &catalog(), &ds, &b[..1]).is_err());
    let mut duplicate = b.clone();
    duplicate.push(b[0].clone());
    assert!(MrrSupportProjection::admit("p", "policy", true, &catalog(), &ds, &duplicate).is_err());
    let mut extra = b.clone();
    extra.push(MrrSupportBinding {
        fact: m::FactId::from_canonical_bytes("unused").unwrap(),
        subject: "unused".into(),
        revision: "u1".into(),
    });
    assert!(MrrSupportProjection::admit("p", "policy", true, &catalog(), &ds, &extra).is_err());
    assert!(
        MrrSupportProjection::admit(
            "p",
            "policy",
            true,
            &catalog(),
            &[ds[0].clone(), ds[0].clone()],
            &b
        )
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
        let projection = MrrFactProjection::admit(&fact, &catalog()).unwrap();
        assert_eq!(projection.original(), &fact);
        let result = projection.verify_content(runtime, &catalog()).unwrap();
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
        let catalog_digest = projection
            .catalog_digest()
            .as_bytes()
            .iter()
            .map(|b| format!("{b:02x}"))
            .collect::<String>();
        fixtures.push(datum!({"request":projection.payload().clone(),"expected":result,"originalDerivation":lineage,"originalCatalogDigest":catalog_digest}));
        println!("CASE actual MRR fact native content parity {name}");
    }
    let unsupported = m::Fact::new(
        m::FactId::from_canonical_bytes("unsupported").unwrap(),
        m::RelationId::from_canonical_bytes("edge").unwrap(),
        vec![m::Value::String("unmapped".into())],
        context,
    );
    assert!(MrrFactProjection::admit(&unsupported, &catalog()).is_err());
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
    assert!(MrrFactProjection::admit(&partial, &catalog()).is_err());
    if let Ok(path) = std::env::var("POO_FLOW_MRR_FACT_ORACLE") {
        std::fs::write(path, wire::to_vec(&Value::Array(fixtures)).unwrap()).unwrap();
    }
}

fn catalog_substitution_rejected_before_native_call(runtime: &SemanticRuntime) {
    use poo_flow_rust_runtime::mrr_support::MrrFactProjection;
    let (derivations, bindings) = fixture();
    let admitted = catalog();
    let support =
        MrrSupportProjection::admit("p", "policy", true, &admitted, &derivations, &bindings)
            .unwrap();
    let fact = MrrFactProjection::admit(derivations[0].output(), &admitted).unwrap();
    let changed = m::RelationCatalog::admit(
        admitted
            .relations()
            .iter()
            .map(|schema| {
                m::RelationSchema::new(
                    schema.id(),
                    schema.predicate(),
                    schema
                        .fields()
                        .iter()
                        .map(|f| {
                            m::RelationField::new(
                                format!("changed_{}", f.name()),
                                f.schema().clone(),
                                f.nullable(),
                            )
                            .unwrap()
                        })
                        .collect(),
                    vec![],
                )
                .unwrap()
            })
            .collect(),
    )
    .unwrap();
    assert_ne!(admitted.digest(), changed.digest());
    assert!(fact.verify_content(runtime, &changed).is_err());
    assert!(
        support
            .evaluate(runtime, &changed, journal(), 1, false.into(), 128)
            .is_err()
    );
    assert_eq!(fact.catalog_digest(), admitted.digest());
    assert_eq!(support.catalog_digest(), admitted.digest());
    assert_eq!(
        fact.verify_content(runtime, &admitted).unwrap()["contentDigest"],
        fact.content_digest()
    );
    println!(
        "CASE changed original catalog rejected by fact and support before native call; original catalog remains usable"
    );
}

#[test]
fn original_catalog_shape_and_relation_correspondence_rejects() {
    use poo_flow_rust_runtime::mrr_support::MrrFactProjection;
    let (ds, bindings) = fixture();
    let original = ds[0].output();
    let schema = |id: &str, predicate: &str, fields: Vec<m::RelationField>, constraints| {
        m::RelationSchema::new(
            m::RelationId::from_canonical_bytes(id).unwrap(),
            predicate,
            fields,
            constraints,
        )
        .unwrap()
    };
    let field = |kind, nullable| m::RelationField::new("col", kind, nullable).unwrap();
    let wrong_arity = m::RelationCatalog::admit(vec![schema(
        "claim",
        "claim",
        vec![
            field(m::ValueSchema::Integer, false),
            m::RelationField::new("extra", m::ValueSchema::Integer, false).unwrap(),
        ],
        vec![],
    )])
    .unwrap();
    let wrong_type = m::RelationCatalog::admit(vec![schema(
        "claim",
        "claim",
        vec![field(m::ValueSchema::Boolean, false)],
        vec![],
    )])
    .unwrap();
    let absent = m::RelationCatalog::admit(vec![schema(
        "missing",
        "missing",
        vec![field(m::ValueSchema::Integer, false)],
        vec![],
    )])
    .unwrap();
    for invalid in [&wrong_arity, &wrong_type, &absent] {
        assert!(MrrFactProjection::admit(original, invalid).is_err());
        assert!(MrrSupportProjection::admit("p", "policy", true, invalid, &ds, &bindings).is_err());
    }
    let duplicate_predicate = m::RelationCatalog::admit(vec![
        schema(
            "claim",
            "claim",
            vec![field(m::ValueSchema::Integer, false)],
            vec![],
        ),
        schema(
            "other",
            "claim",
            vec![field(m::ValueSchema::Integer, false)],
            vec![],
        ),
    ])
    .unwrap();
    let nullable = m::RelationCatalog::admit(vec![schema(
        "claim",
        "claim",
        vec![field(m::ValueSchema::Integer, true)],
        vec![],
    )])
    .unwrap();
    let constrained = m::RelationCatalog::admit(vec![schema(
        "claim",
        "claim",
        vec![field(m::ValueSchema::Integer, false)],
        vec![m::RelationConstraint::Key(vec!["col".into()])],
    )])
    .unwrap();
    let unsupported = m::RelationCatalog::admit(vec![schema(
        "claim",
        "claim",
        vec![field(m::ValueSchema::String, false)],
        vec![],
    )])
    .unwrap();
    let unsafe_name = m::RelationCatalog::admit(vec![schema(
        "claim",
        "claim-name",
        vec![field(m::ValueSchema::Integer, false)],
        vec![],
    )])
    .unwrap();
    let oversized = m::RelationCatalog::admit(
        (0..33)
            .map(|i| {
                schema(
                    &format!("r{i}"),
                    &format!("r{i}"),
                    vec![field(m::ValueSchema::Integer, false)],
                    vec![],
                )
            })
            .collect(),
    )
    .unwrap();
    for invalid in [
        &duplicate_predicate,
        &nullable,
        &constrained,
        &unsupported,
        &unsafe_name,
        &oversized,
    ] {
        assert!(MrrFactProjection::admit(original, invalid).is_err());
        assert!(MrrSupportProjection::admit("p", "policy", true, invalid, &ds, &bindings).is_err());
    }
    let admitted = catalog();
    let projection = MrrFactProjection::admit(original, &admitted).unwrap();
    assert_eq!(projection.payload()["evaluatorRelation"], "claim");
    let mut reordered = admitted.relations().to_vec();
    reordered.reverse();
    let same = m::RelationCatalog::admit(reordered).unwrap();
    assert_eq!(projection.catalog_digest(), same.digest());
    // Supported mixed scalar profile uses the owner's declared positions.
    let mixed_catalog = m::RelationCatalog::admit(vec![schema(
        "claim",
        "claim",
        vec![
            field(m::ValueSchema::Boolean, false),
            m::RelationField::new("n", m::ValueSchema::Integer, false).unwrap(),
        ],
        vec![],
    )])
    .unwrap();
    let mixed = m::Fact::new(
        original.id(),
        original.relation(),
        vec![m::Value::Boolean(true), m::Value::Integer(i64::MIN)],
        *original.context(),
    );
    assert_eq!(
        MrrFactProjection::admit(&mixed, &mixed_catalog)
            .unwrap()
            .payload()["row"],
        Value::Array(vec![true.into(), i64::MIN.into()])
    );
    println!(
        "CASE original catalog shape, missing relation, collisions, unsupported schemas and bounds reject; canonical order and mixed scalar positions retain"
    );
}
