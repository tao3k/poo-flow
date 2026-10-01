---- MODULE EvidenceAssessmentCase ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS Naturals
Evidence == {"source"}
Claims == {"finding", "report"}
CandidateUses == {<<"source", "finding">>}
Dependencies == {<<"finding", "report">>}
Reviewers == {"reviewerA", "reviewerB"}
VARIABLES cited, reviews, active, withdrawn
Explorer == INSTANCE EvidenceAssessmentExplorer
  WITH Evidence <- Evidence, Claims <- Claims,
       CandidateUses <- CandidateUses, Dependencies <- Dependencies,
       Reviewers <- Reviewers, cited <- cited, reviews <- reviews,
       active <- active, withdrawn <- withdrawn
Spec == Explorer!Spec
TypeInvariant == Explorer!TypeInvariant
ActiveAssessmentInvariant == Explorer!ActiveAssessmentInvariant
WithdrawnSourceInvariant == Explorer!WithdrawnSourceInvariant
====
