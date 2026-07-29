namespace PooFlowProof.PooC3.Enterprise.ResponsibilityTransfer

structure Transfer
    (Principal Asset Responsibility TransferContractIdentity
      AuthorityEvidenceIdentity AcceptanceEvidenceIdentity
      EffectiveObservationIdentity : Type) where
  asset : Asset
  responsibility : Responsibility
  previousPrincipal : Principal
  successorPrincipal : Principal
  principalsDistinct : previousPrincipal ≠ successorPrincipal
  transferContractIdentity : TransferContractIdentity
  authorityEvidenceIdentity : AuthorityEvidenceIdentity
  acceptanceEvidenceIdentity : AcceptanceEvidenceIdentity
  effectiveObservationIdentity : EffectiveObservationIdentity
  exactTransferContract : Prop
  transferAuthorityValid : Prop
  successorAccepted : Prop
  effectiveObservationCurrent : Prop
  responsibilityGap : Prop
  noResponsibilityGap : ¬ responsibilityGap
  overlappingExclusiveAuthority : Prop
  noOverlappingExclusiveAuthority :
    ¬ overlappingExclusiveAuthority

def Admitted
    {Principal Asset Responsibility TransferContractIdentity
      AuthorityEvidenceIdentity AcceptanceEvidenceIdentity
      EffectiveObservationIdentity : Type}
    (transfer :
      Transfer
        Principal Asset Responsibility TransferContractIdentity
        AuthorityEvidenceIdentity AcceptanceEvidenceIdentity
        EffectiveObservationIdentity) : Prop :=
  transfer.exactTransferContract ∧
    transfer.transferAuthorityValid ∧
    transfer.successorAccepted ∧
    transfer.effectiveObservationCurrent ∧
    ¬ transfer.responsibilityGap ∧
    ¬ transfer.overlappingExclusiveAuthority

theorem requiresContractAuthorityAndAcceptance
    {Principal Asset Responsibility TransferContractIdentity
      AuthorityEvidenceIdentity AcceptanceEvidenceIdentity
      EffectiveObservationIdentity : Type}
    (transfer :
      Transfer
        Principal Asset Responsibility TransferContractIdentity
        AuthorityEvidenceIdentity AcceptanceEvidenceIdentity
        EffectiveObservationIdentity)
    (admitted : Admitted transfer) :
    transfer.exactTransferContract ∧
      transfer.transferAuthorityValid ∧
      transfer.successorAccepted ∧
      transfer.effectiveObservationCurrent :=
  ⟨admitted.1, admitted.2.1, admitted.2.2.1, admitted.2.2.2.1⟩

theorem hasNoGapOrExclusiveOverlap
    {Principal Asset Responsibility TransferContractIdentity
      AuthorityEvidenceIdentity AcceptanceEvidenceIdentity
      EffectiveObservationIdentity : Type}
    (transfer :
      Transfer
        Principal Asset Responsibility TransferContractIdentity
        AuthorityEvidenceIdentity AcceptanceEvidenceIdentity
        EffectiveObservationIdentity)
    (admitted : Admitted transfer) :
    ¬ transfer.responsibilityGap ∧
      ¬ transfer.overlappingExclusiveAuthority :=
  ⟨admitted.2.2.2.2.1, admitted.2.2.2.2.2⟩

end PooFlowProof.PooC3.Enterprise.ResponsibilityTransfer
