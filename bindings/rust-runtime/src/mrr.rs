// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Original MRR result -> explicit same-domain observation projection -> POO.
//! Native MRR owns result admission. The host owns the temporal correspondence.
use crate::{Error, SemanticRuntime};
use meta_relational_reasoning::{
    self as mrr, CatalogBoundQuery, QueryResultLimits, QueryResultValue, Value as MrrValue,
    ValueSchema, VerifiedQueryResultTransport,
};
use serde_json::{Value, json};
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
    Transport(mrr::QueryResultTransportError),
    UnsupportedProjection,
    InvalidScope,
    InvalidModel,
    Native(Error),
}
impl std::fmt::Display for MrrBridgeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self:?}")
    }
}
impl std::error::Error for MrrBridgeError {}

/// Holds the original re-admitted MRR candidate and receipt, without relabeling it.
#[derive(Debug)]
pub struct MrrObservationEvidence {
    original: VerifiedQueryResultTransport,
    observations: Vec<Value>,
    correspondence: Value,
    scope: ObservationScope,
}
impl MrrObservationEvidence {
    /// Re-admit exact original bytes against the authentic caller-owned query.
    /// Supported columns are exactly `event` String and `position` Integer.
    /// Null, Node, Relation, List, duplicates, extra columns and >128 rows reject.
    pub fn verify(
        query: &CatalogBoundQuery,
        bytes: &[u8],
        limits: QueryResultLimits,
        max_bytes: NonZeroUsize,
        scope: ObservationScope,
    ) -> Result<Self, MrrBridgeError> {
        if bytes.len() > 1_048_576 || max_bytes.get() > 1_048_576 {
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
        let original = mrr::verify_query_result_transport(query, bytes, limits, max_bytes)
            .map_err(MrrBridgeError::Transport)?;
        let candidate = original.candidate();
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
        let correspondence = json!({
            "schema": "poo-flow.mrr-observation-correspondence.v1",
            "claim": "host-declared-same-domain-observation-projection",
            "mrrQueryBindingDigest": hex(binding.query_binding_digest()),
            "mrrGeneration": binding.generation().to_string(),
            "mrrRelationCatalogDigest": hex(binding.relation_catalog_digest().as_bytes()),
            "mrrEntityCatalogDigest": hex(binding.entity_catalog_digest().as_bytes()),
            "mrrSnapshotDigest": hex(binding.snapshot_digest()),
            "mrrResultDigest": hex(receipt.digest()), "mrrRowCount": receipt.row_count(),
            "sourceIdentity": scope.source_identity, "temporalGeneration": scope.temporal_generation,
            "cut": scope.cut, "projection": scope.projection, "policy": scope.policy,
            "clockDomain": scope.clock_domain, "sourceAuthenticated": false,
            "actionAuthorized": false, "coverageVerified": false
        });
        let provenance = format!(
            "sha256:{:x}",
            Sha256::digest(serde_json::to_vec(&correspondence).unwrap())
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
                json!({"identity":event,"domain":scope.clock_domain,"position":position,
                "provenance":provenance,"modality":"observed"}),
            );
        }
        Ok(Self {
            original,
            observations,
            correspondence,
            scope,
        })
    }
    pub fn original(&self) -> &VerifiedQueryResultTransport {
        &self.original
    }
    pub fn correspondence(&self) -> &Value {
        &self.correspondence
    }

    /// Supply a bounded POO family definition with no observations; observations
    /// come exclusively from the re-admitted MRR rows, never a model response.
    /// This returns family-relative classification, not a causal/effect permit.
    pub fn classify(
        &self,
        runtime: &SemanticRuntime,
        mut model: Value,
        query: Value,
    ) -> Result<Value, MrrBridgeError> {
        let object = model.as_object_mut().ok_or(MrrBridgeError::InvalidModel)?;
        if object.contains_key("observations")
            || object.get("domains")
                != Some(&json!([
            {"identity":self.scope.clock_domain,"role":"event-time"}]))
        {
            return Err(MrrBridgeError::InvalidModel);
        }
        object.insert(
            "observations".into(),
            Value::Array(self.observations.clone()),
        );
        runtime
            .call(
                "temporal.family.classify",
                &json!({"profile":"finite-hypothesis-family","model":model,"query":query}),
            )
            .map_err(MrrBridgeError::Native)
    }
}
