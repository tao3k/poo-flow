// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Original owner lineage graph projection; native Scheme verifies derivation truth.
use crate::{
    Error, datum, mrr_rule::MrrRuleProgramProjection, mrr_support::MrrFactProjection, wire::Value,
};
use meta_relational_reasoning as m;
use std::collections::{BTreeMap, BTreeSet};
#[derive(Clone, Debug)]
pub struct MrrDerivationProjection {
    facts: Vec<m::Fact>,
    derivations: Vec<m::Derivation>,
    payload: Value,
}
impl MrrDerivationProjection {
    pub fn admit(
        identity: &str,
        program: &MrrRuleProgramProjection,
        catalog: &m::RelationCatalog,
        root: m::FactId,
        facts: &[m::Fact],
        derivations: &[m::Derivation],
    ) -> Result<Self, Error> {
        if identity.is_empty()
            || identity.chars().count() > 256
            || facts.is_empty()
            || facts.len() > 128
            || derivations.is_empty()
            || derivations.len() > 128
            || program.catalog_digest() != catalog.digest()
        {
            return Err(Error::InvalidInput);
        }
        let mut by_fact = BTreeMap::new();
        let mut projected = Vec::new();
        for fact in facts {
            if by_fact.insert(fact.id(), fact).is_some()
                || Value::from(fact.context().generation().to_string())
                    != program.payload()["generation"]
            {
                return Err(Error::InvalidInput);
            }
            let content = MrrFactProjection::admit(fact, catalog)?;
            projected.push(datum!({"content":content.payload().clone(),"contentDigest":content.content_digest(),
                "source":matches!(fact.context().authority(),m::RelationAuthority::Entity(_))}));
        }
        let mut by_output = BTreeMap::new();
        let mut ids = BTreeSet::new();
        let mut ds = Vec::new();
        for d in derivations {
            m::Derivation::new(
                d.id(),
                d.rule(),
                d.generation(),
                d.output().clone(),
                d.support().to_vec(),
            )
            .map_err(|_| Error::InvalidInput)?;
            let rule = program
                .originals()
                .iter()
                .find(|r| r.id() == d.rule())
                .ok_or(Error::InvalidInput)?;
            if !ids.insert(d.id())
                || by_output.insert(d.output().id(), d).is_some()
                || by_fact.get(&d.output().id()).copied() != Some(d.output())
                || rule.head().relation != d.output().relation()
                || d.support().len() > 128
                || d.support().iter().any(|id| !by_fact.contains_key(id))
            {
                return Err(Error::InvalidInput);
            }
            ds.push(datum!({"identity":d.id().to_string(),"rule":d.rule().to_string(),"generation":d.generation().to_string(),
                "output":d.output().id().to_string(),"supports":d.support().iter().map(|id|Value::from(id.to_string())).collect::<Vec<_>>()}));
        }
        for fact in facts {
            match (fact.context().authority(), fact.context().provenance()) {
                (m::RelationAuthority::Entity(_), m::FactProvenance::Source(_))
                    if !by_output.contains_key(&fact.id()) =>
                {
                    ()
                }
                (m::RelationAuthority::Rule(_), m::FactProvenance::Derivation(_))
                    if by_output.contains_key(&fact.id()) =>
                {
                    ()
                }
                _ => return Err(Error::InvalidInput),
            }
        }
        if !by_output.contains_key(&root) {
            return Err(Error::InvalidInput);
        }
        let mut visiting = BTreeSet::new();
        let mut visited = BTreeSet::new();
        visit(root, &by_output, &mut visiting, &mut visited)?;
        if visited.len() != facts.len() {
            return Err(Error::InvalidInput);
        }
        Ok(Self {
            facts: facts.to_vec(),
            derivations: derivations.to_vec(),
            payload: datum!({"schema":"poo-flow.mrr-derivation-projection.v1","identity":identity,
                "program":program.payload().clone(),"rootFact":root.to_string(),"facts":projected,"derivations":ds}),
        })
    }
    pub fn facts(&self) -> &[m::Fact] {
        &self.facts
    }
    pub fn derivations(&self) -> &[m::Derivation] {
        &self.derivations
    }
    pub fn payload(&self) -> &Value {
        &self.payload
    }
}
fn visit(
    id: m::FactId,
    graph: &BTreeMap<m::FactId, &m::Derivation>,
    visiting: &mut BTreeSet<m::FactId>,
    visited: &mut BTreeSet<m::FactId>,
) -> Result<(), Error> {
    if visited.contains(&id) {
        return Ok(());
    }
    if !visiting.insert(id) {
        return Err(Error::InvalidInput);
    }
    if let Some(d) = graph.get(&id) {
        for child in d.support() {
            visit(*child, graph, visiting, visited)?;
        }
    }
    visiting.remove(&id);
    visited.insert(id);
    Ok(())
}
