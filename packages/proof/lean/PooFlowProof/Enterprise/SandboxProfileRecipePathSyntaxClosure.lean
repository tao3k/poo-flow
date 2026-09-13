import PooFlowProof.Enterprise.SandboxProfileRecipePathSyntaxModel
import PooFlowProof.Enterprise.SandboxProfileRecipePortabilityClosure

namespace PooFlowProof.Enterprise.SandboxProfileRecipePathSyntaxClosure

open PooFlowProof.Enterprise.SandboxProfileRecipePathSyntaxModel
open PooFlowProof.Enterprise.SandboxProfileRecipePortabilityClosure

theorem syntaxAndMaterializationOwnershipCompose
    (fields : List RecipeField)
    (syntaxPortable : PortableRecipeSyntax fields)
    (recipe : PortableRecipe)
    (policy : BackendMaterializationPolicy) :
    PortableRecipeSyntax fields ∧
      receiptClosesRecipe recipe (materialize recipe policy) ∧
      (materialize recipe policy).runtimeTarget =
        policy.targetFor recipe.backendIdentity recipe.resourceRole := by
  exact
    ⟨syntaxPortable,
      everyBackendMaterializationClosesThePortableRecipe recipe policy,
      (runtimeTargetIsOwnedOnlyByTheMaterializationReceipt recipe policy).1⟩

theorem portableDeclarationCannotEmbedRuntimeTarget
    (path : RecipePath) :
    ¬ PortableRecipeSyntax [.runtimeTarget path] := by
  simp [PortableRecipeSyntax, portableRecipeField]

end PooFlowProof.Enterprise.SandboxProfileRecipePathSyntaxClosure
