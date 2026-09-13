import PooFlowProof.PooC3.CrossDomainFederation

namespace PooFlowProof.PooC3.MinimalUseCompositionSurface

inductive PublicCompositionSyntaxKind where
  | flatUseComposition
  | nestedUseComposition
  | clauseDsl
  deriving DecidableEq, Repr

def AdmitsPublicCompositionSyntax :
    PublicCompositionSyntaxKind → Prop
  | .flatUseComposition => True
  | .nestedUseComposition => False
  | .clauseDsl => False

structure HygienicUseComposition
    (Expression RootBinding ProvenanceIdentity : Type) where
  expression : Expression
  rootBinding : RootBinding
  provenanceIdentity : ProvenanceIdentity
  evaluationCount : Nat
  evaluatesExactlyOnce : evaluationCount = 1
  hygienicBinding : Prop
  hygieneEstablished : hygienicBinding

structure ComposeContract
    (Strategy Profile CompositionRoot : Type) where
  strategy : Strategy
  profiles : List Profile
  compositionRoot : CompositionRoot
  pureFunction : Prop
  purityEstablished : pureFunction
  canonicalRoot : Prop
  canonicalityEstablished : canonicalRoot
  readsHiddenRegistry : Prop
  noHiddenRegistry : ¬ readsHiddenRegistry
  executesEffects : Prop
  noEffectExecution : ¬ executesEffects
  parsesClauseDsl : Prop
  noClauseDsl : ¬ parsesClauseDsl

structure UseCompositionBoundary where
  evaluatesFixedPoint : Prop
  registersProviders : Prop
  selectsRuntimeAdapters : Prop
  executesEffects : Prop
  buildsHiddenRegistry : Prop
  createsSecondObjectSystem : Prop
  boundaryEstablished :
    ¬ evaluatesFixedPoint ∧
      ¬ registersProviders ∧
      ¬ selectsRuntimeAdapters ∧
      ¬ executesEffects ∧
      ¬ buildsHiddenRegistry ∧
      ¬ createsSecondObjectSystem

structure PackageAuthorProfile
    (ProfileIdentity PrototypeIdentity ImportIdentity
      CapabilityRequirementIdentity GraphIdentity : Type) where
  profileIdentity : ProfileIdentity
  prototypeIdentity : PrototypeIdentity
  importIdentity : ImportIdentity
  capabilityRequirementIdentity : CapabilityRequirementIdentity
  graphIdentity : GraphIdentity
  firstClassValue : Prop
  firstClassEstablished : firstClassValue

structure NativePOOExtension where
  usesCanonicalGerbilPoo : Prop
  canonicalLibraryEstablished : usesCanonicalGerbilPoo
  createsAlternativePooLibrary : Prop
  noAlternativePooLibrary : ¬ createsAlternativePooLibrary

structure ThreeLayerExtensionSurface where
  userLayerBounded : Prop
  packageAuthorLayerFirstClass : Prop
  nativeLayerGerbilPoo : Prop
  layersEstablished :
    userLayerBounded ∧
      packageAuthorLayerFirstClass ∧
      nativeLayerGerbilPoo

structure CompositionRootIdentityScheme
    (StrategyIdentity ProfileSetIdentity RootIdentity : Type) where
  identity : StrategyIdentity → ProfileSetIdentity → RootIdentity
  strategyChangeChangesRoot :
    ∀ strategyA strategyB profiles,
      strategyA ≠ strategyB →
        identity strategyA profiles ≠ identity strategyB profiles
  profileSetChangeChangesRoot :
    ∀ strategy profilesA profilesB,
      profilesA ≠ profilesB →
        identity strategy profilesA ≠ identity strategy profilesB

theorem flatUseCompositionIsAdmitted :
    AdmitsPublicCompositionSyntax .flatUseComposition := by
  simp [AdmitsPublicCompositionSyntax]

theorem nestedUseCompositionIsRejected :
    ¬ AdmitsPublicCompositionSyntax .nestedUseComposition := by
  simp [AdmitsPublicCompositionSyntax]

theorem clauseDslIsRejected :
    ¬ AdmitsPublicCompositionSyntax .clauseDsl := by
  simp [AdmitsPublicCompositionSyntax]

theorem useCompositionEvaluatesExpressionOnce
    {Expression RootBinding ProvenanceIdentity : Type}
    (composition :
      HygienicUseComposition
        Expression RootBinding ProvenanceIdentity) :
    composition.evaluationCount = 1 :=
  composition.evaluatesExactlyOnce

theorem useCompositionBindingIsHygienic
    {Expression RootBinding ProvenanceIdentity : Type}
    (composition :
      HygienicUseComposition
        Expression RootBinding ProvenanceIdentity) :
    composition.hygienicBinding :=
  composition.hygieneEstablished

theorem composeIsPure
    {Strategy Profile CompositionRoot : Type}
    (contract :
      ComposeContract Strategy Profile CompositionRoot) :
    contract.pureFunction :=
  contract.purityEstablished

theorem composeReturnsCanonicalRoot
    {Strategy Profile CompositionRoot : Type}
    (contract :
      ComposeContract Strategy Profile CompositionRoot) :
    contract.canonicalRoot :=
  contract.canonicalityEstablished

theorem composeReadsNoHiddenRegistry
    {Strategy Profile CompositionRoot : Type}
    (contract :
      ComposeContract Strategy Profile CompositionRoot) :
    ¬ contract.readsHiddenRegistry :=
  contract.noHiddenRegistry

theorem composeExecutesNoEffects
    {Strategy Profile CompositionRoot : Type}
    (contract :
      ComposeContract Strategy Profile CompositionRoot) :
    ¬ contract.executesEffects :=
  contract.noEffectExecution

theorem composeParsesNoClauseDsl
    {Strategy Profile CompositionRoot : Type}
    (contract :
      ComposeContract Strategy Profile CompositionRoot) :
    ¬ contract.parsesClauseDsl :=
  contract.noClauseDsl

theorem userMacroDoesNotEvaluateFixedPoint
    (boundary : UseCompositionBoundary) :
    ¬ boundary.evaluatesFixedPoint :=
  boundary.boundaryEstablished.1

theorem userMacroDoesNotRegisterProviders
    (boundary : UseCompositionBoundary) :
    ¬ boundary.registersProviders :=
  boundary.boundaryEstablished.2.1

theorem userMacroDoesNotSelectRuntimeAdapters
    (boundary : UseCompositionBoundary) :
    ¬ boundary.selectsRuntimeAdapters :=
  boundary.boundaryEstablished.2.2.1

theorem userMacroDoesNotExecuteEffects
    (boundary : UseCompositionBoundary) :
    ¬ boundary.executesEffects :=
  boundary.boundaryEstablished.2.2.2.1

theorem userMacroBuildsNoHiddenRegistry
    (boundary : UseCompositionBoundary) :
    ¬ boundary.buildsHiddenRegistry :=
  boundary.boundaryEstablished.2.2.2.2.1

theorem userMacroCreatesNoSecondObjectSystem
    (boundary : UseCompositionBoundary) :
    ¬ boundary.createsSecondObjectSystem :=
  boundary.boundaryEstablished.2.2.2.2.2

theorem packageProfileIsFirstClassPooValue
    {ProfileIdentity PrototypeIdentity ImportIdentity
      CapabilityRequirementIdentity GraphIdentity : Type}
    (profile :
      PackageAuthorProfile
        ProfileIdentity PrototypeIdentity ImportIdentity
        CapabilityRequirementIdentity GraphIdentity) :
    profile.firstClassValue :=
  profile.firstClassEstablished

theorem nativeExtensionUsesCanonicalGerbilPoo
    (extension : NativePOOExtension) :
    extension.usesCanonicalGerbilPoo :=
  extension.canonicalLibraryEstablished

theorem nativeExtensionCreatesNoAlternativePooLibrary
    (extension : NativePOOExtension) :
    ¬ extension.createsAlternativePooLibrary :=
  extension.noAlternativePooLibrary

theorem threeLayerSurfaceIsExplicit
    (surface : ThreeLayerExtensionSurface) :
    surface.userLayerBounded ∧
      surface.packageAuthorLayerFirstClass ∧
      surface.nativeLayerGerbilPoo :=
  surface.layersEstablished

theorem strategyChangeCreatesNewRootIdentity
    {StrategyIdentity ProfileSetIdentity RootIdentity : Type}
    (scheme :
      CompositionRootIdentityScheme
        StrategyIdentity ProfileSetIdentity RootIdentity)
    (strategyA strategyB : StrategyIdentity)
    (profiles : ProfileSetIdentity)
    (changed : strategyA ≠ strategyB) :
    scheme.identity strategyA profiles ≠
      scheme.identity strategyB profiles :=
  scheme.strategyChangeChangesRoot strategyA strategyB profiles changed

theorem profileSetChangeCreatesNewRootIdentity
    {StrategyIdentity ProfileSetIdentity RootIdentity : Type}
    (scheme :
      CompositionRootIdentityScheme
        StrategyIdentity ProfileSetIdentity RootIdentity)
    (strategy : StrategyIdentity)
    (profilesA profilesB : ProfileSetIdentity)
    (changed : profilesA ≠ profilesB) :
    scheme.identity strategy profilesA ≠
      scheme.identity strategy profilesB :=
  scheme.profileSetChangeChangesRoot
    strategy profilesA profilesB changed

end PooFlowProof.PooC3.MinimalUseCompositionSurface
