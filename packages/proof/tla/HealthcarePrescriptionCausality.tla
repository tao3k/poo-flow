---- MODULE HealthcarePrescriptionCausality ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\*
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS Naturals, TLC

(*
Bounded Healthcare refinement for the wrong-prescription Case.  Observed past
facts, prospective actions and counterfactual candidates remain distinct.
Cedar authorization is deliberately absent; actionAuthority must stay false.

Definitions stay on one physical line because gerbil-parser's native
tla-plus.native-core.v1 contract deliberately excludes multiline layout.
*)

VARIABLES phase, oldOrderActive, pastAdministrationRecorded, errorDiscovered, postDiscoveryOldOrderCommit, reassessmentRequired, reassessed, correctionIssued, correctionHasNewIdentity, counterfactualObserved, actionAuthority

vars == << phase, oldOrderActive, pastAdministrationRecorded, errorDiscovered, postDiscoveryOldOrderCommit, reassessmentRequired, reassessed, correctionIssued, correctionHasNewIdentity, counterfactualObserved, actionAuthority >>

Phases == {"Ordered", "Administered", "ErrorDiscovered", "OldOrderBlocked", "Reassessed", "CounterfactualModeled", "Corrected"}
Init == phase = "Ordered" /\ oldOrderActive = TRUE /\ pastAdministrationRecorded = FALSE /\ errorDiscovered = FALSE /\ postDiscoveryOldOrderCommit = FALSE /\ reassessmentRequired = FALSE /\ reassessed = FALSE /\ correctionIssued = FALSE /\ correctionHasNewIdentity = FALSE /\ counterfactualObserved = FALSE /\ actionAuthority = FALSE
AdministerBeforeDiscovery == ~errorDiscovered /\ oldOrderActive /\ phase \in {"Ordered", "Administered"} /\ phase' = "Administered" /\ pastAdministrationRecorded' = TRUE /\ UNCHANGED << oldOrderActive, errorDiscovered, postDiscoveryOldOrderCommit, reassessmentRequired, reassessed, correctionIssued, correctionHasNewIdentity, counterfactualObserved, actionAuthority >>
DiscoverPrescriptionError == ~errorDiscovered /\ phase' = "ErrorDiscovered" /\ errorDiscovered' = TRUE /\ oldOrderActive' = FALSE /\ reassessmentRequired' = TRUE /\ UNCHANGED << pastAdministrationRecorded, postDiscoveryOldOrderCommit, reassessed, correctionIssued, correctionHasNewIdentity, counterfactualObserved, actionAuthority >>
BlockOldOrderAdministration == errorDiscovered /\ ~oldOrderActive /\ phase' = "OldOrderBlocked" /\ postDiscoveryOldOrderCommit' = FALSE /\ UNCHANGED << oldOrderActive, pastAdministrationRecorded, errorDiscovered, reassessmentRequired, reassessed, correctionIssued, correctionHasNewIdentity, counterfactualObserved, actionAuthority >>
ReassessPatient == errorDiscovered /\ reassessmentRequired /\ phase' = "Reassessed" /\ reassessed' = TRUE /\ UNCHANGED << oldOrderActive, pastAdministrationRecorded, errorDiscovered, postDiscoveryOldOrderCommit, reassessmentRequired, correctionIssued, correctionHasNewIdentity, counterfactualObserved, actionAuthority >>
ModelCounterfactual == errorDiscovered /\ phase' = "CounterfactualModeled" /\ counterfactualObserved' = FALSE /\ UNCHANGED << oldOrderActive, pastAdministrationRecorded, errorDiscovered, postDiscoveryOldOrderCommit, reassessmentRequired, reassessed, correctionIssued, correctionHasNewIdentity, actionAuthority >>
IssueCorrection == errorDiscovered /\ reassessed /\ phase' = "Corrected" /\ correctionIssued' = TRUE /\ correctionHasNewIdentity' = TRUE /\ UNCHANGED << oldOrderActive, pastAdministrationRecorded, errorDiscovered, postDiscoveryOldOrderCommit, reassessmentRequired, reassessed, counterfactualObserved, actionAuthority >>
Next == AdministerBeforeDiscovery \/ DiscoverPrescriptionError \/ BlockOldOrderAdministration \/ ReassessPatient \/ ModelCounterfactual \/ IssueCorrection
Spec == Init /\ [][Next]_vars
TypeInvariant == phase \in Phases /\ oldOrderActive \in BOOLEAN /\ pastAdministrationRecorded \in BOOLEAN /\ errorDiscovered \in BOOLEAN /\ postDiscoveryOldOrderCommit \in BOOLEAN /\ reassessmentRequired \in BOOLEAN /\ reassessed \in BOOLEAN /\ correctionIssued \in BOOLEAN /\ correctionHasNewIdentity \in BOOLEAN /\ counterfactualObserved \in BOOLEAN /\ actionAuthority \in BOOLEAN
DiscoveryRevokesOldOrder == errorDiscovered => ~oldOrderActive
NoOldOrderCommitAfterDiscovery == errorDiscovered => ~postDiscoveryOldOrderCommit
CorrectionRequiresReassessmentAndNewIdentity == correctionIssued => reassessed /\ correctionHasNewIdentity
CounterfactualNeverBecomesObservedFact == ~counterfactualObserved
TemporalAnalysisNeverGrantsActionAuthority == ~actionAuthority

====
