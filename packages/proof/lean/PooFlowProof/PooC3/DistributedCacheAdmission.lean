import PooFlowProof.PooC3.IncrementalFixedPointCacheCorrectness

namespace PooFlowProof.PooC3.DistributedCacheAdmission

inductive DistributedAdmissionKind where
  | candidateOnly
  | locallyAdmitted
  | rejected
  | suspended
  | quarantined
  deriving DecidableEq, Repr

def AdmitsLocalUse : DistributedAdmissionKind → Prop
  | .locallyAdmitted => True
  | .candidateOnly => False
  | .rejected => False
  | .suspended => False
  | .quarantined => False

inductive DistributedCacheClass where
  | semanticValue
  | compatibilityEvidence
  | executionWork
  | materialization
  deriving DecidableEq, Repr

def CarriesSemanticAuthority : DistributedCacheClass → Prop
  | .semanticValue => False
  | .compatibilityEvidence => False
  | .executionWork => False
  | .materialization => False

structure DistributedCandidate
    (SemanticKey PayloadDigest ProvenanceIdentity TrustDomain : Type) where
  semanticKey : SemanticKey
  payloadDigest : PayloadDigest
  provenanceIdentity : ProvenanceIdentity
  sourceTrustDomain : TrustDomain
  cacheClass : DistributedCacheClass

structure LocalAdmissionChecks where
  provenanceTrusted : Prop
  semanticKeyMatches : Prop
  freshnessHolds : Prop
  platformCompatible : Prop
  confidentialityAllowed : Prop
  notRevoked : Prop
  determinismConsistent : Prop

def LocalChecksHold (checks : LocalAdmissionChecks) : Prop :=
  checks.provenanceTrusted ∧
    checks.semanticKeyMatches ∧
    checks.freshnessHolds ∧
    checks.platformCompatible ∧
    checks.confidentialityAllowed ∧
    checks.notRevoked ∧
    checks.determinismConsistent

structure LocalAdmissionReceipt
    (SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
      LocalPolicyIdentity ReceiptIdentity : Type) where
  candidate :
    DistributedCandidate
      SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
  localPolicyIdentity : LocalPolicyIdentity
  checks : LocalAdmissionChecks
  decision : DistributedAdmissionKind
  admittedDecisionRequiresChecks :
    decision = .locallyAdmitted → LocalChecksHold checks
  receiptIdentity : ReceiptIdentity

structure DeterminismConflict
    (SemanticKey ExpectedDigest ObservedDigest ConflictIdentity : Type) where
  semanticKey : SemanticKey
  expectedDigest : ExpectedDigest
  observedDigest : ObservedDigest
  digestsConflict : Prop
  conflictEstablished : digestsConflict
  quarantineRequired : Prop
  quarantineEstablished : quarantineRequired
  conflictIdentity : ConflictIdentity

structure RevocationObservation
    (ProvenanceIdentity RevocationIdentity : Type) where
  provenanceIdentity : ProvenanceIdentity
  revocationIdentity : RevocationIdentity
  revoked : Prop
  revocationObserved : revoked
  localAdmissionAllowed : Prop
  revokedCandidateNotAdmitted : ¬ localAdmissionAllowed

theorem remoteCandidateIsNotLocalAuthority :
    ¬ AdmitsLocalUse .candidateOnly := by
  simp [AdmitsLocalUse]

theorem rejectedCandidateFailsClosed :
    ¬ AdmitsLocalUse .rejected := by
  simp [AdmitsLocalUse]

theorem suspendedAdmissionFailsClosed :
    ¬ AdmitsLocalUse .suspended := by
  simp [AdmitsLocalUse]

theorem quarantinedCandidateFailsClosed :
    ¬ AdmitsLocalUse .quarantined := by
  simp [AdmitsLocalUse]

theorem localAdmissionPermitsUse :
    AdmitsLocalUse .locallyAdmitted := by
  simp [AdmitsLocalUse]

theorem distributedCacheClassIsNotSemanticAuthority
    (cacheClass : DistributedCacheClass) :
    ¬ CarriesSemanticAuthority cacheClass := by
  cases cacheClass <;> simp [CarriesSemanticAuthority]

theorem locallyAdmittedCandidateHasIndependentChecks
    {SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
      LocalPolicyIdentity ReceiptIdentity : Type}
    (receipt :
      LocalAdmissionReceipt
        SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
        LocalPolicyIdentity ReceiptIdentity)
    (admitted : receipt.decision = .locallyAdmitted) :
    LocalChecksHold receipt.checks :=
  receipt.admittedDecisionRequiresChecks admitted

theorem semanticKeyMismatchPreventsCompletedChecks
    (checks : LocalAdmissionChecks)
    (mismatch : ¬ checks.semanticKeyMatches) :
    ¬ LocalChecksHold checks := by
  intro holds
  exact mismatch holds.2.1

theorem staleCandidatePreventsCompletedChecks
    (checks : LocalAdmissionChecks)
    (stale : ¬ checks.freshnessHolds) :
    ¬ LocalChecksHold checks := by
  intro holds
  exact stale holds.2.2.1

theorem incompatiblePlatformPreventsCompletedChecks
    (checks : LocalAdmissionChecks)
    (incompatible : ¬ checks.platformCompatible) :
    ¬ LocalChecksHold checks := by
  intro holds
  exact incompatible holds.2.2.2.1

theorem confidentialityMismatchPreventsCompletedChecks
    (checks : LocalAdmissionChecks)
    (forbidden : ¬ checks.confidentialityAllowed) :
    ¬ LocalChecksHold checks := by
  intro holds
  exact forbidden holds.2.2.2.2.1

theorem revokedCandidatePreventsCompletedChecks
    (checks : LocalAdmissionChecks)
    (revoked : ¬ checks.notRevoked) :
    ¬ LocalChecksHold checks := by
  intro holds
  exact revoked holds.2.2.2.2.2.1

theorem determinismConflictPreventsCompletedChecks
    (checks : LocalAdmissionChecks)
    (conflict : ¬ checks.determinismConsistent) :
    ¬ LocalChecksHold checks := by
  intro holds
  exact conflict holds.2.2.2.2.2.2

theorem determinismConflictRequiresQuarantine
    {SemanticKey ExpectedDigest ObservedDigest ConflictIdentity : Type}
    (conflict :
      DeterminismConflict
        SemanticKey ExpectedDigest ObservedDigest ConflictIdentity) :
    conflict.quarantineRequired :=
  conflict.quarantineEstablished

theorem revocationFailsClosed
    {ProvenanceIdentity RevocationIdentity : Type}
    (observation :
      RevocationObservation ProvenanceIdentity RevocationIdentity) :
    ¬ observation.localAdmissionAllowed :=
  observation.revokedCandidateNotAdmitted

theorem localReceiptCarriesCandidateProvenance
    {SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
      LocalPolicyIdentity ReceiptIdentity : Type}
    (receipt :
      LocalAdmissionReceipt
        SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
        LocalPolicyIdentity ReceiptIdentity) :
    ∃ provenance : ProvenanceIdentity,
      provenance = receipt.candidate.provenanceIdentity := by
  exact ⟨receipt.candidate.provenanceIdentity, rfl⟩

theorem localReceiptCarriesLocalPolicyIdentity
    {SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
      LocalPolicyIdentity ReceiptIdentity : Type}
    (receipt :
      LocalAdmissionReceipt
        SemanticKey PayloadDigest ProvenanceIdentity TrustDomain
        LocalPolicyIdentity ReceiptIdentity) :
    ∃ policy : LocalPolicyIdentity,
      policy = receipt.localPolicyIdentity := by
  exact ⟨receipt.localPolicyIdentity, rfl⟩

end PooFlowProof.PooC3.DistributedCacheAdmission
