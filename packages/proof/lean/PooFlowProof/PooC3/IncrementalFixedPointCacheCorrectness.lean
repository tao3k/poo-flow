import PooFlowProof.PooC3.GraphCompatibilityClosure

namespace PooFlowProof.PooC3.IncrementalFixedPointCacheCorrectness

open PooFlowProof.PooC3.GraphCompatibilityClosure

inductive CacheReuseKind where
  | exactIdentityFresh
  | identityMismatch
  | staleEvidence
  | incompleteExecution
  | suspended
  deriving DecidableEq, Repr

def AdmitsSemanticReuse : CacheReuseKind → Prop
  | .exactIdentityFresh => True
  | .identityMismatch => False
  | .staleEvidence => False
  | .incompleteExecution => False
  | .suspended => False

def IsPublishedSemanticResult : CacheReuseKind → Prop
  | .exactIdentityFresh => True
  | .identityMismatch => False
  | .staleEvidence => False
  | .incompleteExecution => False
  | .suspended => False

structure CacheIdentityScheme
    (InputIdentity DependencyIdentity ObservationCut PolicyIdentity
      CacheIdentity : Type) where
  identity :
    InputIdentity →
      DependencyIdentity →
      ObservationCut →
      PolicyIdentity →
      CacheIdentity
  inputChangeChangesIdentity :
    ∀ inputA inputB dependency cut policy,
      inputA ≠ inputB →
        identity inputA dependency cut policy ≠
          identity inputB dependency cut policy
  dependencyChangeChangesIdentity :
    ∀ input dependencyA dependencyB cut policy,
      dependencyA ≠ dependencyB →
        identity input dependencyA cut policy ≠
          identity input dependencyB cut policy
  cutChangeChangesIdentity :
    ∀ input dependency cutA cutB policy,
      cutA ≠ cutB →
        identity input dependency cutA policy ≠
          identity input dependency cutB policy
  policyChangeChangesIdentity :
    ∀ input dependency cut policyA policyB,
      policyA ≠ policyB →
        identity input dependency cut policyA ≠
          identity input dependency cut policyB

structure IncrementalReevaluationPlan
    (InputIdentity Node ComponentIdentity : Type) where
  changedInputs : List InputIdentity
  reachableDemandFrontier : List Node
  affectedComponents : List (ComponentIdentity × List Node)
  inputReachesNode : InputIdentity → Node → Prop
  everyReachableDependentScheduled :
    ∀ input ∈ changedInputs,
      ∀ node,
        inputReachesNode input node →
          node ∈ reachableDemandFrontier
  everyFrontierNodeHasAffectedComponent :
    ∀ node ∈ reachableDemandFrontier,
      ∃ component ∈ affectedComponents,
        node ∈ component.2

structure SCCReevaluationUnit (Node ComponentIdentity : Type) where
  componentIdentity : ComponentIdentity
  nodes : List Node
  scheduledNodes : List Node
  schedulesWholeComponent : scheduledNodes = nodes
  partialCommit : Prop
  noPartialCommit : ¬ partialCommit

structure EvaluationSuspension
    (InputIdentity ContinuationIdentity ObservationCut : Type) where
  inputIdentity : InputIdentity
  continuationIdentity : ContinuationIdentity
  observationCut : ObservationCut
  incompleteResultAdmitted : Prop
  incompleteResultNotAdmitted : ¬ incompleteResultAdmitted

structure GraphCompatibleCacheEntry
    (Root Node Revision Edge ObservationCut Policy CutIdentity
      ComponentIdentity StateVersion EvidenceIdentity ProofIdentity
      CacheIdentity Value : Type) where
  closure :
    GraphCompatibilityProof
      Root Node Revision Edge ObservationCut Policy CutIdentity
      ComponentIdentity StateVersion EvidenceIdentity ProofIdentity
  cacheIdentity : CacheIdentity
  value : Value
  freshnessContract : Prop
  freshnessHolds : freshnessContract

theorem identityMismatchDoesNotAdmitSemanticReuse :
    ¬ AdmitsSemanticReuse .identityMismatch := by
  simp [AdmitsSemanticReuse]

theorem staleEvidenceDoesNotAdmitSemanticReuse :
    ¬ AdmitsSemanticReuse .staleEvidence := by
  simp [AdmitsSemanticReuse]

theorem incompleteExecutionDoesNotAdmitSemanticReuse :
    ¬ AdmitsSemanticReuse .incompleteExecution := by
  simp [AdmitsSemanticReuse]

theorem suspensionDoesNotAdmitSemanticReuse :
    ¬ AdmitsSemanticReuse .suspended := by
  simp [AdmitsSemanticReuse]

theorem exactFreshIdentityAdmitsSemanticReuse :
    AdmitsSemanticReuse .exactIdentityFresh := by
  simp [AdmitsSemanticReuse]

theorem incompleteExecutionIsNotPublishedSemanticResult :
    ¬ IsPublishedSemanticResult .incompleteExecution := by
  simp [IsPublishedSemanticResult]

theorem changedInputReevaluatesReachableFrontier
    {InputIdentity Node ComponentIdentity : Type}
    (plan :
      IncrementalReevaluationPlan
        InputIdentity Node ComponentIdentity) :
    ∀ input ∈ plan.changedInputs,
      ∀ node,
        plan.inputReachesNode input node →
          node ∈ plan.reachableDemandFrontier :=
  plan.everyReachableDependentScheduled

theorem frontierNodeSchedulesAffectedSCC
    {InputIdentity Node ComponentIdentity : Type}
    (plan :
      IncrementalReevaluationPlan
        InputIdentity Node ComponentIdentity) :
    ∀ node ∈ plan.reachableDemandFrontier,
      ∃ component ∈ plan.affectedComponents,
        node ∈ component.2 :=
  plan.everyFrontierNodeHasAffectedComponent

theorem affectedSCCReevaluatesAsWholeUnit
    {Node ComponentIdentity : Type}
    (unit : SCCReevaluationUnit Node ComponentIdentity) :
    unit.scheduledNodes = unit.nodes :=
  unit.schedulesWholeComponent

theorem affectedSCCForbidsPartialCommit
    {Node ComponentIdentity : Type}
    (unit : SCCReevaluationUnit Node ComponentIdentity) :
    ¬ unit.partialCommit :=
  unit.noPartialCommit

theorem suspensionPreservesContinuation
    {InputIdentity ContinuationIdentity ObservationCut : Type}
    (suspension :
      EvaluationSuspension
        InputIdentity ContinuationIdentity ObservationCut) :
    ∃ continuation : ContinuationIdentity,
      continuation = suspension.continuationIdentity := by
  exact ⟨suspension.continuationIdentity, rfl⟩

theorem suspensionCannotPublishIncompleteResult
    {InputIdentity ContinuationIdentity ObservationCut : Type}
    (suspension :
      EvaluationSuspension
        InputIdentity ContinuationIdentity ObservationCut) :
    ¬ suspension.incompleteResultAdmitted :=
  suspension.incompleteResultNotAdmitted

theorem admittedCacheEntryCarriesGraphClosure
    {Root Node Revision Edge ObservationCut Policy CutIdentity
      ComponentIdentity StateVersion EvidenceIdentity ProofIdentity
      CacheIdentity Value : Type}
    (entry :
      GraphCompatibleCacheEntry
        Root Node Revision Edge ObservationCut Policy CutIdentity
        ComponentIdentity StateVersion EvidenceIdentity ProofIdentity
        CacheIdentity Value) :
    ∃ proof :
        GraphCompatibilityProof
          Root Node Revision Edge ObservationCut Policy CutIdentity
          ComponentIdentity StateVersion EvidenceIdentity ProofIdentity,
      proof = entry.closure := by
  exact ⟨entry.closure, rfl⟩

theorem admittedCacheEntrySatisfiesFreshness
    {Root Node Revision Edge ObservationCut Policy CutIdentity
      ComponentIdentity StateVersion EvidenceIdentity ProofIdentity
      CacheIdentity Value : Type}
    (entry :
      GraphCompatibleCacheEntry
        Root Node Revision Edge ObservationCut Policy CutIdentity
        ComponentIdentity StateVersion EvidenceIdentity ProofIdentity
        CacheIdentity Value) :
    entry.freshnessContract :=
  entry.freshnessHolds

theorem inputChangeCreatesNewCacheIdentity
    {InputIdentity DependencyIdentity ObservationCut PolicyIdentity
      CacheIdentity : Type}
    (scheme :
      CacheIdentityScheme
        InputIdentity DependencyIdentity ObservationCut PolicyIdentity
        CacheIdentity)
    (inputA inputB : InputIdentity)
    (dependency : DependencyIdentity)
    (cut : ObservationCut)
    (policy : PolicyIdentity)
    (changed : inputA ≠ inputB) :
    scheme.identity inputA dependency cut policy ≠
      scheme.identity inputB dependency cut policy :=
  scheme.inputChangeChangesIdentity
    inputA inputB dependency cut policy changed

theorem dependencyChangeCreatesNewCacheIdentity
    {InputIdentity DependencyIdentity ObservationCut PolicyIdentity
      CacheIdentity : Type}
    (scheme :
      CacheIdentityScheme
        InputIdentity DependencyIdentity ObservationCut PolicyIdentity
        CacheIdentity)
    (input : InputIdentity)
    (dependencyA dependencyB : DependencyIdentity)
    (cut : ObservationCut)
    (policy : PolicyIdentity)
    (changed : dependencyA ≠ dependencyB) :
    scheme.identity input dependencyA cut policy ≠
      scheme.identity input dependencyB cut policy :=
  scheme.dependencyChangeChangesIdentity
    input dependencyA dependencyB cut policy changed

theorem observationCutChangeCreatesNewCacheIdentity
    {InputIdentity DependencyIdentity ObservationCut PolicyIdentity
      CacheIdentity : Type}
    (scheme :
      CacheIdentityScheme
        InputIdentity DependencyIdentity ObservationCut PolicyIdentity
        CacheIdentity)
    (input : InputIdentity)
    (dependency : DependencyIdentity)
    (cutA cutB : ObservationCut)
    (policy : PolicyIdentity)
    (changed : cutA ≠ cutB) :
    scheme.identity input dependency cutA policy ≠
      scheme.identity input dependency cutB policy :=
  scheme.cutChangeChangesIdentity
    input dependency cutA cutB policy changed

theorem policyChangeCreatesNewCacheIdentity
    {InputIdentity DependencyIdentity ObservationCut PolicyIdentity
      CacheIdentity : Type}
    (scheme :
      CacheIdentityScheme
        InputIdentity DependencyIdentity ObservationCut PolicyIdentity
        CacheIdentity)
    (input : InputIdentity)
    (dependency : DependencyIdentity)
    (cut : ObservationCut)
    (policyA policyB : PolicyIdentity)
    (changed : policyA ≠ policyB) :
    scheme.identity input dependency cut policyA ≠
      scheme.identity input dependency cut policyB :=
  scheme.policyChangeChangesIdentity
    input dependency cut policyA policyB changed

end PooFlowProof.PooC3.IncrementalFixedPointCacheCorrectness
