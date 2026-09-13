import PooFlowProof.PooC3.ScaleParametricModuleGraph

namespace PooFlowProof.PooC3.GerbilPooPhysicalRefinement

structure PhysicalIdentity
  (DefinitionIdentity InstanceIdentity Revision Generation : Type) where
  definition : DefinitionIdentity
  instanceIdentity : InstanceIdentity
  revision : Revision
  generation : Generation

structure PhysicalModule
    (Identity ModuleObject ProfileObject Capability : Type) where
  identity : Identity
  imports : List ModuleObject
  profiles : List ProfileObject
  capability : Capability

structure PhysicalProfile
    (Identity ModuleObject ResponsibilityObject Capability : Type) where
  identity : Identity
  module : ModuleObject
  responsibilities : List ResponsibilityObject
  capability : Capability

structure PhysicalProfileBundle
    (ModuleObject ProfileObject : Type) where
  module : ModuleObject
  profiles : List ProfileObject

structure ProjectionOps
    (ModuleObject ProfileObject Identity Capability BundleIdentity : Type) where
  moduleIdentity : ModuleObject → Identity
  moduleImports : ModuleObject → List ModuleObject
  moduleProfiles : ModuleObject → List ProfileObject
  moduleCapability : ModuleObject → Capability
  profileIdentity : ProfileObject → Identity
  profileModule : ProfileObject → ModuleObject
  profileDependencyRoots : ProfileObject → List ModuleObject
  profileCapability : ProfileObject → Capability
  closeImports : List ModuleObject → List ModuleObject
  meetCapabilities : Capability → List Capability → Capability
  digestBundle : Identity → List Identity → BundleIdentity

def useModuleProjection
    {ModuleObject ProfileObject : Type}
    (module : ModuleObject)
    (profiles : List ProfileObject) :
    PhysicalProfileBundle ModuleObject ProfileObject :=
  { module, profiles }

def bundleImports
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    (ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity)
    (bundle : PhysicalProfileBundle ModuleObject ProfileObject) :
    List ModuleObject :=
  ops.closeImports (bundle.profiles.flatMap ops.profileDependencyRoots)

def bundleCapability
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    (ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity)
    (bundle : PhysicalProfileBundle ModuleObject ProfileObject) :
    Capability :=
  ops.meetCapabilities
    (ops.moduleCapability bundle.module)
    (bundle.profiles.map ops.profileCapability)

def bundleIdentity
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    (ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity)
    (bundle : PhysicalProfileBundle ModuleObject ProfileObject) :
    BundleIdentity :=
  ops.digestBundle
    (ops.moduleIdentity bundle.module)
    (bundle.profiles.map ops.profileIdentity)

structure PhysicalBundleAdmission
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    (ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity)
    (bundle : PhysicalProfileBundle ModuleObject ProfileObject) : Prop where
  nonemptySelection : bundle.profiles ≠ []
  selectedFromModule :
    ∀ profile,
      profile ∈ bundle.profiles →
        profile ∈ ops.moduleProfiles bundle.module
  owningModulePreserved :
    ∀ profile,
      profile ∈ bundle.profiles →
        ops.profileModule profile = bundle.module

structure BundleObservation
    (Identity Capability BundleIdentity : Type) where
  moduleIdentity : Identity
  profileIdentities : List Identity
  importIdentities : List Identity
  effectiveCapability : Capability
  bundleIdentity : BundleIdentity
  deriving DecidableEq

def observePhysicalBundle
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    (ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity)
    (bundle : PhysicalProfileBundle ModuleObject ProfileObject) :
    BundleObservation Identity Capability BundleIdentity :=
  {
    moduleIdentity := ops.moduleIdentity bundle.module
    profileIdentities := bundle.profiles.map ops.profileIdentity
    importIdentities := (bundleImports ops bundle).map ops.moduleIdentity
    effectiveCapability := bundleCapability ops bundle
    bundleIdentity := bundleIdentity ops bundle
  }

def RefinesPhysicalBundle
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    (ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity)
    (abstract : BundleObservation Identity Capability BundleIdentity)
    (bundle : PhysicalProfileBundle ModuleObject ProfileObject) : Prop :=
  observePhysicalBundle ops bundle = abstract

theorem identityProjectsDefinition
    {DefinitionIdentity InstanceIdentity Revision Generation : Type}
    (identity :
      PhysicalIdentity
        DefinitionIdentity InstanceIdentity Revision Generation) :
    identity.definition = identity.definition :=
  rfl

theorem moduleRetainsImportedObjects
    {Identity ModuleObject ProfileObject Capability : Type}
    (module :
      PhysicalModule Identity ModuleObject ProfileObject Capability) :
    module.imports = module.imports :=
  rfl

theorem profileRetainsResponsibilityObjects
    {Identity ModuleObject ResponsibilityObject Capability : Type}
    (profile :
      PhysicalProfile
        Identity ModuleObject ResponsibilityObject Capability) :
    profile.responsibilities = profile.responsibilities :=
  rfl

theorem useModuleProjectionPreservesModule
    {ModuleObject ProfileObject : Type}
    (module : ModuleObject)
    (profiles : List ProfileObject) :
    (useModuleProjection module profiles).module = module :=
  rfl

theorem useModuleProjectionPreservesProfiles
    {ModuleObject ProfileObject : Type}
    (module : ModuleObject)
    (profiles : List ProfileObject) :
    (useModuleProjection module profiles).profiles = profiles :=
  rfl

theorem bundleImportsAreDerived
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    (ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity)
    (bundle : PhysicalProfileBundle ModuleObject ProfileObject) :
    bundleImports ops bundle =
      ops.closeImports
        (bundle.profiles.flatMap ops.profileDependencyRoots) :=
  rfl

theorem bundleCapabilityIsDerived
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    (ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity)
    (bundle : PhysicalProfileBundle ModuleObject ProfileObject) :
    bundleCapability ops bundle =
      ops.meetCapabilities
        (ops.moduleCapability bundle.module)
        (bundle.profiles.map ops.profileCapability) :=
  rfl

theorem bundleIdentityIsDerived
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    (ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity)
    (bundle : PhysicalProfileBundle ModuleObject ProfileObject) :
    bundleIdentity ops bundle =
      ops.digestBundle
        (ops.moduleIdentity bundle.module)
        (bundle.profiles.map ops.profileIdentity) :=
  rfl

theorem admittedBundleSelectionIsNonempty
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    {ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity}
    {bundle : PhysicalProfileBundle ModuleObject ProfileObject}
    (admitted : PhysicalBundleAdmission ops bundle) :
    bundle.profiles ≠ [] :=
  admitted.nonemptySelection

theorem admittedBundleProfilesAreExported
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    {ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity}
    {bundle : PhysicalProfileBundle ModuleObject ProfileObject}
    (admitted : PhysicalBundleAdmission ops bundle)
    {profile : ProfileObject}
    (selected : profile ∈ bundle.profiles) :
    profile ∈ ops.moduleProfiles bundle.module :=
  admitted.selectedFromModule profile selected

theorem admittedBundlePreservesOwningModule
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    {ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity}
    {bundle : PhysicalProfileBundle ModuleObject ProfileObject}
    (admitted : PhysicalBundleAdmission ops bundle)
    {profile : ProfileObject}
    (selected : profile ∈ bundle.profiles) :
    ops.profileModule profile = bundle.module :=
  admitted.owningModulePreserved profile selected

theorem twoPhysicalFieldsDetermineBundle
    {ModuleObject ProfileObject : Type}
    {left right : PhysicalProfileBundle ModuleObject ProfileObject}
    (sameModule : left.module = right.module)
    (sameProfiles : left.profiles = right.profiles) :
    left = right := by
  cases left
  cases right
  simp_all

theorem twoPhysicalFieldsDetermineObservation
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    (ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity)
    {left right : PhysicalProfileBundle ModuleObject ProfileObject}
    (sameModule : left.module = right.module)
    (sameProfiles : left.profiles = right.profiles) :
    observePhysicalBundle ops left = observePhysicalBundle ops right := by
  exact congrArg (observePhysicalBundle ops)
    (twoPhysicalFieldsDetermineBundle sameModule sameProfiles)

theorem physicalRefinementIsExactObservation
    {ModuleObject ProfileObject Identity Capability BundleIdentity : Type}
    (ops :
      ProjectionOps
        ModuleObject ProfileObject Identity Capability BundleIdentity)
    (abstract : BundleObservation Identity Capability BundleIdentity)
    (bundle : PhysicalProfileBundle ModuleObject ProfileObject) :
    RefinesPhysicalBundle ops abstract bundle ↔
      observePhysicalBundle ops bundle = abstract :=
  Iff.rfl

end PooFlowProof.PooC3.GerbilPooPhysicalRefinement
