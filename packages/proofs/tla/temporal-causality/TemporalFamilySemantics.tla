---- MODULE TemporalFamilySemantics ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* Finite interpretation of one POO TemporalModel hypothesis family.
\* Tuples are the literal source profile admitted by modules/tla-plus/funs.ss.
\* This module checks temporal consistency of proposed causes, not actual
\* causation or intervention semantics.
EXTENDS Naturals, FiniteSets

CONSTANTS ClockDomains, Observations, Hypotheses, Constraints

ObservationIds == {o[1] : o \in Observations}
HypothesisIds == {h[1] : h \in Hypotheses}
DomainIds == {d[1] : d \in ClockDomains}

Order == INSTANCE TemporalOrder WITH Observations <- Observations

Hypothesis(id) == CHOOSE h \in Hypotheses : h[1] = id

ConstraintsFor(hypothesis) ==
  {c \in Constraints : c[2] = hypothesis[1]}

Statuses(hypothesis) ==
  {Order!OrderStatus(hypothesis[2], hypothesis[3], "before")}
    \cup {Order!OrderStatus(c[4], c[5], c[3]) : c \in ConstraintsFor(hypothesis)}

HypothesisStatus(hypothesis) ==
  IF "refuted" \in Statuses(hypothesis)
  THEN "refuted"
  ELSE IF "unknown" \in Statuses(hypothesis)
       THEN "unknown"
       ELSE "admitted"

DataWellFormed ==
  /\ Hypotheses # {}
  /\ Cardinality(ObservationIds) = Cardinality(Observations)
  /\ Cardinality(HypothesisIds) = Cardinality(Hypotheses)
  /\ \A o \in Observations : o[2] \in DomainIds
  /\ \E effect \in ObservationIds :
       \A h \in Hypotheses : h[3] = effect
  /\ \A c \in Constraints :
       /\ c[2] \in HypothesisIds
       /\ c[3] \in {"before", "not-after"}

====
