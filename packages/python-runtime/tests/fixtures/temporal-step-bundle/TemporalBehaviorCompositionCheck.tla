---- MODULE TemporalBehaviorCompositionCheck ----
EXTENDS TemporalBehaviorComposition, Naturals, Sequences, FiniteSets
VARIABLES state, step, held, reached, route
Behavior == INSTANCE TemporalBehaviorSemantics
 WITH StateVariables <- StateVariables, Mechanisms <- Mechanisms,
 Interventions <- Interventions, Horizon <- Horizon, PropertyKind <- PropertyKind,
 Conditions <- Conditions, Deadline <- Deadline, ExpectedOutcomes <- ExpectedOutcomes,
 state <- state, step <- step, held <- held, reached <- reached
NativeStepTableIdentity == "sha256:014164db25b1777d7d429b81d524a226f6ca78aca4a5e06a746783997bc28d7a"
VariableOrder == <<"administration", "control-measurement", "prescription">>
NativeInitialValues == <<"none", "baseline", "none">>
NativeSteps == {<<0, <<"none", "baseline", "none">>, "idle", <<"none", "baseline", "none">>>>, <<0, <<"none", "baseline", "none">>, "administer", <<"none", "baseline", "none">>>>, <<0, <<"none", "baseline", "none">>, "prescribe", <<"none", "baseline", "issued">>>>, <<1, <<"none", "baseline", "none">>, "idle", <<"none", "baseline", "none">>>>, <<1, <<"none", "baseline", "none">>, "administer", <<"none", "baseline", "none">>>>, <<1, <<"none", "baseline", "none">>, "prescribe", <<"none", "baseline", "issued">>>>, <<1, <<"none", "baseline", "issued">>, "idle", <<"none", "baseline", "issued">>>>, <<1, <<"none", "baseline", "issued">>, "administer", <<"given", "baseline", "issued">>>>, <<1, <<"none", "baseline", "issued">>, "prescribe", <<"none", "baseline", "issued">>>>}
StateTuple(s) == [i \in 1..Len(VariableOrder) |-> s[VariableOrder[i]]]
StateFromTuple(values) == [id \in Behavior!VariableIds |->
 values[CHOOSE i \in 1..Len(VariableOrder): VariableOrder[i] = id]]
NativeStepsSoundness == /\ Len(VariableOrder) = Cardinality(Behavior!VariableIds)
 /\ {VariableOrder[i]: i \in 1..Len(VariableOrder)} = Behavior!VariableIds
 /\ NativeInitialValues = StateTuple(Behavior!InitialState)
 /\ \A edge \in NativeSteps:
    /\ edge[1] \in 0..Horizon /\ edge[1] < Horizon
    /\ Len(edge[2]) = Len(VariableOrder) /\ Len(edge[4]) = Len(VariableOrder)
    /\ edge[3] \in Behavior!MechanismIds \cup {"idle"}
    /\ edge[4] = StateTuple(Behavior!Clamp(Behavior!Apply(StateFromTuple(edge[2]),edge[3]),edge[1]+1))
StepAgreement == step < Horizon =>
 \A action \in Behavior!MechanismIds \cup {"idle"}:
 <<step,StateTuple(state),action,StateTuple(Behavior!Clamp(Behavior!Apply(state,action),step+1))>> \in NativeSteps
WitnessActions == <<"idle", "idle">>
WitnessStates == <<[id \in {"administration", "control-measurement", "prescription"} |-> CASE id = "administration" -> "none" [] id = "control-measurement" -> "baseline" [] id = "prescription" -> "none"], [id \in {"administration", "control-measurement", "prescription"} |-> CASE id = "administration" -> "none" [] id = "control-measurement" -> "baseline" [] id = "prescription" -> "none"], [id \in {"administration", "control-measurement", "prescription"} |-> CASE id = "administration" -> "none" [] id = "control-measurement" -> "baseline" [] id = "prescription" -> "none"]>>
CounterActions == <<>>
CounterStates == <<>>
Routes == {"all"} \cup {"witness"}
vars == <<state,step,held,reached,route>>
Init == Behavior!Init /\ route \in Routes
Next == /\ UNCHANGED route
 /\ IF route = "all" THEN Behavior!Next ELSE
     IF step = Horizon THEN UNCHANGED <<state,step,held,reached>>
     ELSE Behavior!Advance(IF route = "witness" THEN WitnessActions[step+1] ELSE CounterActions[step+1])
Spec == Init /\ [][Next]_vars
InputInvariant == Behavior!InputInvariant /\ NativeStepsSoundness
TraceAgreement == /\ (route = "witness" => state = WitnessStates[step+1])
 /\ (route = "counter" => state = CounterStates[step+1])
 /\ (step = Horizon /\ route = "witness" => Behavior!Satisfied)
 /\ (step = Horizon /\ route = "counter" => ~Behavior!Satisfied)
TypeInvariant == Behavior!TypeInvariant
TerminalAgreement == Behavior!TerminalAgreement
====
