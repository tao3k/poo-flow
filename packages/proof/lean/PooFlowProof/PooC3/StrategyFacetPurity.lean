namespace PooFlowProof.PooC3.StrategyFacetPurity

abbrev StrategyId := Nat
abbrev DefinitionRootId := Nat
abbrev ProfileId := Nat
abbrev CompositionId := Nat
abbrev SemanticSlotId := Nat
abbrev ContractId := Nat
abbrev CapabilityRequirementId := Nat

structure ConstructionFacet where
  strategyIdentity : StrategyId
  emptyIdentity : CompositionId
  structuralAdmissionDigest : Nat
  normalizationDigest : Nat
  definitionRoot : DefinitionRootId
deriving Repr, DecidableEq

structure DemandResolutionFacet where
  slotIdentity : SemanticSlotId
  contractIdentity : ContractId
  capabilityRequirement : CapabilityRequirementId
  priority : Nat
  admissionPolicyDigest : Nat
  combinationPolicyDigest : Nat
  dependencyExpansionDigest : Nat
deriving Repr, DecidableEq

structure EvidenceFacet where
  semanticIdentityDigest : Nat
  contributionDigest : Nat
  conflictDigest : Nat
  dependencyDigest : Nat
deriving Repr, DecidableEq

structure PureStrategyProjection where
  construction : ConstructionFacet
  demandResolution : DemandResolutionFacet
  evidence : EvidenceFacet
deriving Repr, DecidableEq

inductive CompositionOperand where
  | profile (identity : ProfileId)
  | anchoredRoot (identity : DefinitionRootId)
  | nestedComposition (identity : CompositionId)
deriving Repr, DecidableEq

structure PureComposition where
  identity : CompositionId
  strategy : PureStrategyProjection
  operands : List CompositionOperand
deriving Repr, DecidableEq

structure LiveEvaluationContext where
  capabilityTokenDigest : Nat
  cacheSnapshotDigest : Nat
  clockEpoch : Nat
  workerIdentity : Nat
  runtimeGeneration : Nat
deriving Repr, DecidableEq

structure DemandRequest where
  composition : PureComposition
  slot : SemanticSlotId
  context : LiveEvaluationContext
deriving Repr, DecidableEq

def construct
    (identity : CompositionId)
    (strategy : PureStrategyProjection)
    (operands : List CompositionOperand) :
    PureComposition :=
  { identity := identity
    strategy := strategy
    operands := operands }

def demand
    (composition : PureComposition)
    (slot : SemanticSlotId)
    (context : LiveEvaluationContext) :
    DemandRequest :=
  { composition := composition
    slot := slot
    context := context }

theorem constructionRetainsOnlyPureProjection
    (identity : CompositionId)
    (strategy : PureStrategyProjection)
    (operands : List CompositionOperand) :
    (construct identity strategy operands).strategy = strategy ∧
      (construct identity strategy operands).operands = operands := by
  exact ⟨rfl, rfl⟩

theorem constructionIndependentOfLiveContext
    (identity : CompositionId)
    (strategy : PureStrategyProjection)
    (operands : List CompositionOperand)
    (leftContext rightContext : LiveEvaluationContext) :
    (fun _ : LiveEvaluationContext =>
      construct identity strategy operands) leftContext =
    (fun _ : LiveEvaluationContext =>
      construct identity strategy operands) rightContext := by
  rfl

theorem liveContextIsExternalToPureComposition
    (composition : PureComposition)
    (slot : SemanticSlotId)
    (context : LiveEvaluationContext) :
    (demand composition slot context).composition = composition ∧
      (demand composition slot context).context = context := by
  exact ⟨rfl, rfl⟩

theorem changingLiveContextCannotChangePureComposition
    (composition : PureComposition)
    (slot : SemanticSlotId)
    (leftContext rightContext : LiveEvaluationContext) :
    (demand composition slot leftContext).composition =
      (demand composition slot rightContext).composition := by
  rfl

end PooFlowProof.PooC3.StrategyFacetPurity
