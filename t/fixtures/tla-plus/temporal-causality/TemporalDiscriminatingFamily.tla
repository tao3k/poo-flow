---- MODULE TemporalDiscriminatingFamily ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* The later source-b observation refutes via-b in the same clock domain.
ClockDomains == {<<"timeline", "logical-version">>}
Observations == {<<"source-a", "timeline", 1, "ledger", "observed">>,
                 <<"source-b", "timeline", 4, "ledger", "observed">>,
                 <<"result", "timeline", 3, "ledger", "observed">>}
Hypotheses == {<<"via-a", "source-a", "result">>,
                <<"via-b", "source-b", "result">>}
Constraints == {}
FamilyComplete == TRUE
====
