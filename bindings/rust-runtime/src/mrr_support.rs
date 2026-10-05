// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Original MRR lineage identities with an explicit host revision correspondence.
//! Shape admission is not rule evaluation, proof admission or source authentication.
use crate::{
    Error, SemanticRuntime, datum,
    wire::{self, Value},
};
use meta_relational_reasoning::{Derivation, FactId};
use sha2::{Digest, Sha256};
use std::collections::{BTreeMap, BTreeSet};

#[derive(Clone, Debug)]
pub struct MrrSupportBinding {
    pub fact: FactId,
    pub subject: String,
    pub revision: String,
}
#[derive(Clone, Debug)]
pub struct MrrSupportProjection {
    originals: Vec<Derivation>,
    program: Value,
}
impl MrrSupportProjection {
    /// Re-admit original owner values; preserve IDs rather than inventing generations.
    pub fn admit(
        identity: &str,
        policy: &str,
        complete: bool,
        derivations: &[Derivation],
        bindings: &[MrrSupportBinding],
    ) -> Result<Self, Error> {
        let text = |s: &str| !s.is_empty() && s.chars().count() <= 256;
        if !text(identity)
            || !text(policy)
            || derivations.is_empty()
            || derivations.len() > 128
            || bindings.len() > 128
        {
            return Err(Error::InvalidInput);
        }
        let mut bound = BTreeMap::new();
        for b in bindings {
            if !text(&b.subject) || !text(&b.revision) || bound.insert(b.fact, b).is_some() {
                return Err(Error::InvalidInput);
            }
        }
        let generation = derivations[0].generation();
        let mut seen = BTreeSet::new();
        let mut used = BTreeSet::new();
        let mut supports = Vec::new();
        for d in derivations {
            if d.generation() != generation || !seen.insert(d.id()) || d.support().len() > 128 {
                return Err(Error::InvalidInput);
            }
            Derivation::new(
                d.id(),
                d.rule(),
                d.generation(),
                d.output().clone(),
                d.support().to_vec(),
            )
            .map_err(|_| Error::InvalidInput)?;
            let mut subjects = BTreeSet::new();
            let mut premises = Vec::new();
            let mut facts = Vec::new();
            for fact in d.support() {
                let b = bound.get(fact).ok_or(Error::InvalidInput)?;
                if !subjects.insert(&b.subject) {
                    return Err(Error::InvalidInput);
                }
                used.insert(*fact);
                premises.push(datum!({"subject":b.subject.clone(),"revision":b.revision.clone()}));
                facts.push(Value::from(fact.to_string()));
            }
            facts.sort_by(|a, b| a.as_str().cmp(&b.as_str()));
            let origin = datum!({"schema":"poo-flow.mrr-support-identity.v1",
                "derivation":d.id().to_string(),"rule":d.rule().to_string(),
                "generation":d.generation().to_string(),"output":d.output().id().to_string(),"support":facts});
            let proof = format!(
                "sha256:{:x}",
                Sha256::digest(wire::to_vec(&origin).map_err(|_| Error::InvalidInput)?)
            );
            supports.push(
                datum!({"identity":d.id().to_string(),"conclusion":d.output().id().to_string(),
                "proof":proof,"premises":premises,"parents":Vec::<Value>::new()}),
            );
        }
        if used.len() != bound.len() {
            return Err(Error::InvalidInput);
        }
        Ok(Self {
            originals: derivations.to_vec(),
            program: datum!({"identity":identity,"policy":policy,"complete":complete,"supports":supports}),
        })
    }
    pub fn originals(&self) -> &[Derivation] {
        &self.originals
    }
    pub fn program(&self) -> &Value {
        &self.program
    }
    /// Scheme owns applicability; the caller supplies the declared temporal journal.
    pub fn evaluate(
        &self,
        runtime: &SemanticRuntime,
        journal: Value,
        as_of: i64,
        valid_at: Value,
        budget: u32,
    ) -> Result<Value, Error> {
        runtime.call("temporal.support.evaluate", &datum!({"schema":"poo-flow.temporal-support-request.v1",
            "program":self.program.clone(),"journal":journal,"asOf":as_of,"validAt":valid_at,"budget":budget}))
    }
}
