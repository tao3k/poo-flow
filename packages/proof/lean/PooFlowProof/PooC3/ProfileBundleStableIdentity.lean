import PooFlowProof.PooC3.GerbilPooPhysicalRefinement

namespace PooFlowProof.PooC3.ProfileBundleStableIdentity

/-!
The stable identity boundary for a physical `ProfileBundle`.

This model deliberately keeps the digest implementation abstract.  The proof
surface fixes the semantic and activation preimages, proves the intended
normalization laws, and makes collision rejection an admission obligation.  It
does not assume that an arbitrary finite digest is injective.
-/

structure BoundSemanticIdentity (Lexical Semantic : Type) where
  lexical : Lexical
  semantic : Semantic
deriving Repr

def renameBinding
    {Lexical Semantic : Type}
    (binding : BoundSemanticIdentity Lexical Semantic)
    (lexical : Lexical) :
    BoundSemanticIdentity Lexical Semantic :=
  { binding with lexical := lexical }

theorem renameBinding_preserves_semantic
    {Lexical Semantic : Type}
    (binding : BoundSemanticIdentity Lexical Semantic)
    (lexical : Lexical) :
    (renameBinding binding lexical).semantic = binding.semantic := by
  rfl

structure SemanticBundleInputs
    (Identity Revision Capability : Type) where
  moduleDefinition : Identity
  moduleInstance : Identity
  orderedProfileRevisions : List Revision
  reachableImportRevisions : List Revision
  effectiveCapabilityContract : Capability
deriving Repr

structure ImportNormalizer (Revision : Type) where
  normalize : List Revision → List Revision
  permutationInvariant :
    ∀ {left right : List Revision},
      left.Perm right → normalize left = normalize right

structure SemanticBundlePreimage
    (Identity Revision Capability : Type) where
  domainTag : String
  moduleDefinition : Identity
  moduleInstance : Identity
  orderedProfileRevisions : List Revision
  normalizedImportRevisions : List Revision
  effectiveCapabilityContract : Capability
deriving Repr

def profileBundleDomainTag : String :=
  "poo-flow.profile-bundle.semantic.v1"

def semanticBundlePreimage
    {Identity Revision Capability : Type}
    (normalizer : ImportNormalizer Revision)
    (inputs : SemanticBundleInputs Identity Revision Capability) :
    SemanticBundlePreimage Identity Revision Capability :=
  { domainTag := profileBundleDomainTag
    moduleDefinition := inputs.moduleDefinition
    moduleInstance := inputs.moduleInstance
    orderedProfileRevisions := inputs.orderedProfileRevisions
    normalizedImportRevisions :=
      normalizer.normalize inputs.reachableImportRevisions
    effectiveCapabilityContract := inputs.effectiveCapabilityContract }

structure ActivationBundlePreimage
    (SemanticIdentity Generation : Type) where
  domainTag : String
  semanticIdentity : SemanticIdentity
  generationIdentity : Generation
deriving Repr

def profileBundleActivationDomainTag : String :=
  "poo-flow.profile-bundle.activation.v1"

def activationBundlePreimage
    {SemanticIdentity Generation : Type}
    (semanticIdentity : SemanticIdentity)
    (generationIdentity : Generation) :
    ActivationBundlePreimage SemanticIdentity Generation :=
  { domainTag := profileBundleActivationDomainTag
    semanticIdentity := semanticIdentity
    generationIdentity := generationIdentity }

structure BundleDigest
    (Identity Revision Capability Generation Digest : Type) where
  semantic :
    SemanticBundlePreimage Identity Revision Capability → Digest
  activation :
    ActivationBundlePreimage Digest Generation → Digest

def semanticBundleIdentity
    {Identity Revision Capability Generation Digest : Type}
    (digest : BundleDigest Identity Revision Capability Generation Digest)
    (normalizer : ImportNormalizer Revision)
    (inputs : SemanticBundleInputs Identity Revision Capability) :
    Digest :=
  digest.semantic (semanticBundlePreimage normalizer inputs)

def activationBundleIdentity
    {Identity Revision Capability Generation Digest : Type}
    (digest : BundleDigest Identity Revision Capability Generation Digest)
    (semanticIdentity : Digest)
    (generationIdentity : Generation) :
    Digest :=
  digest.activation
    (activationBundlePreimage semanticIdentity generationIdentity)

def semanticBundleIdentityAtGeneration
    {Identity Revision Capability Generation Digest : Type}
    (digest : BundleDigest Identity Revision Capability Generation Digest)
    (normalizer : ImportNormalizer Revision)
    (inputs : SemanticBundleInputs Identity Revision Capability)
    (_generationIdentity : Generation) :
    Digest :=
  semanticBundleIdentity digest normalizer inputs

theorem semantic_preimage_has_fixed_domain
    {Identity Revision Capability : Type}
    (normalizer : ImportNormalizer Revision)
    (inputs : SemanticBundleInputs Identity Revision Capability) :
    (semanticBundlePreimage normalizer inputs).domainTag =
      profileBundleDomainTag := by
  rfl

theorem semantic_preimage_retains_declared_profile_order
    {Identity Revision Capability : Type}
    (normalizer : ImportNormalizer Revision)
    (inputs : SemanticBundleInputs Identity Revision Capability) :
    (semanticBundlePreimage normalizer inputs).orderedProfileRevisions =
      inputs.orderedProfileRevisions := by
  rfl

theorem semantic_preimage_includes_effective_capability
    {Identity Revision Capability : Type}
    (normalizer : ImportNormalizer Revision)
    (inputs : SemanticBundleInputs Identity Revision Capability) :
    (semanticBundlePreimage normalizer inputs).effectiveCapabilityContract =
      inputs.effectiveCapabilityContract := by
  rfl

theorem import_permutation_preserves_semantic_preimage
    {Identity Revision Capability : Type}
    (normalizer : ImportNormalizer Revision)
    (inputs : SemanticBundleInputs Identity Revision Capability)
    {left right : List Revision}
    (permutation : left.Perm right) :
    semanticBundlePreimage normalizer
        { inputs with reachableImportRevisions := left } =
      semanticBundlePreimage normalizer
        { inputs with reachableImportRevisions := right } := by
  simp only [semanticBundlePreimage]
  rw [normalizer.permutationInvariant permutation]

theorem import_permutation_preserves_semantic_identity
    {Identity Revision Capability Generation Digest : Type}
    (digest : BundleDigest Identity Revision Capability Generation Digest)
    (normalizer : ImportNormalizer Revision)
    (inputs : SemanticBundleInputs Identity Revision Capability)
    {left right : List Revision}
    (permutation : left.Perm right) :
    semanticBundleIdentity digest normalizer
        { inputs with reachableImportRevisions := left } =
      semanticBundleIdentity digest normalizer
        { inputs with reachableImportRevisions := right } := by
  unfold semanticBundleIdentity
  rw [import_permutation_preserves_semantic_preimage
    normalizer inputs permutation]

theorem module_definition_change_changes_semantic_preimage
    {Identity Revision Capability : Type}
    (normalizer : ImportNormalizer Revision)
    (left right : SemanticBundleInputs Identity Revision Capability)
    (changed : left.moduleDefinition ≠ right.moduleDefinition) :
    semanticBundlePreimage normalizer left ≠
      semanticBundlePreimage normalizer right := by
  intro equalPreimages
  apply changed
  exact congrArg SemanticBundlePreimage.moduleDefinition equalPreimages

theorem module_instance_change_changes_semantic_preimage
    {Identity Revision Capability : Type}
    (normalizer : ImportNormalizer Revision)
    (left right : SemanticBundleInputs Identity Revision Capability)
    (changed : left.moduleInstance ≠ right.moduleInstance) :
    semanticBundlePreimage normalizer left ≠
      semanticBundlePreimage normalizer right := by
  intro equalPreimages
  apply changed
  exact congrArg SemanticBundlePreimage.moduleInstance equalPreimages

theorem profile_order_change_changes_semantic_preimage
    {Identity Revision Capability : Type}
    (normalizer : ImportNormalizer Revision)
    (left right : SemanticBundleInputs Identity Revision Capability)
    (changed :
      left.orderedProfileRevisions ≠ right.orderedProfileRevisions) :
    semanticBundlePreimage normalizer left ≠
      semanticBundlePreimage normalizer right := by
  intro equalPreimages
  apply changed
  exact congrArg
    SemanticBundlePreimage.orderedProfileRevisions
    equalPreimages

theorem capability_change_changes_semantic_preimage
    {Identity Revision Capability : Type}
    (normalizer : ImportNormalizer Revision)
    (left right : SemanticBundleInputs Identity Revision Capability)
    (changed :
      left.effectiveCapabilityContract ≠
        right.effectiveCapabilityContract) :
    semanticBundlePreimage normalizer left ≠
      semanticBundlePreimage normalizer right := by
  intro equalPreimages
  apply changed
  exact congrArg
    SemanticBundlePreimage.effectiveCapabilityContract
    equalPreimages

theorem semantic_identity_is_generation_independent
    {Identity Revision Capability Generation Digest : Type}
    (digest : BundleDigest Identity Revision Capability Generation Digest)
    (normalizer : ImportNormalizer Revision)
    (inputs : SemanticBundleInputs Identity Revision Capability)
    (leftGeneration rightGeneration : Generation) :
    semanticBundleIdentityAtGeneration
        digest normalizer inputs leftGeneration =
      semanticBundleIdentityAtGeneration
        digest normalizer inputs rightGeneration := by
  rfl

theorem activation_preimage_retains_semantic_identity
    {SemanticIdentity Generation : Type}
    (semanticIdentity : SemanticIdentity)
    (generationIdentity : Generation) :
    (activationBundlePreimage semanticIdentity generationIdentity).semanticIdentity =
      semanticIdentity := by
  rfl

theorem activation_preimage_retains_generation
    {SemanticIdentity Generation : Type}
    (semanticIdentity : SemanticIdentity)
    (generationIdentity : Generation) :
    (activationBundlePreimage semanticIdentity generationIdentity).generationIdentity =
      generationIdentity := by
  rfl

theorem distinct_generations_have_distinct_activation_identity
    {Identity Revision Capability Generation Digest : Type}
    (digest : BundleDigest Identity Revision Capability Generation Digest)
    (semanticIdentity : Digest)
    (generationInjective :
      Function.Injective
        (fun generation =>
          activationBundleIdentity digest semanticIdentity generation))
    {leftGeneration rightGeneration : Generation}
    (different : leftGeneration ≠ rightGeneration) :
    activationBundleIdentity digest semanticIdentity leftGeneration ≠
      activationBundleIdentity digest semanticIdentity rightGeneration := by
  exact fun equalIdentity =>
    different (generationInjective equalIdentity)

def SemanticDigestCollision
    {Identity Revision Capability Generation Digest : Type}
    (digest : BundleDigest Identity Revision Capability Generation Digest)
    (left right :
      SemanticBundlePreimage Identity Revision Capability) :
    Prop :=
  left ≠ right ∧ digest.semantic left = digest.semantic right

def SemanticPairAdmitted
    {Identity Revision Capability Generation Digest : Type}
    (digest : BundleDigest Identity Revision Capability Generation Digest)
    (left right :
      SemanticBundlePreimage Identity Revision Capability) :
    Prop :=
  ¬ SemanticDigestCollision digest left right

theorem detected_semantic_collision_fails_closed
    {Identity Revision Capability Generation Digest : Type}
    (digest : BundleDigest Identity Revision Capability Generation Digest)
    (left right :
      SemanticBundlePreimage Identity Revision Capability)
    (collision : SemanticDigestCollision digest left right) :
    ¬ SemanticPairAdmitted digest left right := by
  exact fun admitted => admitted collision

theorem equal_semantic_preimages_have_equal_digests
    {Identity Revision Capability Generation Digest : Type}
    (digest : BundleDigest Identity Revision Capability Generation Digest)
    {left right :
      SemanticBundlePreimage Identity Revision Capability}
    (equalPreimages : left = right) :
    digest.semantic left = digest.semantic right := by
  exact congrArg digest.semantic equalPreimages

end PooFlowProof.PooC3.ProfileBundleStableIdentity
