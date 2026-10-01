---- MODULE TemporalInvalidationExplorer ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS Naturals, FiniteSets

CONSTANTS Subjects, Conclusions, SubjectEdges, ConclusionEdges, Changed,
          ScopeChanged
VARIABLE scheduled

InputInvariant ==
  /\ Changed \subseteq Subjects
  /\ ScopeChanged \in BOOLEAN
  /\ SubjectEdges \subseteq (Subjects \X Conclusions)
  /\ ConclusionEdges \subseteq (Conclusions \X Conclusions)

Direct ==
  IF ScopeChanged THEN Conclusions
  ELSE {c \in Conclusions : \E s \in Changed : <<s, c>> \in SubjectEdges}
Step(S) == S \cup {c \in Conclusions : \E p \in S : <<p, c>> \in ConclusionEdges}

RECURSIVE Reach(_)
Reach(n) == IF n = 0 THEN Direct ELSE Step(Reach(n - 1))
Closure == Reach(Cardinality(Conclusions))

Init == scheduled = Direct
Advance ==
  \E c \in Conclusions \ scheduled :
    /\ \E p \in scheduled : <<p, c>> \in ConclusionEdges
    /\ scheduled' = scheduled \cup {c}
Next == Advance
vars == <<scheduled>>
Spec == Init /\ [][Next]_vars
FairSpec == Spec /\ WF_vars(Advance)

ScheduledWithinClosure == scheduled \subseteq Closure
DirectScheduled == Direct \subseteq scheduled
ReprojectionScheduled == ScopeChanged => scheduled = Conclusions
Terminal == ~ENABLED Advance
TerminalComplete == Terminal => scheduled = Closure
EventuallyComplete == <> (scheduled = Closure)
====
