import PooFlowProof.PooC3.MinimalUseCompositionSurface

namespace PooFlowProof.PooC3.OwnershipBoundaryLayers

inductive OwnershipLayer where
  | gitSubmodule
  | gerbilPackage
  | gerbilModule
  | pooProfile
  deriving DecidableEq, Repr

def ImplicitlyCreatesLayer :
    OwnershipLayer → OwnershipLayer → Prop
  | source, target =>
      if source = target then True else False

structure GitSubmodulePin
    (RepositoryIdentity CommitIdentity CheckoutIdentity
      ProvenanceIdentity : Type) where
  repositoryIdentity : RepositoryIdentity
  commitIdentity : CommitIdentity
  checkoutIdentity : CheckoutIdentity
  provenanceIdentity : ProvenanceIdentity
  parentOwnsChildBuild : Prop
  parentDoesNotOwnChildBuild : ¬ parentOwnsChildBuild
  parentOwnsChildTests : Prop
  parentDoesNotOwnChildTests : ¬ parentOwnsChildTests
  parentOwnsChildPublication : Prop
  parentDoesNotOwnChildPublication : ¬ parentOwnsChildPublication

structure GerbilPackageBoundary
    (PackageIdentity DependencyIdentity InstallationIdentity : Type) where
  packageIdentity : PackageIdentity
  dependencies : List DependencyIdentity
  installationIdentity : InstallationIdentity
  declaresPooProfile : Prop
  noImplicitProfile : ¬ declaresPooProfile
  registersProvider : Prop
  noProviderRegistration : ¬ registersProvider
  definesRuntimeCapability : Prop
  noRuntimeCapability : ¬ definesRuntimeCapability
  selectsCompositionRoot : Prop
  noCompositionRootSelection : ¬ selectsCompositionRoot

structure GerbilModuleBoundary
    (ModulePath ExportIdentity : Type) where
  modulePath : ModulePath
  exports : List ExportIdentity
  grantsRuntimeCapability : Prop
  noCapabilityGrant : ¬ grantsRuntimeCapability
  activatesPooProfile : Prop
  noImplicitProfileActivation : ¬ activatesPooProfile

structure PooProfileBoundary
    (ProfileIdentity PrototypeIdentity ImportRequirementIdentity
      CapabilityRequirementIdentity : Type) where
  profileIdentity : ProfileIdentity
  prototypeIdentity : PrototypeIdentity
  importRequirements : List ImportRequirementIdentity
  capabilityRequirements : List CapabilityRequirementIdentity
  firstClassPooValue : Prop
  firstClassEstablished : firstClassPooValue

structure ParentChildLifecycleBoundary where
  parentPinsChildSource : Prop
  childOwnsBuild : Prop
  childOwnsTests : Prop
  childOwnsPublication : Prop
  parentOwnsChildLifecycle : Prop
  lifecycleBoundary :
    parentPinsChildSource ∧
      childOwnsBuild ∧
      childOwnsTests ∧
      childOwnsPublication ∧
      ¬ parentOwnsChildLifecycle

structure ExplicitLayerProjection
    (SourceIdentity TargetIdentity ProjectionIdentity : Type) where
  sourceIdentity : SourceIdentity
  targetIdentity : TargetIdentity
  projectionIdentity : ProjectionIdentity
  explicitContract : Prop
  contractEstablished : explicitContract

structure SourcePinUpdate
    (CommitIdentity ProfileIdentity : Type) where
  previousCommit : CommitIdentity
  revisedCommit : CommitIdentity
  commitChanged : previousCommit ≠ revisedCommit
  profileIdentity : ProfileIdentity
  activatesProfileAutomatically : Prop
  noAutomaticActivation : ¬ activatesProfileAutomatically

structure ExplicitProfileComposition
    (StrategyIdentity ProfileIdentity CompositionRootIdentity : Type) where
  strategyIdentity : StrategyIdentity
  profiles : List ProfileIdentity
  compositionRootIdentity : CompositionRootIdentity
  activationExplicit : Prop
  explicitActivationEstablished : activationExplicit

theorem submoduleDoesNotImplicitlyCreateGerbilPackage :
    ¬ ImplicitlyCreatesLayer
      .gitSubmodule .gerbilPackage := by
  simp [ImplicitlyCreatesLayer]

theorem submoduleDoesNotImplicitlyCreateGerbilModule :
    ¬ ImplicitlyCreatesLayer
      .gitSubmodule .gerbilModule := by
  simp [ImplicitlyCreatesLayer]

theorem submoduleDoesNotImplicitlyCreatePooProfile :
    ¬ ImplicitlyCreatesLayer
      .gitSubmodule .pooProfile := by
  simp [ImplicitlyCreatesLayer]

theorem gerbilPackageDoesNotImplicitlyCreatePooProfile :
    ¬ ImplicitlyCreatesLayer
      .gerbilPackage .pooProfile := by
  simp [ImplicitlyCreatesLayer]

theorem gerbilModuleDoesNotImplicitlyCreatePooProfile :
    ¬ ImplicitlyCreatesLayer
      .gerbilModule .pooProfile := by
  simp [ImplicitlyCreatesLayer]

theorem parentDoesNotOwnChildBuild
    {RepositoryIdentity CommitIdentity CheckoutIdentity
      ProvenanceIdentity : Type}
    (pin :
      GitSubmodulePin
        RepositoryIdentity CommitIdentity CheckoutIdentity
        ProvenanceIdentity) :
    ¬ pin.parentOwnsChildBuild :=
  pin.parentDoesNotOwnChildBuild

theorem parentDoesNotOwnChildTests
    {RepositoryIdentity CommitIdentity CheckoutIdentity
      ProvenanceIdentity : Type}
    (pin :
      GitSubmodulePin
        RepositoryIdentity CommitIdentity CheckoutIdentity
        ProvenanceIdentity) :
    ¬ pin.parentOwnsChildTests :=
  pin.parentDoesNotOwnChildTests

theorem parentDoesNotOwnChildPublication
    {RepositoryIdentity CommitIdentity CheckoutIdentity
      ProvenanceIdentity : Type}
    (pin :
      GitSubmodulePin
        RepositoryIdentity CommitIdentity CheckoutIdentity
        ProvenanceIdentity) :
    ¬ pin.parentOwnsChildPublication :=
  pin.parentDoesNotOwnChildPublication

theorem gerbilPackageDeclaresNoImplicitProfile
    {PackageIdentity DependencyIdentity InstallationIdentity : Type}
    (boundary :
      GerbilPackageBoundary
        PackageIdentity DependencyIdentity InstallationIdentity) :
    ¬ boundary.declaresPooProfile :=
  boundary.noImplicitProfile

theorem gerbilPackageRegistersNoProvider
    {PackageIdentity DependencyIdentity InstallationIdentity : Type}
    (boundary :
      GerbilPackageBoundary
        PackageIdentity DependencyIdentity InstallationIdentity) :
    ¬ boundary.registersProvider :=
  boundary.noProviderRegistration

theorem gerbilPackageDefinesNoRuntimeCapability
    {PackageIdentity DependencyIdentity InstallationIdentity : Type}
    (boundary :
      GerbilPackageBoundary
        PackageIdentity DependencyIdentity InstallationIdentity) :
    ¬ boundary.definesRuntimeCapability :=
  boundary.noRuntimeCapability

theorem gerbilPackageSelectsNoCompositionRoot
    {PackageIdentity DependencyIdentity InstallationIdentity : Type}
    (boundary :
      GerbilPackageBoundary
        PackageIdentity DependencyIdentity InstallationIdentity) :
    ¬ boundary.selectsCompositionRoot :=
  boundary.noCompositionRootSelection

theorem moduleImportGrantsNoRuntimeCapability
    {ModulePath ExportIdentity : Type}
    (boundary :
      GerbilModuleBoundary ModulePath ExportIdentity) :
    ¬ boundary.grantsRuntimeCapability :=
  boundary.noCapabilityGrant

theorem moduleImportDoesNotActivateProfile
    {ModulePath ExportIdentity : Type}
    (boundary :
      GerbilModuleBoundary ModulePath ExportIdentity) :
    ¬ boundary.activatesPooProfile :=
  boundary.noImplicitProfileActivation

theorem profileIsFirstClassPooValue
    {ProfileIdentity PrototypeIdentity ImportRequirementIdentity
      CapabilityRequirementIdentity : Type}
    (profile :
      PooProfileBoundary
        ProfileIdentity PrototypeIdentity ImportRequirementIdentity
        CapabilityRequirementIdentity) :
    profile.firstClassPooValue :=
  profile.firstClassEstablished

theorem childOwnsItsLifecycle
    (boundary : ParentChildLifecycleBoundary) :
    boundary.childOwnsBuild ∧
      boundary.childOwnsTests ∧
      boundary.childOwnsPublication :=
  ⟨boundary.lifecycleBoundary.2.1,
    boundary.lifecycleBoundary.2.2.1,
    boundary.lifecycleBoundary.2.2.2.1⟩

theorem parentDoesNotOwnChildLifecycle
    (boundary : ParentChildLifecycleBoundary) :
    ¬ boundary.parentOwnsChildLifecycle :=
  boundary.lifecycleBoundary.2.2.2.2

theorem crossLayerProjectionRequiresExplicitContract
    {SourceIdentity TargetIdentity ProjectionIdentity : Type}
    (projection :
      ExplicitLayerProjection
        SourceIdentity TargetIdentity ProjectionIdentity) :
    projection.explicitContract :=
  projection.contractEstablished

theorem sourcePinUpdateDoesNotActivateProfile
    {CommitIdentity ProfileIdentity : Type}
    (update :
      SourcePinUpdate CommitIdentity ProfileIdentity) :
    ¬ update.activatesProfileAutomatically :=
  update.noAutomaticActivation

theorem profileCompositionIsExplicit
    {StrategyIdentity ProfileIdentity CompositionRootIdentity : Type}
    (composition :
      ExplicitProfileComposition
        StrategyIdentity ProfileIdentity CompositionRootIdentity) :
    composition.activationExplicit :=
  composition.explicitActivationEstablished

end PooFlowProof.PooC3.OwnershipBoundaryLayers
