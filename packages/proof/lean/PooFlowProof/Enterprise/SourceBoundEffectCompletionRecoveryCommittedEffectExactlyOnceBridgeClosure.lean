import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCommittedEffectExactlyOnceBridgeCore
import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEffectDomainRollbackTraceEvidence

namespace PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCommittedEffectExactlyOnceBridgeClosure

open PooFlowProof.Enterprise.CommittedEffectApplicationExactlyOnce
open PooFlowProof.Enterprise.PromotionTransactionAtomicity
open PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryAuthorizedTransactionRecoveryBridgeCore
open PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCommittedEffectExactlyOnceBridgeCore
open PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEffectDomainRollbackTraceEvidence

structure SourceBoundEffectCompletionRecoveryCommittedEffectExactlyOnceBridgeEvidence
    (effectDomainTrace :
      SourceBoundEffectCompletionRecoveryEffectDomainRollbackTraceEvidence)
    (sourceEvidenceRegistry :
      String → SourceBoundCommittedEffectExactlyOnceEvidence)
    (observationTraceBindingValid :
      CommittedEffectObservationTraceBindingValid)
    (committedEffectProvenanceBindingValid :
      CommittedEffectProvenanceBindingValid) : Prop where
  committedBindings :
    ∀ (index : Nat),
      sourceBoundEffectCompletionTransactionRecoveryRequired
          (effectDomainTrace.trace index) →
        let commitment := effectDomainTrace.CommitmentAt index
        effectDomainTrace.OutcomeAt index = CommitOutcome.committed →
          SourceBoundEffectCompletionRecoveryCommittedEffectExactlyOnceBridge
            (effectDomainTrace.AuthorizedRecoveryAt index)
            (effectDomainTrace.requestRegistry commitment)
            (effectDomainTrace.RecoveryFenceAt index)
            (effectDomainTrace.RecoveryReceiptAt index)
            effectDomainTrace.effectCoverageWitnessValid
            effectDomainTrace.effectWorldValid
            effectDomainTrace.compensationReceiptValid
            effectDomainTrace.planEffectUniverseBindingValid
            effectDomainTrace.observationWorldBindingValid
            effectDomainTrace.compensationFenceBindingValid
            effectDomainTrace.effectCompensationProvenanceBindingValid
            commitment
            (effectDomainTrace.effectCoverageWitnessRegistry commitment)
            (effectDomainTrace.effectObligationRegistry commitment)
            (effectDomainTrace.compensationReceiptRegistry commitment)
            (effectDomainTrace.effectWorldBeforeRegistry commitment)
            (effectDomainTrace.effectWorldAfterRegistry commitment)
            (sourceEvidenceRegistry commitment)
            observationTraceBindingValid
            committedEffectProvenanceBindingValid

end PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCommittedEffectExactlyOnceBridgeClosure
