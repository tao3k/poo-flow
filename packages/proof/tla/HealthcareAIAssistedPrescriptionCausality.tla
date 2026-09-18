---- MODULE HealthcareAIAssistedPrescriptionCausality ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\*
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS Naturals, TLC

(* Exact bounded lifecycle for the AI-assisted antibiotic prescription Case. *)

VARIABLES phase, interactionEvidenceBound, governanceHoldActive, independentReviewRecorded, alternativePrescriptionSelected, pharmacyVerified, wrongAutoApprovalCommitted, wrongAdministrationCommitted, hypothesizedRiskPromoted, actionAuthority

vars == << phase, interactionEvidenceBound, governanceHoldActive, independentReviewRecorded, alternativePrescriptionSelected, pharmacyVerified, wrongAutoApprovalCommitted, wrongAdministrationCommitted, hypothesizedRiskPromoted, actionAuthority >>

Phases == {"AIRecommended", "InteractionFound", "GovernanceHold", "ClinicianReviewed", "AlternativeSelected", "PharmacyVerified", "CounterfactualModeled"}
Init == phase = "AIRecommended" /\ interactionEvidenceBound = FALSE /\ governanceHoldActive = FALSE /\ independentReviewRecorded = FALSE /\ alternativePrescriptionSelected = FALSE /\ pharmacyVerified = FALSE /\ wrongAutoApprovalCommitted = FALSE /\ wrongAdministrationCommitted = FALSE /\ hypothesizedRiskPromoted = FALSE /\ actionAuthority = FALSE
BindInteractionEvidence == phase = "AIRecommended" /\ phase' = "InteractionFound" /\ interactionEvidenceBound' = TRUE /\ UNCHANGED << governanceHoldActive, independentReviewRecorded, alternativePrescriptionSelected, pharmacyVerified, wrongAutoApprovalCommitted, wrongAdministrationCommitted, hypothesizedRiskPromoted, actionAuthority >>
ApplyGovernanceHold == phase = "InteractionFound" /\ interactionEvidenceBound /\ phase' = "GovernanceHold" /\ governanceHoldActive' = TRUE /\ UNCHANGED << interactionEvidenceBound, independentReviewRecorded, alternativePrescriptionSelected, pharmacyVerified, wrongAutoApprovalCommitted, wrongAdministrationCommitted, hypothesizedRiskPromoted, actionAuthority >>
RecordIndependentReview == phase = "GovernanceHold" /\ governanceHoldActive /\ phase' = "ClinicianReviewed" /\ independentReviewRecorded' = TRUE /\ UNCHANGED << interactionEvidenceBound, governanceHoldActive, alternativePrescriptionSelected, pharmacyVerified, wrongAutoApprovalCommitted, wrongAdministrationCommitted, hypothesizedRiskPromoted, actionAuthority >>
SelectAlternative == phase = "ClinicianReviewed" /\ independentReviewRecorded /\ phase' = "AlternativeSelected" /\ alternativePrescriptionSelected' = TRUE /\ UNCHANGED << interactionEvidenceBound, governanceHoldActive, independentReviewRecorded, pharmacyVerified, wrongAutoApprovalCommitted, wrongAdministrationCommitted, hypothesizedRiskPromoted, actionAuthority >>
VerifyAlternative == phase = "AlternativeSelected" /\ alternativePrescriptionSelected /\ phase' = "PharmacyVerified" /\ pharmacyVerified' = TRUE /\ UNCHANGED << interactionEvidenceBound, governanceHoldActive, independentReviewRecorded, alternativePrescriptionSelected, wrongAutoApprovalCommitted, wrongAdministrationCommitted, hypothesizedRiskPromoted, actionAuthority >>
ModelWrongPath == interactionEvidenceBound /\ phase' = "CounterfactualModeled" /\ wrongAutoApprovalCommitted' = FALSE /\ wrongAdministrationCommitted' = FALSE /\ hypothesizedRiskPromoted' = FALSE /\ UNCHANGED << interactionEvidenceBound, governanceHoldActive, independentReviewRecorded, alternativePrescriptionSelected, pharmacyVerified, actionAuthority >>
Next == BindInteractionEvidence \/ ApplyGovernanceHold \/ RecordIndependentReview \/ SelectAlternative \/ VerifyAlternative \/ ModelWrongPath
Spec == Init /\ [][Next]_vars
TypeInvariant == phase \in Phases /\ interactionEvidenceBound \in BOOLEAN /\ governanceHoldActive \in BOOLEAN /\ independentReviewRecorded \in BOOLEAN /\ alternativePrescriptionSelected \in BOOLEAN /\ pharmacyVerified \in BOOLEAN /\ wrongAutoApprovalCommitted \in BOOLEAN /\ wrongAdministrationCommitted \in BOOLEAN /\ hypothesizedRiskPromoted \in BOOLEAN /\ actionAuthority \in BOOLEAN
AlternativeRequiresIndependentReview == alternativePrescriptionSelected => independentReviewRecorded
WrongAIPathNeverCommits == ~wrongAutoApprovalCommitted /\ ~wrongAdministrationCommitted
HypothesizedRiskNeverBecomesFact == ~hypothesizedRiskPromoted
TemporalAssuranceNeverGrantsActionAuthority == ~actionAuthority

(* The same two-layer trajectory declared by the Scheme Case: the intended
   path may become ready, while the wrong path and its Impact stay non-facts. *)
IntendedTrajectoryReady == interactionEvidenceBound /\ governanceHoldActive /\ independentReviewRecorded /\ alternativePrescriptionSelected /\ pharmacyVerified
ErrorTrajectoryRemainsCounterfactual == ~wrongAutoApprovalCommitted /\ ~wrongAdministrationCommitted
ErrorImpactRemainsHypothesized == ~hypothesizedRiskPromoted
TrajectoryHandoffReady == IntendedTrajectoryReady /\ ErrorTrajectoryRemainsCounterfactual /\ ErrorImpactRemainsHypothesized
TrajectoryHandoffRequiresIndependentReview == TrajectoryHandoffReady => independentReviewRecorded
TrajectoryLayersNeverCollapse == ErrorTrajectoryRemainsCounterfactual /\ ErrorImpactRemainsHypothesized

====
