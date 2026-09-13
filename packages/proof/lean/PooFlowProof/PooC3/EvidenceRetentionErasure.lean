import PooFlowProof.PooC3.GovernanceDecisionAuthority

namespace PooFlowProof.PooC3.EvidenceRetentionErasure

open PooFlowProof.PooC3.GovernanceDecisionAuthority

inductive RetentionOutcomeKind where
  | retained
  | redactedProjection
  | checkpointCompacted
  | erasureCandidate
  | erased
  | suspended
  deriving DecidableEq, Repr

def MutatesLogicalHistory : RetentionOutcomeKind → Prop
  | .retained => False
  | .redactedProjection => False
  | .checkpointCompacted => False
  | .erasureCandidate => False
  | .erased => False
  | .suspended => False

def CarriesDestructiveAuthority : RetentionOutcomeKind → Prop
  | .retained => False
  | .redactedProjection => False
  | .checkpointCompacted => False
  | .erasureCandidate => False
  | .erased => False
  | .suspended => False

structure CanonicalReceiptHeader
    (EvidenceIdentity SchemaIdentity CommitmentIdentity : Type) where
  evidenceIdentity : EvidenceIdentity
  schemaIdentity : SchemaIdentity
  contentCommitment : CommitmentIdentity
  immutableHistory : Prop
  immutabilityEstablished : immutableHistory

structure ErasureAdmissionChecks where
  retentionWindowExpired : Prop
  noLegalHold : Prop
  checkpointCoverageEstablished : Prop
  replayRequirementsPreserved : Prop
  referenceClosureEstablished : Prop
  governanceCapabilityValid : Prop
  replicaPlanComplete : Prop

def ErasureChecksHold (checks : ErasureAdmissionChecks) : Prop :=
  checks.retentionWindowExpired ∧
    checks.noLegalHold ∧
    checks.checkpointCoverageEstablished ∧
    checks.replayRequirementsPreserved ∧
    checks.referenceClosureEstablished ∧
    checks.governanceCapabilityValid ∧
    checks.replicaPlanComplete

structure ErasureAdmissionReceipt
    (EvidenceIdentity PolicyIdentity ObservationIdentity ReceiptIdentity : Type)
    where
  evidenceIdentity : EvidenceIdentity
  policyIdentity : PolicyIdentity
  observationIdentity : ObservationIdentity
  checks : ErasureAdmissionChecks
  checksHold : ErasureChecksHold checks
  receiptIdentity : ReceiptIdentity

structure DisclosureProjection
    (EvidenceIdentity ProjectionIdentity CommitmentIdentity : Type) where
  sourceEvidenceIdentity : EvidenceIdentity
  projectionIdentity : ProjectionIdentity
  sourceCommitment : CommitmentIdentity
  commitmentPreserved : Prop
  preservationEstablished : commitmentPreserved
  claimsPhysicalErasure : Prop
  noErasureClaim : ¬ claimsPhysicalErasure

structure CheckpointCoverage
    (CheckpointIdentity EvidenceRangeIdentity ReplayContractIdentity : Type)
    where
  checkpointIdentity : CheckpointIdentity
  coveredEvidenceRange : EvidenceRangeIdentity
  replayContractIdentity : ReplayContractIdentity
  coverageEstablished : Prop
  coverageProof : coverageEstablished
  replayPreserved : Prop
  replayProof : replayPreserved

structure LegalHoldObservation
    (EvidenceIdentity HoldIdentity : Type) where
  evidenceIdentity : EvidenceIdentity
  holdIdentity : HoldIdentity
  holdActive : Prop
  activeEstablished : holdActive
  erasureAllowed : Prop
  activeHoldPreventsErasure : ¬ erasureAllowed

structure ReferenceClosureEvidence
    (EvidenceIdentity ReferenceIdentity : Type) where
  evidenceIdentity : EvidenceIdentity
  outstandingReferences : List ReferenceIdentity
  noOutstandingReferences : outstandingReferences = []

structure PhysicalErasureReceipt
    (EvidenceIdentity KeyIdentity ReplicaIdentity ReceiptIdentity : Type) where
  evidenceIdentity : EvidenceIdentity
  destroyedKey : KeyIdentity
  purgedReplicas : List ReplicaIdentity
  requiredReplicas : List ReplicaIdentity
  everyRequiredReplicaPurged :
    ∀ replica ∈ requiredReplicas,
      replica ∈ purgedReplicas
  payloadUnavailable : Prop
  unavailabilityEstablished : payloadUnavailable
  logicalHeaderPreserved : Prop
  headerPreservationEstablished : logicalHeaderPreserved
  receiptIdentity : ReceiptIdentity

structure GovernedErasureAuthorization
    (ProposalIdentity ScopeIdentity ActionRole CapabilityIdentity : Type) where
  capability :
    OneShotScopedCapability
      ProposalIdentity ScopeIdentity ActionRole CapabilityIdentity

structure RetentionIdentityScheme
    (EvidenceIdentity PolicyIdentity ObservationIdentity DecisionIdentity : Type)
    where
  identity :
    EvidenceIdentity →
      PolicyIdentity →
      ObservationIdentity →
      DecisionIdentity
  policyChangeChangesDecision :
    ∀ evidence policyA policyB observation,
      policyA ≠ policyB →
        identity evidence policyA observation ≠
          identity evidence policyB observation
  observationChangeChangesDecision :
    ∀ evidence policy observationA observationB,
      observationA ≠ observationB →
        identity evidence policy observationA ≠
          identity evidence policy observationB

theorem retentionNeverRewritesLogicalHistory
    (outcome : RetentionOutcomeKind) :
    ¬ MutatesLogicalHistory outcome := by
  cases outcome <;> simp [MutatesLogicalHistory]

theorem retentionProposalCarriesNoDestructiveAuthority
    (outcome : RetentionOutcomeKind) :
    ¬ CarriesDestructiveAuthority outcome := by
  cases outcome <;> simp [CarriesDestructiveAuthority]

theorem canonicalHeaderRemainsImmutable
    {EvidenceIdentity SchemaIdentity CommitmentIdentity : Type}
    (header :
      CanonicalReceiptHeader
        EvidenceIdentity SchemaIdentity CommitmentIdentity) :
    header.immutableHistory :=
  header.immutabilityEstablished

theorem erasureAdmissionCarriesEveryCheck
    {EvidenceIdentity PolicyIdentity ObservationIdentity ReceiptIdentity : Type}
    (receipt :
      ErasureAdmissionReceipt
        EvidenceIdentity PolicyIdentity ObservationIdentity ReceiptIdentity) :
    ErasureChecksHold receipt.checks :=
  receipt.checksHold

theorem redactionPreservesSourceCommitment
    {EvidenceIdentity ProjectionIdentity CommitmentIdentity : Type}
    (projection :
      DisclosureProjection
        EvidenceIdentity ProjectionIdentity CommitmentIdentity) :
    projection.commitmentPreserved :=
  projection.preservationEstablished

theorem redactionDoesNotClaimPhysicalErasure
    {EvidenceIdentity ProjectionIdentity CommitmentIdentity : Type}
    (projection :
      DisclosureProjection
        EvidenceIdentity ProjectionIdentity CommitmentIdentity) :
    ¬ projection.claimsPhysicalErasure :=
  projection.noErasureClaim

theorem checkpointCarriesCoverage
    {CheckpointIdentity EvidenceRangeIdentity ReplayContractIdentity : Type}
    (checkpoint :
      CheckpointCoverage
        CheckpointIdentity EvidenceRangeIdentity ReplayContractIdentity) :
    checkpoint.coverageEstablished :=
  checkpoint.coverageProof

theorem checkpointPreservesReplayContract
    {CheckpointIdentity EvidenceRangeIdentity ReplayContractIdentity : Type}
    (checkpoint :
      CheckpointCoverage
        CheckpointIdentity EvidenceRangeIdentity ReplayContractIdentity) :
    checkpoint.replayPreserved :=
  checkpoint.replayProof

theorem activeLegalHoldPreventsErasure
    {EvidenceIdentity HoldIdentity : Type}
    (hold : LegalHoldObservation EvidenceIdentity HoldIdentity) :
    ¬ hold.erasureAllowed :=
  hold.activeHoldPreventsErasure

theorem referenceClosureHasNoOutstandingReferences
    {EvidenceIdentity ReferenceIdentity : Type}
    (closure :
      ReferenceClosureEvidence EvidenceIdentity ReferenceIdentity) :
    closure.outstandingReferences = [] :=
  closure.noOutstandingReferences

theorem erasurePurgesEveryRequiredReplica
    {EvidenceIdentity KeyIdentity ReplicaIdentity ReceiptIdentity : Type}
    (receipt :
      PhysicalErasureReceipt
        EvidenceIdentity KeyIdentity ReplicaIdentity ReceiptIdentity) :
    ∀ replica ∈ receipt.requiredReplicas,
      replica ∈ receipt.purgedReplicas :=
  receipt.everyRequiredReplicaPurged

theorem erasureEstablishesPayloadUnavailability
    {EvidenceIdentity KeyIdentity ReplicaIdentity ReceiptIdentity : Type}
    (receipt :
      PhysicalErasureReceipt
        EvidenceIdentity KeyIdentity ReplicaIdentity ReceiptIdentity) :
    receipt.payloadUnavailable :=
  receipt.unavailabilityEstablished

theorem erasurePreservesLogicalHeader
    {EvidenceIdentity KeyIdentity ReplicaIdentity ReceiptIdentity : Type}
    (receipt :
      PhysicalErasureReceipt
        EvidenceIdentity KeyIdentity ReplicaIdentity ReceiptIdentity) :
    receipt.logicalHeaderPreserved :=
  receipt.headerPreservationEstablished

theorem governedErasureCapabilityIsAtMostOnce
    {ProposalIdentity ScopeIdentity ActionRole CapabilityIdentity : Type}
    (authorization :
      GovernedErasureAuthorization
        ProposalIdentity ScopeIdentity ActionRole CapabilityIdentity) :
    authorization.capability.consumptionCount ≤ 1 :=
  authorization.capability.atMostOnce

theorem retentionPolicyChangeCreatesNewDecisionIdentity
    {EvidenceIdentity PolicyIdentity ObservationIdentity DecisionIdentity : Type}
    (scheme :
      RetentionIdentityScheme
        EvidenceIdentity PolicyIdentity ObservationIdentity DecisionIdentity)
    (evidence : EvidenceIdentity)
    (policyA policyB : PolicyIdentity)
    (observation : ObservationIdentity)
    (changed : policyA ≠ policyB) :
    scheme.identity evidence policyA observation ≠
      scheme.identity evidence policyB observation :=
  scheme.policyChangeChangesDecision
    evidence policyA policyB observation changed

theorem retentionObservationChangeCreatesNewDecisionIdentity
    {EvidenceIdentity PolicyIdentity ObservationIdentity DecisionIdentity : Type}
    (scheme :
      RetentionIdentityScheme
        EvidenceIdentity PolicyIdentity ObservationIdentity DecisionIdentity)
    (evidence : EvidenceIdentity)
    (policy : PolicyIdentity)
    (observationA observationB : ObservationIdentity)
    (changed : observationA ≠ observationB) :
    scheme.identity evidence policy observationA ≠
      scheme.identity evidence policy observationB :=
  scheme.observationChangeChangesDecision
    evidence policy observationA observationB changed

end PooFlowProof.PooC3.EvidenceRetentionErasure
