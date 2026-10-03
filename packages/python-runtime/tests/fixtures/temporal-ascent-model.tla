---- MODULE TemporalAscent ----
ModelIdentity == "provider-model"
ClockDomains == {<<"local", "logical-version">>}
Observations == {<<"cause", "local", 1, "source", "observed">>, <<"effect", "local", 2, "source", "observed">>}
Hypotheses == {<<"target", "cause", "effect">>}
Constraints == {}
FamilyComplete == TRUE
FamilySemantics == "exclusive-explanations"
====
