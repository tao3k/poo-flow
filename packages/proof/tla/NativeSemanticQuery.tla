---- MODULE NativeSemanticQuery ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\*
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS Naturals, TLC

(*
Bounded transition model for one POO semantic state and a read-only Query.
GQL is represented only by Provider execution; it never owns semantic state.
Definitions stay on one physical line for gerbil-parser's native TLA+ contract.
*)

VARIABLES queryPhase, contractBound, providerBound, resultBound, semanticRevision, resultRevision, actionAuthority

vars == << queryPhase, contractBound, providerBound, resultBound, semanticRevision, resultRevision, actionAuthority >>

QueryPhases == {"declared", "admitted", "executed", "rejected"}

Init == queryPhase = "declared" /\ contractBound = FALSE /\ providerBound = FALSE /\ resultBound = FALSE /\ semanticRevision = 0 /\ resultRevision = 0 /\ actionAuthority = FALSE

BindContract == queryPhase = "declared" /\ contractBound' = TRUE /\ UNCHANGED << queryPhase, providerBound, resultBound, semanticRevision, resultRevision, actionAuthority >>
AdmitQuery == queryPhase = "declared" /\ contractBound /\ queryPhase' = "admitted" /\ UNCHANGED << contractBound, providerBound, resultBound, semanticRevision, resultRevision, actionAuthority >>
RejectQuery == queryPhase = "declared" /\ ~contractBound /\ queryPhase' = "rejected" /\ UNCHANGED << contractBound, providerBound, resultBound, semanticRevision, resultRevision, actionAuthority >>
ExecuteProvider == queryPhase = "admitted" /\ contractBound /\ queryPhase' = "executed" /\ providerBound' = TRUE /\ resultBound' = TRUE /\ resultRevision' = semanticRevision /\ UNCHANGED << contractBound, semanticRevision, actionAuthority >>
Quiesce == queryPhase \in {"executed", "rejected"} /\ UNCHANGED vars

Next == BindContract \/ AdmitQuery \/ RejectQuery \/ ExecuteProvider \/ Quiesce

Spec == Init /\ [][Next]_vars

TypeInvariant == queryPhase \in QueryPhases /\ semanticRevision \in Nat /\ resultRevision \in Nat
QueryNeverMutatesSemanticRevision == semanticRevision = 0
QueryNeverGrantsActionAuthority == ~actionAuthority
ProviderRequiresAdmission == providerBound => queryPhase = "executed" /\ contractBound
ResultBindsProviderAndRevision == resultBound => providerBound /\ resultRevision = semanticRevision

====
