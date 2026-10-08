---- MODULE EvidenceLineageExplorer ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* Internal nondeterministic exploration of evidence retrieval, citation,
\* independent use checking, artifact admission and evidence correction.
EXTENDS Naturals, FiniteSets

CONSTANTS Evidence, Claims, CandidateUses, Dependencies
Semantics == INSTANCE EvidenceLineageSemantics
  WITH Evidence <- Evidence, Claims <- Claims,
       CandidateUses <- CandidateUses,
       Dependencies <- Dependencies

VARIABLES soundUses, retrieved, cited, checked, rejected, active, corrected
vars == <<soundUses, retrieved, cited, checked, rejected, active, corrected>>

Init ==
  /\ soundUses \in SUBSET CandidateUses
  /\ retrieved = {}
  /\ cited = {}
  /\ checked = {}
  /\ rejected = {}
  /\ active = {}
  /\ corrected = {}

Retrieve(e) ==
  /\ e \in Evidence \ (retrieved \cup corrected)
  /\ retrieved' = retrieved \cup {e}
  /\ UNCHANGED <<soundUses, cited, checked, rejected, active, corrected>>

Cite(use) ==
  /\ use \in CandidateUses \ cited
  /\ use[1] \in retrieved \ corrected
  /\ cited' = cited \cup {use}
  /\ active' = active \ Semantics!Closure({use[2]}, Cardinality(Claims))
  /\ UNCHANGED <<soundUses, retrieved, checked, rejected, corrected>>

CheckUse(use) ==
  /\ use \in cited \ (checked \cup rejected)
  /\ use[1] \notin corrected
  /\ checked' = IF use \in soundUses THEN checked \cup {use} ELSE checked
  /\ rejected' = IF use \in soundUses THEN rejected ELSE rejected \cup {use}
  /\ UNCHANGED <<soundUses, retrieved, cited, active, corrected>>

LocalSupport(claim) ==
  /\ Semantics!UseOf(claim) \cap cited # {}
  /\ Semantics!UseOf(claim) \cap cited \subseteq checked

ParentSupport(claim) ==
  \E parent \in active : <<parent, claim>> \in Dependencies

Admit(claim) ==
  /\ claim \in Claims \ active
  /\ (LocalSupport(claim) \/ ParentSupport(claim))
  /\ Semantics!UseOf(claim) \cap cited \subseteq checked
  /\ active' = active \cup {claim}
  /\ UNCHANGED <<soundUses, retrieved, cited, checked, rejected, corrected>>

Correct(e) ==
  /\ e \in retrieved \ corrected
  /\ corrected' = corrected \cup {e}
  /\ checked' = checked \ Semantics!UsesOf(e)
  /\ active' = active \ Semantics!AffectedBy(e, cited)
  /\ UNCHANGED <<soundUses, retrieved, cited, rejected>>

Explore ==
  \/ \E e \in Evidence : Retrieve(e)
  \/ \E use \in CandidateUses : Cite(use)
  \/ \E use \in CandidateUses : CheckUse(use)
  \/ \E claim \in Claims : Admit(claim)
  \/ \E e \in Evidence : Correct(e)
Spec == Init /\ [][Explore]_vars

TypeInvariant ==
  /\ Semantics!DataWellFormed
  /\ soundUses \subseteq CandidateUses
  /\ retrieved \subseteq Evidence
  /\ corrected \subseteq retrieved
  /\ cited \subseteq CandidateUses
  /\ checked \subseteq cited
  /\ rejected \subseteq cited
  /\ active \subseteq Claims

UsePartitionInvariant == checked \cap rejected = {}
CheckedUseInvariant ==
  \A use \in checked : use \in soundUses /\ use[1] \notin corrected
ActiveSupportInvariant ==
  \A claim \in active :
    /\ Semantics!UseOf(claim) \cap cited \subseteq checked
    /\ (LocalSupport(claim) \/ ParentSupport(claim))
CorrectionInvariant ==
  \A e \in corrected : active \cap Semantics!AffectedBy(e, cited) = {}

====
