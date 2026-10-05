// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
#![cfg(feature = "mrr-transport")]
use meta_relational_reasoning as m;
use poo_flow_rust_runtime::{mrr_rule::MrrRuleProgramProjection, wire};
fn catalog() -> m::RelationCatalog {
    m::RelationCatalog::admit(
        ["edge", "path"]
            .into_iter()
            .map(|name| {
                m::RelationSchema::new(
                    m::RelationId::from_canonical_bytes(name).unwrap(),
                    name,
                    ["from", "to"]
                        .into_iter()
                        .map(|n| m::RelationField::new(n, m::ValueSchema::Integer, false).unwrap())
                        .collect(),
                    vec![],
                )
                .unwrap()
            })
            .collect(),
    )
    .unwrap()
}
fn variable(n: &str) -> m::Term {
    m::Term::Variable(m::Variable::new(n).unwrap())
}
fn atom(rel: &str, names: &[&str]) -> m::Atom {
    m::Atom {
        relation: m::RelationId::from_canonical_bytes(rel).unwrap(),
        terms: names.iter().map(|n| variable(n)).collect(),
    }
}
fn rules() -> Vec<m::Rule> {
    vec![
        m::Rule::new(
            m::RuleId::from_canonical_bytes("base").unwrap(),
            atom("path", &["x", "y"]),
            vec![atom("edge", &["x", "y"])],
        )
        .unwrap(),
        m::Rule::new(
            m::RuleId::from_canonical_bytes("recursive").unwrap(),
            atom("path", &["x", "z"]),
            vec![atom("path", &["x", "y"]), atom("edge", &["y", "z"])],
        )
        .unwrap(),
    ]
}
fn admit(
    c: &m::RelationCatalog,
    r: &[m::Rule],
) -> Result<MrrRuleProgramProjection, poo_flow_rust_runtime::Error> {
    MrrRuleProgramProjection::admit(
        "rules",
        m::GenerationId::from_canonical_bytes("rule-generation").unwrap(),
        1,
        c,
        r,
    )
}

use poo_flow_rust_runtime::mrr_derivation::MrrDerivationProjection;
fn owner_fixture() -> (
    MrrRuleProgramProjection,
    m::RelationCatalog,
    Vec<m::Fact>,
    Vec<m::Derivation>,
) {
    let c = catalog();
    let rs = rules();
    let p = admit(&c, &rs).unwrap();
    let generation = m::GenerationId::from_canonical_bytes("rule-generation").unwrap();
    let source = m::EntityId::from_canonical_bytes("edge-owner").unwrap();
    let context = m::RelationContext::new(
        generation,
        m::RelationAuthority::Entity(source),
        m::FactProvenance::Source(source),
        m::EvidenceCompleteness::Complete,
        m::FactValidity::Valid,
    )
    .unwrap();
    let fact = |name: &str, relation: &str, row: Vec<m::Value>, ctx| {
        m::Fact::new(
            m::FactId::from_canonical_bytes(name).unwrap(),
            m::RelationId::from_canonical_bytes(relation).unwrap(),
            row,
            ctx,
        )
    };
    let a = fact(
        "a",
        "edge",
        vec![m::Value::Integer(1), m::Value::Integer(2)],
        context,
    );
    let b = fact(
        "b",
        "edge",
        vec![m::Value::Integer(2), m::Value::Integer(3)],
        context,
    );
    let make = |name: &str, rule: &m::Rule, row: Vec<m::Value>, supports: Vec<m::FactId>| {
        let id = m::DerivationId::from_canonical_bytes(name).unwrap();
        let ctx = m::RelationContext::new(
            generation,
            m::RelationAuthority::Rule(rule.id()),
            m::FactProvenance::Derivation(id),
            m::EvidenceCompleteness::Complete,
            m::FactValidity::Valid,
        )
        .unwrap();
        m::Derivation::new(
            id,
            rule.id(),
            generation,
            fact(name, "path", row, ctx),
            supports,
        )
        .unwrap()
    };
    let intermediate = make(
        "path12",
        &rs[0],
        vec![m::Value::Integer(1), m::Value::Integer(2)],
        vec![a.id()],
    );
    let root = make(
        "path13",
        &rs[1],
        vec![m::Value::Integer(1), m::Value::Integer(3)],
        vec![intermediate.output().id(), b.id()],
    );
    (
        p,
        c,
        vec![a, b, intermediate.output().clone(), root.output().clone()],
        vec![intermediate, root],
    )
}
#[test]
fn original_recursive_derivation_preserves_direct_inputs() {
    let (p, c, facts, ds) = owner_fixture();
    let projection =
        MrrDerivationProjection::admit("lineage", &p, &c, ds[1].output().id(), &facts, &ds)
            .unwrap();
    assert_eq!(projection.facts(), facts.as_slice());
    assert_eq!(projection.derivations(), ds.as_slice());
    assert!(ds[1].support().contains(&ds[0].output().id()));
    assert!(!ds[1].support().contains(&facts[0].id()));
    if let Ok(path) = std::env::var("POO_FLOW_MRR_DERIVATION_ORACLE") {
        std::fs::write(path, wire::to_vec(projection.payload()).unwrap()).unwrap();
    }
    println!(
        "CASE original recursive Derivation uses intermediate fact plus edge as direct inputs"
    );
}
#[test]
fn reject_missing_extra_duplicate_context_generation_cycle_and_rule_identity() {
    let (p, c, facts, ds) = owner_fixture();
    let root = ds[1].output().id();
    let reject = |fs: &[m::Fact], derivations: &[m::Derivation]| {
        MrrDerivationProjection::admit("lineage", &p, &c, root, fs, derivations).is_err()
    };
    assert!(reject(&facts[1..], &ds));
    assert!(reject(&facts, &ds[..1]));
    let mut extra = facts.clone();
    extra.push(m::Fact::new(
        m::FactId::from_canonical_bytes("unused").unwrap(),
        facts[0].relation(),
        facts[0].values().to_vec(),
        *facts[0].context(),
    ));
    assert!(reject(&extra, &ds));
    let mut duplicate = facts.clone();
    duplicate.push(facts[0].clone());
    assert!(reject(&duplicate, &ds));
    assert!(reject(
        &facts,
        &[ds[0].clone(), ds[1].clone(), ds[1].clone()]
    ));
    let bad = m::Fact::new(
        facts[0].id(),
        facts[0].relation(),
        facts[0].values().to_vec(),
        m::RelationContext::new(
            m::GenerationId::from_canonical_bytes("changed").unwrap(),
            facts[0].context().authority(),
            facts[0].context().provenance(),
            m::EvidenceCompleteness::Complete,
            m::FactValidity::Valid,
        )
        .unwrap(),
    );
    let mut stale = facts.clone();
    stale[0] = bad;
    assert!(reject(&stale, &ds));
    let circular = m::Derivation::new(
        ds[0].id(),
        ds[0].rule(),
        ds[0].generation(),
        ds[0].output().clone(),
        vec![root],
    )
    .unwrap();
    assert!(reject(&facts, &[circular, ds[1].clone()]));
    let unknown = m::RuleId::from_canonical_bytes("unknown").unwrap();
    let out = ds[1].output();
    let wrong = m::Fact::new(
        out.id(),
        out.relation(),
        out.values().to_vec(),
        m::RelationContext::new(
            ds[1].generation(),
            m::RelationAuthority::Rule(unknown),
            m::FactProvenance::Derivation(ds[1].id()),
            m::EvidenceCompleteness::Complete,
            m::FactValidity::Valid,
        )
        .unwrap(),
    );
    let wrong_d = m::Derivation::new(
        ds[1].id(),
        unknown,
        ds[1].generation(),
        wrong.clone(),
        ds[1].support().to_vec(),
    )
    .unwrap();
    let mut changed = facts.clone();
    changed[3] = wrong;
    assert!(reject(&changed, &[ds[0].clone(), wrong_d]));
    assert!(MrrDerivationProjection::admit("lineage", &p, &c, facts[0].id(), &facts, &ds).is_err());
    println!(
        "CASE missing/unused/duplicate facts and derivations, stale generation, cyclic support, unknown rule and source root reject"
    );
}
