// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Original MRR lineage identities with an explicit host revision correspondence.
//! Shape admission is not rule evaluation, proof admission or source authentication.
use crate::{
    Error, SemanticRuntime, datum,
    wire::{self, Value},
};
use meta_relational_reasoning::{Derivation, FactId, RelationCatalog, RelationCatalogDigest};
use sha2::{Digest, Sha256};
use std::collections::{BTreeMap, BTreeSet};

#[derive(Clone, Debug)]
pub struct MrrSupportBinding {
    pub fact: FactId,
    pub subject: String,
    pub revision: String,
}
pub struct MrrSupportCut {
    pub as_of: i64,
    pub valid_at: Value,
    pub budget: u32,
}
pub struct MrrSupportClaimQuery {
    pub claim: FactId,
    pub policy_generation: i64,
    pub policy_digest: String,
    pub expected_context: Option<String>,
}
#[derive(Clone, Debug)]
pub struct MrrSupportProjection {
    originals: Vec<Derivation>,
    program: Value,
    catalog_digest: RelationCatalogDigest,
}
impl MrrSupportProjection {
    /// Re-admit original owner values; preserve IDs rather than inventing generations.
    pub fn admit(
        identity: &str,
        policy: &str,
        complete: bool,
        catalog: &RelationCatalog,
        derivations: &[Derivation],
        bindings: &[MrrSupportBinding],
    ) -> Result<Self, Error> {
        let conclusions: Vec<_> = derivations
            .iter()
            .map(|d| d.output().id())
            .collect::<BTreeSet<_>>()
            .into_iter()
            .collect();
        Self::admit_inventory(
            identity,
            policy,
            complete,
            catalog,
            derivations,
            bindings,
            &conclusions,
        )
    }
    /// Named, caller-scoped inventory also retains conclusions with no derivation.
    /// Completeness is a declared premise, not a proof of exhaustive provenance.
    pub fn admit_inventory(
        identity: &str,
        policy: &str,
        complete: bool,
        catalog: &RelationCatalog,
        derivations: &[Derivation],
        bindings: &[MrrSupportBinding],
        conclusions: &[FactId],
    ) -> Result<Self, Error> {
        let text = |s: &str| !s.is_empty() && s.chars().count() <= 256;
        if !text(identity)
            || !text(policy)
            || conclusions.is_empty()
            || conclusions.len() > 128
            || conclusions.iter().collect::<BTreeSet<_>>().len() != conclusions.len()
            || derivations.len() > 128
            || bindings.len() > 128
        {
            return Err(Error::InvalidInput);
        }
        validate_catalog(catalog)?;
        let mut bound = BTreeMap::new();
        for b in bindings {
            if !text(&b.subject)
                || !text(&b.revision)
                || conclusions.contains(&b.fact)
                || bound.insert(b.fact, b).is_some()
            {
                return Err(Error::InvalidInput);
            }
        }
        let generation = derivations.first().map(Derivation::generation);
        let declared: BTreeSet<_> = conclusions.iter().copied().collect();
        let mut outputs = BTreeMap::new();
        for d in derivations {
            if !declared.contains(&d.output().id()) || bound.contains_key(&d.output().id()) {
                return Err(Error::InvalidInput);
            }
            if let Some(previous) = outputs.insert(d.output().id(), d.output())
                && (previous.relation() != d.output().relation()
                    || previous.values() != d.output().values())
            {
                return Err(Error::InvalidInput);
            }
        }
        let mut seen = BTreeSet::new();
        let mut used = BTreeSet::new();
        let mut supports = Vec::new();
        for d in derivations {
            if Some(d.generation()) != generation || !seen.insert(d.id()) || d.support().len() > 128
            {
                return Err(Error::InvalidInput);
            }
            catalog
                .relation(d.output().relation())
                .ok_or(Error::InvalidInput)?
                .validate_fact(d.output())
                .map_err(|_| Error::InvalidInput)?;
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
            let mut parents = BTreeSet::new();
            for fact in d.support() {
                facts.push(Value::from(fact.to_string()));
                if declared.contains(fact) {
                    parents.insert(*fact);
                    continue;
                }
                let b = bound.get(fact).ok_or(Error::InvalidInput)?;
                if !subjects.insert(&b.subject) {
                    return Err(Error::InvalidInput);
                }
                used.insert(*fact);
                premises.push(datum!({"subject":b.subject.clone(),"revision":b.revision.clone()}));
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
                "proof":proof,"premises":premises,"parents":parents.iter().map(|id|Value::from(id.to_string())).collect::<Vec<_>>()}),
            );
        }
        if used.len() != bound.len() {
            return Err(Error::InvalidInput);
        }
        Ok(Self {
            originals: derivations.to_vec(),
            catalog_digest: catalog.digest(),
            program: datum!({"identity":identity,"policy":policy,"complete":complete,"conclusions":declared.iter().map(|id|Value::from(id.to_string())).collect::<Vec<_>>(),"supports":supports}),
        })
    }
    pub fn originals(&self) -> &[Derivation] {
        &self.originals
    }
    pub fn program(&self) -> &Value {
        &self.program
    }
    pub fn catalog_digest(&self) -> RelationCatalogDigest {
        self.catalog_digest
    }
    /// Native reverse claim scheduling and both cut evaluations; no Rust solver.
    pub fn revise(
        &self,
        runtime: &SemanticRuntime,
        catalog: &RelationCatalog,
        journal: Value,
        previous_as_of: i64,
        cut: MrrSupportCut,
    ) -> Result<Value, Error> {
        recheck_catalog(catalog, self.catalog_digest)?;
        runtime.call(
            "temporal.support.revise",
            &datum!({"schema":"poo-flow.temporal-support-revision-request.v1",
            "previousAsOf":previous_as_of,"task":{
            "schema":"poo-flow.temporal-support-request.v1", "program":self.program.clone(),
            "journal":journal,"asOf":cut.as_of,"validAt":cut.valid_at,"budget":cut.budget}}),
        )
    }
    /// Query a named claim under the registered host policy and clock. A retained
    /// selection binding acts as a stale Context fence, never an effect permit.
    pub fn select(
        &self,
        runtime: &SemanticRuntime,
        catalog: &RelationCatalog,
        task: Value,
        query: MrrSupportClaimQuery,
    ) -> Result<Value, Error> {
        recheck_catalog(catalog, self.catalog_digest)?;
        if task["program"] != self.program {
            return Err(Error::InvalidInput);
        }
        runtime.call(
            "temporal.support.claim",
            &datum!({
            "schema":"poo-flow.temporal-support-claim-request.v1","expectedGeneration":query.policy_generation,
            "expectedPolicyDigest":query.policy_digest,"task":task,"claim":query.claim.to_string(),
            "expectedContextBinding":query.expected_context.map(Value::from).unwrap_or(false.into())}),
        )
    }
    /// Scheme owns applicability; the caller supplies the declared temporal journal.
    pub fn evaluate(
        &self,
        runtime: &SemanticRuntime,
        catalog: &RelationCatalog,
        journal: Value,
        as_of: i64,
        valid_at: Value,
        budget: u32,
    ) -> Result<Value, Error> {
        recheck_catalog(catalog, self.catalog_digest)?;
        runtime.call("temporal.support.evaluate", &datum!({"schema":"poo-flow.temporal-support-request.v1",
            "program":self.program.clone(),"journal":journal,"asOf":as_of,"validAt":valid_at,"budget":budget}))
    }
}

/// Original owner Fact content for the integer/boolean evaluator row profile.
#[derive(Clone, Debug)]
pub struct MrrFactProjection {
    original: meta_relational_reasoning::Fact,
    payload: Value,
    content_digest: String,
    catalog_digest: RelationCatalogDigest,
}
impl MrrFactProjection {
    pub fn admit(
        fact: &meta_relational_reasoning::Fact,
        catalog: &RelationCatalog,
    ) -> Result<Self, Error> {
        use meta_relational_reasoning::{EvidenceCompleteness, FactValidity};
        validate_catalog(catalog)?;
        let schema = catalog
            .relation(fact.relation())
            .ok_or(Error::InvalidInput)?;
        schema
            .validate_fact(fact)
            .map_err(|_| Error::InvalidInput)?;
        let evaluator_relation = schema.predicate();
        fact.context().validate().map_err(|_| Error::InvalidInput)?;
        if fact.context().completeness() != EvidenceCompleteness::Complete
            || fact.context().validity() != FactValidity::Valid
            || evaluator_relation.is_empty()
            || evaluator_relation.len() > 256
            || !evaluator_relation
                .bytes()
                .all(|c| c.is_ascii_alphanumeric() || c == b'_')
            || fact.values().is_empty()
            || fact.values().len() > 32
        {
            return Err(Error::InvalidInput);
        }
        let row: Vec<Value> = fact
            .values()
            .iter()
            .map(|v| match v {
                meta_relational_reasoning::Value::Integer(n) => Ok(Value::from(*n)),
                meta_relational_reasoning::Value::Boolean(b) => Ok(Value::from(*b)),
                _ => Err(Error::InvalidInput),
            })
            .collect::<Result<_, _>>()?;
        let id = fact.id().to_string();
        let generation = fact.context().generation().to_string();
        let relation = fact.relation().to_string();
        let canonical = Value::Array(vec![
            "poo-flow.mrr-fact-content.v1".into(),
            id.clone().into(),
            generation.clone().into(),
            relation.clone().into(),
            evaluator_relation.into(),
            row.clone().into(),
        ]);
        let content_digest = format!(
            "sha256:{:x}",
            Sha256::digest(wire::to_vec(&canonical).map_err(|_| Error::InvalidInput)?)
        );
        Ok(Self {
            original: fact.clone(),
            catalog_digest: catalog.digest(),
            payload: datum!({"schema":"poo-flow.mrr-fact-request.v1",
            "identity":id,"generation":generation,"relationId":relation,"evaluatorRelation":evaluator_relation,"row":row}),
            content_digest,
        })
    }
    pub fn original(&self) -> &meta_relational_reasoning::Fact {
        &self.original
    }
    pub fn payload(&self) -> &Value {
        &self.payload
    }
    pub fn content_digest(&self) -> &str {
        &self.content_digest
    }
    pub fn catalog_digest(&self) -> RelationCatalogDigest {
        self.catalog_digest
    }
    pub fn verify_content(
        &self,
        runtime: &SemanticRuntime,
        catalog: &RelationCatalog,
    ) -> Result<Value, Error> {
        recheck_catalog(catalog, self.catalog_digest)?;
        let result = runtime.call("temporal.fact.content", &self.payload)?;
        if result["contentDigest"].as_str() != Some(self.content_digest.as_str()) {
            return Err(Error::InvalidInput);
        }
        Ok(result)
    }
}

// The owner catalog admits field shape and context, not rule execution or cross-row
// Key/Unique/FD constraints. Requiring its current value avoids an unchecked legacy path.
pub(crate) fn validate_catalog(catalog: &RelationCatalog) -> Result<(), Error> {
    if catalog.relations().len() > 32 {
        return Err(Error::InvalidInput);
    }
    let mut predicates = BTreeSet::new();
    for schema in catalog.relations() {
        let predicate = schema.predicate();
        if predicate.len() > 256
            || !predicate
                .bytes()
                .all(|c| c.is_ascii_alphanumeric() || c == b'_')
            || !predicates.insert(predicate)
            || schema.fields().is_empty()
            || schema.fields().len() > 32
            || !schema.constraints().is_empty()
            || schema.fields().iter().any(|f| {
                f.nullable()
                    || !matches!(
                        f.schema(),
                        meta_relational_reasoning::ValueSchema::Integer
                            | meta_relational_reasoning::ValueSchema::Boolean
                    )
            })
        {
            return Err(Error::InvalidInput);
        }
    }
    Ok(())
}
fn recheck_catalog(
    catalog: &RelationCatalog,
    expected: RelationCatalogDigest,
) -> Result<(), Error> {
    validate_catalog(catalog)?;
    if catalog.digest() != expected {
        return Err(Error::InvalidInput);
    }
    Ok(())
}
