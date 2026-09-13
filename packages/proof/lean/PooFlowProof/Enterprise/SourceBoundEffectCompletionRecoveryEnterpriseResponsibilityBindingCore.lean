import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationSubjectBridgeCore
import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryOwnerEvidenceBindingClosure
import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBindingModel

namespace PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBindingCore

abbrev AuthorizationSubject :=
  PooFlowProof.Enterprise.CedarDualEngineAuthorization.AuthorizationSubject

abbrev DecisionSemantics :=
  PooFlowProof.Enterprise.CedarDualEngineAuthorization.DecisionSemantics

abbrev DecisionReceipt :=
  PooFlowProof.Enterprise.CedarDualEngineAuthorization.DecisionReceipt

abbrev DecisionReceiptValid :=
  PooFlowProof.Enterprise.CedarDualEngineAuthorization.DecisionReceiptValid

abbrev PrincipalId :=
  PooFlowProof.Enterprise.HumanAuthorityAccountability.PrincipalId

abbrev ReceiptId :=
  PooFlowProof.Enterprise.CedarDualEngineAuthorization.ReceiptId

abbrev AuthorityGrant :=
  PooFlowProof.Enterprise.HumanAuthorityAccountability.AuthorityGrant

abbrev BoundAuthorityReceipt :=
  PooFlowProof.Enterprise.HumanAuthorityAccountability.BoundAuthorityReceipt

abbrev AuthorityReceiptValid :=
  PooFlowProof.Enterprise.HumanAuthorityAccountability.AuthorityReceiptValid

abbrev EvidenceFreshnessChecks :=
  PooFlowProof.Enterprise.EvidenceFreshness.Checks

abbrev CedarAuthorizationEvidence :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationLifecycleCore.SourceBoundEffectCompletionRecoveryCedarAuthorizationEvidence

abbrev OwnerAuditAuthenticityEvidence :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryOwnerAuditCommitmentCore.SourceBoundEffectCompletionRecoveryOwnerAuditAuthenticityEvidence

abbrev CedarSnapshotSubjectBindingValid :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationSubjectBridgeCore.SourceBoundEffectCompletionRecoveryCedarSnapshotSubjectBindingValid

abbrev CedarDualDecisionIdentityValid :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationSubjectBridgeCore.SourceBoundEffectCompletionRecoveryCedarDualDecisionIdentityValid

structure SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment where
  assignmentIdentity : String
  commitment : String
  authorityPrincipal : PrincipalId
  accountablePrincipal : PrincipalId
  responsibilityScopeDigest : String
  subject : AuthorizationSubject
  authorityReceiptId : ReceiptId
  acceptanceEvidenceIdentity : String
  effectiveEpoch : Nat
  accepted : Bool

def SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment.Valid
    (assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop)
    (expectedCommitment : String)
    (expectedSubject : AuthorizationSubject)
    (authorityReceipt : BoundAuthorityReceipt)
    (assignment :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment) :
    Prop :=
  assignment.assignmentIdentity ≠ "" ∧
    assignment.commitment = expectedCommitment ∧
      assignment.authorityPrincipal ≠ "" ∧
        assignment.accountablePrincipal ≠ "" ∧
          assignment.accountablePrincipal ≠ assignment.authorityPrincipal ∧
            assignment.responsibilityScopeDigest ≠ "" ∧
              assignment.subject = expectedSubject ∧
                assignment.authorityReceiptId = authorityReceipt.receiptId ∧
                  assignment.effectiveEpoch = expectedSubject.epoch ∧
                    assignment.acceptanceEvidenceIdentity ≠ "" ∧
                      assignment.accepted = true ∧
                        assignmentValid assignment

structure SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBound
    (snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid)
    (semantics : DecisionSemantics)
    (decisionReceiptValid : DecisionReceiptValid)
    (dualDecisionIdentityValid : CedarDualDecisionIdentityValid)
    (authorityReceiptValid : AuthorityReceiptValid)
    (assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop)
    (lifecycle : CedarAuthorizationEvidence)
    (authenticity : OwnerAuditAuthenticityEvidence)
    (subject : AuthorizationSubject)
    (left right : DecisionReceipt)
    (expectedBundle :
      PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest)
    (grant : AuthorityGrant)
    (authorityReceipt : BoundAuthorityReceipt)
    (checks : EvidenceFreshnessChecks)
    (expectedCommitment : String)
    (recoveryEpoch : Nat)
    (assignment :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment) :
    Prop where
  subjectBound :
    PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationSubjectBridgeCore.SourceBoundEffectCompletionRecoveryCedarAuthorizationSubjectBound
      snapshotSubjectBindingValid
      semantics
      decisionReceiptValid
      dualDecisionIdentityValid
      lifecycle
      subject
      left
      right
      expectedBundle
  authorizedOwner :
    PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryOwnerEvidenceBindingClosure.SourceBoundEffectCompletionRecoveryAuthorizedOwnerAssertion
      semantics
      decisionReceiptValid
      authorityReceiptValid
      subject
      left
      right
      grant
      authorityReceipt
      checks
      recoveryEpoch
  assignmentClosed :
    assignment.Valid
      assignmentValid
      expectedCommitment
      subject
      authorityReceipt
  lifecycleCommitmentMatches :
    lifecycle.commitment = assignment.commitment
  authenticityCommitmentMatches :
    authenticity.commitment = assignment.commitment
  lifecycleAuthorityMatches :
    lifecycle.authorityIdentity = assignment.authorityPrincipal
  authenticityAuthorityMatches :
    authenticity.authorityIdentity = assignment.authorityPrincipal
  grantPrincipalMatches :
    grant.principal = assignment.authorityPrincipal
  authorityReceiptPrincipalMatches :
    authorityReceipt.principal = assignment.authorityPrincipal
  lifecycleAccountabilityMatches :
    lifecycle.accountabilityIdentity = assignment.accountablePrincipal
  authenticityAccountabilityMatches :
    authenticity.accountabilityIdentity = assignment.accountablePrincipal
  lifecycleResponsibilityMatches :
    lifecycle.responsibilityScopeDigest =
      assignment.responsibilityScopeDigest
  authenticityResponsibilityMatches :
    authenticity.responsibilityScopeDigest =
      assignment.responsibilityScopeDigest

theorem enterpriseResponsibilityBindsAccountability
    {snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid}
    {semantics : DecisionSemantics}
    {decisionReceiptValid : DecisionReceiptValid}
    {dualDecisionIdentityValid : CedarDualDecisionIdentityValid}
    {authorityReceiptValid : AuthorityReceiptValid}
    {assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop}
    {lifecycle : CedarAuthorizationEvidence}
    {authenticity : OwnerAuditAuthenticityEvidence}
    {subject : AuthorizationSubject}
    {left right : DecisionReceipt}
    {expectedBundle :
      PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest}
    {grant : AuthorityGrant}
    {authorityReceipt : BoundAuthorityReceipt}
    {checks : EvidenceFreshnessChecks}
    {expectedCommitment : String}
    {recoveryEpoch : Nat}
    {assignment :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    (binding :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBound
        snapshotSubjectBindingValid
        semantics
        decisionReceiptValid
        dualDecisionIdentityValid
        authorityReceiptValid
        assignmentValid
        lifecycle
        authenticity
        subject
        left
        right
        expectedBundle
        grant
        authorityReceipt
        checks
        expectedCommitment
        recoveryEpoch
        assignment) :
    lifecycle.accountabilityIdentity =
        authenticity.accountabilityIdentity ∧
      authenticity.accountabilityIdentity =
        assignment.accountablePrincipal := by
  constructor
  · exact binding.lifecycleAccountabilityMatches.trans
      binding.authenticityAccountabilityMatches.symm
  · exact binding.authenticityAccountabilityMatches

theorem enterpriseResponsibilityBindsScope
    {snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid}
    {semantics : DecisionSemantics}
    {decisionReceiptValid : DecisionReceiptValid}
    {dualDecisionIdentityValid : CedarDualDecisionIdentityValid}
    {authorityReceiptValid : AuthorityReceiptValid}
    {assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop}
    {lifecycle : CedarAuthorizationEvidence}
    {authenticity : OwnerAuditAuthenticityEvidence}
    {subject : AuthorizationSubject}
    {left right : DecisionReceipt}
    {expectedBundle :
      PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest}
    {grant : AuthorityGrant}
    {authorityReceipt : BoundAuthorityReceipt}
    {checks : EvidenceFreshnessChecks}
    {expectedCommitment : String}
    {recoveryEpoch : Nat}
    {assignment :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    (binding :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBound
        snapshotSubjectBindingValid
        semantics
        decisionReceiptValid
        dualDecisionIdentityValid
        authorityReceiptValid
        assignmentValid
        lifecycle
        authenticity
        subject
        left
        right
        expectedBundle
        grant
        authorityReceipt
        checks
        expectedCommitment
        recoveryEpoch
        assignment) :
    lifecycle.responsibilityScopeDigest =
        authenticity.responsibilityScopeDigest ∧
      authenticity.responsibilityScopeDigest =
        assignment.responsibilityScopeDigest := by
  constructor
  · exact binding.lifecycleResponsibilityMatches.trans
      binding.authenticityResponsibilityMatches.symm
  · exact binding.authenticityResponsibilityMatches

theorem enterpriseResponsibilityBindsAuthority
    {snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid}
    {semantics : DecisionSemantics}
    {decisionReceiptValid : DecisionReceiptValid}
    {dualDecisionIdentityValid : CedarDualDecisionIdentityValid}
    {authorityReceiptValid : AuthorityReceiptValid}
    {assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop}
    {lifecycle : CedarAuthorizationEvidence}
    {authenticity : OwnerAuditAuthenticityEvidence}
    {subject : AuthorizationSubject}
    {left right : DecisionReceipt}
    {expectedBundle :
      PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest}
    {grant : AuthorityGrant}
    {authorityReceipt : BoundAuthorityReceipt}
    {checks : EvidenceFreshnessChecks}
    {expectedCommitment : String}
    {recoveryEpoch : Nat}
    {assignment :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    (binding :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBound
        snapshotSubjectBindingValid
        semantics
        decisionReceiptValid
        dualDecisionIdentityValid
        authorityReceiptValid
        assignmentValid
        lifecycle
        authenticity
        subject
        left
        right
        expectedBundle
        grant
        authorityReceipt
        checks
        expectedCommitment
        recoveryEpoch
        assignment) :
    lifecycle.authorityIdentity = grant.principal ∧
      grant.principal = authorityReceipt.principal ∧
        authorityReceipt.principal = assignment.authorityPrincipal := by
  constructor
  · exact binding.lifecycleAuthorityMatches.trans
      binding.grantPrincipalMatches.symm
  constructor
  · exact binding.grantPrincipalMatches.trans
      binding.authorityReceiptPrincipalMatches.symm
  · exact binding.authorityReceiptPrincipalMatches

theorem enterpriseResponsibilityBindsCommitment
    {snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid}
    {semantics : DecisionSemantics}
    {decisionReceiptValid : DecisionReceiptValid}
    {dualDecisionIdentityValid : CedarDualDecisionIdentityValid}
    {authorityReceiptValid : AuthorityReceiptValid}
    {assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop}
    {lifecycle : CedarAuthorizationEvidence}
    {authenticity : OwnerAuditAuthenticityEvidence}
    {subject : AuthorizationSubject}
    {left right : DecisionReceipt}
    {expectedBundle :
      PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest}
    {grant : AuthorityGrant}
    {authorityReceipt : BoundAuthorityReceipt}
    {checks : EvidenceFreshnessChecks}
    {expectedCommitment : String}
    {recoveryEpoch : Nat}
    {assignment :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    (binding :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBound
        snapshotSubjectBindingValid
        semantics
        decisionReceiptValid
        dualDecisionIdentityValid
        authorityReceiptValid
        assignmentValid
        lifecycle
        authenticity
        subject
        left
        right
        expectedBundle
        grant
        authorityReceipt
        checks
        expectedCommitment
        recoveryEpoch
        assignment) :
    lifecycle.commitment = authenticity.commitment ∧
      authenticity.commitment = assignment.commitment ∧
        assignment.commitment = expectedCommitment := by
  have assignmentCommitment :
      assignment.commitment = expectedCommitment := by
    rcases binding.assignmentClosed with
      ⟨_, commitmentMatches, _, _, _, _, _, _, _, _, _, _⟩
    exact commitmentMatches
  exact
    ⟨binding.lifecycleCommitmentMatches.trans
        binding.authenticityCommitmentMatches.symm,
      binding.authenticityCommitmentMatches,
      assignmentCommitment⟩

theorem enterpriseResponsibilitySeparatesAuthorityAndAccountability
    {snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid}
    {semantics : DecisionSemantics}
    {decisionReceiptValid : DecisionReceiptValid}
    {dualDecisionIdentityValid : CedarDualDecisionIdentityValid}
    {authorityReceiptValid : AuthorityReceiptValid}
    {assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop}
    {lifecycle : CedarAuthorizationEvidence}
    {authenticity : OwnerAuditAuthenticityEvidence}
    {subject : AuthorizationSubject}
    {left right : DecisionReceipt}
    {expectedBundle :
      PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest}
    {grant : AuthorityGrant}
    {authorityReceipt : BoundAuthorityReceipt}
    {checks : EvidenceFreshnessChecks}
    {expectedCommitment : String}
    {recoveryEpoch : Nat}
    {assignment :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    (binding :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBound
        snapshotSubjectBindingValid
        semantics
        decisionReceiptValid
        dualDecisionIdentityValid
        authorityReceiptValid
        assignmentValid
        lifecycle
        authenticity
        subject
        left
        right
        expectedBundle
        grant
        authorityReceipt
        checks
        expectedCommitment
        recoveryEpoch
        assignment) :
    assignment.accountablePrincipal ≠ assignment.authorityPrincipal := by
  rcases binding.assignmentClosed with
    ⟨_, _, _, _, principalsDistinct, _, _, _, _, _, _, _⟩
  exact principalsDistinct

theorem enterpriseResponsibilityBindsRecoveryEpoch
    {snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid}
    {semantics : DecisionSemantics}
    {decisionReceiptValid : DecisionReceiptValid}
    {dualDecisionIdentityValid : CedarDualDecisionIdentityValid}
    {authorityReceiptValid : AuthorityReceiptValid}
    {assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop}
    {lifecycle : CedarAuthorizationEvidence}
    {authenticity : OwnerAuditAuthenticityEvidence}
    {subject : AuthorizationSubject}
    {left right : DecisionReceipt}
    {expectedBundle :
      PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest}
    {grant : AuthorityGrant}
    {authorityReceipt : BoundAuthorityReceipt}
    {checks : EvidenceFreshnessChecks}
    {expectedCommitment : String}
    {recoveryEpoch : Nat}
    {assignment :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    (binding :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBound
        snapshotSubjectBindingValid
        semantics
        decisionReceiptValid
        dualDecisionIdentityValid
        authorityReceiptValid
        assignmentValid
        lifecycle
        authenticity
        subject
        left
        right
        expectedBundle
        grant
        authorityReceipt
        checks
        expectedCommitment
        recoveryEpoch
        assignment) :
    assignment.effectiveEpoch = recoveryEpoch := by
  have assignmentEpoch :
      assignment.effectiveEpoch = subject.epoch := by
    rcases binding.assignmentClosed with
      ⟨_, _, _, _, _, _, _, _, epochMatches, _, _, _⟩
    exact epochMatches
  exact assignmentEpoch.trans binding.authorizedOwner.recoveryEpochBinds

end PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBindingCore
