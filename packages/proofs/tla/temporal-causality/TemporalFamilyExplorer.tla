---- MODULE TemporalFamilyExplorer ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* TLC explores every bounded ordering of a supplied candidate family.
\* No domain-specific action list is part of the POO TemporalModel contract.
EXTENDS Naturals, FiniteSets

CONSTANTS ClockDomains, Observations, Hypotheses, Constraints,
          FamilyComplete, ExplorationLimit, Target, ExpectedClassifications

Semantics == INSTANCE TemporalFamilySemantics
  WITH ClockDomains <- ClockDomains,
       Observations <- Observations,
       Hypotheses <- Hypotheses,
       Constraints <- Constraints

VARIABLES remaining, admitted, refuted, unknown
vars == <<remaining, admitted, refuted, unknown>>

HypothesisIds == Semantics!HypothesisIds
Explored == admitted \cup refuted \cup unknown
\* Zero requests full traversal of the declared finite family; positive values
\* are operational checking limits and cannot change source-model truth.
EffectiveLimit ==
  IF ExplorationLimit = 0 THEN Cardinality(HypothesisIds)
  ELSE ExplorationLimit

Init ==
  /\ remaining = HypothesisIds
  /\ admitted = {}
  /\ refuted = {}
  /\ unknown = {}

Explore(id) ==
  /\ id \in remaining
  /\ Cardinality(Explored) < EffectiveLimit
  /\ remaining' = remaining \ {id}
  /\ admitted' =
       IF Semantics!HypothesisStatus(Semantics!Hypothesis(id)) = "admitted"
       THEN admitted \cup {id} ELSE admitted
  /\ refuted' =
       IF Semantics!HypothesisStatus(Semantics!Hypothesis(id)) = "refuted"
       THEN refuted \cup {id} ELSE refuted
  /\ unknown' =
       IF Semantics!HypothesisStatus(Semantics!Hypothesis(id)) = "unknown"
       THEN unknown \cup {id} ELSE unknown

ExploreAny == \E id \in remaining : Explore(id)
Next == ExploreAny
Spec == Init /\ [][Next]_vars
FairSpec == Spec /\ WF_vars(ExploreAny)

Terminal == remaining = {} \/ Cardinality(Explored) = EffectiveLimit

Classification ==
  IF Target \in refuted THEN "refuted"
  ELSE IF Target \in admitted
       THEN IF remaining = {} /\ FamilyComplete /\ unknown = {}
               /\ Cardinality(admitted) = 1
            THEN "necessary" ELSE "possible"
       ELSE "unknown"

PartitionInvariant ==
  /\ remaining \subseteq HypothesisIds
  /\ admitted \subseteq HypothesisIds
  /\ refuted \subseteq HypothesisIds
  /\ unknown \subseteq HypothesisIds
  /\ remaining \cap Explored = {}
  /\ admitted \cap refuted = {}
  /\ admitted \cap unknown = {}
  /\ refuted \cap unknown = {}
  /\ remaining \cup Explored = HypothesisIds

StatusInvariant ==
  /\ \A id \in admitted :
       Semantics!HypothesisStatus(Semantics!Hypothesis(id)) = "admitted"
  /\ \A id \in refuted :
       Semantics!HypothesisStatus(Semantics!Hypothesis(id)) = "refuted"
  /\ \A id \in unknown :
       Semantics!HypothesisStatus(Semantics!Hypothesis(id)) = "unknown"

BoundInvariant == Cardinality(Explored) <= EffectiveLimit
InputInvariant ==
  /\ Semantics!DataWellFormed
  /\ Target \in HypothesisIds
  /\ ExplorationLimit \in Nat
  /\ FamilyComplete \in BOOLEAN
  /\ ExpectedClassifications \subseteq
       {"possible", "necessary", "refuted", "unknown"}
TerminalAgreement == Terminal => Classification \in ExpectedClassifications
EventuallyTerminal == <>Terminal

====
