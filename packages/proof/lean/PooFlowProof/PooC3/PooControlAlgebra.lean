import PooFlowProof.PooC3.GerbilGambitRuntimeCorrespondence

namespace PooFlowProof.PooC3.PooControlAlgebra

inductive TerminalEffect where
  | continue
  | suspend
  | deny
  | cancel
  deriving DecidableEq, Repr

inductive HandlerTransition where
  | normalReturn
  | noncontinuableBoundary
  deriving DecidableEq, Repr

def applyTerminalEffect : TerminalEffect → HandlerTransition
  | .continue => .normalReturn
  | .suspend => .noncontinuableBoundary
  | .deny => .noncontinuableBoundary
  | .cancel => .noncontinuableBoundary

structure ControlContextIdentity
    (Evaluator Process Thread Root Revision Generation Demand SafePoint
      DynamicContext IssuerWitness : Type) where
  evaluator : Evaluator
  process : Process
  thread : Thread
  root : Root
  revision : Revision
  generation : Generation
  demand : Demand
  safePoint : SafePoint
  dynamicContext : DynamicContext
  issuerWitness : IssuerWitness

structure ControlCondition (Context ConditionIdentity Evidence : Type) where
  context : Context
  conditionIdentity : ConditionIdentity
  evidence : Evidence
  immutablePooObject : Prop
  immutabilityEstablished : immutablePooObject
  containsRawContinuation : Prop
  noRawContinuation : ¬ containsRawContinuation
  containsProfileResult : Prop
  noProfileResult : ¬ containsProfileResult
  acquiresAuthorityFromShape : Prop
  noShapeAuthority : ¬ acquiresAuthorityFromShape

structure ConditionExtension
    (Context ConditionIdentity BaseEvidence ExtendedEvidence : Type) where
  base : ControlCondition Context ConditionIdentity BaseEvidence
  extended : ControlCondition Context ConditionIdentity ExtendedEvidence
  preservesContext : extended.context = base.context
  preservesIdentity :
    extended.conditionIdentity = base.conditionIdentity
  addsOnlyPureEvidence : Prop
  pureEvidenceEstablished : addsOnlyPureEvidence
  weakensCapabilityRequirement : Prop
  noCapabilityWeakening : ¬ weakensCapabilityRequirement
  acquiresAuthority : Prop
  noAuthorityAcquisition : ¬ acquiresAuthority
  erasesToBaseObservation : Prop
  erasureEstablished : erasesToBaseObservation

structure ControlDecision
    (ConditionIdentity CapabilityWitness Evidence : Type) where
  conditionIdentity : ConditionIdentity
  capabilityWitness : CapabilityWitness
  evidence : Evidence
  effect : TerminalEffect
  immutablePooObject : Prop
  immutabilityEstablished : immutablePooObject
  containsSecondTerminalEffect : Prop
  exactlyOneEffect : ¬ containsSecondTerminalEffect
  containsProfileValue : Prop
  noProfileValue : ¬ containsProfileValue
  containsRawContinuation : Prop
  noRawContinuation : ¬ containsRawContinuation

structure DecisionAdmission
    (ConditionIdentity CapabilityWitness Evidence : Type) where
  decision :
    ControlDecision ConditionIdentity CapabilityWitness Evidence
  expectedConditionIdentity : ConditionIdentity
  identityMatches :
    decision.conditionIdentity = expectedConditionIdentity
  capabilityValid : Prop
  capabilityEstablished : capabilityValid
  capabilityLiveAndUnconsumed : Prop
  liveAuthorityEstablished : capabilityLiveAndUnconsumed
  terminalEffectAllowed : Prop
  effectPermissionEstablished : terminalEffectAllowed

def EffectConstraint := TerminalEffect → Prop

def Attenuates
    (parent child : EffectConstraint) : Prop :=
  ∀ effect, child effect → parent effect

def intersectConstraints
    (left right : EffectConstraint) : EffectConstraint :=
  fun effect => left effect ∧ right effect

structure ControlCapability
    (Context IssuerWitness RuntimeCell : Type) where
  context : Context
  issuerWitness : IssuerWitness
  runtimeCell : RuntimeCell
  allowedEffects : EffectConstraint
  immutablePooObject : Prop
  immutabilityEstablished : immutablePooObject
  authorityDerivedFromObjectShape : Prop
  noShapeAuthority : ¬ authorityDerivedFromObjectShape
  usesMutableGlobalRegistry : Prop
  noGlobalRegistry : ¬ usesMutableGlobalRegistry
  reusableAuthority : Prop
  oneShotAuthority : ¬ reusableAuthority

structure CapabilityExtension
    (Context IssuerWitness RuntimeCell : Type) where
  parent : ControlCapability Context IssuerWitness RuntimeCell
  child : ControlCapability Context IssuerWitness RuntimeCell
  attenuates : Attenuates parent.allowedEffects child.allowedEffects
  createsNewIssuerWitness : Prop
  noNewIssuerWitness : ¬ createsNewIssuerWitness
  removesRevocation : Prop
  revocationPreserved : ¬ removesRevocation
  lengthensExpiry : Prop
  expiryNotLengthened : ¬ lengthensExpiry
  relaxesIdentityFence : Prop
  fenceNotRelaxed : ¬ relaxesIdentityFence

structure HandlerBoundary where
  acknowledgmentReachesProfileDomain : Prop
  acknowledgmentDiscarded : ¬ acknowledgmentReachesProfileDomain
  arbitraryHandlerValueAccepted : Prop
  noArbitraryHandlerValue : ¬ arbitraryHandlerValueAccepted
  resumeReturnedAsLocalDecision : Prop
  resumeIsCoordinatorAdmission : ¬ resumeReturnedAsLocalDecision

structure ControlReceiptBoundary where
  immutableEvidence : Prop
  evidenceEstablished : immutableEvidence
  carriesLiveAuthority : Prop
  noLiveAuthority : ¬ carriesLiveAuthority
  becomesProfileSlot : Prop
  notProfileSlot : ¬ becomesProfileSlot
  changesTerminalEffect : Prop
  noTerminalEffectChange : ¬ changesTerminalEffect

structure AlgebraAdmissionClosure where
  fixedGerbilPooCallFormsRecorded : Prop
  threeFamiliesArePooObjects : Prop
  conditionExtensionPreservesFence : Prop
  effectsClosedAndExclusive : Prop
  resumeIsCoordinatorAdmission : Prop
  attenuationOnly : Prop
  noGlobalRegistry : Prop
  noHandlerValueInjection : Prop
  nonContinueFailsClosed : Prop
  traceMatchesMermaid : Prop
  priorRfcObligationsSatisfied : Prop

def ImplementationAdmitted
    (closure : AlgebraAdmissionClosure) : Prop :=
  closure.fixedGerbilPooCallFormsRecorded ∧
    closure.threeFamiliesArePooObjects ∧
    closure.conditionExtensionPreservesFence ∧
    closure.effectsClosedAndExclusive ∧
    closure.resumeIsCoordinatorAdmission ∧
    closure.attenuationOnly ∧
    closure.noGlobalRegistry ∧
    closure.noHandlerValueInjection ∧
    closure.nonContinueFailsClosed ∧
    closure.traceMatchesMermaid ∧
    closure.priorRfcObligationsSatisfied

theorem continueReturnsNormally :
    applyTerminalEffect .continue = .normalReturn := by
  rfl

theorem suspendUsesNoncontinuableBoundary :
    applyTerminalEffect .suspend = .noncontinuableBoundary := by
  rfl

theorem denyUsesNoncontinuableBoundary :
    applyTerminalEffect .deny = .noncontinuableBoundary := by
  rfl

theorem cancelUsesNoncontinuableBoundary :
    applyTerminalEffect .cancel = .noncontinuableBoundary := by
  rfl

theorem conditionIsImmutablePooObject
    {Context ConditionIdentity Evidence : Type}
    (condition : ControlCondition Context ConditionIdentity Evidence) :
    condition.immutablePooObject :=
  condition.immutabilityEstablished

theorem conditionContainsNoRawContinuation
    {Context ConditionIdentity Evidence : Type}
    (condition : ControlCondition Context ConditionIdentity Evidence) :
    ¬ condition.containsRawContinuation :=
  condition.noRawContinuation

theorem conditionContainsNoProfileResult
    {Context ConditionIdentity Evidence : Type}
    (condition : ControlCondition Context ConditionIdentity Evidence) :
    ¬ condition.containsProfileResult :=
  condition.noProfileResult

theorem conditionShapeGrantsNoAuthority
    {Context ConditionIdentity Evidence : Type}
    (condition : ControlCondition Context ConditionIdentity Evidence) :
    ¬ condition.acquiresAuthorityFromShape :=
  condition.noShapeAuthority

theorem conditionExtensionPreservesContext
    {Context ConditionIdentity BaseEvidence ExtendedEvidence : Type}
    (extension :
      ConditionExtension
        Context ConditionIdentity BaseEvidence ExtendedEvidence) :
    extension.extended.context = extension.base.context :=
  extension.preservesContext

theorem conditionExtensionPreservesIdentity
    {Context ConditionIdentity BaseEvidence ExtendedEvidence : Type}
    (extension :
      ConditionExtension
        Context ConditionIdentity BaseEvidence ExtendedEvidence) :
    extension.extended.conditionIdentity =
      extension.base.conditionIdentity :=
  extension.preservesIdentity

theorem conditionExtensionCannotWeakenCapability
    {Context ConditionIdentity BaseEvidence ExtendedEvidence : Type}
    (extension :
      ConditionExtension
        Context ConditionIdentity BaseEvidence ExtendedEvidence) :
    ¬ extension.weakensCapabilityRequirement :=
  extension.noCapabilityWeakening

theorem conditionExtensionCannotAcquireAuthority
    {Context ConditionIdentity BaseEvidence ExtendedEvidence : Type}
    (extension :
      ConditionExtension
        Context ConditionIdentity BaseEvidence ExtendedEvidence) :
    ¬ extension.acquiresAuthority :=
  extension.noAuthorityAcquisition

theorem conditionExtensionErasesToBase
    {Context ConditionIdentity BaseEvidence ExtendedEvidence : Type}
    (extension :
      ConditionExtension
        Context ConditionIdentity BaseEvidence ExtendedEvidence) :
    extension.erasesToBaseObservation :=
  extension.erasureEstablished

theorem decisionHasExactlyOneTerminalEffect
    {ConditionIdentity CapabilityWitness Evidence : Type}
    (decision :
      ControlDecision ConditionIdentity CapabilityWitness Evidence) :
    ¬ decision.containsSecondTerminalEffect :=
  decision.exactlyOneEffect

theorem decisionContainsNoProfileValue
    {ConditionIdentity CapabilityWitness Evidence : Type}
    (decision :
      ControlDecision ConditionIdentity CapabilityWitness Evidence) :
    ¬ decision.containsProfileValue :=
  decision.noProfileValue

theorem decisionContainsNoRawContinuation
    {ConditionIdentity CapabilityWitness Evidence : Type}
    (decision :
      ControlDecision ConditionIdentity CapabilityWitness Evidence) :
    ¬ decision.containsRawContinuation :=
  decision.noRawContinuation

theorem admittedDecisionMatchesCondition
    {ConditionIdentity CapabilityWitness Evidence : Type}
    (admission :
      DecisionAdmission ConditionIdentity CapabilityWitness Evidence) :
    admission.decision.conditionIdentity =
      admission.expectedConditionIdentity :=
  admission.identityMatches

theorem admittedDecisionHasLiveAuthority
    {ConditionIdentity CapabilityWitness Evidence : Type}
    (admission :
      DecisionAdmission ConditionIdentity CapabilityWitness Evidence) :
    admission.capabilityValid ∧
      admission.capabilityLiveAndUnconsumed ∧
      admission.terminalEffectAllowed :=
  ⟨admission.capabilityEstablished, admission.liveAuthorityEstablished,
    admission.effectPermissionEstablished⟩

theorem intersectionAttenuatesLeft
    (left right : EffectConstraint) :
    Attenuates left (intersectConstraints left right) := by
  intro effect admitted
  exact admitted.1

theorem intersectionAttenuatesRight
    (left right : EffectConstraint) :
    Attenuates right (intersectConstraints left right) := by
  intro effect admitted
  exact admitted.2

theorem attenuationIsTransitive
    (parent middle child : EffectConstraint)
    (first : Attenuates parent middle)
    (second : Attenuates middle child) :
    Attenuates parent child := by
  intro effect admitted
  exact first effect (second effect admitted)

theorem capabilityShapeGrantsNoAuthority
    {Context IssuerWitness RuntimeCell : Type}
    (capability :
      ControlCapability Context IssuerWitness RuntimeCell) :
    ¬ capability.authorityDerivedFromObjectShape :=
  capability.noShapeAuthority

theorem capabilityUsesNoGlobalRegistry
    {Context IssuerWitness RuntimeCell : Type}
    (capability :
      ControlCapability Context IssuerWitness RuntimeCell) :
    ¬ capability.usesMutableGlobalRegistry :=
  capability.noGlobalRegistry

theorem capabilityIsOneShot
    {Context IssuerWitness RuntimeCell : Type}
    (capability :
      ControlCapability Context IssuerWitness RuntimeCell) :
    ¬ capability.reusableAuthority :=
  capability.oneShotAuthority

theorem capabilityExtensionCannotCreateIssuer
    {Context IssuerWitness RuntimeCell : Type}
    (extension :
      CapabilityExtension Context IssuerWitness RuntimeCell) :
    ¬ extension.createsNewIssuerWitness :=
  extension.noNewIssuerWitness

theorem capabilityExtensionPreservesRevocation
    {Context IssuerWitness RuntimeCell : Type}
    (extension :
      CapabilityExtension Context IssuerWitness RuntimeCell) :
    ¬ extension.removesRevocation :=
  extension.revocationPreserved

theorem capabilityExtensionCannotLengthenExpiry
    {Context IssuerWitness RuntimeCell : Type}
    (extension :
      CapabilityExtension Context IssuerWitness RuntimeCell) :
    ¬ extension.lengthensExpiry :=
  extension.expiryNotLengthened

theorem capabilityExtensionCannotRelaxFence
    {Context IssuerWitness RuntimeCell : Type}
    (extension :
      CapabilityExtension Context IssuerWitness RuntimeCell) :
    ¬ extension.relaxesIdentityFence :=
  extension.fenceNotRelaxed

theorem handlerAcknowledgmentDoesNotReachProfile
    (boundary : HandlerBoundary) :
    ¬ boundary.acknowledgmentReachesProfileDomain :=
  boundary.acknowledgmentDiscarded

theorem handlerAcceptsNoArbitraryValue
    (boundary : HandlerBoundary) :
    ¬ boundary.arbitraryHandlerValueAccepted :=
  boundary.noArbitraryHandlerValue

theorem resumeIsNotLocalHandlerDecision
    (boundary : HandlerBoundary) :
    ¬ boundary.resumeReturnedAsLocalDecision :=
  boundary.resumeIsCoordinatorAdmission

theorem receiptCarriesNoLiveAuthority
    (receipt : ControlReceiptBoundary) :
    ¬ receipt.carriesLiveAuthority :=
  receipt.noLiveAuthority

theorem receiptIsNotProfileSlot
    (receipt : ControlReceiptBoundary) :
    ¬ receipt.becomesProfileSlot :=
  receipt.notProfileSlot

theorem evidenceDoesNotChangeTerminalEffect
    (receipt : ControlReceiptBoundary) :
    ¬ receipt.changesTerminalEffect :=
  receipt.noTerminalEffectChange

theorem missingGerbilPooCallFormsBlocksImplementation
    (closure : AlgebraAdmissionClosure)
    (missing : ¬ closure.fixedGerbilPooCallFormsRecorded) :
    ¬ ImplementationAdmitted closure := by
  intro admitted
  exact missing admitted.1

theorem missingClosedEffectProofBlocksImplementation
    (closure : AlgebraAdmissionClosure)
    (missing : ¬ closure.effectsClosedAndExclusive) :
    ¬ ImplementationAdmitted closure := by
  intro admitted
  exact missing admitted.2.2.2.1

theorem missingAttenuationProofBlocksImplementation
    (closure : AlgebraAdmissionClosure)
    (missing : ¬ closure.attenuationOnly) :
    ¬ ImplementationAdmitted closure := by
  intro admitted
  exact missing admitted.2.2.2.2.2.1

theorem missingPriorRfcClosureBlocksImplementation
    (closure : AlgebraAdmissionClosure)
    (missing : ¬ closure.priorRfcObligationsSatisfied) :
    ¬ ImplementationAdmitted closure := by
  intro admitted
  exact missing admitted.2.2.2.2.2.2.2.2.2.2

end PooFlowProof.PooC3.PooControlAlgebra
