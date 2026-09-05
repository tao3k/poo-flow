import PooFlowProof.PooC3.DistributedCacheAdmission

namespace PooFlowProof.PooC3.DistributedEvaluatorDelegation

open PooFlowProof.PooC3.DistributedCacheAdmission

structure PureDemandEnvelope
    (Root InputIdentity DependencyIdentity ObservationCut PolicyIdentity
      DemandIdentity : Type) where
  canonicalRoot : Root
  inputIdentity : InputIdentity
  dependencyIdentity : DependencyIdentity
  observationCut : ObservationCut
  policyIdentity : PolicyIdentity
  demandIdentity : DemandIdentity
  pureDemand : Prop
  purityEstablished : pureDemand
  carriesActionAuthority : Prop
  noActionAuthority : ¬ carriesActionAuthority

structure DelegationFence
    (DemandIdentity FenceIdentity CoordinatorIdentity : Type) where
  demandIdentity : DemandIdentity
  fenceIdentity : FenceIdentity
  coordinatorIdentity : CoordinatorIdentity
  current : Prop
  notRevoked : Prop

def FenceChecksHold
    {DemandIdentity FenceIdentity CoordinatorIdentity : Type}
    (fence :
      DelegationFence DemandIdentity FenceIdentity CoordinatorIdentity) :
    Prop :=
  fence.current ∧ fence.notRevoked

inductive WorkerResultKind where
  | currentCandidate
  | staleFence
  | revokedFence
  | suspended
  | protocolViolation
  deriving DecidableEq, Repr

def CanEnterLocalAdmission : WorkerResultKind → Prop
  | .currentCandidate => True
  | .staleFence => False
  | .revokedFence => False
  | .suspended => False
  | .protocolViolation => False

def AdmitsDirectPublication : WorkerResultKind → Prop
  | .currentCandidate => False
  | .staleFence => False
  | .revokedFence => False
  | .suspended => False
  | .protocolViolation => False

structure PortableSuspension
    (DemandIdentity ObservationCut PolicyIdentity ResumeToken : Type) where
  demandIdentity : DemandIdentity
  observationCut : ObservationCut
  policyIdentity : PolicyIdentity
  resumeToken : ResumeToken
  capturesVmContinuation : Prop
  noCapturedVmContinuation : ¬ capturesVmContinuation
  carriesActionAuthority : Prop
  noActionAuthority : ¬ carriesActionAuthority
  resumableDataComplete : Prop
  resumableDataEstablished : resumableDataComplete

structure ResumeChecks where
  demandIdentityMatches : Prop
  observationCutMatches : Prop
  policyIdentityMatches : Prop
  fenceCurrent : Prop

def ResumeChecksHold (checks : ResumeChecks) : Prop :=
  checks.demandIdentityMatches ∧
    checks.observationCutMatches ∧
    checks.policyIdentityMatches ∧
    checks.fenceCurrent

structure CoordinatorCommitReceipt
    (DemandIdentity FenceIdentity PublicationIdentity : Type) where
  demandIdentity : DemandIdentity
  fenceIdentity : FenceIdentity
  publicationIdentity : PublicationIdentity
  commitCount : Nat
  singleCommit : commitCount = 1

structure CoordinatorAdmittedWorkerCandidate
    (DemandIdentity FenceIdentity CoordinatorIdentity
      SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
      LocalPolicyIdentity ReceiptIdentity : Type) where
  fence :
    DelegationFence DemandIdentity FenceIdentity CoordinatorIdentity
  fenceChecks : FenceChecksHold fence
  localAdmission :
    LocalAdmissionReceipt
      SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
      LocalPolicyIdentity ReceiptIdentity
  locallyAdmitted :
    localAdmission.decision = .locallyAdmitted

theorem pureDemandEnvelopeCarriesNoActionAuthority
    {Root InputIdentity DependencyIdentity ObservationCut PolicyIdentity
      DemandIdentity : Type}
    (envelope :
      PureDemandEnvelope
        Root InputIdentity DependencyIdentity ObservationCut PolicyIdentity
        DemandIdentity) :
    ¬ envelope.carriesActionAuthority :=
  envelope.noActionAuthority

theorem pureDemandEnvelopeCarriesPurityEvidence
    {Root InputIdentity DependencyIdentity ObservationCut PolicyIdentity
      DemandIdentity : Type}
    (envelope :
      PureDemandEnvelope
        Root InputIdentity DependencyIdentity ObservationCut PolicyIdentity
        DemandIdentity) :
    envelope.pureDemand :=
  envelope.purityEstablished

theorem currentWorkerResultMayEnterLocalAdmission :
    CanEnterLocalAdmission .currentCandidate := by
  simp [CanEnterLocalAdmission]

theorem staleFenceResultFailsClosed :
    ¬ CanEnterLocalAdmission .staleFence := by
  simp [CanEnterLocalAdmission]

theorem revokedFenceResultFailsClosed :
    ¬ CanEnterLocalAdmission .revokedFence := by
  simp [CanEnterLocalAdmission]

theorem suspendedResultDoesNotEnterAdmission :
    ¬ CanEnterLocalAdmission .suspended := by
  simp [CanEnterLocalAdmission]

theorem workerResultNeverPublishesDirectly
    (kind : WorkerResultKind) :
    ¬ AdmitsDirectPublication kind := by
  cases kind <;> simp [AdmitsDirectPublication]

theorem staleFencePreventsFenceChecks
    {DemandIdentity FenceIdentity CoordinatorIdentity : Type}
    (fence :
      DelegationFence DemandIdentity FenceIdentity CoordinatorIdentity)
    (stale : ¬ fence.current) :
    ¬ FenceChecksHold fence := by
  intro checks
  exact stale checks.1

theorem revokedFencePreventsFenceChecks
    {DemandIdentity FenceIdentity CoordinatorIdentity : Type}
    (fence :
      DelegationFence DemandIdentity FenceIdentity CoordinatorIdentity)
    (revoked : ¬ fence.notRevoked) :
    ¬ FenceChecksHold fence := by
  intro checks
  exact revoked checks.2

theorem portableSuspensionIsNotRawVmContinuation
    {DemandIdentity ObservationCut PolicyIdentity ResumeToken : Type}
    (suspension :
      PortableSuspension
        DemandIdentity ObservationCut PolicyIdentity ResumeToken) :
    ¬ suspension.capturesVmContinuation :=
  suspension.noCapturedVmContinuation

theorem portableSuspensionCarriesNoActionAuthority
    {DemandIdentity ObservationCut PolicyIdentity ResumeToken : Type}
    (suspension :
      PortableSuspension
        DemandIdentity ObservationCut PolicyIdentity ResumeToken) :
    ¬ suspension.carriesActionAuthority :=
  suspension.noActionAuthority

theorem portableSuspensionCarriesResumableData
    {DemandIdentity ObservationCut PolicyIdentity ResumeToken : Type}
    (suspension :
      PortableSuspension
        DemandIdentity ObservationCut PolicyIdentity ResumeToken) :
    suspension.resumableDataComplete :=
  suspension.resumableDataEstablished

theorem changedDemandPreventsResume
    (checks : ResumeChecks)
    (changed : ¬ checks.demandIdentityMatches) :
    ¬ ResumeChecksHold checks := by
  intro holds
  exact changed holds.1

theorem changedObservationCutPreventsResume
    (checks : ResumeChecks)
    (changed : ¬ checks.observationCutMatches) :
    ¬ ResumeChecksHold checks := by
  intro holds
  exact changed holds.2.1

theorem changedPolicyPreventsResume
    (checks : ResumeChecks)
    (changed : ¬ checks.policyIdentityMatches) :
    ¬ ResumeChecksHold checks := by
  intro holds
  exact changed holds.2.2.1

theorem staleResumeFencePreventsResume
    (checks : ResumeChecks)
    (stale : ¬ checks.fenceCurrent) :
    ¬ ResumeChecksHold checks := by
  intro holds
  exact stale holds.2.2.2

theorem coordinatorCommitIsSinglePublication
    {DemandIdentity FenceIdentity PublicationIdentity : Type}
    (receipt :
      CoordinatorCommitReceipt
        DemandIdentity FenceIdentity PublicationIdentity) :
    receipt.commitCount = 1 :=
  receipt.singleCommit

theorem coordinatorCandidateCarriesIndependentLocalChecks
    {DemandIdentity FenceIdentity CoordinatorIdentity
      SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
      LocalPolicyIdentity ReceiptIdentity : Type}
    (candidate :
      CoordinatorAdmittedWorkerCandidate
        DemandIdentity FenceIdentity CoordinatorIdentity
        SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
        LocalPolicyIdentity ReceiptIdentity) :
    LocalChecksHold candidate.localAdmission.checks :=
  locallyAdmittedCandidateHasIndependentChecks
    candidate.localAdmission candidate.locallyAdmitted

theorem coordinatorCandidateCarriesCurrentFence
    {DemandIdentity FenceIdentity CoordinatorIdentity
      SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
      LocalPolicyIdentity ReceiptIdentity : Type}
    (candidate :
      CoordinatorAdmittedWorkerCandidate
        DemandIdentity FenceIdentity CoordinatorIdentity
        SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
        LocalPolicyIdentity ReceiptIdentity) :
    candidate.fence.current :=
  candidate.fenceChecks.1

theorem coordinatorCandidateCarriesNonrevokedFence
    {DemandIdentity FenceIdentity CoordinatorIdentity
      SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
      LocalPolicyIdentity ReceiptIdentity : Type}
    (candidate :
      CoordinatorAdmittedWorkerCandidate
        DemandIdentity FenceIdentity CoordinatorIdentity
        SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
        LocalPolicyIdentity ReceiptIdentity) :
    candidate.fence.notRevoked :=
  candidate.fenceChecks.2

end PooFlowProof.PooC3.DistributedEvaluatorDelegation
