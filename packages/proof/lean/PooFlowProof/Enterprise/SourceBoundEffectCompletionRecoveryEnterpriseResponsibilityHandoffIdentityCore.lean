import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffCore
import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffIdentityModel

namespace PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffIdentityCore

open
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffCore

def SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffAcceptanceEvidenceGloballyNonreusing
    {HandoffKey : Type}
    (handoffAt : HandoffKey → Prop)
    (transferAt : HandoffKey → EnterpriseResponsibilityTransfer) :
    Prop :=
  ∀ {left right},
    handoffAt left →
      handoffAt right →
        (transferAt left).acceptanceEvidenceIdentity =
            (transferAt right).acceptanceEvidenceIdentity →
          left = right

def SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffObservationEvidenceGloballyNonreusing
    {HandoffKey : Type}
    (handoffAt : HandoffKey → Prop)
    (transferAt : HandoffKey → EnterpriseResponsibilityTransfer) :
    Prop :=
  ∀ {left right},
    handoffAt left →
      handoffAt right →
        (transferAt left).effectiveObservationIdentity =
            (transferAt right).effectiveObservationIdentity →
          left = right

structure SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffIdentityClassification
    {HandoffKey : Type}
    (handoffAt : HandoffKey → Prop)
    (transferAt : HandoffKey → EnterpriseResponsibilityTransfer) :
    Prop where
  acceptanceEvidenceGloballyNonreusing :
    SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffAcceptanceEvidenceGloballyNonreusing
      handoffAt
      transferAt
  observationEvidenceGloballyNonreusing :
    SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffObservationEvidenceGloballyNonreusing
      handoffAt
      transferAt

theorem distinctHandoffsHaveDistinctAcceptanceEvidence
    {HandoffKey : Type}
    {handoffAt : HandoffKey → Prop}
    {transferAt : HandoffKey → EnterpriseResponsibilityTransfer}
    (classification :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffIdentityClassification
        handoffAt
        transferAt)
    {left right : HandoffKey}
    (leftHandoff : handoffAt left)
    (rightHandoff : handoffAt right)
    (distinct : left ≠ right) :
    (transferAt left).acceptanceEvidenceIdentity ≠
      (transferAt right).acceptanceEvidenceIdentity := by
  intro replayed
  exact distinct
    (classification.acceptanceEvidenceGloballyNonreusing
      leftHandoff
      rightHandoff
      replayed)

theorem distinctHandoffsHaveDistinctObservationEvidence
    {HandoffKey : Type}
    {handoffAt : HandoffKey → Prop}
    {transferAt : HandoffKey → EnterpriseResponsibilityTransfer}
    (classification :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffIdentityClassification
        handoffAt
        transferAt)
    {left right : HandoffKey}
    (leftHandoff : handoffAt left)
    (rightHandoff : handoffAt right)
    (distinct : left ≠ right) :
    (transferAt left).effectiveObservationIdentity ≠
      (transferAt right).effectiveObservationIdentity := by
  intro replayed
  exact distinct
    (classification.observationEvidenceGloballyNonreusing
      leftHandoff
      rightHandoff
      replayed)

theorem acceptanceEvidenceIdentityDeterminesHandoffPosition
    {HandoffKey : Type}
    {handoffAt : HandoffKey → Prop}
    {transferAt : HandoffKey → EnterpriseResponsibilityTransfer}
    (classification :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffIdentityClassification
        handoffAt
        transferAt)
    {left right : HandoffKey}
    (leftHandoff : handoffAt left)
    (rightHandoff : handoffAt right)
    (sameAcceptance :
      (transferAt left).acceptanceEvidenceIdentity =
        (transferAt right).acceptanceEvidenceIdentity) :
    left = right :=
  classification.acceptanceEvidenceGloballyNonreusing
    leftHandoff
    rightHandoff
    sameAcceptance

theorem observationEvidenceIdentityDeterminesHandoffPosition
    {HandoffKey : Type}
    {handoffAt : HandoffKey → Prop}
    {transferAt : HandoffKey → EnterpriseResponsibilityTransfer}
    (classification :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffIdentityClassification
        handoffAt
        transferAt)
    {left right : HandoffKey}
    (leftHandoff : handoffAt left)
    (rightHandoff : handoffAt right)
    (sameObservation :
      (transferAt left).effectiveObservationIdentity =
        (transferAt right).effectiveObservationIdentity) :
    left = right :=
  classification.observationEvidenceGloballyNonreusing
    leftHandoff
    rightHandoff
    sameObservation

end PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffIdentityCore
