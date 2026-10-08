// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Trusted Host adapter: native Library semantics inside the Data transaction.
//! Enrollment and clocks are Host controls; declared eligibility is never a grant.
use crate::{
    SemanticRuntime, datum,
    mrr::MrrFamilyAdmission,
    wire::{self, Value},
};
use cid::Cid;
use mrr_data_backend::{AuthorityExpectation, AuthorityStatus, BackendError, ProfilePort};
use mrr_data_content::{
    ConditionalCommitPortError, ConditionalContentCommitOutcome, ConditionalContentCommitPort,
    ConditionalContentWrite, ContentBlock, ContentCodec, ContentRevision, PublishReceipt,
};

#[derive(Debug)]
pub enum PublicationError {
    InvalidPlan,
    GrantBinding,
    SourceBinding,
    Native(crate::Error),
    Proof(crate::mrr::MrrBridgeError),
    NotCurrent,
    Ineligible,
}
impl std::fmt::Display for PublicationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self:?}")
    }
}
impl std::error::Error for PublicationError {}
/// Trusted configured caller state, separate from ordinary model request data.
pub struct PublicationHost<'a> {
    pub port: &'a ProfilePort,
    pub guards: &'a [AuthorityExpectation],
    pub grant_id: &'a str,
    pub source_id: &'a str,
    pub admission: &'a MrrFamilyAdmission,
    pub runtime: &'a SemanticRuntime,
}
/// An immutable request binding, selected and enrolled by the trusted Host.
/// The grant commitment includes proof, payload root, actor/destination and CAS.
/// The Host independently authenticates those inputs before enrolling that CID.
pub struct PublicationPlan {
    scope: String,
    operation: String,
    expected: Option<ContentRevision>,
    replacement: Cid,
    admission: Value,
    flow: Value,
    commitment: Cid,
}
impl PublicationPlan {
    pub fn new(
        scope: &str,
        operation: &str,
        expected: Option<ContentRevision>,
        replacement: Cid,
        admission: &MrrFamilyAdmission,
        flow: &Value,
    ) -> Result<Self, PublicationError> {
        if [scope, operation]
            .iter()
            .any(|s| s.is_empty() || s.len() > 256)
            || flow["schema"] != "poo-flow.context-flow-request.v1"
            || flow["expectedRestrictionDigest"].as_str().is_none()
            || admission.result()["admissionDigest"].as_str().is_none()
            || admission.result()["classification"] != "necessary"
            || flow["sourceDigest"] != admission.result()["sourceDigest"]
            || flow["contentDigest"].as_str()
                != Some(
                    format!(
                        "sha256:{}",
                        replacement
                            .hash()
                            .digest()
                            .iter()
                            .map(|b| format!("{b:02x}"))
                            .collect::<String>()
                    )
                    .as_str(),
                )
        {
            return Err(PublicationError::InvalidPlan);
        }
        ContentCodec::from_cid(&replacement).map_err(|_| PublicationError::InvalidPlan)?;
        let mut flow = flow.clone();
        // The fresh Host clock is read only inside protected validation.
        flow["declaredAt"] = 0_i32.into();
        let previous = expected.map_or(
            Value::Bool(false),
            |r| datum!({"revision":r.revision,"root":r.root.to_string()}),
        );
        let binding = datum!({"schema":"poo-flow.data-publication-plan.v1",
            "scope":scope,"operation":operation,"expected":previous,
            "replacement":replacement.to_string(),"admission":admission.result()["admissionDigest"].clone(),"flow":flow.clone()});
        let bytes = wire::to_vec(&binding).map_err(|_| PublicationError::InvalidPlan)?;
        if bytes.len() > 65536 {
            return Err(PublicationError::InvalidPlan);
        }
        let commitment = ContentBlock::new(ContentCodec::Raw, &bytes).cid();
        Ok(Self {
            scope: scope.into(),
            operation: operation.into(),
            expected,
            replacement,
            admission: admission.result()["admissionDigest"].clone(),
            flow,
            commitment,
        })
    }
    pub fn commitment(&self) -> Cid {
        self.commitment
    }
    /// Guard enrollment is administrative and must happen before this call.
    /// The Host advances Data fences before refreshing native state, keeps all
    /// home guards, and never nests Data writes in the validator.
    /// Historical replay does not read a fresh clock or repeat native validation.
    pub async fn commit<'a, C>(
        &'a self,
        host: PublicationHost<'_>,
        physical: Option<&'a PublishReceipt>,
        clock: C,
    ) -> Result<
        ConditionalContentCommitOutcome<'a>,
        ConditionalCommitPortError<BackendError, PublicationError>,
    >
    where
        C: FnOnce() -> u64 + Send,
    {
        let PublicationHost {
            port: base,
            guards,
            grant_id,
            source_id,
            admission,
            runtime,
        } = host;
        if !guards.iter().any(|g| {
            g.authority_id == grant_id
                && g.state.status == AuthorityStatus::Active
                && g.state.commitment == self.commitment
        }) || admission.result()["admissionDigest"] != self.admission
        {
            return Err(ConditionalCommitPortError::Validation(
                PublicationError::GrantBinding,
            ));
        }
        let source = guards
            .iter()
            .find(|g| g.authority_id == source_id && g.state.status == AuthorityStatus::Active)
            .filter(|_| source_id != grant_id)
            .ok_or(ConditionalCommitPortError::Validation(
                PublicationError::SourceBinding,
            ))?
            .state;
        let port = base
            .with_authorities(guards)
            .map_err(ConditionalCommitPortError::BeforeCommit)?;
        let write = ConditionalContentWrite {
            scope: &self.scope,
            operation_id: &self.operation,
            expected: self.expected,
            replacement: self.replacement,
        };
        let outcome = port
            .commit(write, physical, |_| {
                let current = admission
                    .current(runtime)
                    .map_err(PublicationError::Proof)?;
                if current["status"] != "current" {
                    return Err(PublicationError::NotCurrent);
                }
                let digest = current["currentSourceDigest"]
                    .as_str()
                    .ok_or(PublicationError::SourceBinding)?;
                if ContentBlock::new(ContentCodec::Raw, digest.as_bytes()).cid()
                    != source.commitment
                {
                    return Err(PublicationError::SourceBinding);
                }
                let mut flow = self.flow.clone();
                flow["declaredAt"] = clock().into();
                let decision = runtime
                    .call("context.flow.evaluate", &flow)
                    .map_err(PublicationError::Native)?;
                if decision["status"] != "eligible" {
                    return Err(PublicationError::Ineligible);
                }
                Ok(())
            })
            .await?;
        // Rebind the borrowed receipt to this immutable plan, not the local port.
        Ok(match outcome {
            ConditionalContentCommitOutcome::Committed(r) => {
                ConditionalContentCommitOutcome::Committed(
                    mrr_data_content::ConditionalContentReceipt {
                        write,
                        committed: r.committed,
                    },
                )
            }
            ConditionalContentCommitOutcome::Replayed(r) => {
                ConditionalContentCommitOutcome::Replayed(
                    mrr_data_content::ConditionalContentReceipt {
                        write,
                        committed: r.committed,
                    },
                )
            }
        })
    }
}
