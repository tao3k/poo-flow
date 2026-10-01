---- MODULE TemporalRevisionCase ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS TemporalRevisionData

CONSTANTS CutPosition, ValidAtPosition, Subject, FirstRevision
VARIABLE admitted

Explorer == INSTANCE TemporalRevisionExplorer
  WITH Revisions <- Revisions,
       CutPosition <- CutPosition,
       ValidAtPosition <- ValidAtPosition,
       Subject <- Subject,
       FirstRevision <- FirstRevision,
       admitted <- admitted

FairSpec == Explorer!FairSpec
InputInvariant == Explorer!InputInvariant
HistoryInvariant == Explorer!HistoryInvariant
HistoricalCutInvariant == Explorer!HistoricalCutInvariant
NoSilentWinner == Explorer!NoSilentWinner
ActiveIsHead == Explorer!ActiveIsHead
EventuallyComplete == Explorer!EventuallyComplete

====
