import PooFlowProof.PooC3.IncrementalTruthMaintenance

namespace PooFlowProof.PooC3.GovernanceDecisionAuthority

inductive GovernanceDecisionKind where
  | candidateEvidence
  | satisfied
  | expired
  | revoked
  | invalid
  deriving DecidableEq, Repr

def MayRequestScopedCapability : GovernanceDecisionKind → Prop
  | .satisfied => True
  | .candidateEvidence => False
  | .expired => False
  | .revoked => False
  | .invalid => False

def GovernanceEvidenceCarriesActionAuthority :
    GovernanceDecisionKind → Prop
  | .candidateEvidence => False
  | .satisfied => False
  | .expired => False
  | .revoked => False
  | .invalid => False

structure GovernanceChecks where
  exactProposal : Prop
  exactEvidenceCut : Prop
  quorumSatisfied : Prop
  separationSatisfied : Prop
  scopeMatches : Prop
  versionPreconditionHolds : Prop
  policyMatches : Prop
  temporalRequirementsHold : Prop
  notRevoked : Prop

def GovernanceChecksHold (checks : GovernanceChecks) : Prop :=
  checks.exactProposal ∧
    checks.exactEvidenceCut ∧
    checks.quorumSatisfied ∧
    checks.separationSatisfied ∧
    checks.scopeMatches ∧
    checks.versionPreconditionHolds ∧
    checks.policyMatches ∧
    checks.temporalRequirementsHold ∧
    checks.notRevoked

structure GovernanceDecisionReceipt
    (ProposalIdentity EvidenceCutIdentity PolicyIdentity ScopeIdentity
      DecisionIdentity : Type) where
  proposalIdentity : ProposalIdentity
  evidenceCutIdentity : EvidenceCutIdentity
  policyIdentity : PolicyIdentity
  scopeIdentity : ScopeIdentity
  checks : GovernanceChecks
  checksHold : GovernanceChecksHold checks
  decisionIdentity : DecisionIdentity

structure QuorumEvidence (PrincipalIdentity : Type) where
  approvingPrincipals : List PrincipalIdentity
  principalsDistinct : approvingPrincipals.Nodup
  thresholdSatisfied : Prop
  thresholdEstablished : thresholdSatisfied

structure SeparationOfDuties
    (PrincipalIdentity : Type) where
  proposer : PrincipalIdentity
  approver : PrincipalIdentity
  executor : PrincipalIdentity
  proposerNotApprover : proposer ≠ approver
  approverNotExecutor : approver ≠ executor

structure OneShotScopedCapability
    (ProposalIdentity ScopeIdentity ActionRole CapabilityIdentity : Type) where
  proposalIdentity : ProposalIdentity
  scopeIdentity : ScopeIdentity
  actionRole : ActionRole
  capabilityIdentity : CapabilityIdentity
  consumptionCount : Nat
  atMostOnce : consumptionCount ≤ 1

structure CapabilityConsumptionReceipt
    (CapabilityIdentity ActionReceiptIdentity : Type) where
  capabilityIdentity : CapabilityIdentity
  actionReceiptIdentity : ActionReceiptIdentity
  consumptionCount : Nat
  consumedExactlyOnce : consumptionCount = 1

structure GovernanceRevocation
    (DecisionIdentity RevocationIdentity : Type) where
  decisionIdentity : DecisionIdentity
  revocationIdentity : RevocationIdentity
  capabilityIssuanceAllowed : Prop
  issuanceFailsClosed : ¬ capabilityIssuanceAllowed

structure BreakGlassDecision
    (ProposalIdentity ScopeIdentity PolicyIdentity TimeObservationIdentity
      ReceiptIdentity : Type) where
  proposalIdentity : ProposalIdentity
  scopeIdentity : ScopeIdentity
  policyIdentity : PolicyIdentity
  timeObservationIdentity : TimeObservationIdentity
  receiptIdentity : ReceiptIdentity
  policyAllowsBreakGlass : Prop
  policyEstablished : policyAllowsBreakGlass
  scopeIsExplicit : Prop
  scopeEstablished : scopeIsExplicit
  expiryIsExplicit : Prop
  expiryEstablished : expiryIsExplicit
  reasonRecorded : Prop
  reasonEstablished : reasonRecorded
  postActionReviewRequired : Prop
  reviewObligationEstablished : postActionReviewRequired
  carriesGlobalAuthority : Prop
  noGlobalAuthority : ¬ carriesGlobalAuthority

structure DecisionIdentityScheme
    (ProposalIdentity EvidenceCutIdentity ScopeIdentity PolicyIdentity
      DecisionIdentity : Type) where
  identity :
    ProposalIdentity →
      EvidenceCutIdentity →
      ScopeIdentity →
      PolicyIdentity →
      DecisionIdentity
  proposalChangeChangesDecision :
    ∀ proposalA proposalB cut scope policy,
      proposalA ≠ proposalB →
        identity proposalA cut scope policy ≠
          identity proposalB cut scope policy
  cutChangeChangesDecision :
    ∀ proposal cutA cutB scope policy,
      cutA ≠ cutB →
        identity proposal cutA scope policy ≠
          identity proposal cutB scope policy
  scopeChangeChangesDecision :
    ∀ proposal cut scopeA scopeB policy,
      scopeA ≠ scopeB →
        identity proposal cut scopeA policy ≠
          identity proposal cut scopeB policy
  policyChangeChangesDecision :
    ∀ proposal cut scope policyA policyB,
      policyA ≠ policyB →
        identity proposal cut scope policyA ≠
          identity proposal cut scope policyB

theorem candidateApprovalIsNotCapabilityAuthority :
    ¬ GovernanceEvidenceCarriesActionAuthority .candidateEvidence := by
  simp [GovernanceEvidenceCarriesActionAuthority]

theorem satisfiedApprovalStillIsNotActionAuthority :
    ¬ GovernanceEvidenceCarriesActionAuthority .satisfied := by
  simp [GovernanceEvidenceCarriesActionAuthority]

theorem satisfiedDecisionMayRequestScopedCapability :
    MayRequestScopedCapability .satisfied := by
  simp [MayRequestScopedCapability]

theorem expiredDecisionFailsClosed :
    ¬ MayRequestScopedCapability .expired := by
  simp [MayRequestScopedCapability]

theorem revokedDecisionFailsClosed :
    ¬ MayRequestScopedCapability .revoked := by
  simp [MayRequestScopedCapability]

theorem invalidDecisionFailsClosed :
    ¬ MayRequestScopedCapability .invalid := by
  simp [MayRequestScopedCapability]

theorem decisionReceiptCarriesAllGovernanceChecks
    {ProposalIdentity EvidenceCutIdentity PolicyIdentity ScopeIdentity
      DecisionIdentity : Type}
    (receipt :
      GovernanceDecisionReceipt
        ProposalIdentity EvidenceCutIdentity PolicyIdentity ScopeIdentity
        DecisionIdentity) :
    GovernanceChecksHold receipt.checks :=
  receipt.checksHold

theorem quorumCarriesDistinctPrincipals
    {PrincipalIdentity : Type}
    (quorum : QuorumEvidence PrincipalIdentity) :
    quorum.approvingPrincipals.Nodup :=
  quorum.principalsDistinct

theorem quorumCarriesThresholdEvidence
    {PrincipalIdentity : Type}
    (quorum : QuorumEvidence PrincipalIdentity) :
    quorum.thresholdSatisfied :=
  quorum.thresholdEstablished

theorem proposerAndApproverAreSeparated
    {PrincipalIdentity : Type}
    (separation : SeparationOfDuties PrincipalIdentity) :
    separation.proposer ≠ separation.approver :=
  separation.proposerNotApprover

theorem approverAndExecutorAreSeparated
    {PrincipalIdentity : Type}
    (separation : SeparationOfDuties PrincipalIdentity) :
    separation.approver ≠ separation.executor :=
  separation.approverNotExecutor

theorem scopedCapabilityIsAtMostOnce
    {ProposalIdentity ScopeIdentity ActionRole CapabilityIdentity : Type}
    (capability :
      OneShotScopedCapability
        ProposalIdentity ScopeIdentity ActionRole CapabilityIdentity) :
    capability.consumptionCount ≤ 1 :=
  capability.atMostOnce

theorem capabilityReceiptRecordsSingleConsumption
    {CapabilityIdentity ActionReceiptIdentity : Type}
    (receipt :
      CapabilityConsumptionReceipt
        CapabilityIdentity ActionReceiptIdentity) :
    receipt.consumptionCount = 1 :=
  receipt.consumedExactlyOnce

theorem revocationPreventsCapabilityIssuance
    {DecisionIdentity RevocationIdentity : Type}
    (revocation :
      GovernanceRevocation DecisionIdentity RevocationIdentity) :
    ¬ revocation.capabilityIssuanceAllowed :=
  revocation.issuanceFailsClosed

theorem breakGlassRequiresExplicitPolicy
    {ProposalIdentity ScopeIdentity PolicyIdentity TimeObservationIdentity
      ReceiptIdentity : Type}
    (decision :
      BreakGlassDecision
        ProposalIdentity ScopeIdentity PolicyIdentity TimeObservationIdentity
        ReceiptIdentity) :
    decision.policyAllowsBreakGlass :=
  decision.policyEstablished

theorem breakGlassRequiresExplicitScopeAndExpiry
    {ProposalIdentity ScopeIdentity PolicyIdentity TimeObservationIdentity
      ReceiptIdentity : Type}
    (decision :
      BreakGlassDecision
        ProposalIdentity ScopeIdentity PolicyIdentity TimeObservationIdentity
        ReceiptIdentity) :
    decision.scopeIsExplicit ∧ decision.expiryIsExplicit :=
  ⟨decision.scopeEstablished, decision.expiryEstablished⟩

theorem breakGlassCarriesPostActionReviewObligation
    {ProposalIdentity ScopeIdentity PolicyIdentity TimeObservationIdentity
      ReceiptIdentity : Type}
    (decision :
      BreakGlassDecision
        ProposalIdentity ScopeIdentity PolicyIdentity TimeObservationIdentity
        ReceiptIdentity) :
    decision.postActionReviewRequired :=
  decision.reviewObligationEstablished

theorem breakGlassCarriesNoGlobalAuthority
    {ProposalIdentity ScopeIdentity PolicyIdentity TimeObservationIdentity
      ReceiptIdentity : Type}
    (decision :
      BreakGlassDecision
        ProposalIdentity ScopeIdentity PolicyIdentity TimeObservationIdentity
        ReceiptIdentity) :
    ¬ decision.carriesGlobalAuthority :=
  decision.noGlobalAuthority

theorem proposalChangeCreatesNewDecisionIdentity
    {ProposalIdentity EvidenceCutIdentity ScopeIdentity PolicyIdentity
      DecisionIdentity : Type}
    (scheme :
      DecisionIdentityScheme
        ProposalIdentity EvidenceCutIdentity ScopeIdentity PolicyIdentity
        DecisionIdentity)
    (proposalA proposalB : ProposalIdentity)
    (cut : EvidenceCutIdentity)
    (scope : ScopeIdentity)
    (policy : PolicyIdentity)
    (changed : proposalA ≠ proposalB) :
    scheme.identity proposalA cut scope policy ≠
      scheme.identity proposalB cut scope policy :=
  scheme.proposalChangeChangesDecision
    proposalA proposalB cut scope policy changed

theorem evidenceCutChangeCreatesNewDecisionIdentity
    {ProposalIdentity EvidenceCutIdentity ScopeIdentity PolicyIdentity
      DecisionIdentity : Type}
    (scheme :
      DecisionIdentityScheme
        ProposalIdentity EvidenceCutIdentity ScopeIdentity PolicyIdentity
        DecisionIdentity)
    (proposal : ProposalIdentity)
    (cutA cutB : EvidenceCutIdentity)
    (scope : ScopeIdentity)
    (policy : PolicyIdentity)
    (changed : cutA ≠ cutB) :
    scheme.identity proposal cutA scope policy ≠
      scheme.identity proposal cutB scope policy :=
  scheme.cutChangeChangesDecision
    proposal cutA cutB scope policy changed

theorem scopeChangeCreatesNewDecisionIdentity
    {ProposalIdentity EvidenceCutIdentity ScopeIdentity PolicyIdentity
      DecisionIdentity : Type}
    (scheme :
      DecisionIdentityScheme
        ProposalIdentity EvidenceCutIdentity ScopeIdentity PolicyIdentity
        DecisionIdentity)
    (proposal : ProposalIdentity)
    (cut : EvidenceCutIdentity)
    (scopeA scopeB : ScopeIdentity)
    (policy : PolicyIdentity)
    (changed : scopeA ≠ scopeB) :
    scheme.identity proposal cut scopeA policy ≠
      scheme.identity proposal cut scopeB policy :=
  scheme.scopeChangeChangesDecision
    proposal cut scopeA scopeB policy changed

theorem policyChangeCreatesNewDecisionIdentity
    {ProposalIdentity EvidenceCutIdentity ScopeIdentity PolicyIdentity
      DecisionIdentity : Type}
    (scheme :
      DecisionIdentityScheme
        ProposalIdentity EvidenceCutIdentity ScopeIdentity PolicyIdentity
        DecisionIdentity)
    (proposal : ProposalIdentity)
    (cut : EvidenceCutIdentity)
    (scope : ScopeIdentity)
    (policyA policyB : PolicyIdentity)
    (changed : policyA ≠ policyB) :
    scheme.identity proposal cut scope policyA ≠
      scheme.identity proposal cut scope policyB :=
  scheme.policyChangeChangesDecision
    proposal cut scope policyA policyB changed

end PooFlowProof.PooC3.GovernanceDecisionAuthority
