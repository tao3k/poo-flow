---- MODULE TemporalConclusionSelection ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS Naturals, FiniteSets

\* A proposal is <<new revision, predecessor, expected version, proof>>.
CONSTANTS Revisions, Proposals, InitialSelected, InitialVersion
VARIABLES selected, version, attempted, committed, conflicted

InputInvariant ==
  /\ InitialSelected \in Revisions
  /\ InitialVersion \in Nat
  /\ Proposals \subseteq (Revisions \X Revisions \X Nat \X STRING)
  /\ \A p \in Proposals :
       /\ p[1] # InitialSelected
       /\ p[2] = InitialSelected
       /\ p[3] = InitialVersion
       /\ p[4] # ""

ProposalIds == {p[1] : p \in Proposals}
vars == <<selected, version, attempted, committed, conflicted>>

Init ==
  /\ selected = InitialSelected
  /\ version = InitialVersion
  /\ attempted = {}
  /\ committed = {}
  /\ conflicted = {}

CanCommit(p) ==
  /\ p[1] \notin attempted
  /\ selected = p[2]
  /\ version = p[3]

Commit(p) ==
  /\ CanCommit(p)
  /\ selected' = p[1]
  /\ version' = version + 1
  /\ attempted' = attempted \cup {p[1]}
  /\ committed' = committed \cup {p[1]}
  /\ UNCHANGED conflicted

Conflict(p) ==
  /\ p[1] \notin attempted
  /\ ~CanCommit(p)
  /\ attempted' = attempted \cup {p[1]}
  /\ conflicted' = conflicted \cup {p[1]}
  /\ UNCHANGED <<selected, version, committed>>

ResolveAny == \E p \in Proposals : Commit(p) \/ Conflict(p)
Spec == Init /\ [][ResolveAny]_vars
FairSpec == Spec /\ WF_vars(ResolveAny)

PartitionInvariant ==
  /\ attempted = committed \cup conflicted
  /\ committed \cap conflicted = {}
  /\ attempted \subseteq ProposalIds
AtMostOneCommit == Cardinality(committed) <= 1
VersionInvariant == version = InitialVersion + Cardinality(committed)
SelectionInvariant ==
  IF committed = {} THEN selected = InitialSelected
  ELSE selected \in committed
StaleProposalConflicts ==
  (attempted = ProposalIds) =>
    conflicted = ProposalIds \ committed
EventuallyResolved == <> (attempted = ProposalIds)
====
