---- MODULE TemporalInvalidationCase ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS TemporalInvalidationData

CONSTANT ScopeChanged
VARIABLE scheduled

Explorer == INSTANCE TemporalInvalidationExplorer
  WITH Subjects <- Subjects,
       Conclusions <- Conclusions,
       SubjectEdges <- SubjectEdges,
       ConclusionEdges <- ConclusionEdges,
       Changed <- Changed,
       ScopeChanged <- ScopeChanged,
       scheduled <- scheduled

FairSpec == Explorer!FairSpec
InputInvariant == Explorer!InputInvariant
ScheduledWithinClosure == Explorer!ScheduledWithinClosure
DirectScheduled == Explorer!DirectScheduled
ReprojectionScheduled == Explorer!ReprojectionScheduled
TerminalComplete == Explorer!TerminalComplete
EventuallyComplete == Explorer!EventuallyComplete
====
