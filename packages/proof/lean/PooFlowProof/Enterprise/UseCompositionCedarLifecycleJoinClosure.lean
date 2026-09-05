import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationLifecycleModel
import PooFlowProof.Enterprise.UseCompositionCedarCapabilityGrantClosure
import PooFlowProof.Enterprise.UseCompositionCedarLifecycleJoinModel

namespace PooFlowProof.Enterprise.UseCompositionCedarLifecycleJoinClosure

open PooFlowProof.Enterprise.ReceiptAuthorityBindingClosure
open PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationLifecycleModel
open PooFlowProof.Enterprise.UseCompositionCedarCapabilityGrantClosure

abbrev CompositionDecisionSemantics :=
  PooFlowProof.Enterprise.CedarDualEngineAuthorization.DecisionSemantics

abbrev CompositionDecisionReceiptValid :=
  PooFlowProof.Enterprise.CedarDualEngineAuthorization.DecisionReceiptValid

abbrev CompositionDecisionReceipt :=
  PooFlowProof.Enterprise.CedarDualEngineAuthorization.DecisionReceipt

/-!
The capability-grant closure proves subject, profile, generation, policy-context,
and bridge-authority binding.  This owner joins that admitted grant to the
independent Cedar authorization lifecycle without copying the lifecycle model.
-/

structure CompositionCedarLifecycleGrantReceipt where
  receiptIdentity : String
  deriving DecidableEq

structure CompositionCedarLifecycleGrantBinding where
  grant : CompositionCapabilityGrant
  decisionIdentity : Nat
  commitment : Nat
  accountabilityIdentity : Nat
  responsibilityScopeDigest : Nat
  activeFenceToken : Nat
  policyEvidenceRoot : Nat
  credentialIdentity : Nat
  credentialGeneration : Nat
  deriving DecidableEq

abbrev CompositionCedarLifecycleGrantAcceptanceAuthority :=
  AcceptanceAuthority
    CompositionCedarLifecycleGrantReceipt
    CompositionCedarLifecycleGrantBinding

abbrev CompositionCedarLifecycleGrantAuthorityBoundNode
    (authority : CompositionCedarLifecycleGrantAcceptanceAuthority) :=
  AuthorityBoundNode
    CompositionCedarLifecycleGrantReceipt
    CompositionCedarLifecycleGrantBinding
    authority

theorem lifecycleGrantAuthorityBoundNodeAccepted
    {authority : CompositionCedarLifecycleGrantAcceptanceAuthority}
    (node : CompositionCedarLifecycleGrantAuthorityBoundNode authority) :
    authority.accepted node.nodeBinding := by
  have accepted := authority.sound
    node.artifact node.validatedBinding node.validation
  rw [node.exactBinding] at accepted
  exact accepted

structure CompositionCedarLifecycleJoinClosed
    (semantics : CompositionDecisionSemantics)
    (decisionValid : CompositionDecisionReceiptValid)
    (bridgeAuthority : SubjectContextBridgeAcceptanceAuthority)
    (bridgeNode : SubjectContextBridgeAuthorityBoundNode bridgeAuthority)
    (request : CompositionCapabilityRequest)
    (grant : CompositionCapabilityGrant)
    (left right : CompositionDecisionReceipt)
    (lifecycleGrantAuthority :
      CompositionCedarLifecycleGrantAcceptanceAuthority)
    (lifecycleGrantNode :
      CompositionCedarLifecycleGrantAuthorityBoundNode
        lifecycleGrantAuthority)
    (authorityPathAuthorized : Nat → Nat → Nat → Nat → Prop)
    (separationOfDutySatisfied : Nat → Nat → Nat → Prop)
    (lifecycleEvidence : AuthorizationLifecycleEvidence) : Prop where
  grantClosed :
    CompositionCedarGrantClosed
      semantics decisionValid bridgeAuthority bridgeNode
      request grant left right
  lifecycleClosed :
    lifecycleEvidence.Closed
      authorityPathAuthorized separationOfDutySatisfied
  lifecycleGrantBound : lifecycleGrantNode.nodeBinding.grant = grant
  subjectEpochBound :
    request.authorizationSubject.epoch = request.runtimeGeneration
  lifecycleAuthorityBound :
    lifecycleEvidence.authorityIdentity =
      request.validationContext.authorityIdentity
  lifecycleRuntimeBound :
    lifecycleEvidence.runtimeEpoch = request.runtimeGeneration
  lifecyclePolicySnapshotBound :
    lifecycleEvidence.snapshot.snapshotIdentity =
      request.validationContext.policySnapshotIdentity
  decisionIdentityBound :
    lifecycleGrantNode.nodeBinding.decisionIdentity =
      lifecycleEvidence.decisionIdentity
  commitmentBound :
    lifecycleGrantNode.nodeBinding.commitment = lifecycleEvidence.commitment
  accountabilityBound :
    lifecycleGrantNode.nodeBinding.accountabilityIdentity =
      lifecycleEvidence.accountabilityIdentity
  responsibilityScopeBound :
    lifecycleGrantNode.nodeBinding.responsibilityScopeDigest =
      lifecycleEvidence.responsibilityScopeDigest
  activeFenceBound :
    lifecycleGrantNode.nodeBinding.activeFenceToken =
      lifecycleEvidence.activeFenceToken
  policyEvidenceRootBound :
    lifecycleGrantNode.nodeBinding.policyEvidenceRoot =
      lifecycleEvidence.snapshot.evidenceRoot
  credentialIdentityBound :
    lifecycleGrantNode.nodeBinding.credentialIdentity =
      lifecycleEvidence.credential.credentialIdentity
  credentialGenerationBound :
    lifecycleGrantNode.nodeBinding.credentialGeneration =
      lifecycleEvidence.credential.generation

theorem closedLifecycleJoinUsesAuthorityValidatedGrantBinding
    {semantics : CompositionDecisionSemantics}
    {decisionValid : CompositionDecisionReceiptValid}
    {bridgeAuthority : SubjectContextBridgeAcceptanceAuthority}
    {bridgeNode : SubjectContextBridgeAuthorityBoundNode bridgeAuthority}
    {request : CompositionCapabilityRequest}
    {grant : CompositionCapabilityGrant}
    {left right : CompositionDecisionReceipt}
    {lifecycleGrantAuthority :
      CompositionCedarLifecycleGrantAcceptanceAuthority}
    {lifecycleGrantNode :
      CompositionCedarLifecycleGrantAuthorityBoundNode
        lifecycleGrantAuthority}
    {authorityPathAuthorized : Nat → Nat → Nat → Nat → Prop}
    {separationOfDutySatisfied : Nat → Nat → Nat → Prop}
    {lifecycleEvidence : AuthorizationLifecycleEvidence}
    (closed :
      CompositionCedarLifecycleJoinClosed
        semantics decisionValid bridgeAuthority bridgeNode
        request grant left right lifecycleGrantAuthority lifecycleGrantNode
        authorityPathAuthorized separationOfDutySatisfied lifecycleEvidence) :
    lifecycleGrantAuthority.accepted lifecycleGrantNode.nodeBinding ∧
      lifecycleGrantNode.nodeBinding.grant = grant :=
  ⟨lifecycleGrantAuthorityBoundNodeAccepted lifecycleGrantNode,
    closed.lifecycleGrantBound⟩

theorem closedLifecycleJoinRejectsDecisionReplay
    {semantics : CompositionDecisionSemantics}
    {decisionValid : CompositionDecisionReceiptValid}
    {bridgeAuthority : SubjectContextBridgeAcceptanceAuthority}
    {bridgeNode : SubjectContextBridgeAuthorityBoundNode bridgeAuthority}
    {request : CompositionCapabilityRequest}
    {grant : CompositionCapabilityGrant}
    {left right : CompositionDecisionReceipt}
    {lifecycleGrantAuthority :
      CompositionCedarLifecycleGrantAcceptanceAuthority}
    {lifecycleGrantNode :
      CompositionCedarLifecycleGrantAuthorityBoundNode
        lifecycleGrantAuthority}
    {authorityPathAuthorized : Nat → Nat → Nat → Nat → Prop}
    {separationOfDutySatisfied : Nat → Nat → Nat → Prop}
    {lifecycleEvidence : AuthorizationLifecycleEvidence}
    (closed :
      CompositionCedarLifecycleJoinClosed
        semantics decisionValid bridgeAuthority bridgeNode
        request grant left right lifecycleGrantAuthority lifecycleGrantNode
        authorityPathAuthorized separationOfDutySatisfied lifecycleEvidence)
    (mismatch :
      lifecycleGrantNode.nodeBinding.decisionIdentity ≠
        lifecycleEvidence.decisionIdentity) : False :=
  mismatch closed.decisionIdentityBound

theorem closedLifecycleJoinRejectsFenceReplay
    {semantics : CompositionDecisionSemantics}
    {decisionValid : CompositionDecisionReceiptValid}
    {bridgeAuthority : SubjectContextBridgeAcceptanceAuthority}
    {bridgeNode : SubjectContextBridgeAuthorityBoundNode bridgeAuthority}
    {request : CompositionCapabilityRequest}
    {grant : CompositionCapabilityGrant}
    {left right : CompositionDecisionReceipt}
    {lifecycleGrantAuthority :
      CompositionCedarLifecycleGrantAcceptanceAuthority}
    {lifecycleGrantNode :
      CompositionCedarLifecycleGrantAuthorityBoundNode
        lifecycleGrantAuthority}
    {authorityPathAuthorized : Nat → Nat → Nat → Nat → Prop}
    {separationOfDutySatisfied : Nat → Nat → Nat → Prop}
    {lifecycleEvidence : AuthorizationLifecycleEvidence}
    (closed :
      CompositionCedarLifecycleJoinClosed
        semantics decisionValid bridgeAuthority bridgeNode
        request grant left right lifecycleGrantAuthority lifecycleGrantNode
        authorityPathAuthorized separationOfDutySatisfied lifecycleEvidence)
    (mismatch :
      lifecycleGrantNode.nodeBinding.activeFenceToken ≠
        lifecycleEvidence.activeFenceToken) : False :=
  mismatch closed.activeFenceBound

theorem closedLifecycleJoinRejectsCredentialReplay
    {semantics : CompositionDecisionSemantics}
    {decisionValid : CompositionDecisionReceiptValid}
    {bridgeAuthority : SubjectContextBridgeAcceptanceAuthority}
    {bridgeNode : SubjectContextBridgeAuthorityBoundNode bridgeAuthority}
    {request : CompositionCapabilityRequest}
    {grant : CompositionCapabilityGrant}
    {left right : CompositionDecisionReceipt}
    {lifecycleGrantAuthority :
      CompositionCedarLifecycleGrantAcceptanceAuthority}
    {lifecycleGrantNode :
      CompositionCedarLifecycleGrantAuthorityBoundNode
        lifecycleGrantAuthority}
    {authorityPathAuthorized : Nat → Nat → Nat → Nat → Prop}
    {separationOfDutySatisfied : Nat → Nat → Nat → Prop}
    {lifecycleEvidence : AuthorizationLifecycleEvidence}
    (closed :
      CompositionCedarLifecycleJoinClosed
        semantics decisionValid bridgeAuthority bridgeNode
        request grant left right lifecycleGrantAuthority lifecycleGrantNode
        authorityPathAuthorized separationOfDutySatisfied lifecycleEvidence)
    (mismatch :
      lifecycleGrantNode.nodeBinding.credentialIdentity ≠
        lifecycleEvidence.credential.credentialIdentity) : False :=
  mismatch closed.credentialIdentityBound

theorem closedLifecycleJoinProvidesCurrentCoordinates
    {semantics : CompositionDecisionSemantics}
    {decisionValid : CompositionDecisionReceiptValid}
    {bridgeAuthority : SubjectContextBridgeAcceptanceAuthority}
    {bridgeNode : SubjectContextBridgeAuthorityBoundNode bridgeAuthority}
    {request : CompositionCapabilityRequest}
    {grant : CompositionCapabilityGrant}
    {left right : CompositionDecisionReceipt}
    {lifecycleGrantAuthority :
      CompositionCedarLifecycleGrantAcceptanceAuthority}
    {lifecycleGrantNode :
      CompositionCedarLifecycleGrantAuthorityBoundNode
        lifecycleGrantAuthority}
    {authorityPathAuthorized : Nat → Nat → Nat → Nat → Prop}
    {separationOfDutySatisfied : Nat → Nat → Nat → Prop}
    {lifecycleEvidence : AuthorizationLifecycleEvidence}
    (closed :
      CompositionCedarLifecycleJoinClosed
        semantics decisionValid bridgeAuthority bridgeNode
        request grant left right lifecycleGrantAuthority lifecycleGrantNode
        authorityPathAuthorized separationOfDutySatisfied lifecycleEvidence) :
    lifecycleEvidence.authorityIdentity =
        request.validationContext.authorityIdentity ∧
      lifecycleEvidence.runtimeEpoch = request.runtimeGeneration ∧
      lifecycleEvidence.snapshot.snapshotIdentity =
        request.validationContext.policySnapshotIdentity :=
  ⟨closed.lifecycleAuthorityBound,
    closed.lifecycleRuntimeBound,
    closed.lifecyclePolicySnapshotBound⟩

end PooFlowProof.Enterprise.UseCompositionCedarLifecycleJoinClosure
