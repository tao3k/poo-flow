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
#[test]
fn original_rule_content_and_catalog_projection() {
    let catalog = catalog();
    let rules = rules();
    let projection = admit(&catalog, &rules).unwrap();
    assert_eq!(projection.originals(), rules.as_slice());
    assert_eq!(projection.catalog_digest(), catalog.digest());
    assert_eq!(
        projection.payload()["rules"].as_array().unwrap()[1]["body"]
            .as_array()
            .unwrap()
            .len(),
        2
    );
    if let Ok(path) = std::env::var("POO_FLOW_MRR_RULE_ORACLE") {
        std::fs::write(path, wire::to_vec(projection.payload()).unwrap()).unwrap();
    }
    println!("CASE original base and recursive Rules retain head/body/variables and owner catalog");
}
#[test]
fn reject_missing_relations_arity_literal_type_duplicate_and_variable_type() {
    let c = catalog();
    let rs = rules();
    assert!(admit(&c, &[rs[0].clone(), rs[0].clone()]).is_err());
    let id = rs[0].id();
    for body in [
        vec![atom("missing", &["x", "y"])],
        vec![atom("edge", &["x", "y", "z"])],
        vec![m::Atom {
            relation: rs[0].body()[0].relation,
            terms: vec![variable("x"), m::Term::Value(m::Value::Boolean(true))],
        }],
    ] {
        let head = if body[0].terms.iter().any(|t| t == &variable("y")) {
            atom("path", &["x", "y"])
        } else {
            atom("path", &["x", "x"])
        };
        assert!(admit(&c, &[m::Rule::new(id, head, body).unwrap()]).is_err());
    }
    let mixed = m::RelationCatalog::admit(
        c.relations()
            .iter()
            .map(|s| {
                m::RelationSchema::new(
                    s.id(),
                    s.predicate(),
                    s.fields()
                        .iter()
                        .map(|f| {
                            m::RelationField::new(
                                f.name(),
                                if s.predicate() == "path" {
                                    m::ValueSchema::Boolean
                                } else {
                                    m::ValueSchema::Integer
                                },
                                false,
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
    assert!(admit(&mixed, &rs).is_err());
    assert!(admit(&c, &vec![rs[0].clone(); 33]).is_err());
    println!(
        "CASE missing relation arity literal type repeated rule variable type and rule bound rejected"
    );
}
