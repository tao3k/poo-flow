---- MODULE TemporalConclusionSelectionCase ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS TemporalConclusionSelectionData

VARIABLES selected, version, attempted, committed, conflicted

Model == INSTANCE TemporalConclusionSelection
  WITH Revisions <- Revisions,
       Proposals <- Proposals,
       InitialSelected <- InitialSelected,
       InitialVersion <- InitialVersion,
       selected <- selected,
       version <- version,
       attempted <- attempted,
       committed <- committed,
       conflicted <- conflicted

FairSpec == Model!FairSpec
InputInvariant == Model!InputInvariant
PartitionInvariant == Model!PartitionInvariant
AtMostOneCommit == Model!AtMostOneCommit
VersionInvariant == Model!VersionInvariant
SelectionInvariant == Model!SelectionInvariant
StaleProposalConflicts == Model!StaleProposalConflicts
EventuallyResolved == Model!EventuallyResolved
====
