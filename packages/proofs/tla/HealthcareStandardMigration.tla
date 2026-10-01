---- MODULE HealthcareStandardMigration ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\*
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS Naturals, TLC

(* Bounded governance lifecycle for one exact HL7v2 to AU Core migration. *)

VARIABLES phase, parserBound, mappingComplete, conformanceBound, humanReviewed, cedarPermit, cutoverReady, aiAuthority

vars == << phase, parserBound, mappingComplete, conformanceBound, humanReviewed, cedarPermit, cutoverReady, aiAuthority >>

Phases == {"Inventory", "Mapped", "Conformant", "HumanReviewed", "Authorized", "CutoverReady"}
Init == phase = "Inventory" /\ parserBound = FALSE /\ mappingComplete = FALSE /\ conformanceBound = FALSE /\ humanReviewed = FALSE /\ cedarPermit = FALSE /\ cutoverReady = FALSE /\ aiAuthority = FALSE
BindParser == phase = "Inventory" /\ phase' = "Mapped" /\ parserBound' = TRUE /\ mappingComplete' = TRUE /\ UNCHANGED << conformanceBound, humanReviewed, cedarPermit, cutoverReady, aiAuthority >>
BindConformance == phase = "Mapped" /\ parserBound /\ mappingComplete /\ phase' = "Conformant" /\ conformanceBound' = TRUE /\ UNCHANGED << parserBound, mappingComplete, humanReviewed, cedarPermit, cutoverReady, aiAuthority >>
RecordHumanReview == phase = "Conformant" /\ conformanceBound /\ phase' = "HumanReviewed" /\ humanReviewed' = TRUE /\ UNCHANGED << parserBound, mappingComplete, conformanceBound, cedarPermit, cutoverReady, aiAuthority >>
RecordCedarPermit == phase = "HumanReviewed" /\ humanReviewed /\ phase' = "Authorized" /\ cedarPermit' = TRUE /\ UNCHANGED << parserBound, mappingComplete, conformanceBound, humanReviewed, cutoverReady, aiAuthority >>
AdmitCutover == phase = "Authorized" /\ cedarPermit /\ phase' = "CutoverReady" /\ cutoverReady' = TRUE /\ UNCHANGED << parserBound, mappingComplete, conformanceBound, humanReviewed, cedarPermit, aiAuthority >>
Next == BindParser \/ BindConformance \/ RecordHumanReview \/ RecordCedarPermit \/ AdmitCutover
Spec == Init /\ [][Next]_vars

TypeInvariant == phase \in Phases /\ parserBound \in BOOLEAN /\ mappingComplete \in BOOLEAN /\ conformanceBound \in BOOLEAN /\ humanReviewed \in BOOLEAN /\ cedarPermit \in BOOLEAN /\ cutoverReady \in BOOLEAN /\ aiAuthority \in BOOLEAN
AINeverGrantsAuthority == ~aiAuthority
ReviewRequiresConformance == humanReviewed => conformanceBound
CedarPermitRequiresHumanReview == cedarPermit => humanReviewed
CutoverRequiresCedarPermit == cutoverReady => cedarPermit
CutoverRequiresCompleteEvidence == cutoverReady => parserBound /\ mappingComplete /\ conformanceBound /\ humanReviewed

====
