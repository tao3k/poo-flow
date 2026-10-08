---- MODULE EvidenceLineageSemantics ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* A finite candidate relation is supplied by the caller.  Retrieval,
\* citation, checked use and downstream dependency are distinct relations.
EXTENDS Naturals, FiniteSets

CONSTANTS Evidence, Claims, CandidateUses, Dependencies

UseOf(claim) == {use \in CandidateUses : use[2] = claim}
UsesOf(evidence) == {use \in CandidateUses : use[1] = evidence}
Dependents(claims) ==
  {claim \in Claims : \E source \in claims : <<source, claim>> \in Dependencies}
Step(claims) == claims \cup Dependents(claims)
RECURSIVE Closure(_, _)
Closure(claims, n) ==
  IF n = 0 THEN claims ELSE Closure(Step(claims), n - 1)
AffectedBy(evidence, uses) ==
  Closure({use[2] : use \in UsesOf(evidence) \cap uses},
          Cardinality(Claims))

DataWellFormed ==
  /\ Evidence # {}
  /\ Claims # {}
  /\ CandidateUses \subseteq Evidence \X Claims
  /\ Dependencies \subseteq Claims \X Claims
  /\ \A claim \in Claims : <<claim, claim>> \notin Dependencies

====
