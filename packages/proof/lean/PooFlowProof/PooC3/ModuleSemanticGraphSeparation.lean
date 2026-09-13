import PooFlowProof.PooC3.NamespaceSeparation

namespace PooFlowProof.PooC3.ModuleSemanticGraphSeparation

inductive GraphRole where
  | gerbilModuleImport
  | pooSemanticDefinition
  deriving DecidableEq, Repr

def SupportsLazySemanticFixedPoint : GraphRole → Prop
  | .pooSemanticDefinition => True
  | .gerbilModuleImport => False

inductive GraphEdgeRole where
  | gerbilModuleImportEdge
  | profileSemanticRequirementEdge
  deriving DecidableEq, Repr

def IsLexicalCodeDependency : GraphEdgeRole → Prop
  | .gerbilModuleImportEdge => True
  | .profileSemanticRequirementEdge => False

def IsSemanticRequirement : GraphEdgeRole → Prop
  | .profileSemanticRequirementEdge => True
  | .gerbilModuleImportEdge => False

structure GerbilModuleGraph
    (GraphIdentity ModuleIdentity EdgeIdentity PhaseIdentity : Type) where
  graphIdentity : GraphIdentity
  modules : List ModuleIdentity
  importEdges : List EdgeIdentity
  phases : List PhaseIdentity
  ownsExpansionAndLoading : Prop
  ownershipEstablished : ownsExpansionAndLoading

structure PooSemanticGraph
    (GraphIdentity ProfileIdentity EdgeIdentity ComponentIdentity : Type) where
  graphIdentity : GraphIdentity
  profiles : List ProfileIdentity
  semanticEdges : List EdgeIdentity
  stronglyConnectedComponents : List ComponentIdentity
  ownsSemanticFixedPoint : Prop
  ownershipEstablished : ownsSemanticFixedPoint

structure SemanticGraphConstructionReceipt
    (ModuleGraphIdentity SemanticGraphIdentity ReceiptIdentity : Type) where
  moduleGraphIdentity : ModuleGraphIdentity
  semanticGraphIdentity : SemanticGraphIdentity
  requiredModulesLoaded : Prop
  modulesLoadedEstablished : requiredModulesLoaded
  composeProfilesInvoked : Prop
  composeInvocationEstablished : composeProfilesInvoked
  receiptIdentity : ReceiptIdentity

structure CrossProfileDependencyBoundary
    (ModuleEdgeIdentity SemanticEdgeIdentity : Type) where
  moduleImportEdgeIdentity : ModuleEdgeIdentity
  semanticRequirementEdgeIdentity : SemanticEdgeIdentity
  moduleImportCreatesSemanticRequirement : Prop
  noImplicitSemanticRequirement :
    ¬ moduleImportCreatesSemanticRequirement
  semanticRequirementCreatesModuleImport : Prop
  noImplicitModuleImport :
    ¬ semanticRequirementCreatesModuleImport

structure ModuleSystemOwnershipBoundary where
  pooFlowLoadsGerbilModules : Prop
  pooFlowOwnsMacroPhases : Prop
  pooFlowResolvesCircularModuleInitialization : Prop
  ownershipBoundary :
    ¬ pooFlowLoadsGerbilModules ∧
      ¬ pooFlowOwnsMacroPhases ∧
      ¬ pooFlowResolvesCircularModuleInitialization

inductive GraphFailureKind where
  | missingModuleImport
  | macroPhaseFailure
  | circularModuleInitialization
  | missingSemanticRequirement
  | capabilityRequirementFailure
  | semanticFixedPointDivergence
  deriving DecidableEq, Repr

def OwnedByGerbilModuleGraph : GraphFailureKind → Prop
  | .missingModuleImport => True
  | .macroPhaseFailure => True
  | .circularModuleInitialization => True
  | .missingSemanticRequirement => False
  | .capabilityRequirementFailure => False
  | .semanticFixedPointDivergence => False

def OwnedByPooSemanticGraph : GraphFailureKind → Prop
  | .missingModuleImport => False
  | .macroPhaseFailure => False
  | .circularModuleInitialization => False
  | .missingSemanticRequirement => True
  | .capabilityRequirementFailure => True
  | .semanticFixedPointDivergence => True

structure DistinctGraphIdentities
    (ModuleGraphIdentity SemanticGraphIdentity : Type) where
  moduleGraphIdentity : ModuleGraphIdentity
  semanticGraphIdentity : SemanticGraphIdentity
  identitiesConflated : Prop
  identitiesSeparated : ¬ identitiesConflated

structure SemanticGraphIdentityScheme
    (ProfileSetIdentity PolicyIdentity SemanticGraphIdentity : Type) where
  identity :
    ProfileSetIdentity → PolicyIdentity → SemanticGraphIdentity
  profileSetChangeChangesGraph :
    ∀ profilesA profilesB policy,
      profilesA ≠ profilesB →
        identity profilesA policy ≠ identity profilesB policy
  policyChangeChangesGraph :
    ∀ profiles policyA policyB,
      policyA ≠ policyB →
        identity profiles policyA ≠ identity profiles policyB

theorem moduleGraphDoesNotSupportLazySemanticFixedPoint :
    ¬ SupportsLazySemanticFixedPoint .gerbilModuleImport := by
  simp [SupportsLazySemanticFixedPoint]

theorem semanticGraphSupportsLazyFixedPoint :
    SupportsLazySemanticFixedPoint .pooSemanticDefinition := by
  simp [SupportsLazySemanticFixedPoint]

theorem moduleImportEdgeIsLexicalDependency :
    IsLexicalCodeDependency .gerbilModuleImportEdge := by
  simp [IsLexicalCodeDependency]

theorem semanticRequirementEdgeIsNotLexicalDependency :
    ¬ IsLexicalCodeDependency .profileSemanticRequirementEdge := by
  simp [IsLexicalCodeDependency]

theorem semanticRequirementEdgeIsSemantic :
    IsSemanticRequirement .profileSemanticRequirementEdge := by
  simp [IsSemanticRequirement]

theorem moduleImportEdgeIsNotSemanticRequirement :
    ¬ IsSemanticRequirement .gerbilModuleImportEdge := by
  simp [IsSemanticRequirement]

theorem moduleGraphOwnsExpansionAndLoading
    {GraphIdentity ModuleIdentity EdgeIdentity PhaseIdentity : Type}
    (graph :
      GerbilModuleGraph
        GraphIdentity ModuleIdentity EdgeIdentity PhaseIdentity) :
    graph.ownsExpansionAndLoading :=
  graph.ownershipEstablished

theorem semanticGraphOwnsFixedPoint
    {GraphIdentity ProfileIdentity EdgeIdentity ComponentIdentity : Type}
    (graph :
      PooSemanticGraph
        GraphIdentity ProfileIdentity EdgeIdentity ComponentIdentity) :
    graph.ownsSemanticFixedPoint :=
  graph.ownershipEstablished

theorem semanticGraphConstructionRequiresLoadedModules
    {ModuleGraphIdentity SemanticGraphIdentity ReceiptIdentity : Type}
    (receipt :
      SemanticGraphConstructionReceipt
        ModuleGraphIdentity SemanticGraphIdentity ReceiptIdentity) :
    receipt.requiredModulesLoaded :=
  receipt.modulesLoadedEstablished

theorem semanticGraphConstructionRequiresComposeProfiles
    {ModuleGraphIdentity SemanticGraphIdentity ReceiptIdentity : Type}
    (receipt :
      SemanticGraphConstructionReceipt
        ModuleGraphIdentity SemanticGraphIdentity ReceiptIdentity) :
    receipt.composeProfilesInvoked :=
  receipt.composeInvocationEstablished

theorem moduleImportDoesNotCreateSemanticRequirement
    {ModuleEdgeIdentity SemanticEdgeIdentity : Type}
    (boundary :
      CrossProfileDependencyBoundary
        ModuleEdgeIdentity SemanticEdgeIdentity) :
    ¬ boundary.moduleImportCreatesSemanticRequirement :=
  boundary.noImplicitSemanticRequirement

theorem semanticRequirementDoesNotCreateModuleImport
    {ModuleEdgeIdentity SemanticEdgeIdentity : Type}
    (boundary :
      CrossProfileDependencyBoundary
        ModuleEdgeIdentity SemanticEdgeIdentity) :
    ¬ boundary.semanticRequirementCreatesModuleImport :=
  boundary.noImplicitModuleImport

theorem pooFlowDoesNotLoadGerbilModules
    (boundary : ModuleSystemOwnershipBoundary) :
    ¬ boundary.pooFlowLoadsGerbilModules :=
  boundary.ownershipBoundary.1

theorem pooFlowDoesNotOwnMacroPhases
    (boundary : ModuleSystemOwnershipBoundary) :
    ¬ boundary.pooFlowOwnsMacroPhases :=
  boundary.ownershipBoundary.2.1

theorem pooFlowDoesNotResolveCircularModuleInitialization
    (boundary : ModuleSystemOwnershipBoundary) :
    ¬ boundary.pooFlowResolvesCircularModuleInitialization :=
  boundary.ownershipBoundary.2.2

theorem circularModuleFailureBelongsToGerbilGraph :
    OwnedByGerbilModuleGraph .circularModuleInitialization := by
  simp [OwnedByGerbilModuleGraph]

theorem semanticDivergenceBelongsToPooGraph :
    OwnedByPooSemanticGraph .semanticFixedPointDivergence := by
  simp [OwnedByPooSemanticGraph]

theorem graphIdentitiesRemainDistinct
    {ModuleGraphIdentity SemanticGraphIdentity : Type}
    (identities :
      DistinctGraphIdentities
        ModuleGraphIdentity SemanticGraphIdentity) :
    ¬ identities.identitiesConflated :=
  identities.identitiesSeparated

theorem profileSetChangeCreatesNewSemanticGraphIdentity
    {ProfileSetIdentity PolicyIdentity SemanticGraphIdentity : Type}
    (scheme :
      SemanticGraphIdentityScheme
        ProfileSetIdentity PolicyIdentity SemanticGraphIdentity)
    (profilesA profilesB : ProfileSetIdentity)
    (policy : PolicyIdentity)
    (changed : profilesA ≠ profilesB) :
    scheme.identity profilesA policy ≠ scheme.identity profilesB policy :=
  scheme.profileSetChangeChangesGraph
    profilesA profilesB policy changed

theorem semanticPolicyChangeCreatesNewGraphIdentity
    {ProfileSetIdentity PolicyIdentity SemanticGraphIdentity : Type}
    (scheme :
      SemanticGraphIdentityScheme
        ProfileSetIdentity PolicyIdentity SemanticGraphIdentity)
    (profiles : ProfileSetIdentity)
    (policyA policyB : PolicyIdentity)
    (changed : policyA ≠ policyB) :
    scheme.identity profiles policyA ≠ scheme.identity profiles policyB :=
  scheme.policyChangeChangesGraph profiles policyA policyB changed

end PooFlowProof.PooC3.ModuleSemanticGraphSeparation
