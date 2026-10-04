// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Original MRR result -> explicit same-domain observation projection -> POO.
//! Native MRR owns result admission. The host owns the temporal correspondence.
use crate::{Error, SemanticRuntime};
use crate::{
    datum,
    wire::{self, Value},
};
use meta_relational_reasoning::{
    self as mrr, CandidateQueryResult, CatalogBoundQuery, QueryResultAdmissionReceipt,
    QueryResultLimits, QueryResultValue, Value as MrrValue, ValueSchema,
};
use sha2::{Digest, Sha256};
use std::num::NonZeroUsize;

/// Explicit trusted-host correspondence; generation is not derived from MRR IDs.
/// This profile interprets integer `position` cells in one declared clock domain.
#[derive(Debug, Clone)]
pub struct ObservationScope {
    pub source_identity: String,
    pub temporal_generation: u64,
    pub cut: String,
    pub projection: String,
    pub policy: String,
    pub clock_domain: String,
}

#[derive(Debug)]
pub enum MrrBridgeError {
    Admission(mrr::QueryResultAdmissionError),
    Transport(mrr::QueryResultTransportError),
    ReceiptMismatch,
    UnsupportedProjection,
    InvalidScope,
    InvalidModel,
    InvalidArchive,
    Native(Error),
}
impl std::fmt::Display for MrrBridgeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self:?}")
    }
}
impl std::error::Error for MrrBridgeError {}

/// Native owner values retained after receiver-side re-admission. No serialized DTO.
#[derive(Debug)]
pub struct AdmittedMrrResult {
    candidate: CandidateQueryResult,
    receipt: QueryResultAdmissionReceipt,
}
impl AdmittedMrrResult {
    pub fn candidate(&self) -> &CandidateQueryResult {
        &self.candidate
    }
    pub fn receipt(&self) -> &QueryResultAdmissionReceipt {
        &self.receipt
    }
}

/// Holds the original re-admitted MRR candidate and receipt, without relabeling it.
#[derive(Debug)]
pub struct MrrObservationEvidence {
    original: AdmittedMrrResult,
    observations: Vec<Value>,
    correspondence: Value,
    scope: ObservationScope,
}

/// Explicit host-selected authority and decision scope, outside model input.
pub struct SourceRegistrationContext {
    pub authority: String,
    pub subject: String,
    pub scope: String,
}
/// Handle for the registered native source version and original verified task.
pub struct RegisteredMrrSource {
    registration: Value,
    task: Value,
    source_identity: String,
}
impl RegisteredMrrSource {
    pub fn registration(&self) -> &Value {
        &self.registration
    }
    pub fn admit(
        &self,
        runtime: &SemanticRuntime,
        conclusion_identity: &str,
    ) -> Result<MrrFamilyAdmission, MrrBridgeError> {
        let result = runtime
            .call(
                "temporal.family.admit",
                &datum!({
                    "sourceIdentity": &self.source_identity,
                    "sourceDigest": &self.registration["sourceDigest"],
                    "task": &self.task, "conclusionIdentity": conclusion_identity
                }),
            )
            .map_err(MrrBridgeError::Native)?;
        Ok(MrrFamilyAdmission { result })
    }
}
/// Original native proof receipt; current applicability is checked separately.
pub struct MrrFamilyAdmission {
    result: Value,
}
impl MrrFamilyAdmission {
    pub fn result(&self) -> &Value {
        &self.result
    }
    /// Retain a Scheme-replayed proof-bound root on the native owner thread.
    pub fn revision_root(
        &self,
        runtime: &SemanticRuntime,
    ) -> Result<MrrFamilyRevision, MrrBridgeError> {
        runtime
            .call(
                "temporal.family.revision.root",
                &datum!({"admissionDigest": &self.result["admissionDigest"]}),
            )
            .map(|result| MrrFamilyRevision { result })
            .map_err(MrrBridgeError::Native)
    }
    pub fn current(&self, runtime: &SemanticRuntime) -> Result<Value, MrrBridgeError> {
        runtime
            .call(
                "temporal.family.current",
                &datum!({
                    "admissionDigest": &self.result["admissionDigest"]
                }),
            )
            .map_err(MrrBridgeError::Native)
    }
}
/// Host-declared scoped frontier; completeness is a premise, not authentication.
pub struct FamilyRevisionFrontier {
    pub index_identity: String,
    pub index_digest: String,
    pub previous_cut: String,
    pub revised_cut: String,
    pub previous_projection: String,
    pub revised_projection: String,
    pub changed_subjects: Vec<String>,
    pub affected_conclusions: Vec<String>,
    pub inventory_complete: bool,
    pub trigger: FamilyRevisionTrigger,
}
pub enum FamilyRevisionTrigger {
    PremiseDelta,
    ValidTimeReprojection,
}
pub enum FamilyRevisionOperation {
    Correct,
    Retract,
}
/// Original Scheme receipt for an immutable in-process revision, never a permit.
pub struct MrrFamilyRevision {
    result: Value,
}
impl MrrFamilyRevision {
    pub fn result(&self) -> &Value {
        &self.result
    }
    pub fn change(
        &self,
        runtime: &SemanticRuntime,
        admission: &MrrFamilyAdmission,
        frontier: &FamilyRevisionFrontier,
        operation: FamilyRevisionOperation,
    ) -> Result<Self, MrrBridgeError> {
        let operation = match operation {
            FamilyRevisionOperation::Correct => "correct",
            FamilyRevisionOperation::Retract => "retract",
        };
        let trigger = match frontier.trigger {
            FamilyRevisionTrigger::PremiseDelta => "premise-delta",
            FamilyRevisionTrigger::ValidTimeReprojection => "valid-time-reprojection",
        };
        runtime.call("temporal.family.revision.change", &datum!({
            "previousDigest": &self.result["revisionDigest"],
            "admissionDigest": &admission.result["admissionDigest"], "operation": operation,
            "frontier": { "indexIdentity": &frontier.index_identity,
                "indexDigest": &frontier.index_digest, "previousCut": &frontier.previous_cut,
                "revisedCut": &frontier.revised_cut, "previousProjection": &frontier.previous_projection,
                "revisedProjection": &frontier.revised_projection,
                "changedSubjects": frontier.changed_subjects.iter().map(Value::from).collect::<Vec<_>>(),
                "affectedConclusions": frontier.affected_conclusions.iter().map(Value::from).collect::<Vec<_>>(),
                "inventoryComplete": frontier.inventory_complete, "trigger": trigger }
        })).map(|result| Self { result }).map_err(MrrBridgeError::Native)
    }
    /// Export complete native Family premises with a caller-retained digest anchor.
    pub fn archive(
        runtime: &SemanticRuntime,
        identity: &str,
        revisions: &[&Self],
    ) -> Result<MrrFamilyProofArchive, MrrBridgeError> {
        let archive = runtime.call("temporal.family.archive.export", &datum!({
            "identity": identity,
            "revisionDigests": revisions.iter().map(|v| v.result["revisionDigest"].clone()).collect::<Vec<_>>()
        })).map_err(MrrBridgeError::Native)?;
        let expected_digest = archive["archiveDigest"]
            .as_str()
            .ok_or(MrrBridgeError::InvalidArchive)?
            .to_owned();
        Ok(MrrFamilyProofArchive {
            archive,
            expected_digest,
        })
    }
    /// Replay every retained original proof and validate the supplied graph inventory.
    /// The returned native journal is read-only and has no durable/current CAS claim.
    pub fn journal(
        runtime: &SemanticRuntime,
        identity: &str,
        revisions: &[&Self],
    ) -> Result<Value, MrrBridgeError> {
        runtime.call("temporal.family.journal", &datum!({"identity": identity,
            "revisionDigests": revisions.iter().map(|v| v.result["revisionDigest"].clone()).collect::<Vec<_>>()
        })).map_err(MrrBridgeError::Native)
    }
}
/// Complete Family proof premises. Loading bytes is inert, never proof admission.
/// Native replay recomputes the graph against the separately retained digest.
/// Original physical MRR source authentication is outside this Family archive.
pub struct MrrFamilyProofArchive {
    archive: Value,
    expected_digest: String,
}
impl MrrFamilyProofArchive {
    pub fn digest(&self) -> &str {
        &self.expected_digest
    }
    pub fn value(&self) -> &Value {
        &self.archive
    }
    pub fn to_bytes(&self) -> Result<Vec<u8>, MrrBridgeError> {
        let bytes = wire::to_vec(&self.archive).map_err(|_| MrrBridgeError::InvalidArchive)?;
        if bytes.len() > 1_048_576 {
            return Err(MrrBridgeError::InvalidArchive);
        }
        Ok(bytes)
    }
    pub fn from_bytes(bytes: &[u8], expected_digest: &str) -> Result<Self, MrrBridgeError> {
        if bytes.is_empty()
            || bytes.len() > 1_048_576
            || expected_digest.len() != 71
            || !expected_digest.starts_with("sha256:")
            || !expected_digest.as_bytes()[7..]
                .iter()
                .all(|c| c.is_ascii_digit() || (b'a'..=b'f').contains(c))
        {
            return Err(MrrBridgeError::InvalidArchive);
        }
        let archive = wire::from_slice(bytes).map_err(|_| MrrBridgeError::InvalidArchive)?;
        if archive["archiveDigest"].as_str() != Some(expected_digest) {
            return Err(MrrBridgeError::InvalidArchive);
        }
        Ok(Self {
            archive,
            expected_digest: expected_digest.to_owned(),
        })
    }
    /// Read-only historical replay. Does not register current Source or handles.
    pub fn replay(&self, runtime: &SemanticRuntime) -> Result<Value, MrrBridgeError> {
        runtime
            .call(
                "temporal.family.archive.replay",
                &datum!({
                    "archive": &self.archive, "expectedDigest": &self.expected_digest
                }),
            )
            .map_err(MrrBridgeError::Native)
    }
}
impl MrrObservationEvidence {
    /// Register only observations reconstructed from original MRR owner values.
    /// Native Scheme owns the snapshot digest and monotonic current-source fence.
    pub fn register_current(
        &self,
        runtime: &SemanticRuntime,
        model: Value,
        query: Value,
        context: SourceRegistrationContext,
    ) -> Result<RegisteredMrrSource, MrrBridgeError> {
        let task = self.classification_request(model, query)?;
        let registration = runtime
            .register_source(&datum!({
                "scope": { "identity": &self.scope.source_identity,
                    "authority": context.authority, "subject": context.subject,
                    "scope": context.scope, "cut": &self.scope.cut,
                    "projection": &self.scope.projection, "policy": &self.scope.policy,
                    "generation": self.scope.temporal_generation },
                "task": &task
            }))
            .map_err(MrrBridgeError::Native)?;
        Ok(RegisteredMrrSource {
            registration,
            task,
            source_identity: self.scope.source_identity.clone(),
        })
    }
    /// Reconstruct original owner values from bounded Scheme v2 bytes, then
    /// check the host's Temporal projection. The query must come from the
    /// authentic source binder; transport bytes do not authenticate execution.
    pub fn verify_transport(
        query: &CatalogBoundQuery,
        bytes: &[u8],
        limits: QueryResultLimits,
        max_bytes: NonZeroUsize,
        scope: ObservationScope,
    ) -> Result<Self, MrrBridgeError> {
        if max_bytes.get() > 1024 * 1024 || bytes.len() > max_bytes.get() {
            return Err(MrrBridgeError::UnsupportedProjection);
        }
        let original = mrr::verify_query_result_transport(query, bytes, limits, max_bytes)
            .map_err(MrrBridgeError::Transport)?;
        Self::verify(
            query,
            original.candidate(),
            original.receipt(),
            limits,
            max_bytes,
            scope,
        )
    }

    /// Re-admit original native owner values against the authentic caller-owned query.
    /// Supported columns are exactly `event` String and `position` Integer.
    /// Null, Node, Relation, List, duplicates, extra columns and >128 rows reject.
    pub fn verify(
        query: &CatalogBoundQuery,
        candidate: &CandidateQueryResult,
        receipt: &QueryResultAdmissionReceipt,
        limits: QueryResultLimits,
        max_bytes: NonZeroUsize,
        scope: ObservationScope,
    ) -> Result<Self, MrrBridgeError> {
        if max_bytes.get() > 1_048_576
            || candidate.rows().len() > 128
            || candidate.columns().len() != 2
        {
            return Err(MrrBridgeError::UnsupportedProjection);
        }
        let text = |v: &str| !v.is_empty() && v.len() <= 128 && !v.chars().any(char::is_control);
        if [
            &scope.source_identity,
            &scope.cut,
            &scope.projection,
            &scope.policy,
            &scope.clock_domain,
        ]
        .iter()
        .any(|s| !text(s))
            || scope.temporal_generation > i64::MAX as u64
        {
            return Err(MrrBridgeError::InvalidScope);
        }
        // Bound supported cells before owner digest computation or cloning.
        let mut cell_bytes = 0usize;
        for row in candidate.rows() {
            if row.len() != 2 {
                return Err(MrrBridgeError::UnsupportedProjection);
            }
            for cell in row {
                let length = match cell {
                    QueryResultValue::Scalar {
                        schema: ValueSchema::String,
                        value: MrrValue::String(v),
                    } => v.len(),
                    QueryResultValue::Scalar {
                        schema: ValueSchema::Integer,
                        value: MrrValue::Integer(_),
                    } => 8,
                    _ => return Err(MrrBridgeError::UnsupportedProjection),
                };
                cell_bytes = cell_bytes
                    .checked_add(length)
                    .ok_or(MrrBridgeError::UnsupportedProjection)?;
                if cell_bytes > max_bytes.get() {
                    return Err(MrrBridgeError::UnsupportedProjection);
                }
            }
        }
        let checked = mrr::admit_query_result_candidate(query, candidate, limits)
            .map_err(MrrBridgeError::Admission)?;
        if &checked != receipt {
            return Err(MrrBridgeError::ReceiptMismatch);
        }
        let original = AdmittedMrrResult {
            candidate: candidate.clone(),
            receipt: receipt.clone(),
        };
        if candidate.columns()
            != [
                mrr::Binding::new("event").unwrap(),
                mrr::Binding::new("position").unwrap(),
            ]
            || candidate.rows().is_empty()
            || candidate.rows().len() > 128
        {
            return Err(MrrBridgeError::UnsupportedProjection);
        }
        let hex = |bytes: &[u8]| bytes.iter().map(|b| format!("{b:02x}")).collect::<String>();
        let receipt = original.receipt();
        let binding = receipt.binding();
        let correspondence = datum!({
            "schema": "poo-flow.mrr-observation-correspondence.v2",
            "claim": "host-declared-same-domain-observation-projection",
            "mrrQueryBindingDigest": hex(binding.query_binding_digest()),
            "mrrGeneration": binding.generation().to_string(),
            "mrrRelationCatalogDigest": hex(binding.relation_catalog_digest().as_bytes()),
            "mrrEntityCatalogDigest": hex(binding.entity_catalog_digest().as_bytes()),
            "mrrSnapshotDigest": hex(binding.snapshot_digest()),
            "mrrResultDigest": hex(receipt.digest()), "mrrRowCount": receipt.row_count(),
            "sourceIdentity": &scope.source_identity, "temporalGeneration": scope.temporal_generation,
            "cut": &scope.cut, "projection": &scope.projection, "policy": &scope.policy,
            "clockDomain": &scope.clock_domain, "sourceAuthenticated": false,
            "actionAuthorized": false, "coverageVerified": false
        });
        let provenance = format!(
            "sha256:{:x}",
            Sha256::digest(wire::to_vec(&correspondence).unwrap())
        );
        let mut ids = std::collections::BTreeSet::new();
        let mut observations = Vec::new();
        for row in candidate.rows() {
            let [
                QueryResultValue::Scalar {
                    schema: ValueSchema::String,
                    value: MrrValue::String(event),
                },
                QueryResultValue::Scalar {
                    schema: ValueSchema::Integer,
                    value: MrrValue::Integer(position),
                },
            ] = row.as_slice()
            else {
                return Err(MrrBridgeError::UnsupportedProjection);
            };
            if !text(event) || !ids.insert(event.clone()) {
                return Err(MrrBridgeError::UnsupportedProjection);
            }
            observations.push(
                datum!({"identity":event,"domain":&scope.clock_domain,"position":position,
                "provenance":&provenance,"modality":"observed"}),
            );
        }
        Ok(Self {
            original,
            observations,
            correspondence,
            scope,
        })
    }
    pub fn original(&self) -> &AdmittedMrrResult {
        &self.original
    }
    pub fn correspondence(&self) -> &Value {
        &self.correspondence
    }

    /// Supply a bounded POO family definition with no observations; observations
    /// come exclusively from the re-admitted MRR rows, never a model response.
    /// This returns family-relative classification, not a causal/effect permit.
    /// Construct the exact read-only native request from verified owner evidence.
    /// External adapters may freeze this value for a tool call; they cannot
    /// override observations or select another clock domain through the model.
    pub fn classification_request(
        &self,
        mut model: Value,
        query: Value,
    ) -> Result<Value, MrrBridgeError> {
        let object = model.as_object_mut().ok_or(MrrBridgeError::InvalidModel)?;
        if object.contains_key("observations")
            || object.get("domains")
                != Some(&datum!([
            {"identity":&self.scope.clock_domain,"role":"event-time"}]))
        {
            return Err(MrrBridgeError::InvalidModel);
        }
        object.insert(
            "observations".into(),
            Value::Array(self.observations.clone()),
        );
        Ok(datum!({"profile":"finite-hypothesis-family","model":model,"query":query}))
    }

    pub fn classify(
        &self,
        runtime: &SemanticRuntime,
        model: Value,
        query: Value,
    ) -> Result<Value, MrrBridgeError> {
        runtime
            .call(
                "temporal.family.classify",
                &self.classification_request(model, query)?,
            )
            .map_err(MrrBridgeError::Native)
    }
}
