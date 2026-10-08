---- MODULE EvidenceAssessmentExplorer ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* Review outcomes are nondeterministic attestations.  A new assessment or
\* withdrawn source invalidates active claims through declared dependencies.
EXTENDS Naturals, FiniteSets

CONSTANTS Evidence, Claims, CandidateUses, Dependencies, Reviewers
Semantics == INSTANCE EvidenceLineageSemantics
  WITH Evidence <- Evidence, Claims <- Claims,
       CandidateUses <- CandidateUses, Dependencies <- Dependencies

VerdictNames == {"supports", "refutes", "uncertain"}
VARIABLES cited, reviews, active, withdrawn
vars == <<cited, reviews, active, withdrawn>>

Init ==
  /\ cited = {}
  /\ reviews = {}
  /\ active = {}
  /\ withdrawn = {}

Verdicts(use) ==
  {verdict \in VerdictNames :
    \E review \in reviews : review[1] = use /\ review[3] = verdict}
AssessmentClass(use) ==
  IF use[1] \in withdrawn THEN "stale"
  ELSE LET verdicts == Verdicts(use)
       IN IF verdicts = {} THEN "unreviewed"
          ELSE IF "supports" \in verdicts /\ "refutes" \in verdicts
               THEN "contested"
          ELSE IF "uncertain" \in verdicts THEN "uncertain"
          ELSE IF "refutes" \in verdicts THEN "refuted"
          ELSE "supported"

Affected(claim) == Semantics!Closure({claim}, Cardinality(Claims))

Cite(use) ==
  /\ use \in CandidateUses \ cited
  /\ use[1] \notin withdrawn
  /\ cited' = cited \cup {use}
  /\ active' = active \ Affected(use[2])
  /\ UNCHANGED <<reviews, withdrawn>>

Review(use, reviewer, verdict) ==
  /\ use \in cited
  /\ use[1] \notin withdrawn
  /\ reviewer \in Reviewers
  /\ verdict \in VerdictNames
  /\ ~\E previous \in reviews :
       previous[1] = use /\ previous[2] = reviewer
  /\ reviews' = reviews \cup {<<use, reviewer, verdict>>}
  /\ active' = active \ Affected(use[2])
  /\ UNCHANGED <<cited, withdrawn>>

LocalSupport(claim) ==
  /\ Semantics!UseOf(claim) \cap cited # {}
  /\ \A use \in Semantics!UseOf(claim) \cap cited :
       AssessmentClass(use) = "supported"
ParentSupport(claim) ==
  \E parent \in active : <<parent, claim>> \in Dependencies

Admit(claim) ==
  /\ claim \in Claims \ active
  /\ (LocalSupport(claim) \/ ParentSupport(claim))
  /\ \A use \in Semantics!UseOf(claim) \cap cited :
       AssessmentClass(use) = "supported"
  /\ active' = active \cup {claim}
  /\ UNCHANGED <<cited, reviews, withdrawn>>

Withdraw(evidence) ==
  /\ evidence \in Evidence \ withdrawn
  /\ withdrawn' = withdrawn \cup {evidence}
  /\ active' = active \ Semantics!AffectedBy(evidence, cited)
  /\ UNCHANGED <<cited, reviews>>

Explore ==
  \/ \E use \in CandidateUses : Cite(use)
  \/ \E use \in CandidateUses :
       \E reviewer \in Reviewers :
         \E verdict \in VerdictNames : Review(use, reviewer, verdict)
  \/ \E claim \in Claims : Admit(claim)
  \/ \E evidence \in Evidence : Withdraw(evidence)
Spec == Init /\ [][Explore]_vars

TypeInvariant ==
  /\ Semantics!DataWellFormed
  /\ Reviewers # {}
  /\ cited \subseteq CandidateUses
  /\ reviews \subseteq CandidateUses \X Reviewers \X VerdictNames
  /\ active \subseteq Claims
  /\ withdrawn \subseteq Evidence

ActiveAssessmentInvariant ==
  \A claim \in active :
    /\ \A use \in Semantics!UseOf(claim) \cap cited :
         AssessmentClass(use) = "supported"
    /\ (LocalSupport(claim) \/ ParentSupport(claim))

WithdrawnSourceInvariant ==
  \A evidence \in withdrawn :
    active \cap Semantics!AffectedBy(evidence, cited) = {}

====
