---- MODULE TemporalHypothesisFamily ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* Finite literal family for the POO source-to-model projection.
\* This module declares candidate data; it is not a TLC behavior specification.
ClockDomains == {<<"timeline", "logical-version">>}
Observations == {<<"source-a", "timeline", 1, "ledger", "observed">>, <<"source-b", "timeline", 2, "ledger", "observed">>, <<"result", "timeline", 3, "ledger", "observed">>}
Hypotheses == {<<"via-a", "source-a", "result">>, <<"via-b", "source-b", "result">>}
Constraints == {<<"a-before-result", "via-a", "before", "source-a", "result">>}
FamilyComplete == TRUE
====
