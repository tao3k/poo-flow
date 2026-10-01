---- MODULE TemporalRevisionData ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* Two concurrent corrections and one retraction of only one branch.
Revisions == {<<"r1", "subject", "assert", "", 10, 1, 5>>,
              <<"r2", "subject", "correct", "r1", 20, 2, 6>>,
              <<"r3", "subject", "correct", "r1", 22, 2, 6>>,
              <<"r4", "subject", "retract", "r2", 30, 0, 0>>}
====
