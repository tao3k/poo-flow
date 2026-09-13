import PooFlowProof.PooC3.ModuleSemanticGraphSeparation

namespace PooFlowProof.PooC3.ExplicitRequirementResolution

inductive ResolutionOutcomeKind where
  | exactContribution
  | aggregatedContributions
  | admittedAbsence
  | missing
  | incomplete
  | ambiguous
  | incompatible
  deriving DecidableEq, Repr

def AdmitsSemanticResolution : ResolutionOutcomeKind → Prop
  | .exactContribution => True
  | .aggregatedContributions => True
  | .admittedAbsence => True
  | .missing => False
  | .incomplete => False
  | .ambiguous => False
  | .incompatible => False

structure SemanticRequirement
    (RequirementIdentity ContractIdentity ScopeIdentity
      SelectionPolicyIdentity FailurePolicyIdentity : Type) where
  requirementIdentity : RequirementIdentity
  contractIdentity : ContractIdentity
  scopeIdentity : ScopeIdentity
  selectionPolicyIdentity : SelectionPolicyIdentity
  failurePolicyIdentity : FailurePolicyIdentity
  immutableObject : Prop
  immutabilityEstablished : immutableObject

structure SemanticContribution
    (ContributionIdentity RevisionIdentity ContractIdentity ScopeIdentity
      SlotIdentity PriorityIdentity CapabilityContractIdentity : Type) where
  contributionIdentity : ContributionIdentity
  revisionIdentity : RevisionIdentity
  contractIdentity : ContractIdentity
  scopeIdentity : ScopeIdentity
  slotIdentity : SlotIdentity
  priorityIdentity : PriorityIdentity
  capabilityContractIdentity : CapabilityContractIdentity
  carriesLiveCapabilityToken : Prop
  noLiveCapabilityToken : ¬ carriesLiveCapabilityToken

structure RequirementResolutionPolicy
    (PolicyIdentity : Type) where
  policyIdentity : PolicyIdentity
  purePooObject : Prop
  purityEstablished : purePooObject
  performsRuntimeDiscovery : Prop
  noRuntimeDiscovery : ¬ performsRuntimeDiscovery
  grantsRuntimeAuthority : Prop
  noRuntimeAuthority : ¬ grantsRuntimeAuthority

structure ExplicitCandidateClosure
    (ContributionIdentity ClosureIdentity : Type) where
  candidates : List ContributionIdentity
  closureIdentity : ClosureIdentity
  readsLoadedModuleState : Prop
  noLoadedModuleDiscovery : ¬ readsLoadedModuleState
  readsFilesystemState : Prop
  noFilesystemDiscovery : ¬ readsFilesystemState
  readsGlobalRegistry : Prop
  noGlobalRegistry : ¬ readsGlobalRegistry

structure DirectionalCompatibility where
  offeredSatisfiesRequired : Prop
  requesterAcceptsRevisionAndSchema : Prop
  capabilityScopeDoesNotEscalate : Prop
  confidentialityProjectionSufficient : Prop
  lifecycleConstraintsHold : Prop
  compatibilityEstablished :
    offeredSatisfiesRequired ∧
      requesterAcceptsRevisionAndSchema ∧
      capabilityScopeDoesNotEscalate ∧
      confidentialityProjectionSufficient ∧
      lifecycleConstraintsHold

structure SlotPriorityBoundary where
  slotLocalPriority : Prop
  slotLocalEstablished : slotLocalPriority
  globalProfilePriority : Prop
  noGlobalProfilePriority : ¬ globalProfilePriority
  operandOrderSelectsWinner : Prop
  noOperandOrderWinner : ¬ operandOrderSelectsWinner

structure StructuralResolution where
  topologyDependsOnLiveValue : Prop
  noLiveValueTopology : ¬ topologyDependsOnLiveValue

structure CyclicRequirementResolution
    (RequirementIdentity ComponentIdentity : Type) where
  requirements : List RequirementIdentity
  componentIdentity : ComponentIdentity
  representedAsSemanticScc : Prop
  sccEstablished : representedAsSemanticScc

structure RequirementResolutionReceipt
    (RequesterIdentity RequirementIdentity CandidateSetIdentity
      PolicyIdentity EvidenceCutIdentity ResultIdentity ReceiptIdentity : Type)
    where
  requesterIdentity : RequesterIdentity
  requirementIdentity : RequirementIdentity
  candidateSetIdentity : CandidateSetIdentity
  policyIdentity : PolicyIdentity
  evidenceCutIdentity : EvidenceCutIdentity
  resultIdentity : ResultIdentity
  receiptIdentity : ReceiptIdentity
  identityComplete : Prop
  completenessEstablished : identityComplete

structure ResolutionCacheBoundary
    (RequirementIdentity CandidateSetIdentity PolicyIdentity
      EvidenceCutIdentity CacheIdentity : Type) where
  requirementIdentity : RequirementIdentity
  candidateSetIdentity : CandidateSetIdentity
  policyIdentity : PolicyIdentity
  evidenceCutIdentity : EvidenceCutIdentity
  cacheIdentity : CacheIdentity
  includesLoadedModuleState : Prop
  excludesLoadedModuleState : ¬ includesLoadedModuleState
  includesFilesystemState : Prop
  excludesFilesystemState : ¬ includesFilesystemState

structure ResolutionIdentityScheme
    (RequirementIdentity CandidateSetIdentity PolicyIdentity
      ResolutionIdentity : Type) where
  identity :
    RequirementIdentity →
      CandidateSetIdentity →
      PolicyIdentity →
      ResolutionIdentity
  requirementChangeChangesResolution :
    ∀ requirementA requirementB candidates policy,
      requirementA ≠ requirementB →
        identity requirementA candidates policy ≠
          identity requirementB candidates policy
  candidateSetChangeChangesResolution :
    ∀ requirement candidatesA candidatesB policy,
      candidatesA ≠ candidatesB →
        identity requirement candidatesA policy ≠
          identity requirement candidatesB policy

theorem exactContributionAdmitsResolution :
    AdmitsSemanticResolution .exactContribution := by
  simp [AdmitsSemanticResolution]

theorem aggregateAdmitsResolution :
    AdmitsSemanticResolution .aggregatedContributions := by
  simp [AdmitsSemanticResolution]

theorem admittedAbsenceAdmitsResolution :
    AdmitsSemanticResolution .admittedAbsence := by
  simp [AdmitsSemanticResolution]

theorem missingRequirementFailsClosed :
    ¬ AdmitsSemanticResolution .missing := by
  simp [AdmitsSemanticResolution]

theorem incompleteEvidenceFailsClosed :
    ¬ AdmitsSemanticResolution .incomplete := by
  simp [AdmitsSemanticResolution]

theorem ambiguousCandidatesFailClosed :
    ¬ AdmitsSemanticResolution .ambiguous := by
  simp [AdmitsSemanticResolution]

theorem requirementIsImmutablePooObject
    {RequirementIdentity ContractIdentity ScopeIdentity
      SelectionPolicyIdentity FailurePolicyIdentity : Type}
    (requirement :
      SemanticRequirement
        RequirementIdentity ContractIdentity ScopeIdentity
        SelectionPolicyIdentity FailurePolicyIdentity) :
    requirement.immutableObject :=
  requirement.immutabilityEstablished

theorem contributionCarriesNoLiveCapabilityToken
    {ContributionIdentity RevisionIdentity ContractIdentity ScopeIdentity
      SlotIdentity PriorityIdentity CapabilityContractIdentity : Type}
    (contribution :
      SemanticContribution
        ContributionIdentity RevisionIdentity ContractIdentity ScopeIdentity
        SlotIdentity PriorityIdentity CapabilityContractIdentity) :
    ¬ contribution.carriesLiveCapabilityToken :=
  contribution.noLiveCapabilityToken

theorem resolutionPolicyIsPurePooObject
    {PolicyIdentity : Type}
    (policy : RequirementResolutionPolicy PolicyIdentity) :
    policy.purePooObject :=
  policy.purityEstablished

theorem resolutionPolicyPerformsNoRuntimeDiscovery
    {PolicyIdentity : Type}
    (policy : RequirementResolutionPolicy PolicyIdentity) :
    ¬ policy.performsRuntimeDiscovery :=
  policy.noRuntimeDiscovery

theorem resolutionPolicyGrantsNoRuntimeAuthority
    {PolicyIdentity : Type}
    (policy : RequirementResolutionPolicy PolicyIdentity) :
    ¬ policy.grantsRuntimeAuthority :=
  policy.noRuntimeAuthority

theorem candidateClosureReadsNoLoadedModuleState
    {ContributionIdentity ClosureIdentity : Type}
    (closure :
      ExplicitCandidateClosure
        ContributionIdentity ClosureIdentity) :
    ¬ closure.readsLoadedModuleState :=
  closure.noLoadedModuleDiscovery

theorem candidateClosureReadsNoFilesystemState
    {ContributionIdentity ClosureIdentity : Type}
    (closure :
      ExplicitCandidateClosure
        ContributionIdentity ClosureIdentity) :
    ¬ closure.readsFilesystemState :=
  closure.noFilesystemDiscovery

theorem candidateClosureReadsNoGlobalRegistry
    {ContributionIdentity ClosureIdentity : Type}
    (closure :
      ExplicitCandidateClosure
        ContributionIdentity ClosureIdentity) :
    ¬ closure.readsGlobalRegistry :=
  closure.noGlobalRegistry

theorem compatibilityDirectionIsContributionToRequirement
    (compatibility : DirectionalCompatibility) :
    compatibility.offeredSatisfiesRequired :=
  compatibility.compatibilityEstablished.1

theorem compatibilityPreventsCapabilityEscalation
    (compatibility : DirectionalCompatibility) :
    compatibility.capabilityScopeDoesNotEscalate :=
  compatibility.compatibilityEstablished.2.2.1

theorem priorityRemainsSlotLocal
    (boundary : SlotPriorityBoundary) :
    boundary.slotLocalPriority :=
  boundary.slotLocalEstablished

theorem globalProfilePriorityIsRejected
    (boundary : SlotPriorityBoundary) :
    ¬ boundary.globalProfilePriority :=
  boundary.noGlobalProfilePriority

theorem operandOrderCannotSelectWinner
    (boundary : SlotPriorityBoundary) :
    ¬ boundary.operandOrderSelectsWinner :=
  boundary.noOperandOrderWinner

theorem structuralTopologyReadsNoLiveValue
    (resolution : StructuralResolution) :
    ¬ resolution.topologyDependsOnLiveValue :=
  resolution.noLiveValueTopology

theorem cyclicRequirementsBecomeSemanticScc
    {RequirementIdentity ComponentIdentity : Type}
    (cycle :
      CyclicRequirementResolution
        RequirementIdentity ComponentIdentity) :
    cycle.representedAsSemanticScc :=
  cycle.sccEstablished

theorem resolutionReceiptIsIdentityComplete
    {RequesterIdentity RequirementIdentity CandidateSetIdentity
      PolicyIdentity EvidenceCutIdentity ResultIdentity ReceiptIdentity : Type}
    (receipt :
      RequirementResolutionReceipt
        RequesterIdentity RequirementIdentity CandidateSetIdentity
        PolicyIdentity EvidenceCutIdentity ResultIdentity ReceiptIdentity) :
    receipt.identityComplete :=
  receipt.completenessEstablished

theorem cacheExcludesLoadedModuleState
    {RequirementIdentity CandidateSetIdentity PolicyIdentity
      EvidenceCutIdentity CacheIdentity : Type}
    (cache :
      ResolutionCacheBoundary
        RequirementIdentity CandidateSetIdentity PolicyIdentity
        EvidenceCutIdentity CacheIdentity) :
    ¬ cache.includesLoadedModuleState :=
  cache.excludesLoadedModuleState

theorem cacheExcludesFilesystemState
    {RequirementIdentity CandidateSetIdentity PolicyIdentity
      EvidenceCutIdentity CacheIdentity : Type}
    (cache :
      ResolutionCacheBoundary
        RequirementIdentity CandidateSetIdentity PolicyIdentity
        EvidenceCutIdentity CacheIdentity) :
    ¬ cache.includesFilesystemState :=
  cache.excludesFilesystemState

theorem requirementChangeCreatesNewResolutionIdentity
    {RequirementIdentity CandidateSetIdentity PolicyIdentity
      ResolutionIdentity : Type}
    (scheme :
      ResolutionIdentityScheme
        RequirementIdentity CandidateSetIdentity PolicyIdentity
        ResolutionIdentity)
    (requirementA requirementB : RequirementIdentity)
    (candidates : CandidateSetIdentity)
    (policy : PolicyIdentity)
    (changed : requirementA ≠ requirementB) :
    scheme.identity requirementA candidates policy ≠
      scheme.identity requirementB candidates policy :=
  scheme.requirementChangeChangesResolution
    requirementA requirementB candidates policy changed

theorem candidateSetChangeCreatesNewResolutionIdentity
    {RequirementIdentity CandidateSetIdentity PolicyIdentity
      ResolutionIdentity : Type}
    (scheme :
      ResolutionIdentityScheme
        RequirementIdentity CandidateSetIdentity PolicyIdentity
        ResolutionIdentity)
    (requirement : RequirementIdentity)
    (candidatesA candidatesB : CandidateSetIdentity)
    (policy : PolicyIdentity)
    (changed : candidatesA ≠ candidatesB) :
    scheme.identity requirement candidatesA policy ≠
      scheme.identity requirement candidatesB policy :=
  scheme.candidateSetChangeChangesResolution
    requirement candidatesA candidatesB policy changed

end PooFlowProof.PooC3.ExplicitRequirementResolution
