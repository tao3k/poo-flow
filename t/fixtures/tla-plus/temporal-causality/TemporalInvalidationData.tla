---- MODULE TemporalInvalidationData ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

Subjects == {"prescription", "deployment"}
Conclusions == {"dose", "alert", "audit", "release"}
SubjectEdges == {<<"prescription", "dose">>, <<"deployment", "release">>}
ConclusionEdges == {<<"dose", "alert">>, <<"dose", "audit">>,
                    <<"alert", "audit">>, <<"alert", "dose">>}
Changed == {"prescription"}
====
