// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Bounded original MRR rule content projection. Scheme alone evaluates proofs.
use crate::{Error, datum, mrr_support::validate_catalog, wire::Value};
use meta_relational_reasoning as m;
use std::collections::{BTreeMap, BTreeSet};

#[derive(Clone, Debug)]
pub struct MrrRuleProgramProjection {
    originals: Vec<m::Rule>,
    catalog_digest: m::RelationCatalogDigest,
    payload: Value,
}
impl MrrRuleProgramProjection {
    /// The host declares the correspondence to ASCENT's numeric generation.
    /// This does not authenticate a provider or execute the original rules.
    pub fn admit(
        identity: &str,
        generation: m::GenerationId,
        ascent_generation: i64,
        catalog: &m::RelationCatalog,
        rules: &[m::Rule],
    ) -> Result<Self, Error> {
        validate_catalog(catalog)?;
        if identity.is_empty()
            || identity.chars().count() > 256
            || ascent_generation < 0
            || rules.is_empty()
            || rules.len() > 32
        {
            return Err(Error::InvalidInput);
        }
        let mut ids = BTreeSet::new();
        let mut projected = Vec::new();
        for rule in rules {
            if !ids.insert(rule.id()) || rule.body().len() > 32 {
                return Err(Error::InvalidInput);
            }
            m::Rule::new(rule.id(), rule.head().clone(), rule.body().to_vec())
                .map_err(|_| Error::InvalidInput)?;
            let mut types = BTreeMap::new();
            let body = rule
                .body()
                .iter()
                .map(|a| atom(a, catalog, &mut types))
                .collect::<Result<Vec<_>, _>>()?;
            let head = atom(rule.head(), catalog, &mut types)?;
            projected.push(datum!({"identity":rule.id().to_string(),"head":head,"body":body}));
        }
        let relations = catalog.relations().iter().map(|r| datum!({"identity":r.id().to_string(),
            "predicate":r.predicate(),"columns":r.fields().iter().map(|f| Value::from(match f.schema() {
                m::ValueSchema::Integer => "integer", m::ValueSchema::Boolean => "boolean", _ => unreachable!()
            })).collect::<Vec<_>>()})).collect::<Vec<_>>();
        let catalog_digest = catalog.digest();
        let digest = catalog_digest
            .as_bytes()
            .iter()
            .map(|b| format!("{b:02x}"))
            .collect::<String>();
        Ok(Self {
            originals: rules.to_vec(),
            catalog_digest,
            payload: datum!({"schema":"poo-flow.mrr-rule-program.v1","identity":identity,
                "catalogDigest":digest,"generation":generation.to_string(),"ascentGeneration":ascent_generation,
                "relations":relations,"rules":projected}),
        })
    }
    pub fn originals(&self) -> &[m::Rule] {
        &self.originals
    }
    pub fn payload(&self) -> &Value {
        &self.payload
    }
    pub fn catalog_digest(&self) -> m::RelationCatalogDigest {
        self.catalog_digest
    }
}
fn atom(
    a: &m::Atom,
    catalog: &m::RelationCatalog,
    types: &mut BTreeMap<String, m::ValueSchema>,
) -> Result<Value, Error> {
    let schema = catalog.relation(a.relation).ok_or(Error::InvalidInput)?;
    if a.terms.len() != schema.fields().len() {
        return Err(Error::InvalidInput);
    }
    let mut terms = Vec::new();
    for (term, field) in a.terms.iter().zip(schema.fields()) {
        let value = match term {
            m::Term::Variable(v) => {
                let name = v.as_str();
                if name.is_empty()
                    || name.len() > 256
                    || !name.bytes().all(|c| c.is_ascii_alphanumeric() || c == b'_')
                    || m::Variable::new(name).is_none()
                {
                    return Err(Error::InvalidInput);
                }
                if let Some(previous) = types.insert(name.to_owned(), field.schema().clone()) {
                    if previous != *field.schema() {
                        return Err(Error::InvalidInput);
                    }
                }
                datum!({"kind":"variable","name":name})
            }
            m::Term::Value(m::Value::Integer(n)) if *field.schema() == m::ValueSchema::Integer => {
                datum!({"kind":"integer","value":*n})
            }
            m::Term::Value(m::Value::Boolean(b)) if *field.schema() == m::ValueSchema::Boolean => {
                datum!({"kind":"boolean","value":*b})
            }
            _ => return Err(Error::InvalidInput),
        };
        terms.push(value);
    }
    Ok(datum!({"relationId":a.relation.to_string(),"terms":terms}))
}
