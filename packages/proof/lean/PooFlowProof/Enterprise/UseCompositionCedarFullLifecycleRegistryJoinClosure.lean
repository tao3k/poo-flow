import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationLifecycleClosure
import PooFlowProof.Enterprise.UseCompositionCedarCapabilityGrantClosure
import PooFlowProof.Enterprise.UseCompositionCedarLifecycleRegistryJoinModel

namespace PooFlowProof.Enterprise.UseCompositionCedarFullLifecycleRegistryJoinClosure

open PooFlowProof.Enterprise.ReceiptAuthorityBindingClosure
open PooFlowProof.Enterprise.SourceBoundEffectCompletionCrashRecoveryClosure
open PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationLifecycleClosure
open PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationLifecycleCore
open PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryConvergenceClosure
open PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryOwnerAuditCommitmentClosure
open PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryOwnerAuditCommitmentCore
open PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryOwnerAuditCore
open PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryProgressEvidenceClosure
open PooFlowProof.Enterprise.UseCompositionCedarCapabilityGrantClosure

abbrev CompositionDecisionSemantics :=
  PooFlowProof.Enterprise.CedarDualEngineAuthorization.DecisionSemantics

abbrev CompositionDecisionReceiptValid :=
  PooFlowProof.Enterprise.CedarDualEngineAuthorization.DecisionReceiptValid

abbrev CompositionDecisionReceipt :=
  PooFlowProof.Enterprise.CedarDualEngineAuthorization.DecisionReceipt

/-!
Packages the large source-bound lifecycle witness behind one dependent
selection.  Composition consumes the package; it does not duplicate its
commitment, signature, registry, recovery, or Cedar semantics.
-/

structure FullCedarLifecycleSelection where
  trace : SourceBoundEffectCompletionRecoveryTrace
  budgets : Nat → SourceBoundEffectCompletionRecoveryProgressBudget
  scopes : Nat → SourceBoundEffectCompletionRecoveryProgressScope
  providerAcknowledgementStable : Nat → Prop
  expectations : Nat → SourceBoundEffectCompletionRecoveryExpectation
  witnesses : Nat → SourceBoundEffectCompletionRecoveryOwnerAuditWitness
  scheme : SourceBoundEffectCompletionRecoveryOwnerAuditCommitmentScheme
  signatureVerified : String → String → String → Prop
  registry :
    String → SourceBoundEffectCompletionRecoveryCedarAuthorizationEvidence
  authorityPathAuthorized : String → String → String → String → Prop
  separationOfDutySatisfied : String → String → String → Prop
  envelopes :
    Nat → SourceBoundEffectCompletionRecoveryOwnerAuditCommitmentEnvelope
  authenticityEvidence :
    Nat → SourceBoundEffectCompletionRecoveryOwnerAuditAuthenticityEvidence
  lifecycleEvidence :
    SourceBoundEffectCompletionRecoveryCedarAuthorizationLifecycleEvidence
      trace budgets scopes providerAcknowledgementStable expectations
      witnesses scheme signatureVerified registry
      authorityPathAuthorized separationOfDutySatisfied
      envelopes authenticityEvidence
  index : Nat
  notCommitted : trace index ≠ .committed

theorem fullCedarLifecycleSelectionAuthorizationAdmitted
    (selection : FullCedarLifecycleSelection) :
    (selection.registry
      (selection.envelopes selection.index).commitment).Admitted
        selection.authorityPathAuthorized
        selection.separationOfDutySatisfied
        (selection.authenticityEvidence selection.index).authorityIdentity
        (selection.envelopes selection.index).commitment :=
  closedCedarLifecycleAuthorizationAdmitted
    selection.lifecycleEvidence selection.notCommitted

structure CompositionFullLifecycleGrantReceipt where
  receiptIdentity : String
  deriving DecidableEq

structure CompositionFullLifecycleGrantBinding where
  grant : CompositionCapabilityGrant
  lifecycleEvidence :
    SourceBoundEffectCompletionRecoveryCedarAuthorizationEvidence
  inputIdentitySemanticIdentity : String
  inputIdentityGeneration : Nat

abbrev CompositionFullLifecycleGrantAcceptanceAuthority :=
  AcceptanceAuthority
    CompositionFullLifecycleGrantReceipt
    CompositionFullLifecycleGrantBinding

abbrev CompositionFullLifecycleGrantAuthorityBoundNode
    (authority : CompositionFullLifecycleGrantAcceptanceAuthority) :=
  AuthorityBoundNode
    CompositionFullLifecycleGrantReceipt
    CompositionFullLifecycleGrantBinding
    authority

theorem fullLifecycleGrantAuthorityBoundNodeAccepted
    {authority : CompositionFullLifecycleGrantAcceptanceAuthority}
    (node : CompositionFullLifecycleGrantAuthorityBoundNode authority) :
    authority.accepted node.nodeBinding := by
  have accepted := authority.sound
    node.artifact node.validatedBinding node.validation
  rw [node.exactBinding] at accepted
  exact accepted

structure CompositionCedarFullLifecycleRegistryJoinClosed
    (semantics : CompositionDecisionSemantics)
    (decisionValid : CompositionDecisionReceiptValid)
    (bridgeAuthority : SubjectContextBridgeAcceptanceAuthority)
    (bridgeNode : SubjectContextBridgeAuthorityBoundNode bridgeAuthority)
    (request : CompositionCapabilityRequest)
    (grant : CompositionCapabilityGrant)
    (left right : CompositionDecisionReceipt)
    (fullLifecycleAuthority :
      CompositionFullLifecycleGrantAcceptanceAuthority)
    (fullLifecycleNode :
      CompositionFullLifecycleGrantAuthorityBoundNode fullLifecycleAuthority)
    (selection : FullCedarLifecycleSelection) : Prop where
  grantClosed :
    CompositionCedarGrantClosed
      semantics decisionValid bridgeAuthority bridgeNode
      request grant left right
  lifecycleBindingAccepted :
    fullLifecycleAuthority.accepted fullLifecycleNode.nodeBinding
  lifecycleGrantBound : fullLifecycleNode.nodeBinding.grant = grant
  selectedLifecycleEvidenceBound :
    fullLifecycleNode.nodeBinding.lifecycleEvidence =
      selection.registry (selection.envelopes selection.index).commitment
  subjectEpochBound :
    request.authorizationSubject.epoch = request.runtimeGeneration
  requestRuntimeEpochBound :
    (selection.envelopes selection.index).payload.runtimeEpoch =
      request.runtimeGeneration

theorem closedFullLifecycleJoinUsesAuthorityValidatedBinding
    {semantics : CompositionDecisionSemantics}
    {decisionValid : CompositionDecisionReceiptValid}
    {bridgeAuthority : SubjectContextBridgeAcceptanceAuthority}
    {bridgeNode : SubjectContextBridgeAuthorityBoundNode bridgeAuthority}
    {request : CompositionCapabilityRequest}
    {grant : CompositionCapabilityGrant}
    {left right : CompositionDecisionReceipt}
    {fullLifecycleAuthority :
      CompositionFullLifecycleGrantAcceptanceAuthority}
    {fullLifecycleNode :
      CompositionFullLifecycleGrantAuthorityBoundNode fullLifecycleAuthority}
    {selection : FullCedarLifecycleSelection}
    (closed :
      CompositionCedarFullLifecycleRegistryJoinClosed
        semantics decisionValid bridgeAuthority bridgeNode request grant
        left right fullLifecycleAuthority fullLifecycleNode selection) :
    fullLifecycleAuthority.accepted fullLifecycleNode.nodeBinding ∧
      fullLifecycleNode.nodeBinding.grant = grant :=
  ⟨closed.lifecycleBindingAccepted, closed.lifecycleGrantBound⟩

theorem closedFullLifecycleJoinProvidesRegistryAdmission
    {semantics : CompositionDecisionSemantics}
    {decisionValid : CompositionDecisionReceiptValid}
    {bridgeAuthority : SubjectContextBridgeAcceptanceAuthority}
    {bridgeNode : SubjectContextBridgeAuthorityBoundNode bridgeAuthority}
    {request : CompositionCapabilityRequest}
    {grant : CompositionCapabilityGrant}
    {left right : CompositionDecisionReceipt}
    {fullLifecycleAuthority :
      CompositionFullLifecycleGrantAcceptanceAuthority}
    {fullLifecycleNode :
      CompositionFullLifecycleGrantAuthorityBoundNode fullLifecycleAuthority}
    {selection : FullCedarLifecycleSelection}
    (_closed :
      CompositionCedarFullLifecycleRegistryJoinClosed
        semantics decisionValid bridgeAuthority bridgeNode request grant
        left right fullLifecycleAuthority fullLifecycleNode selection) :
    (selection.registry
      (selection.envelopes selection.index).commitment).Admitted
        selection.authorityPathAuthorized
        selection.separationOfDutySatisfied
        (selection.authenticityEvidence selection.index).authorityIdentity
        (selection.envelopes selection.index).commitment :=
  fullCedarLifecycleSelectionAuthorizationAdmitted selection

theorem closedFullLifecycleJoinRejectsUnselectedEvidence
    {semantics : CompositionDecisionSemantics}
    {decisionValid : CompositionDecisionReceiptValid}
    {bridgeAuthority : SubjectContextBridgeAcceptanceAuthority}
    {bridgeNode : SubjectContextBridgeAuthorityBoundNode bridgeAuthority}
    {request : CompositionCapabilityRequest}
    {grant : CompositionCapabilityGrant}
    {left right : CompositionDecisionReceipt}
    {fullLifecycleAuthority :
      CompositionFullLifecycleGrantAcceptanceAuthority}
    {fullLifecycleNode :
      CompositionFullLifecycleGrantAuthorityBoundNode fullLifecycleAuthority}
    {selection : FullCedarLifecycleSelection}
    (closed :
      CompositionCedarFullLifecycleRegistryJoinClosed
        semantics decisionValid bridgeAuthority bridgeNode request grant
        left right fullLifecycleAuthority fullLifecycleNode selection)
    (mismatch :
      fullLifecycleNode.nodeBinding.lifecycleEvidence ≠
        selection.registry
          (selection.envelopes selection.index).commitment) : False :=
  mismatch closed.selectedLifecycleEvidenceBound

theorem closedFullLifecycleJoinBindsRuntimeAndFence
    {semantics : CompositionDecisionSemantics}
    {decisionValid : CompositionDecisionReceiptValid}
    {bridgeAuthority : SubjectContextBridgeAcceptanceAuthority}
    {bridgeNode : SubjectContextBridgeAuthorityBoundNode bridgeAuthority}
    {request : CompositionCapabilityRequest}
    {grant : CompositionCapabilityGrant}
    {left right : CompositionDecisionReceipt}
    {fullLifecycleAuthority :
      CompositionFullLifecycleGrantAcceptanceAuthority}
    {fullLifecycleNode :
      CompositionFullLifecycleGrantAuthorityBoundNode fullLifecycleAuthority}
    {selection : FullCedarLifecycleSelection}
    (closed :
      CompositionCedarFullLifecycleRegistryJoinClosed
        semantics decisionValid bridgeAuthority bridgeNode request grant
        left right fullLifecycleAuthority fullLifecycleNode selection) :
    fullLifecycleNode.nodeBinding.lifecycleEvidence.runtimeEpoch =
        request.runtimeGeneration ∧
      fullLifecycleNode.nodeBinding.lifecycleEvidence.activeFenceToken =
        (selection.envelopes selection.index).payload.activeFenceToken := by
  have bindings :=
    selection.lifecycleEvidence.cedarBindings
      selection.index selection.notCommitted
  constructor
  · calc
      fullLifecycleNode.nodeBinding.lifecycleEvidence.runtimeEpoch =
          (selection.registry
            (selection.envelopes selection.index).commitment).runtimeEpoch := by
        rw [closed.selectedLifecycleEvidenceBound]
      _ = (selection.envelopes selection.index).payload.runtimeEpoch :=
        bindings.2.2.2.2.2.1
      _ = request.runtimeGeneration := closed.requestRuntimeEpochBound
  · calc
      fullLifecycleNode.nodeBinding.lifecycleEvidence.activeFenceToken =
          (selection.registry
            (selection.envelopes selection.index).commitment).activeFenceToken := by
        rw [closed.selectedLifecycleEvidenceBound]
      _ = (selection.envelopes selection.index).payload.activeFenceToken :=
        bindings.2.2.2.2.2.2

end PooFlowProof.Enterprise.UseCompositionCedarFullLifecycleRegistryJoinClosure
