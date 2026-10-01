---- MODULE TemporalRevisionSemantics ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* Finite append-only evidence revision semantics. Each tuple is
\* <<id, subject, operation, predecessor, admission, valid-start, valid-end>>.
\* Empty predecessor is a root; retractions have 0 validity endpoints.
EXTENDS Naturals, FiniteSets

CONSTANT Revisions

RevisionIds == {r[1] : r \in Revisions}
Revision(id) == CHOOSE r \in Revisions : r[1] = id

VisibleAt(selected, cut) ==
  {id \in selected : Revision(id)[5] <= cut}

Heads(selected) ==
  {id \in selected :
     ~\E child \in selected : Revision(child)[4] = id}

SubjectHeads(selected, subject) ==
  {id \in Heads(selected) : Revision(id)[2] = subject}

ActiveAt(selected, subject, validAt) ==
  LET heads == SubjectHeads(selected, subject)
  IN IF Cardinality(heads) = 1
     THEN LET head == CHOOSE id \in heads : TRUE
          IN IF Revision(head)[3] # "retract"
                /\ Revision(head)[6] <= validAt
                /\ validAt < Revision(head)[7]
             THEN {head} ELSE {}
     ELSE {}

WellFormed ==
  /\ Revisions # {}
  /\ Cardinality(RevisionIds) = Cardinality(Revisions)
  /\ \A r \in Revisions :
       /\ r[5] \in Nat
       /\ r[3] \in {"assert", "correct", "retract"}
       /\ IF r[3] = "assert"
          THEN r[4] = "" /\ r[6] \in Nat /\ r[7] \in Nat
               /\ r[6] < r[7]
          ELSE /\ r[4] \in RevisionIds
               /\ Revision(r[4])[2] = r[2]
               /\ Revision(r[4])[3] # "retract"
               /\ Revision(r[4])[5] < r[5]
               /\ IF r[3] = "retract"
                  THEN r[6] = 0 /\ r[7] = 0
                  ELSE r[6] \in Nat /\ r[7] \in Nat
                       /\ r[6] < r[7]

====
