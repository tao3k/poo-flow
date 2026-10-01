---- MODULE TemporalRevisionExplorer ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* Explore all predecessor-respecting admissions of a finite revision set.
EXTENDS Naturals, FiniteSets

CONSTANTS Revisions, CutPosition, ValidAtPosition, Subject, FirstRevision

Semantics == INSTANCE TemporalRevisionSemantics WITH Revisions <- Revisions

VARIABLE admitted
vars == <<admitted>>

RevisionIds == Semantics!RevisionIds
Revision(id) == Semantics!Revision(id)

Init == admitted = {}

Append(id) ==
  /\ id \in RevisionIds \ admitted
  /\ (Revision(id)[4] = "" \/ Revision(id)[4] \in admitted)
  /\ admitted' = admitted \cup {id}

AppendAny == \E id \in RevisionIds : Append(id)
Next == AppendAny
Spec == Init /\ [][Next]_vars
FairSpec == Spec /\ WF_vars(AppendAny)

HistoricalCut == Semantics!VisibleAt(admitted, CutPosition)
CurrentHeads == Semantics!SubjectHeads(admitted, Subject)
CurrentActive == Semantics!ActiveAt(admitted, Subject, ValidAtPosition)
Conflict == Cardinality(CurrentHeads) > 1
Terminal == admitted = RevisionIds

InputInvariant ==
  /\ Semantics!WellFormed
  /\ CutPosition \in Nat
  /\ ValidAtPosition \in Nat
  /\ FirstRevision \in RevisionIds
  /\ Revision(FirstRevision)[5] <= CutPosition
  /\ \A id \in RevisionIds \ {FirstRevision} :
       Revision(id)[5] > CutPosition

HistoryInvariant == admitted \subseteq RevisionIds
HistoricalCutInvariant ==
  FirstRevision \in admitted => HistoricalCut = {FirstRevision}
NoSilentWinner == Conflict => CurrentActive = {}
ActiveIsHead == CurrentActive \subseteq CurrentHeads
EventuallyComplete == <>Terminal

====
