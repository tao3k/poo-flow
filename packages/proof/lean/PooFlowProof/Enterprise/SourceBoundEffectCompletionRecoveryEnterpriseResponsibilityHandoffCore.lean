import PooFlowProof.Enterprise.ResponsibilityTransfer
import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBindingCore
import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffModel

namespace PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffCore

open
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBindingCore

abbrev EnterpriseResponsibilityTransfer :=
  PooFlowProof.Enterprise.ResponsibilityTransfer.Transfer
    PrincipalId
    AuthorizationSubject
    String
    String
    String
    String
    String

structure SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffBound
    (transferContractBinds : String → String → String → Prop)
    (effectiveObservationBinds : String → Nat → Prop)
    (before after :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment)
    (transfer : EnterpriseResponsibilityTransfer) :
    Prop where
  principalsChanged :
    before.accountablePrincipal ≠ after.accountablePrincipal
  transferAdmitted :
    PooFlowProof.Enterprise.ResponsibilityTransfer.Admitted transfer
  transferAssetMatchesBefore :
    transfer.asset = before.subject
  transferAssetMatchesAfter :
    transfer.asset = after.subject
  transferResponsibilityMatchesBefore :
    transfer.responsibility = before.responsibilityScopeDigest
  transferResponsibilityMatchesAfter :
    transfer.responsibility = after.responsibilityScopeDigest
  previousPrincipalMatches :
    transfer.previousPrincipal = before.accountablePrincipal
  successorPrincipalMatches :
    transfer.successorPrincipal = after.accountablePrincipal
  transferContractIdentityPresent :
    transfer.transferContractIdentity ≠ ""
  transferContractBindsCommitments :
    transferContractBinds
      transfer.transferContractIdentity
      before.commitment
      after.commitment
  authorityEvidenceMatches :
    transfer.authorityEvidenceIdentity = after.authorityReceiptId
  acceptanceEvidenceMatches :
    transfer.acceptanceEvidenceIdentity =
      after.acceptanceEvidenceIdentity
  effectiveObservationIdentityPresent :
    transfer.effectiveObservationIdentity ≠ ""
  effectiveObservationBindsEpoch :
    effectiveObservationBinds
      transfer.effectiveObservationIdentity
      after.effectiveEpoch

def SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAdjacentContinuity
    (transferContractBinds : String → String → String → Prop)
    (effectiveObservationBinds : String → Nat → Prop)
    (before after :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment)
    (transfer : EnterpriseResponsibilityTransfer) :
    Prop :=
  (before.accountablePrincipal = after.accountablePrincipal ∧
      before.subject = after.subject ∧
        before.responsibilityScopeDigest =
          after.responsibilityScopeDigest) ∨
    SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffBound
      transferContractBinds
      effectiveObservationBinds
      before
      after
      transfer

theorem changedAdjacentContinuityRequiresHandoff
    {transferContractBinds : String → String → String → Prop}
    {effectiveObservationBinds : String → Nat → Prop}
    {before after :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    {transfer : EnterpriseResponsibilityTransfer}
    (changed :
      before.accountablePrincipal ≠ after.accountablePrincipal)
    (continuous :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAdjacentContinuity
        transferContractBinds
        effectiveObservationBinds
        before
        after
        transfer) :
    SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffBound
      transferContractBinds
      effectiveObservationBinds
      before
      after
      transfer := by
  rcases continuous with stable | handoff
  · exact False.elim (changed stable.left)
  · exact handoff

theorem adjacentContinuityPreservesSubjectAndScope
    {transferContractBinds : String → String → String → Prop}
    {effectiveObservationBinds : String → Nat → Prop}
    {before after :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    {transfer : EnterpriseResponsibilityTransfer}
    (continuous :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAdjacentContinuity
        transferContractBinds
        effectiveObservationBinds
        before
        after
        transfer) :
    before.subject = after.subject ∧
      before.responsibilityScopeDigest =
        after.responsibilityScopeDigest := by
  rcases continuous with stable | handoff
  · exact ⟨stable.right.left, stable.right.right⟩
  · exact
      ⟨handoff.transferAssetMatchesBefore.symm.trans
          handoff.transferAssetMatchesAfter,
        handoff.transferResponsibilityMatchesBefore.symm.trans
          handoff.transferResponsibilityMatchesAfter⟩

theorem handoffClosesResponsibilityGapAndExclusiveOverlap
    {transferContractBinds : String → String → String → Prop}
    {effectiveObservationBinds : String → Nat → Prop}
    {before after :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    {transfer : EnterpriseResponsibilityTransfer}
    (handoff :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffBound
        transferContractBinds
        effectiveObservationBinds
        before
        after
        transfer) :
    ¬transfer.responsibilityGap ∧
      ¬transfer.overlappingExclusiveAuthority :=
  PooFlowProof.Enterprise.ResponsibilityTransfer.hasNoGapOrExclusiveOverlap
    transfer
    handoff.transferAdmitted

theorem handoffRequiresContractAuthorityAcceptanceAndCurrentObservation
    {transferContractBinds : String → String → String → Prop}
    {effectiveObservationBinds : String → Nat → Prop}
    {before after :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    {transfer : EnterpriseResponsibilityTransfer}
    (handoff :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffBound
        transferContractBinds
        effectiveObservationBinds
        before
        after
        transfer) :
    transfer.exactTransferContract ∧
      transfer.transferAuthorityValid ∧
        transfer.successorAccepted ∧
          transfer.effectiveObservationCurrent :=
  PooFlowProof.Enterprise.ResponsibilityTransfer.requiresContractAuthorityAndAcceptance
    transfer
    handoff.transferAdmitted

theorem handoffBindsContractToExactCommitments
    {transferContractBinds : String → String → String → Prop}
    {effectiveObservationBinds : String → Nat → Prop}
    {before after :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    {transfer : EnterpriseResponsibilityTransfer}
    (handoff :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffBound
        transferContractBinds
        effectiveObservationBinds
        before
        after
        transfer) :
    transferContractBinds
      transfer.transferContractIdentity
      before.commitment
      after.commitment :=
  handoff.transferContractBindsCommitments

theorem handoffBindsEffectiveObservationToSuccessorEpoch
    {transferContractBinds : String → String → String → Prop}
    {effectiveObservationBinds : String → Nat → Prop}
    {before after :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    {transfer : EnterpriseResponsibilityTransfer}
    (handoff :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffBound
        transferContractBinds
        effectiveObservationBinds
        before
        after
        transfer) :
    effectiveObservationBinds
      transfer.effectiveObservationIdentity
      after.effectiveEpoch :=
  handoff.effectiveObservationBindsEpoch

theorem stableResponsibilityNeedsNoHandoffProof
    {transferContractBinds : String → String → String → Prop}
    {effectiveObservationBinds : String → Nat → Prop}
    {before after :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    {transfer : EnterpriseResponsibilityTransfer}
    (samePrincipal :
      before.accountablePrincipal = after.accountablePrincipal)
    (sameSubject : before.subject = after.subject)
    (sameScope :
      before.responsibilityScopeDigest =
        after.responsibilityScopeDigest) :
    SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAdjacentContinuity
      transferContractBinds
      effectiveObservationBinds
      before
      after
      transfer :=
  Or.inl ⟨samePrincipal, sameSubject, sameScope⟩

end PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityHandoffCore
