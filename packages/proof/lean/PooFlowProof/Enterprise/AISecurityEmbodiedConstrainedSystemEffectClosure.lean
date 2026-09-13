import PooFlowProof.Enterprise.AISecurityArchitectureCompositionClosure
import PooFlowProof.Enterprise.EffectDomainCoverage
import PooFlowProof.Enterprise.PromotionTransactionRecovery

namespace PooFlowProof.Enterprise.AISecurityEmbodiedConstrainedSystemEffectClosure

/--
EASE-001 closes over the whole effect consequence envelope.  Authorization is
necessary, but it cannot substitute domain coverage, replay safety, fenced
recovery, terminal recovery evidence, or compensation evidence.
-/
def constrainedSystemEffectClosed
    (facts : PooFlowProof.PooC3.AuthorizedEffectEvidenceFacts)
    (effectDomainCovered : Prop)
    (duplicateSafe : Prop)
    (recoveryFenced : Prop)
    (recoveryTerminal : Prop)
    (compensationValidated : Prop) : Prop :=
  PooFlowProof.PooC3.authorizedEffectL1 facts ∧
    effectDomainCovered ∧
    duplicateSafe ∧
    recoveryFenced ∧
    recoveryTerminal ∧
    compensationValidated

theorem authorizedEffectAloneDoesNotClose
    (facts : PooFlowProof.PooC3.AuthorizedEffectEvidenceFacts)
    (_authorized : PooFlowProof.PooC3.authorizedEffectL1 facts) :
    ¬constrainedSystemEffectClosed facts False True True True True := by
  simp [constrainedSystemEffectClosed]

theorem ease001FormalBound
    (facts : PooFlowProof.PooC3.AuthorizedEffectEvidenceFacts)
    (effectDomainCovered duplicateSafe recoveryFenced recoveryTerminal
      compensationValidated : Prop)
    (closed : constrainedSystemEffectClosed facts effectDomainCovered
      duplicateSafe recoveryFenced recoveryTerminal compensationValidated) :
    PooFlowProof.PooC3.authorizedEffectL1 facts ∧
      effectDomainCovered ∧
      duplicateSafe ∧
      recoveryFenced ∧
      recoveryTerminal ∧
      compensationValidated :=
  closed

/-- Reuse the exactly-once owner: duplicate closure has a prior commit. -/
theorem duplicateClosureRequiresPriorCommit
    (ledger : List
      PooFlowProof.Enterprise.PromotionTransactionAtomicity.PromotionCommitReceipt)
    (commitValid :
      PooFlowProof.Enterprise.PromotionTransactionAtomicity.CommitReceiptValid)
    (request :
      PooFlowProof.Enterprise.PromotionTransactionAtomicity.PromotionCommitRequest)
    (receipt :
      PooFlowProof.Enterprise.PromotionTransactionRecovery.AtomicEffectReceipt)
    (closed :
      PooFlowProof.Enterprise.PromotionTransactionRecovery.effectOutcomeClosed
        commitValid ledger request receipt)
    (duplicate : receipt.base.outcome =
      PooFlowProof.Enterprise.PromotionTransactionAtomicity.CommitOutcome.duplicate) :
    PooFlowProof.Enterprise.PromotionTransactionRecovery.priorCommitExists
      commitValid ledger request :=
  PooFlowProof.Enterprise.PromotionTransactionRecovery.closedDuplicateRequiresPriorCommit
    ledger commitValid request receipt closed duplicate

/-- Reuse the rollback owner: closed rollback restores observed effects. -/
theorem rollbackClosureRestoresObservedEffect
    (ledger : List
      PooFlowProof.Enterprise.PromotionTransactionAtomicity.PromotionCommitReceipt)
    (commitValid :
      PooFlowProof.Enterprise.PromotionTransactionAtomicity.CommitReceiptValid)
    (request :
      PooFlowProof.Enterprise.PromotionTransactionAtomicity.PromotionCommitRequest)
    (receipt :
      PooFlowProof.Enterprise.PromotionTransactionRecovery.AtomicEffectReceipt)
    (closed :
      PooFlowProof.Enterprise.PromotionTransactionRecovery.effectOutcomeClosed
        commitValid ledger request receipt)
    (rolledBack : receipt.base.outcome =
      PooFlowProof.Enterprise.PromotionTransactionAtomicity.CommitOutcome.rolledBack) :
    receipt.postEffect = receipt.preEffect :=
  PooFlowProof.Enterprise.PromotionTransactionRecovery.closedRollbackRestoresCompleteEffectObservation
    ledger commitValid request receipt closed rolledBack

/-- Reuse the effect-domain owner: closure covers every declared plan effect. -/
theorem rollbackClosureCoversEffectUniverse
    (request :
      PooFlowProof.Enterprise.PromotionTransactionAtomicity.PromotionCommitRequest)
    (witnessValid :
      PooFlowProof.Enterprise.EffectDomainCoverage.EffectCoverageWitnessValid)
    (worldValid : PooFlowProof.Enterprise.EffectDomainCoverage.EffectWorldValid)
    (compensationValid :
      PooFlowProof.Enterprise.EffectDomainCoverage.CompensationReceiptValid)
    (witness : PooFlowProof.Enterprise.EffectDomainCoverage.EffectCoverageWitness)
    (obligations : List
      PooFlowProof.Enterprise.EffectDomainCoverage.EffectObligation)
    (compensationReceipts : List
      PooFlowProof.Enterprise.EffectDomainCoverage.CompensationReceipt)
    (before after : PooFlowProof.Enterprise.EffectDomainCoverage.EffectWorld)
    (closed : PooFlowProof.Enterprise.EffectDomainCoverage.EffectRollbackEvidenceClosed
      request witnessValid worldValid compensationValid witness obligations
        compensationReceipts before after) :
    PooFlowProof.Enterprise.EffectDomainCoverage.worldsAgreeOn
      witness.effectUniverse before after :=
  PooFlowProof.Enterprise.EffectDomainCoverage.coveredRollbackAgreesOnEveryPlanEffect
    request witnessValid worldValid compensationValid witness obligations
      compensationReceipts before after closed

end PooFlowProof.Enterprise.AISecurityEmbodiedConstrainedSystemEffectClosure
