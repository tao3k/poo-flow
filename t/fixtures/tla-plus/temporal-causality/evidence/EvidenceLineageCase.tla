---- MODULE EvidenceLineageCase ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS Naturals
Evidence == {"ePrimary", "eDistractor"}
Claims == {"cFinding", "cReport"}
CandidateUses == {<<"ePrimary", "cFinding">>,
                  <<"eDistractor", "cFinding">>}
Dependencies == {<<"cFinding", "cReport">>}
VARIABLES soundUses, retrieved, cited, checked, rejected, active, corrected
Explorer == INSTANCE EvidenceLineageExplorer
  WITH Evidence <- Evidence, Claims <- Claims,
       CandidateUses <- CandidateUses,
       Dependencies <- Dependencies,
       soundUses <- soundUses,
       retrieved <- retrieved, cited <- cited, checked <- checked,
       rejected <- rejected, active <- active, corrected <- corrected
Spec == Explorer!Spec
TypeInvariant == Explorer!TypeInvariant
UsePartitionInvariant == Explorer!UsePartitionInvariant
CheckedUseInvariant == Explorer!CheckedUseInvariant
ActiveSupportInvariant == Explorer!ActiveSupportInvariant
CorrectionInvariant == Explorer!CorrectionInvariant
====
