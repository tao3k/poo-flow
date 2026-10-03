---- MODULE TemporalFamilyCase ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* A finite, domain-neutral instance of the generic exploration kernel.
EXTENDS TemporalHypothesisFamily

CONSTANTS ExplorationLimit, Target, ExpectedClassifications
VARIABLES remaining, admitted, refuted, unknown

Explorer == INSTANCE TemporalFamilyExplorer
  WITH ClockDomains <- ClockDomains,
       Observations <- Observations,
       Hypotheses <- Hypotheses,
       Constraints <- Constraints,
       FamilyComplete <- FamilyComplete,
       FamilySemantics <- "exclusive-explanations",
       ExplorationLimit <- ExplorationLimit,
       Target <- Target,
       ExpectedClassifications <- ExpectedClassifications,
       remaining <- remaining,
       admitted <- admitted,
       refuted <- refuted,
       unknown <- unknown

FairSpec == Explorer!FairSpec
InputInvariant == Explorer!InputInvariant
PartitionInvariant == Explorer!PartitionInvariant
StatusInvariant == Explorer!StatusInvariant
BoundInvariant == Explorer!BoundInvariant
TerminalAgreement == Explorer!TerminalAgreement
EventuallyTerminal == Explorer!EventuallyTerminal

====
