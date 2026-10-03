---- MODULE TemporalBehaviorSemantics ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
\* Interpretation of the finite logical-step POO behavior profile v1.
\* Idle is always possible. No fairness or empirical causal authority is assumed.
EXTENDS Naturals, Sequences, FiniteSets
CONSTANTS StateVariables, Mechanisms, Interventions, Horizon,
          PropertyKind, Conditions, Deadline, ExpectedOutcomes
VARIABLES state, step, held, reached
vars == <<state, step, held, reached>>
VariableIds == {v[1]: v \in StateVariables}
MechanismIds == {m[1]: m \in Mechanisms}
Variable(id) == CHOOSE v \in StateVariables: v[1] = id
Mechanism(id) == CHOOSE m \in Mechanisms: m[1] = id
Holds(conditions, s) == \A c \in conditions: s[c[2]] = c[3]
Writes(assignments, id) == \E a \in assignments: a[2] = id
Written(assignments, id) == (CHOOSE a \in assignments: a[2] = id)[3]
Applies(index, t, id) ==
  /\ Interventions[index][2] <= t
  /\ Writes(Interventions[index][3], id)
ActiveIndices(t, id) == {i \in 1..Len(Interventions): Applies(i, t, id)}
LastIndex(t, id) == CHOOSE i \in ActiveIndices(t, id):
  \A j \in ActiveIndices(t, id): j <= i
Clamp(s, t) == [id \in VariableIds |->
  IF ActiveIndices(t, id) = {} THEN s[id]
  ELSE Written(Interventions[LastIndex(t, id)][3], id)]
Apply(s, action) ==
  IF action = "idle" THEN s
  ELSE [id \in VariableIds |->
    IF Holds(Mechanism(action)[2], s) /\ Writes(Mechanism(action)[3], id)
    THEN Written(Mechanism(action)[3], id) ELSE s[id]]
InitialState == Clamp([id \in VariableIds |-> Variable(id)[3]], 0)
Init ==
  /\ state = InitialState
  /\ step = 0
  /\ held = Holds(Conditions, InitialState)
  /\ reached = Holds(Conditions, InitialState)
Advance(action) ==
  LET after == Clamp(Apply(state, action), step + 1)
  IN /\ step < Horizon
     /\ state' = after
     /\ step' = step + 1
     /\ held' = IF step + 1 <= Deadline THEN held /\ Holds(Conditions, after) ELSE held
     /\ reached' = IF step + 1 <= Deadline THEN reached \/ Holds(Conditions, after) ELSE reached
Next == (\E action \in MechanismIds \cup {"idle"}: Advance(action))
        \/ (step = Horizon /\ UNCHANGED vars)
Spec == Init /\ [][Next]_vars
Satisfied == IF PropertyKind = "safety" THEN held ELSE reached
TypeInvariant ==
  /\ step \in 0..Horizon
  /\ DOMAIN state = VariableIds
  /\ \A id \in VariableIds: state[id] \in Variable(id)[2]
  /\ held \in BOOLEAN
  /\ reached \in BOOLEAN
InputInvariant ==
  /\ Deadline \in 0..Horizon
  /\ PropertyKind \in {"safety", "reachability", "bounded-progress"}
  /\ ExpectedOutcomes \subseteq BOOLEAN
  /\ "idle" \notin MechanismIds
TerminalAgreement == step = Horizon => Satisfied \in ExpectedOutcomes
====
