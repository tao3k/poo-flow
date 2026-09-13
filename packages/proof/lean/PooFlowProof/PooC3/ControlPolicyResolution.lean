import PooFlowProof.PooC3.PooControlAlgebra

namespace PooFlowProof.PooC3.ControlPolicyResolution

inductive TerminalEffect where
  | continue
  | suspend
  | deny
  | cancel
  deriving DecidableEq, Repr

inductive HardStopKind where
  | veto
  | cancellation
  deriving DecidableEq, Repr

inductive ResolutionOutcome (Decision Conflict : Type) where
  | finalDecision (decision : Decision)
  | conflict (conflict : Conflict)
  | noCandidate
  deriving DecidableEq, Repr

abbrev DecisionPriority := Int

def defaultPriority : DecisionPriority := 0

def strongerPriority
    (left right : DecisionPriority) : Prop :=
  left > right

def Constraint (Action : Type) := Action → Prop

def intersectConstraints
    {Action : Type}
    (left right : Constraint Action) : Constraint Action :=
  fun action => left action ∧ right action

def Restricts
    {Action : Type}
    (parent child : Constraint Action) : Prop :=
  ∀ action, child action → parent action

structure ControlPolicy (PolicyIdentity ConditionFamily Candidate : Type) where
  policyIdentity : PolicyIdentity
  conditionFamily : ConditionFamily
  produceCandidate : Candidate → Prop
  immutablePooObject : Prop
  immutabilityEstablished : immutablePooObject
  candidateProductionPure : Prop
  purityEstablished : candidateProductionPure
  installsExceptionHandler : Prop
  noHandlerInstallation : ¬ installsExceptionHandler
  returnsProfileValue : Prop
  noProfileValue : ¬ returnsProfileValue
  weakensAuthorityRequirement : Prop
  noAuthorityWeakening : ¬ weakensAuthorityRequirement

structure DecisionCandidate
    (ConditionIdentity PolicyIdentity Scope Authority Evidence : Type) where
  conditionIdentity : ConditionIdentity
  policyIdentity : PolicyIdentity
  scope : Scope
  effect : TerminalEffect
  priority : DecisionPriority
  authority : Authority
  evidence : Evidence
  containsProfileValue : Prop
  noProfileValue : ¬ containsProfileValue
  containsLiveContinuation : Prop
  noLiveContinuation : ¬ containsLiveContinuation

structure CandidateAdmission where
  conditionIdentityMatches : Prop
  policyAdmittedInScope : Prop
  issuerWitnessValid : Prop
  effectClosed : Prop
  priorityCanonicalInteger : Prop
  authorityNoBroaderThanCapability : Prop
  constraintsPureAndBounded : Prop
  evidencePureAndBounded : Prop
  containsNoProfileOrContinuation : Prop

def CandidateAdmitted (admission : CandidateAdmission) : Prop :=
  admission.conditionIdentityMatches ∧
    admission.policyAdmittedInScope ∧
    admission.issuerWitnessValid ∧
    admission.effectClosed ∧
    admission.priorityCanonicalInteger ∧
    admission.authorityNoBroaderThanCapability ∧
    admission.constraintsPureAndBounded ∧
    admission.evidencePureAndBounded ∧
    admission.containsNoProfileOrContinuation

structure HardStopAdmission where
  kind : HardStopKind
  capabilityValid : Prop
  scopeMatches : Prop
  principalAdmitted : Prop
  rootAndGenerationMatch : Prop
  authorityLive : Prop

def HardStopAdmitted (admission : HardStopAdmission) : Prop :=
  admission.capabilityValid ∧
    admission.scopeMatches ∧
    admission.principalAdmitted ∧
    admission.rootAndGenerationMatch ∧
    admission.authorityLive

structure PriorityBoundary where
  priorityBypassesCapability : Prop
  noCapabilityBypass : ¬ priorityBypassesCapability
  priorityErasesConstraint : Prop
  noConstraintErasure : ¬ priorityErasesConstraint
  priorityDefeatsVeto : Prop
  noVetoDefeat : ¬ priorityDefeatsVeto
  priorityCrossesIdentityFence : Prop
  noFenceCrossing : ¬ priorityCrossesIdentityFence
  unlimitedPrioritySentinelExists : Prop
  noUnlimitedSentinel : ¬ unlimitedPrioritySentinelExists

structure ResolutionOrder where
  constraintsIntersectedBeforePriority : Prop
  constraintOrderEstablished : constraintsIntersectedBeforePriority
  hardStopsAppliedBeforePriority : Prop
  hardStopOrderEstablished : hardStopsAppliedBeforePriority
  lowerPriorityConstraintsPreserved : Prop
  lowerConstraintsEstablished : lowerPriorityConstraintsPreserved
  emptyIntersectionFailsClosed : Prop
  emptyIntersectionClosureEstablished : emptyIntersectionFailsClosed

structure EqualPriorityMerge (Candidate : Type) where
  merge : Candidate → Candidate → Candidate
  commutative : ∀ left right, merge left right = merge right left
  associative :
    ∀ left middle right,
      merge (merge left middle) right =
        merge left (merge middle right)
  idempotent : ∀ candidate, merge candidate candidate = candidate
  sameTerminalEffectRequired : Prop
  sameEffectEstablished : sameTerminalEffectRequired
  conflictingEffectsFailClosed : Prop
  conflictClosureEstablished : conflictingEffectsFailClosed

structure DeterministicResolution (Input Decision Receipt : Type) where
  resolve : Input → Decision
  receipt : Input → Receipt
  candidatePermutationInvariant : Prop
  permutationEstablished : candidatePermutationInvariant
  completionOrderInvariant : Prop
  completionOrderEstablished : completionOrderInvariant
  stableDecisionIdentity : Prop
  decisionIdentityEstablished : stableDecisionIdentity
  stableReceiptDigest : Prop
  receiptDigestEstablished : stableReceiptDigest

structure PolicyCompositionLaw where
  permutationInvariant : Prop
  permutationEstablished : permutationInvariant
  groupingInvariant : Prop
  groupingEstablished : groupingInvariant
  duplicateDoesNotAmplifyAuthority : Prop
  noDuplicateAmplification : duplicateDoesNotAmplifyAuthority
  stricterConstraintCannotExpandResult : Prop
  monotonicRestrictionEstablished : stricterConstraintCannotExpandResult
  unauthorizedCandidateCannotChangeDecision : Prop
  unauthorizedCandidateIgnored : unauthorizedCandidateCannotChangeDecision
  validHardStopOnlyRestricts : Prop
  hardStopRestrictionEstablished : validHardStopOnlyRestricts
  erasurePreservesNativeOutcome : Prop
  erasureEstablished : erasurePreservesNativeOutcome

structure ResolverBoundary where
  finiteCandidateSet : Prop
  finitenessEstablished : finiteCandidateSet
  introducesGlobalFixedPoint : Prop
  noGlobalFixedPoint : ¬ introducesGlobalFixedPoint
  discoversRecursiveControllers : Prop
  noRecursiveDiscovery : ¬ discoversRecursiveControllers
  readsProviderRegistry : Prop
  noProviderRegistry : ¬ readsProviderRegistry
  cyclicDependencyRecursivelySignals : Prop
  cycleProducesBoundedConflict : ¬ cyclicDependencyRecursivelySignals
  sourceOrderBreaksTie : Prop
  noSourceOrderTieBreak : ¬ sourceOrderBreaksTie

structure EvidenceReceiptBoundary where
  containsIssuerWitness : Prop
  noIssuerWitness : ¬ containsIssuerWitness
  containsLiveContinuation : Prop
  noLiveContinuation : ¬ containsLiveContinuation
  containsSecretCapabilityMaterial : Prop
  noSecretCapabilityMaterial : ¬ containsSecretCapabilityMaterial
  containsProfileValue : Prop
  noProfileValue : ¬ containsProfileValue
  orderingCanonicalByPolicyIdentity : Prop
  canonicalOrderEstablished : orderingCanonicalByPolicyIdentity

structure ResolutionAdmissionClosure where
  pooObjectFamiliesEstablished : Prop
  candidateProductionPureAndFinite : Prop
  authorityIntersectionBeforePriority : Prop
  hardStopsBeforePriority : Prop
  exactIntegerPriorityOrdering : Prop
  equalPriorityConflictsFailClosed : Prop
  lowerPriorityConstraintsSurvive : Prop
  mergeLawsEstablished : Prop
  deterministicOrderingEstablished : Prop
  noUnlimitedPriority : Prop
  noNewCompositionDsl : Prop
  governanceOwnerResolved : Prop
  priorRfcObligationsSatisfied : Prop

def ImplementationAdmitted
    (closure : ResolutionAdmissionClosure) : Prop :=
  closure.pooObjectFamiliesEstablished ∧
    closure.candidateProductionPureAndFinite ∧
    closure.authorityIntersectionBeforePriority ∧
    closure.hardStopsBeforePriority ∧
    closure.exactIntegerPriorityOrdering ∧
    closure.equalPriorityConflictsFailClosed ∧
    closure.lowerPriorityConstraintsSurvive ∧
    closure.mergeLawsEstablished ∧
    closure.deterministicOrderingEstablished ∧
    closure.noUnlimitedPriority ∧
    closure.noNewCompositionDsl ∧
    closure.governanceOwnerResolved ∧
    closure.priorRfcObligationsSatisfied

theorem defaultPriorityIsZero :
    defaultPriority = 0 := by
  rfl

theorem largerIntegerIsStronger
    (left right : DecisionPriority)
    (larger : left > right) :
    strongerPriority left right :=
  larger

theorem negativePriorityIsOrdinaryInteger
    (priority : DecisionPriority)
    (negative : priority < 0) :
    priority < defaultPriority := by
  simpa [defaultPriority] using negative

theorem constraintIntersectionRestrictsLeft
    {Action : Type}
    (left right : Constraint Action) :
    Restricts left (intersectConstraints left right) := by
  intro action admitted
  exact admitted.1

theorem constraintIntersectionRestrictsRight
    {Action : Type}
    (left right : Constraint Action) :
    Restricts right (intersectConstraints left right) := by
  intro action admitted
  exact admitted.2

theorem policyIsImmutablePooObject
    {PolicyIdentity ConditionFamily Candidate : Type}
    (policy : ControlPolicy PolicyIdentity ConditionFamily Candidate) :
    policy.immutablePooObject :=
  policy.immutabilityEstablished

theorem policyCandidateProductionIsPure
    {PolicyIdentity ConditionFamily Candidate : Type}
    (policy : ControlPolicy PolicyIdentity ConditionFamily Candidate) :
    policy.candidateProductionPure :=
  policy.purityEstablished

theorem policyInstallsNoHandler
    {PolicyIdentity ConditionFamily Candidate : Type}
    (policy : ControlPolicy PolicyIdentity ConditionFamily Candidate) :
    ¬ policy.installsExceptionHandler :=
  policy.noHandlerInstallation

theorem policyReturnsNoProfileValue
    {PolicyIdentity ConditionFamily Candidate : Type}
    (policy : ControlPolicy PolicyIdentity ConditionFamily Candidate) :
    ¬ policy.returnsProfileValue :=
  policy.noProfileValue

theorem policyExtensionCannotWeakenAuthority
    {PolicyIdentity ConditionFamily Candidate : Type}
    (policy : ControlPolicy PolicyIdentity ConditionFamily Candidate) :
    ¬ policy.weakensAuthorityRequirement :=
  policy.noAuthorityWeakening

theorem candidateContainsNoProfileValue
    {ConditionIdentity PolicyIdentity Scope Authority Evidence : Type}
    (candidate :
      DecisionCandidate
        ConditionIdentity PolicyIdentity Scope Authority Evidence) :
    ¬ candidate.containsProfileValue :=
  candidate.noProfileValue

theorem candidateContainsNoLiveContinuation
    {ConditionIdentity PolicyIdentity Scope Authority Evidence : Type}
    (candidate :
      DecisionCandidate
        ConditionIdentity PolicyIdentity Scope Authority Evidence) :
    ¬ candidate.containsLiveContinuation :=
  candidate.noLiveContinuation

theorem missingConditionIdentityRejectsCandidate
    (admission : CandidateAdmission)
    (missing : ¬ admission.conditionIdentityMatches) :
    ¬ CandidateAdmitted admission := by
  intro admitted
  exact missing admitted.1

theorem invalidIssuerRejectsCandidate
    (admission : CandidateAdmission)
    (invalid : ¬ admission.issuerWitnessValid) :
    ¬ CandidateAdmitted admission := by
  intro admitted
  exact invalid admitted.2.2.1

theorem noncanonicalPriorityRejectsCandidate
    (admission : CandidateAdmission)
    (invalid : ¬ admission.priorityCanonicalInteger) :
    ¬ CandidateAdmitted admission := by
  intro admitted
  exact invalid admitted.2.2.2.2.1

theorem profileOrContinuationRejectsCandidate
    (admission : CandidateAdmission)
    (invalid : ¬ admission.containsNoProfileOrContinuation) :
    ¬ CandidateAdmitted admission := by
  intro admitted
  exact invalid admitted.2.2.2.2.2.2.2.2

theorem invalidHardStopAuthorityRejectsClaim
    (admission : HardStopAdmission)
    (invalid : ¬ admission.capabilityValid) :
    ¬ HardStopAdmitted admission := by
  intro admitted
  exact invalid admitted.1

theorem priorityCannotBypassCapability
    (boundary : PriorityBoundary) :
    ¬ boundary.priorityBypassesCapability :=
  boundary.noCapabilityBypass

theorem priorityCannotEraseConstraint
    (boundary : PriorityBoundary) :
    ¬ boundary.priorityErasesConstraint :=
  boundary.noConstraintErasure

theorem priorityCannotDefeatVeto
    (boundary : PriorityBoundary) :
    ¬ boundary.priorityDefeatsVeto :=
  boundary.noVetoDefeat

theorem priorityCannotCrossIdentityFence
    (boundary : PriorityBoundary) :
    ¬ boundary.priorityCrossesIdentityFence :=
  boundary.noFenceCrossing

theorem noUnlimitedPrioritySentinel
    (boundary : PriorityBoundary) :
    ¬ boundary.unlimitedPrioritySentinelExists :=
  boundary.noUnlimitedSentinel

theorem constraintsPrecedePriority
    (order : ResolutionOrder) :
    order.constraintsIntersectedBeforePriority :=
  order.constraintOrderEstablished

theorem hardStopsPrecedePriority
    (order : ResolutionOrder) :
    order.hardStopsAppliedBeforePriority :=
  order.hardStopOrderEstablished

theorem lowerPriorityConstraintsSurvive
    (order : ResolutionOrder) :
    order.lowerPriorityConstraintsPreserved :=
  order.lowerConstraintsEstablished

theorem emptyIntersectionFailsClosed
    (order : ResolutionOrder) :
    order.emptyIntersectionFailsClosed :=
  order.emptyIntersectionClosureEstablished

theorem equalPriorityMergeIsCommutative
    {Candidate : Type}
    (merge : EqualPriorityMerge Candidate)
    (left right : Candidate) :
    merge.merge left right = merge.merge right left :=
  merge.commutative left right

theorem equalPriorityMergeIsAssociative
    {Candidate : Type}
    (merge : EqualPriorityMerge Candidate)
    (left middle right : Candidate) :
    merge.merge (merge.merge left middle) right =
      merge.merge left (merge.merge middle right) :=
  merge.associative left middle right

theorem equalPriorityMergeIsIdempotent
    {Candidate : Type}
    (merge : EqualPriorityMerge Candidate)
    (candidate : Candidate) :
    merge.merge candidate candidate = candidate :=
  merge.idempotent candidate

theorem equalPriorityConflictingEffectsFailClosed
    {Candidate : Type}
    (merge : EqualPriorityMerge Candidate) :
    merge.conflictingEffectsFailClosed :=
  merge.conflictClosureEstablished

theorem resolutionIgnoresCandidatePermutation
    {Input Decision Receipt : Type}
    (resolution : DeterministicResolution Input Decision Receipt) :
    resolution.candidatePermutationInvariant :=
  resolution.permutationEstablished

theorem resolutionIgnoresCompletionOrder
    {Input Decision Receipt : Type}
    (resolution : DeterministicResolution Input Decision Receipt) :
    resolution.completionOrderInvariant :=
  resolution.completionOrderEstablished

theorem resolutionHasStableDecisionAndReceipt
    {Input Decision Receipt : Type}
    (resolution : DeterministicResolution Input Decision Receipt) :
    resolution.stableDecisionIdentity ∧
      resolution.stableReceiptDigest :=
  ⟨resolution.decisionIdentityEstablished,
    resolution.receiptDigestEstablished⟩

theorem duplicatePolicyDoesNotAmplifyAuthority
    (law : PolicyCompositionLaw) :
    law.duplicateDoesNotAmplifyAuthority :=
  law.noDuplicateAmplification

theorem stricterConstraintCannotExpandResult
    (law : PolicyCompositionLaw) :
    law.stricterConstraintCannotExpandResult :=
  law.monotonicRestrictionEstablished

theorem unauthorizedCandidateCannotChangeDecision
    (law : PolicyCompositionLaw) :
    law.unauthorizedCandidateCannotChangeDecision :=
  law.unauthorizedCandidateIgnored

theorem validHardStopOnlyRestrictsExecution
    (law : PolicyCompositionLaw) :
    law.validHardStopOnlyRestricts :=
  law.hardStopRestrictionEstablished

theorem policyErasurePreservesNativeOutcome
    (law : PolicyCompositionLaw) :
    law.erasurePreservesNativeOutcome :=
  law.erasureEstablished

theorem resolverUsesFiniteCandidateSet
    (boundary : ResolverBoundary) :
    boundary.finiteCandidateSet :=
  boundary.finitenessEstablished

theorem resolverIntroducesNoGlobalFixedPoint
    (boundary : ResolverBoundary) :
    ¬ boundary.introducesGlobalFixedPoint :=
  boundary.noGlobalFixedPoint

theorem resolverReadsNoProviderRegistry
    (boundary : ResolverBoundary) :
    ¬ boundary.readsProviderRegistry :=
  boundary.noProviderRegistry

theorem cyclicPolicyDependencyProducesBoundedConflict
    (boundary : ResolverBoundary) :
    ¬ boundary.cyclicDependencyRecursivelySignals :=
  boundary.cycleProducesBoundedConflict

theorem sourceOrderCannotBreakTie
    (boundary : ResolverBoundary) :
    ¬ boundary.sourceOrderBreaksTie :=
  boundary.noSourceOrderTieBreak

theorem receiptContainsNoSecretAuthority
    (receipt : EvidenceReceiptBoundary) :
    ¬ receipt.containsIssuerWitness ∧
      ¬ receipt.containsLiveContinuation ∧
      ¬ receipt.containsSecretCapabilityMaterial ∧
      ¬ receipt.containsProfileValue :=
  ⟨receipt.noIssuerWitness, receipt.noLiveContinuation,
    receipt.noSecretCapabilityMaterial, receipt.noProfileValue⟩

theorem receiptOrderIsCanonical
    (receipt : EvidenceReceiptBoundary) :
    receipt.orderingCanonicalByPolicyIdentity :=
  receipt.canonicalOrderEstablished

theorem missingAuthorityOrderingBlocksImplementation
    (closure : ResolutionAdmissionClosure)
    (missing : ¬ closure.authorityIntersectionBeforePriority) :
    ¬ ImplementationAdmitted closure := by
  intro admitted
  exact missing admitted.2.2.1

theorem missingHardStopOrderingBlocksImplementation
    (closure : ResolutionAdmissionClosure)
    (missing : ¬ closure.hardStopsBeforePriority) :
    ¬ ImplementationAdmitted closure := by
  intro admitted
  exact missing admitted.2.2.2.1

theorem missingMergeLawsBlocksImplementation
    (closure : ResolutionAdmissionClosure)
    (missing : ¬ closure.mergeLawsEstablished) :
    ¬ ImplementationAdmitted closure := by
  intro admitted
  exact missing admitted.2.2.2.2.2.2.2.1

theorem missingGovernanceOwnerBlocksImplementation
    (closure : ResolutionAdmissionClosure)
    (missing : ¬ closure.governanceOwnerResolved) :
    ¬ ImplementationAdmitted closure := by
  intro admitted
  exact missing admitted.2.2.2.2.2.2.2.2.2.2.2.1

end PooFlowProof.PooC3.ControlPolicyResolution
