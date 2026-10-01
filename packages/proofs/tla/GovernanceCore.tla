---- MODULE GovernanceCore ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\*
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS Naturals, TLC

(*
POO Flow Governance transition model.

Cedar evaluation is deliberately absent. This specification checks only
pre-threat observation, threat lifecycle, Governance admission, enterprise
security-evidence closure, and fail-closed Provider handoff.

Definitions stay on one physical line because gerbil-parser's native
tla-plus.native-core.v1 contract deliberately excludes multiline layout.
*)

VARIABLES threatPhase, preconditionObserved, evidenceBound, assessmentBound, governanceAdmitted, threatIntelligenceBound, securityGraphClosed, separationOfDuties, enterpriseAssuranceBound, providerBound, residualAccepted, actionAuthority

vars == << threatPhase, preconditionObserved, evidenceBound, assessmentBound, governanceAdmitted, threatIntelligenceBound, securityGraphClosed, separationOfDuties, enterpriseAssuranceBound, providerBound, residualAccepted, actionAuthority >>

ThreatPhases == {"latent", "exposed", "realized", "mitigated", "accepted"}
ActiveBlocker == threatPhase \in {"exposed", "realized"}

Init == threatPhase = "latent" /\ preconditionObserved = FALSE /\ evidenceBound = FALSE /\ assessmentBound = FALSE /\ governanceAdmitted = FALSE /\ threatIntelligenceBound = FALSE /\ securityGraphClosed = FALSE /\ separationOfDuties = FALSE /\ enterpriseAssuranceBound = FALSE /\ providerBound = FALSE /\ residualAccepted = FALSE /\ actionAuthority = FALSE

ObservePrecondition == preconditionObserved' = TRUE /\ evidenceBound' = TRUE /\ UNCHANGED << threatPhase, assessmentBound, governanceAdmitted, threatIntelligenceBound, securityGraphClosed, separationOfDuties, enterpriseAssuranceBound, providerBound, residualAccepted, actionAuthority >>
ExposeThreat == preconditionObserved /\ evidenceBound /\ threatPhase' = "exposed" /\ assessmentBound' = FALSE /\ governanceAdmitted' = FALSE /\ enterpriseAssuranceBound' = FALSE /\ providerBound' = FALSE /\ UNCHANGED << preconditionObserved, evidenceBound, threatIntelligenceBound, securityGraphClosed, separationOfDuties, residualAccepted, actionAuthority >>
RealizeThreat == threatPhase = "exposed" /\ threatPhase' = "realized" /\ assessmentBound' = FALSE /\ governanceAdmitted' = FALSE /\ enterpriseAssuranceBound' = FALSE /\ providerBound' = FALSE /\ UNCHANGED << preconditionObserved, evidenceBound, threatIntelligenceBound, securityGraphClosed, separationOfDuties, residualAccepted, actionAuthority >>
MitigateThreat == threatPhase \in {"exposed", "realized"} /\ threatPhase' = "mitigated" /\ assessmentBound' = FALSE /\ governanceAdmitted' = FALSE /\ enterpriseAssuranceBound' = FALSE /\ providerBound' = FALSE /\ UNCHANGED << preconditionObserved, evidenceBound, threatIntelligenceBound, securityGraphClosed, separationOfDuties, residualAccepted, actionAuthority >>
AcceptResidualThreat == threatPhase = "realized" /\ evidenceBound /\ threatPhase' = "accepted" /\ residualAccepted' = TRUE /\ assessmentBound' = FALSE /\ governanceAdmitted' = FALSE /\ enterpriseAssuranceBound' = FALSE /\ providerBound' = FALSE /\ UNCHANGED << preconditionObserved, evidenceBound, threatIntelligenceBound, securityGraphClosed, separationOfDuties, actionAuthority >>
AssessGovernance == ~ActiveBlocker /\ assessmentBound' = TRUE /\ UNCHANGED << threatPhase, preconditionObserved, evidenceBound, governanceAdmitted, threatIntelligenceBound, securityGraphClosed, separationOfDuties, enterpriseAssuranceBound, providerBound, residualAccepted, actionAuthority >>
AdmitGovernance == assessmentBound /\ ~ActiveBlocker /\ governanceAdmitted' = TRUE /\ UNCHANGED << threatPhase, preconditionObserved, evidenceBound, assessmentBound, threatIntelligenceBound, securityGraphClosed, separationOfDuties, enterpriseAssuranceBound, providerBound, residualAccepted, actionAuthority >>
BindEnterpriseEvidence == governanceAdmitted /\ assessmentBound /\ ~ActiveBlocker /\ threatIntelligenceBound' = TRUE /\ securityGraphClosed' = TRUE /\ separationOfDuties' = TRUE /\ enterpriseAssuranceBound' = TRUE /\ UNCHANGED << threatPhase, preconditionObserved, evidenceBound, assessmentBound, governanceAdmitted, providerBound, residualAccepted, actionAuthority >>
BindProvider == governanceAdmitted /\ assessmentBound /\ enterpriseAssuranceBound /\ threatIntelligenceBound /\ securityGraphClosed /\ separationOfDuties /\ ~ActiveBlocker /\ providerBound' = TRUE /\ UNCHANGED << threatPhase, preconditionObserved, evidenceBound, assessmentBound, governanceAdmitted, threatIntelligenceBound, securityGraphClosed, separationOfDuties, enterpriseAssuranceBound, residualAccepted, actionAuthority >>

Next == ObservePrecondition \/ ExposeThreat \/ RealizeThreat \/ MitigateThreat \/ AcceptResidualThreat \/ AssessGovernance \/ AdmitGovernance \/ BindEnterpriseEvidence \/ BindProvider

Spec == Init /\ [][Next]_vars

TypeInvariant == threatPhase \in ThreatPhases
ObservedPreconditionHasEvidence == preconditionObserved => evidenceBound
EnterpriseAssuranceIsClosed == enterpriseAssuranceBound => threatIntelligenceBound /\ securityGraphClosed /\ separationOfDuties
ProviderHandoffIsFailClosed == providerBound => assessmentBound /\ governanceAdmitted /\ enterpriseAssuranceBound /\ ~ActiveBlocker
AcceptedResidualHasAuthorityEvidence == threatPhase = "accepted" => residualAccepted /\ evidenceBound
GovernanceNeverGrantsActionAuthority == ~actionAuthority

====
