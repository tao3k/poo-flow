---- MODULE TemporalComposition ----
ModelIdentity == "care"
ClockDomains == {<<"local", "logical-version">>, <<"remote", "logical-version">>}
Observations == {<<"care/alternative", "local", 2, "ledger", "observed">>, <<"care/cause", "local", 1, "ledger", "observed">>, <<"care/effect", "local", 3, "ledger", "observed">>}
Hypotheses == {<<"via-a", "care/cause", "care/effect">>, <<"via-b", "care/alternative", "care/effect">>}
Constraints == {}
FamilyComplete == TRUE
FamilySemantics == "exclusive-explanations"
====
