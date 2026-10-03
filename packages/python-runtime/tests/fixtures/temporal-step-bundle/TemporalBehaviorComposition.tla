---- MODULE TemporalBehaviorComposition ----
ModelIdentity == "medication"
StateVariables == {<<"administration", {"given", "none"}, "none">>, <<"control-measurement", {"baseline", "changed"}, "baseline">>, <<"prescription", {"issued", "none"}, "none">>}
Mechanisms == {<<"administer", {<<"order-required", "prescription", "issued">>}, {<<"dose", "administration", "given">>}, "scenario-administration-assumption">>, <<"prescribe", {}, {<<"order", "prescription", "issued">>}, "scenario-order-assumption">>}
Interventions == <<>>
Horizon == 2
PropertyIdentity == "property"
PropertyKind == "safety"
Conditions == {<<"goal", "control-measurement", "baseline">>}
Deadline == 2
ExpectedOutcomes == {TRUE}
====
