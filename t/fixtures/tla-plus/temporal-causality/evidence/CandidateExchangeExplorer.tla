---- MODULE CandidateExchangeExplorer ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* Finite candidate-exchange protocol. Provider and verifier outcomes are
\* inputs; their semantic correctness is outside this model.
\* "reviewable" is an inert handoff state, never Temporal admission.
EXTENDS Naturals, FiniteSets

CONSTANTS Candidates, GqlRequired, AscentRequired, Cuts, MaxGeneration
ASSUME /\ Candidates # {}
       /\ IsFiniteSet(Candidates)
       /\ GqlRequired \subseteq Candidates
       /\ AscentRequired \subseteq Candidates
       /\ GqlRequired \cup AscentRequired = Candidates
       /\ Cuts # {}
       /\ IsFiniteSet(Cuts)
       /\ MaxGeneration \in Nat

\* No check is the unknown state in this finite configuration.
Verdicts == {"valid", "invalid"}
ReceiptUniverse == (0..MaxGeneration) \X Cuts \X Candidates \X BOOLEAN
CheckUniverse == (0..MaxGeneration) \X Cuts \X Candidates \X Verdicts

VARIABLES generation, cut, covered, gqlReceipts, ascentReceipts,
          gqlChecks, ascentChecks, contested, reviewable
vars == <<generation, cut, covered, gqlReceipts, ascentReceipts,
          gqlChecks, ascentChecks, contested, reviewable>>

Init ==
  /\ generation = 0
  /\ cut = CHOOSE selected \in Cuts : TRUE
  /\ covered = FALSE
  /\ gqlReceipts = {}
  /\ ascentReceipts = {}
  /\ gqlChecks = {}
  /\ ascentChecks = {}
  /\ contested = {}
  /\ reviewable = {}

UniqueReceipt(receipts, sourceGeneration, sourceCut, candidate) ==
  \A receipt \in receipts :
    receipt[1] # sourceGeneration \/ receipt[2] # sourceCut
    \/ receipt[3] # candidate

GqlCandidate(candidate, complete) ==
  /\ candidate \in Candidates
  /\ complete \in BOOLEAN
  /\ UniqueReceipt(gqlReceipts, generation, cut, candidate)
  /\ gqlReceipts' = gqlReceipts
                    \cup {<<generation, cut, candidate, complete>>}
  /\ UNCHANGED <<generation, cut, covered, ascentReceipts,
                 gqlChecks, ascentChecks, contested, reviewable>>

AscentCandidate(candidate, complete) ==
  /\ candidate \in Candidates
  /\ complete \in BOOLEAN
  /\ UniqueReceipt(ascentReceipts, generation, cut, candidate)
  /\ ascentReceipts' = ascentReceipts
                       \cup {<<generation, cut, candidate, complete>>}
  /\ UNCHANGED <<generation, cut, covered, gqlReceipts,
                 gqlChecks, ascentChecks, contested, reviewable>>

UniqueCheck(checks, sourceGeneration, sourceCut, candidate) ==
  \A check \in checks :
    check[1] # sourceGeneration \/ check[2] # sourceCut
    \/ check[3] # candidate

GqlCheck(candidate, verdict) ==
  /\ verdict \in Verdicts
  /\ <<generation, cut, candidate, TRUE>> \in gqlReceipts
     \/ <<generation, cut, candidate, FALSE>> \in gqlReceipts
  /\ UniqueCheck(gqlChecks, generation, cut, candidate)
  /\ gqlChecks' = gqlChecks
                   \cup {<<generation, cut, candidate, verdict>>}
  /\ UNCHANGED <<generation, cut, covered, gqlReceipts,
                 ascentReceipts, ascentChecks, contested, reviewable>>

AscentCheck(candidate, verdict) ==
  /\ verdict \in Verdicts
  /\ <<generation, cut, candidate, TRUE>> \in ascentReceipts
     \/ <<generation, cut, candidate, FALSE>> \in ascentReceipts
  /\ UniqueCheck(ascentChecks, generation, cut, candidate)
  /\ ascentChecks' = ascentChecks
                      \cup {<<generation, cut, candidate, verdict>>}
  /\ UNCHANGED <<generation, cut, covered, gqlReceipts,
                 ascentReceipts, gqlChecks, contested, reviewable>>

DeclareCoverage ==
  /\ ~covered
  /\ covered' = TRUE
  /\ UNCHANGED <<generation, cut, gqlReceipts, ascentReceipts,
                 gqlChecks, ascentChecks, contested, reviewable>>

\* A second receipt or a contradictory check can arrive after a candidate
\* was marked reviewable. The dispute atomically withdraws that handoff.
ConflictingReceipt(candidate) ==
  /\ candidate \in Candidates \ contested
  /\ (\E complete \in BOOLEAN :
        <<generation, cut, candidate, complete>> \in gqlReceipts
        \/ <<generation, cut, candidate, complete>> \in ascentReceipts)
  /\ contested' = contested \cup {candidate}
  /\ reviewable' = reviewable \ {candidate}
  /\ UNCHANGED <<generation, cut, covered, gqlReceipts, ascentReceipts,
                 gqlChecks, ascentChecks>>

ConflictingCheck(candidate) ==
  /\ candidate \in Candidates \ contested
  /\ (<<generation, cut, candidate, "valid">> \in gqlChecks
      \/ <<generation, cut, candidate, "valid">> \in ascentChecks)
  /\ contested' = contested \cup {candidate}
  /\ reviewable' = reviewable \ {candidate}
  /\ UNCHANGED <<generation, cut, covered, gqlReceipts, ascentReceipts,
                 gqlChecks, ascentChecks>>

RequiredComplete(candidate) ==
  /\ (candidate \notin GqlRequired \/
      (<<generation, cut, candidate, TRUE>> \in gqlReceipts
       /\ <<generation, cut, candidate, "valid">> \in gqlChecks))
  /\ (candidate \notin AscentRequired \/
      (<<generation, cut, candidate, TRUE>> \in ascentReceipts
       /\ <<generation, cut, candidate, "valid">> \in ascentChecks))

MarkReviewable(candidate) ==
  /\ candidate \in Candidates \ reviewable
  /\ candidate \notin contested
  /\ covered
  /\ RequiredComplete(candidate)
  /\ reviewable' = reviewable \cup {candidate}
  /\ UNCHANGED <<generation, cut, covered, gqlReceipts,
                 ascentReceipts, gqlChecks, ascentChecks, contested>>

\* A revision may reuse source bytes; generation still changes.
\* Old receipts and checks remain historical. Reviewability and coverage
\* for the prior generation are retired atomically.
Revise ==
  /\ generation < MaxGeneration
  /\ \E nextCut \in Cuts :
       /\ generation' = generation + 1
       /\ cut' = nextCut
  /\ covered' = FALSE
  /\ contested' = {}
  /\ reviewable' = {}
  /\ UNCHANGED <<gqlReceipts, ascentReceipts, gqlChecks, ascentChecks>>

Explore ==
  \/ \E candidate \in Candidates, complete \in BOOLEAN :
       GqlCandidate(candidate, complete)
  \/ \E candidate \in Candidates, complete \in BOOLEAN :
       AscentCandidate(candidate, complete)
  \/ \E candidate \in Candidates, verdict \in Verdicts :
       GqlCheck(candidate, verdict)
  \/ \E candidate \in Candidates, verdict \in Verdicts :
       AscentCheck(candidate, verdict)
  \/ DeclareCoverage
  \/ \E candidate \in Candidates : ConflictingReceipt(candidate)
  \/ \E candidate \in Candidates : ConflictingCheck(candidate)
  \/ \E candidate \in Candidates : MarkReviewable(candidate)
  \/ Revise
Spec == Init /\ [][Explore]_vars

TypeInvariant ==
  /\ generation \in 0..MaxGeneration
  /\ cut \in Cuts
  /\ covered \in BOOLEAN
  /\ gqlReceipts \subseteq ReceiptUniverse
  /\ ascentReceipts \subseteq ReceiptUniverse
  /\ gqlChecks \subseteq CheckUniverse
  /\ ascentChecks \subseteq CheckUniverse
  /\ contested \subseteq Candidates
  /\ reviewable \subseteq Candidates

ReviewabilityInvariant ==
  \A candidate \in reviewable :
    covered /\ RequiredComplete(candidate) /\ candidate \notin contested

CoverageInvariant == ~covered => reviewable = {}
ContestInvariant == contested \cap reviewable = {}

ReceiptUniquenessInvariant ==
  /\ \A left, right \in gqlReceipts :
       (left[1] = right[1] /\ left[2] = right[2] /\ left[3] = right[3])
       => left = right
  /\ \A left, right \in ascentReceipts :
       (left[1] = right[1] /\ left[2] = right[2] /\ left[3] = right[3])
       => left = right

CheckUniquenessInvariant ==
  /\ \A left, right \in gqlChecks :
       (left[1] = right[1] /\ left[2] = right[2] /\ left[3] = right[3])
       => left = right
  /\ \A left, right \in ascentChecks :
       (left[1] = right[1] /\ left[2] = right[2] /\ left[3] = right[3])
       => left = right

====
