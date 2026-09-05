import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationSubjectBridgeClosure
import PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBindingCore

namespace PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBindingClosure

open
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBindingCore

abbrev RecoveryTrace :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryConvergenceClosure.SourceBoundEffectCompletionRecoveryTrace

abbrev RecoveryState :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionCrashRecoveryClosure.SourceBoundEffectCompletionCrashRecoveryState

abbrev ProgressBudget :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryProgressEvidenceClosure.SourceBoundEffectCompletionRecoveryProgressBudget

abbrev ProgressScope :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryProgressEvidenceClosure.SourceBoundEffectCompletionRecoveryProgressScope

abbrev RecoveryExpectation :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionCrashRecoveryClosure.SourceBoundEffectCompletionRecoveryExpectation

abbrev OwnerAuditWitness :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryOwnerAuditCore.SourceBoundEffectCompletionRecoveryOwnerAuditWitness

abbrev CommitmentScheme :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryOwnerAuditCommitmentCore.SourceBoundEffectCompletionRecoveryOwnerAuditCommitmentScheme

abbrev CommitmentEnvelope :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryOwnerAuditCommitmentCore.SourceBoundEffectCompletionRecoveryOwnerAuditCommitmentEnvelope

abbrev AuthenticityEvidence :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryOwnerAuditCommitmentCore.SourceBoundEffectCompletionRecoveryOwnerAuditAuthenticityEvidence

abbrev SubjectBridgeEvidence :=
  PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryCedarAuthorizationSubjectBridgeClosure.SourceBoundEffectCompletionRecoveryCedarAuthorizationSubjectBridgeEvidence

structure SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityEvidence
    (trace : RecoveryTrace)
    (budgets : Nat → ProgressBudget)
    (scopes : Nat → ProgressScope)
    (providerAcknowledgementStable : Nat → Prop)
    (expectations : Nat → RecoveryExpectation)
    (witnesses : Nat → OwnerAuditWitness)
    (scheme : CommitmentScheme)
    (signatureVerified : String → String → String → Prop)
    (authorizationRegistry : String → CedarAuthorizationEvidence)
    (authorityPathAuthorized : String → String → String → String → Prop)
    (separationOfDutySatisfied : String → String → String → Prop)
    (envelopes : Nat → CommitmentEnvelope)
    (authenticityEvidence : Nat → AuthenticityEvidence)
    (snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid)
    (semantics : DecisionSemantics)
    (decisionReceiptValid : DecisionReceiptValid)
    (dualDecisionIdentityValid : CedarDualDecisionIdentityValid)
    (subjectRegistry : String → AuthorizationSubject)
    (leftReceiptRegistry rightReceiptRegistry :
      String → DecisionReceipt)
    (bundleDigestAt :
      Nat → PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest)
    (bundleDigestAtValid :
      Nat →
        PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest →
          Prop)
    (authorityReceiptValid : AuthorityReceiptValid)
    (assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop)
    (grantRegistry : String → AuthorityGrant)
    (authorityReceiptRegistry : String → BoundAuthorityReceipt)
    (freshnessChecksAt : Nat → EvidenceFreshnessChecks)
    (assignmentRegistry :
      String →
        SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment) :
    Prop where
  subjectBridgeEvidence :
    SubjectBridgeEvidence
      trace
      budgets
      scopes
      providerAcknowledgementStable
      expectations
      witnesses
      scheme
      signatureVerified
      authorizationRegistry
      authorityPathAuthorized
      separationOfDutySatisfied
      envelopes
      authenticityEvidence
      snapshotSubjectBindingValid
      semantics
      decisionReceiptValid
      dualDecisionIdentityValid
      subjectRegistry
      leftReceiptRegistry
      rightReceiptRegistry
      bundleDigestAt
      bundleDigestAtValid
  responsibilityBindings :
    ∀ index,
      trace index ≠
          PooFlowProof.Enterprise.SourceBoundEffectCompletionCrashRecoveryClosure.SourceBoundEffectCompletionCrashRecoveryState.committed →
        let commitment := (envelopes index).commitment
        SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBound
          snapshotSubjectBindingValid
          semantics
          decisionReceiptValid
          dualDecisionIdentityValid
          authorityReceiptValid
          assignmentValid
          (authorizationRegistry commitment)
          (authenticityEvidence index)
          (subjectRegistry commitment)
          (leftReceiptRegistry commitment)
          (rightReceiptRegistry commitment)
          (bundleDigestAt index)
          (grantRegistry commitment)
          (authorityReceiptRegistry commitment)
          (freshnessChecksAt index)
          commitment
          (authorizationRegistry commitment).runtimeEpoch
          (assignmentRegistry commitment)

theorem closedEnterpriseResponsibilityBindsAccountabilityAt
    {trace : RecoveryTrace}
    {budgets : Nat → ProgressBudget}
    {scopes : Nat → ProgressScope}
    {providerAcknowledgementStable : Nat → Prop}
    {expectations : Nat → RecoveryExpectation}
    {witnesses : Nat → OwnerAuditWitness}
    {scheme : CommitmentScheme}
    {signatureVerified : String → String → String → Prop}
    {authorizationRegistry : String → CedarAuthorizationEvidence}
    {authorityPathAuthorized : String → String → String → String → Prop}
    {separationOfDutySatisfied : String → String → String → Prop}
    {envelopes : Nat → CommitmentEnvelope}
    {authenticityEvidence : Nat → AuthenticityEvidence}
    {snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid}
    {semantics : DecisionSemantics}
    {decisionReceiptValid : DecisionReceiptValid}
    {dualDecisionIdentityValid : CedarDualDecisionIdentityValid}
    {subjectRegistry : String → AuthorizationSubject}
    {leftReceiptRegistry rightReceiptRegistry :
      String → DecisionReceipt}
    {bundleDigestAt :
      Nat → PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest}
    {bundleDigestAtValid :
      Nat →
        PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest →
          Prop}
    {authorityReceiptValid : AuthorityReceiptValid}
    {assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop}
    {grantRegistry : String → AuthorityGrant}
    {authorityReceiptRegistry : String → BoundAuthorityReceipt}
    {freshnessChecksAt : Nat → EvidenceFreshnessChecks}
    {assignmentRegistry :
      String →
        SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    (evidence :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityEvidence
        trace
        budgets
        scopes
        providerAcknowledgementStable
        expectations
        witnesses
        scheme
        signatureVerified
        authorizationRegistry
        authorityPathAuthorized
        separationOfDutySatisfied
        envelopes
        authenticityEvidence
        snapshotSubjectBindingValid
        semantics
        decisionReceiptValid
        dualDecisionIdentityValid
        subjectRegistry
        leftReceiptRegistry
        rightReceiptRegistry
        bundleDigestAt
        bundleDigestAtValid
        authorityReceiptValid
        assignmentValid
        grantRegistry
        authorityReceiptRegistry
        freshnessChecksAt
        assignmentRegistry)
    (index : Nat)
    (active :
      trace index ≠
        PooFlowProof.Enterprise.SourceBoundEffectCompletionCrashRecoveryClosure.SourceBoundEffectCompletionCrashRecoveryState.committed) :
    let commitment := (envelopes index).commitment
    (authorizationRegistry commitment).accountabilityIdentity =
        (authenticityEvidence index).accountabilityIdentity ∧
      (authenticityEvidence index).accountabilityIdentity =
        (assignmentRegistry commitment).accountablePrincipal := by
  exact enterpriseResponsibilityBindsAccountability
    (evidence.responsibilityBindings index active)

theorem closedEnterpriseResponsibilityBindsScopeAt
    {trace : RecoveryTrace}
    {budgets : Nat → ProgressBudget}
    {scopes : Nat → ProgressScope}
    {providerAcknowledgementStable : Nat → Prop}
    {expectations : Nat → RecoveryExpectation}
    {witnesses : Nat → OwnerAuditWitness}
    {scheme : CommitmentScheme}
    {signatureVerified : String → String → String → Prop}
    {authorizationRegistry : String → CedarAuthorizationEvidence}
    {authorityPathAuthorized : String → String → String → String → Prop}
    {separationOfDutySatisfied : String → String → String → Prop}
    {envelopes : Nat → CommitmentEnvelope}
    {authenticityEvidence : Nat → AuthenticityEvidence}
    {snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid}
    {semantics : DecisionSemantics}
    {decisionReceiptValid : DecisionReceiptValid}
    {dualDecisionIdentityValid : CedarDualDecisionIdentityValid}
    {subjectRegistry : String → AuthorizationSubject}
    {leftReceiptRegistry rightReceiptRegistry :
      String → DecisionReceipt}
    {bundleDigestAt :
      Nat → PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest}
    {bundleDigestAtValid :
      Nat →
        PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest →
          Prop}
    {authorityReceiptValid : AuthorityReceiptValid}
    {assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop}
    {grantRegistry : String → AuthorityGrant}
    {authorityReceiptRegistry : String → BoundAuthorityReceipt}
    {freshnessChecksAt : Nat → EvidenceFreshnessChecks}
    {assignmentRegistry :
      String →
        SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    (evidence :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityEvidence
        trace
        budgets
        scopes
        providerAcknowledgementStable
        expectations
        witnesses
        scheme
        signatureVerified
        authorizationRegistry
        authorityPathAuthorized
        separationOfDutySatisfied
        envelopes
        authenticityEvidence
        snapshotSubjectBindingValid
        semantics
        decisionReceiptValid
        dualDecisionIdentityValid
        subjectRegistry
        leftReceiptRegistry
        rightReceiptRegistry
        bundleDigestAt
        bundleDigestAtValid
        authorityReceiptValid
        assignmentValid
        grantRegistry
        authorityReceiptRegistry
        freshnessChecksAt
        assignmentRegistry)
    (index : Nat)
    (active :
      trace index ≠
        PooFlowProof.Enterprise.SourceBoundEffectCompletionCrashRecoveryClosure.SourceBoundEffectCompletionCrashRecoveryState.committed) :
    let commitment := (envelopes index).commitment
    (authorizationRegistry commitment).responsibilityScopeDigest =
        (authenticityEvidence index).responsibilityScopeDigest ∧
      (authenticityEvidence index).responsibilityScopeDigest =
        (assignmentRegistry commitment).responsibilityScopeDigest := by
  exact enterpriseResponsibilityBindsScope
    (evidence.responsibilityBindings index active)

theorem closedEnterpriseResponsibilityBindsCommitmentAt
    {trace : RecoveryTrace}
    {budgets : Nat → ProgressBudget}
    {scopes : Nat → ProgressScope}
    {providerAcknowledgementStable : Nat → Prop}
    {expectations : Nat → RecoveryExpectation}
    {witnesses : Nat → OwnerAuditWitness}
    {scheme : CommitmentScheme}
    {signatureVerified : String → String → String → Prop}
    {authorizationRegistry : String → CedarAuthorizationEvidence}
    {authorityPathAuthorized : String → String → String → String → Prop}
    {separationOfDutySatisfied : String → String → String → Prop}
    {envelopes : Nat → CommitmentEnvelope}
    {authenticityEvidence : Nat → AuthenticityEvidence}
    {snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid}
    {semantics : DecisionSemantics}
    {decisionReceiptValid : DecisionReceiptValid}
    {dualDecisionIdentityValid : CedarDualDecisionIdentityValid}
    {subjectRegistry : String → AuthorizationSubject}
    {leftReceiptRegistry rightReceiptRegistry :
      String → DecisionReceipt}
    {bundleDigestAt :
      Nat → PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest}
    {bundleDigestAtValid :
      Nat →
        PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest →
          Prop}
    {authorityReceiptValid : AuthorityReceiptValid}
    {assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop}
    {grantRegistry : String → AuthorityGrant}
    {authorityReceiptRegistry : String → BoundAuthorityReceipt}
    {freshnessChecksAt : Nat → EvidenceFreshnessChecks}
    {assignmentRegistry :
      String →
        SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    (evidence :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityEvidence
        trace
        budgets
        scopes
        providerAcknowledgementStable
        expectations
        witnesses
        scheme
        signatureVerified
        authorizationRegistry
        authorityPathAuthorized
        separationOfDutySatisfied
        envelopes
        authenticityEvidence
        snapshotSubjectBindingValid
        semantics
        decisionReceiptValid
        dualDecisionIdentityValid
        subjectRegistry
        leftReceiptRegistry
        rightReceiptRegistry
        bundleDigestAt
        bundleDigestAtValid
        authorityReceiptValid
        assignmentValid
        grantRegistry
        authorityReceiptRegistry
        freshnessChecksAt
        assignmentRegistry)
    (index : Nat)
    (active :
      trace index ≠
        PooFlowProof.Enterprise.SourceBoundEffectCompletionCrashRecoveryClosure.SourceBoundEffectCompletionCrashRecoveryState.committed) :
    let commitment := (envelopes index).commitment
    (authorizationRegistry commitment).commitment =
        (authenticityEvidence index).commitment ∧
      (authenticityEvidence index).commitment =
        (assignmentRegistry commitment).commitment ∧
      (assignmentRegistry commitment).commitment = commitment := by
  exact enterpriseResponsibilityBindsCommitment
    (evidence.responsibilityBindings index active)

theorem closedEnterpriseResponsibilityPreservesSubjectBridge
    {trace : RecoveryTrace}
    {budgets : Nat → ProgressBudget}
    {scopes : Nat → ProgressScope}
    {providerAcknowledgementStable : Nat → Prop}
    {expectations : Nat → RecoveryExpectation}
    {witnesses : Nat → OwnerAuditWitness}
    {scheme : CommitmentScheme}
    {signatureVerified : String → String → String → Prop}
    {authorizationRegistry : String → CedarAuthorizationEvidence}
    {authorityPathAuthorized : String → String → String → String → Prop}
    {separationOfDutySatisfied : String → String → String → Prop}
    {envelopes : Nat → CommitmentEnvelope}
    {authenticityEvidence : Nat → AuthenticityEvidence}
    {snapshotSubjectBindingValid : CedarSnapshotSubjectBindingValid}
    {semantics : DecisionSemantics}
    {decisionReceiptValid : DecisionReceiptValid}
    {dualDecisionIdentityValid : CedarDualDecisionIdentityValid}
    {subjectRegistry : String → AuthorizationSubject}
    {leftReceiptRegistry rightReceiptRegistry :
      String → DecisionReceipt}
    {bundleDigestAt :
      Nat → PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest}
    {bundleDigestAtValid :
      Nat →
        PooFlowProof.Enterprise.BundleEvidenceBinding.BundleDigest →
          Prop}
    {authorityReceiptValid : AuthorityReceiptValid}
    {assignmentValid :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment →
        Prop}
    {grantRegistry : String → AuthorityGrant}
    {authorityReceiptRegistry : String → BoundAuthorityReceipt}
    {freshnessChecksAt : Nat → EvidenceFreshnessChecks}
    {assignmentRegistry :
      String →
        SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityAssignment}
    (evidence :
      SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityEvidence
        trace
        budgets
        scopes
        providerAcknowledgementStable
        expectations
        witnesses
        scheme
        signatureVerified
        authorizationRegistry
        authorityPathAuthorized
        separationOfDutySatisfied
        envelopes
        authenticityEvidence
        snapshotSubjectBindingValid
        semantics
        decisionReceiptValid
        dualDecisionIdentityValid
        subjectRegistry
        leftReceiptRegistry
        rightReceiptRegistry
        bundleDigestAt
        bundleDigestAtValid
        authorityReceiptValid
        assignmentValid
        grantRegistry
        authorityReceiptRegistry
        freshnessChecksAt
        assignmentRegistry) :
    SubjectBridgeEvidence
      trace
      budgets
      scopes
      providerAcknowledgementStable
      expectations
      witnesses
      scheme
      signatureVerified
      authorizationRegistry
      authorityPathAuthorized
      separationOfDutySatisfied
      envelopes
      authenticityEvidence
      snapshotSubjectBindingValid
      semantics
      decisionReceiptValid
      dualDecisionIdentityValid
      subjectRegistry
      leftReceiptRegistry
      rightReceiptRegistry
      bundleDigestAt
      bundleDigestAtValid :=
  evidence.subjectBridgeEvidence

end PooFlowProof.Enterprise.SourceBoundEffectCompletionRecoveryEnterpriseResponsibilityBindingClosure
