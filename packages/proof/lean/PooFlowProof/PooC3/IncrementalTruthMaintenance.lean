import PooFlowProof.PooC3.EventIngressCausalCut

namespace PooFlowProof.PooC3.IncrementalTruthMaintenance

open PooFlowProof.PooC3.EventIngressCausalCut

inductive ConclusionStateKind where
  | historical
  | active
  | superseded
  | retracted
  deriving DecidableEq, Repr

def IsActiveConclusion : ConclusionStateKind → Prop
  | .active => True
  | .historical => False
  | .superseded => False
  | .retracted => False

structure DerivedConclusionProvenance
    (ConclusionIdentity GenerationIdentity PolicyIdentity CutIdentity
      ObservationSetIdentity ProofIdentity : Type) where
  conclusionIdentity : ConclusionIdentity
  generationIdentity : GenerationIdentity
  policyIdentity : PolicyIdentity
  causalCutIdentity : CutIdentity
  observationSetIdentity : ObservationSetIdentity
  proofIdentity : ProofIdentity
  historicalEvidenceImmutable : Prop
  immutabilityEstablished : historicalEvidenceImmutable

structure LateEventCutRevision
    (EventIdentity CutIdentity RevisionIdentity : Type) where
  previousCut : ImmutableCausalCut EventIdentity CutIdentity
  revisedCut : ImmutableCausalCut EventIdentity CutIdentity
  cutIdentityChanged :
    revisedCut.cutIdentity ≠ previousCut.cutIdentity
  revisionIdentity : RevisionIdentity

structure MonotoneUpdatePlan (ConclusionIdentity : Type) where
  previousReachable : List ConclusionIdentity
  revisedReachable : List ConclusionIdentity
  previousFrontierPreserved :
    ∀ conclusion ∈ previousReachable,
      conclusion ∈ revisedReachable

structure NonMonotoneUpdatePlan
    (ConclusionIdentity RetractionIdentity : Type) where
  affectedConclusions : List ConclusionIdentity
  invalidatedConclusions : List ConclusionIdentity
  everyAffectedConclusionInvalidated :
    ∀ conclusion ∈ affectedConclusions,
      conclusion ∈ invalidatedConclusions
  retractionIdentity : RetractionIdentity

structure RetractionReceipt
    (ConclusionIdentity CutIdentity ReasonIdentity ReceiptIdentity : Type) where
  conclusionIdentity : ConclusionIdentity
  revisedCutIdentity : CutIdentity
  reasonIdentity : ReasonIdentity
  receiptIdentity : ReceiptIdentity
  marksConclusionInactive : Prop
  inactiveEstablished : marksConclusionInactive
  deletesHistoricalEvidence : Prop
  preservesHistoricalEvidence : ¬ deletesHistoricalEvidence

structure ActiveConclusionSelection
    (ConclusionIdentity SelectionIdentity : Type) where
  candidates : List ConclusionIdentity
  activeConclusion : ConclusionIdentity
  activeIsCandidate : activeConclusion ∈ candidates
  selectionIdentity : SelectionIdentity
  isEligible : ConclusionIdentity → Prop
  activeEligible : isEligible activeConclusion
  uniqueActive :
    ∀ candidate ∈ candidates,
      isEligible candidate →
        candidate = activeConclusion

structure ReverseDependencyInvalidation
    (EventIdentity ConclusionIdentity InvalidationIdentity : Type) where
  changedEvent : EventIdentity
  affectedConclusions : List ConclusionIdentity
  scheduledForReevaluation : List ConclusionIdentity
  everyAffectedConclusionScheduled :
    ∀ conclusion ∈ affectedConclusions,
      conclusion ∈ scheduledForReevaluation
  invalidationIdentity : InvalidationIdentity

structure EffectCompensationProposal
    (EffectReceiptIdentity CompensationIntentIdentity : Type) where
  originalEffectReceiptIdentity : EffectReceiptIdentity
  compensationIntentIdentity : CompensationIntentIdentity
  carriesActionAuthority : Prop
  noActionAuthority : ¬ carriesActionAuthority

structure ConclusionIdentityScheme
    (CutIdentity PolicyIdentity ConclusionIdentity : Type) where
  identity : CutIdentity → PolicyIdentity → ConclusionIdentity
  cutChangeChangesConclusion :
    ∀ cutA cutB policy,
      cutA ≠ cutB →
        identity cutA policy ≠ identity cutB policy
  policyChangeChangesConclusion :
    ∀ cut policyA policyB,
      policyA ≠ policyB →
        identity cut policyA ≠ identity cut policyB

structure HistoricalCutReplay
    (CutIdentity ConclusionIdentity : Type) where
  cutIdentity : CutIdentity
  originalConclusion : ConclusionIdentity
  replayConclusion : ConclusionIdentity
  replayStable : replayConclusion = originalConclusion

theorem historicalConclusionIsNotActive :
    ¬ IsActiveConclusion .historical := by
  simp [IsActiveConclusion]

theorem supersededConclusionIsNotActive :
    ¬ IsActiveConclusion .superseded := by
  simp [IsActiveConclusion]

theorem retractedConclusionIsNotActive :
    ¬ IsActiveConclusion .retracted := by
  simp [IsActiveConclusion]

theorem selectedConclusionIsActive :
    IsActiveConclusion .active := by
  simp [IsActiveConclusion]

theorem historicalProofRemainsImmutable
    {ConclusionIdentity GenerationIdentity PolicyIdentity CutIdentity
      ObservationSetIdentity ProofIdentity : Type}
    (provenance :
      DerivedConclusionProvenance
        ConclusionIdentity GenerationIdentity PolicyIdentity CutIdentity
        ObservationSetIdentity ProofIdentity) :
    provenance.historicalEvidenceImmutable :=
  provenance.immutabilityEstablished

theorem lateEventCreatesNewCausalCutIdentity
    {EventIdentity CutIdentity RevisionIdentity : Type}
    (revision :
      LateEventCutRevision EventIdentity CutIdentity RevisionIdentity) :
    revision.revisedCut.cutIdentity ≠
      revision.previousCut.cutIdentity :=
  revision.cutIdentityChanged

theorem lateEventPreservesPreviousCutImmutability
    {EventIdentity CutIdentity RevisionIdentity : Type}
    (revision :
      LateEventCutRevision EventIdentity CutIdentity RevisionIdentity) :
    revision.previousCut.immutableInput :=
  revision.previousCut.immutabilityEstablished

theorem monotoneRevisionPreservesPreviousFrontier
    {ConclusionIdentity : Type}
    (plan : MonotoneUpdatePlan ConclusionIdentity) :
    ∀ conclusion ∈ plan.previousReachable,
      conclusion ∈ plan.revisedReachable :=
  plan.previousFrontierPreserved

theorem nonMonotoneRevisionInvalidatesEveryAffectedConclusion
    {ConclusionIdentity RetractionIdentity : Type}
    (plan :
      NonMonotoneUpdatePlan
        ConclusionIdentity RetractionIdentity) :
    ∀ conclusion ∈ plan.affectedConclusions,
      conclusion ∈ plan.invalidatedConclusions :=
  plan.everyAffectedConclusionInvalidated

theorem retractionMarksConclusionInactive
    {ConclusionIdentity CutIdentity ReasonIdentity ReceiptIdentity : Type}
    (receipt :
      RetractionReceipt
        ConclusionIdentity CutIdentity ReasonIdentity ReceiptIdentity) :
    receipt.marksConclusionInactive :=
  receipt.inactiveEstablished

theorem retractionPreservesHistoricalEvidence
    {ConclusionIdentity CutIdentity ReasonIdentity ReceiptIdentity : Type}
    (receipt :
      RetractionReceipt
        ConclusionIdentity CutIdentity ReasonIdentity ReceiptIdentity) :
    ¬ receipt.deletesHistoricalEvidence :=
  receipt.preservesHistoricalEvidence

theorem activeSelectionChoosesCandidate
    {ConclusionIdentity SelectionIdentity : Type}
    (selection :
      ActiveConclusionSelection
        ConclusionIdentity SelectionIdentity) :
    selection.activeConclusion ∈ selection.candidates :=
  selection.activeIsCandidate

theorem activeSelectionIsUnique
    {ConclusionIdentity SelectionIdentity : Type}
    (selection :
      ActiveConclusionSelection
        ConclusionIdentity SelectionIdentity) :
    ∀ candidate ∈ selection.candidates,
      selection.isEligible candidate →
        candidate = selection.activeConclusion :=
  selection.uniqueActive

theorem reverseDependenciesScheduleEveryAffectedConclusion
    {EventIdentity ConclusionIdentity InvalidationIdentity : Type}
    (invalidation :
      ReverseDependencyInvalidation
        EventIdentity ConclusionIdentity InvalidationIdentity) :
    ∀ conclusion ∈ invalidation.affectedConclusions,
      conclusion ∈ invalidation.scheduledForReevaluation :=
  invalidation.everyAffectedConclusionScheduled

theorem compensationProposalCarriesNoActionAuthority
    {EffectReceiptIdentity CompensationIntentIdentity : Type}
    (proposal :
      EffectCompensationProposal
        EffectReceiptIdentity CompensationIntentIdentity) :
    ¬ proposal.carriesActionAuthority :=
  proposal.noActionAuthority

theorem cutChangeCreatesNewConclusionIdentity
    {CutIdentity PolicyIdentity ConclusionIdentity : Type}
    (scheme :
      ConclusionIdentityScheme
        CutIdentity PolicyIdentity ConclusionIdentity)
    (cutA cutB : CutIdentity)
    (policy : PolicyIdentity)
    (changed : cutA ≠ cutB) :
    scheme.identity cutA policy ≠ scheme.identity cutB policy :=
  scheme.cutChangeChangesConclusion cutA cutB policy changed

theorem policyChangeCreatesNewConclusionIdentity
    {CutIdentity PolicyIdentity ConclusionIdentity : Type}
    (scheme :
      ConclusionIdentityScheme
        CutIdentity PolicyIdentity ConclusionIdentity)
    (cut : CutIdentity)
    (policyA policyB : PolicyIdentity)
    (changed : policyA ≠ policyB) :
    scheme.identity cut policyA ≠ scheme.identity cut policyB :=
  scheme.policyChangeChangesConclusion cut policyA policyB changed

theorem historicalCutReplayRemainsStable
    {CutIdentity ConclusionIdentity : Type}
    (replay :
      HistoricalCutReplay CutIdentity ConclusionIdentity) :
    replay.replayConclusion = replay.originalConclusion :=
  replay.replayStable

end PooFlowProof.PooC3.IncrementalTruthMaintenance
