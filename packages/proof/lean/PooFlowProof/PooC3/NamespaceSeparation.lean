import PooFlowProof.PooC3.OwnershipBoundaryLayers

namespace PooFlowProof.PooC3.NamespaceSeparation

inductive NamespaceRole where
  | repositorySource
  | projectionModule
  | profileBinding
  | governanceLanguage
  deriving DecidableEq, Repr

def MaySubstituteNamespaceRole :
    NamespaceRole → NamespaceRole → Prop
  | source, target =>
      if source = target then True else False

inductive ProjectionImplementationStatus where
  | proposedContract
  | implementedAndVerified
  deriving DecidableEq, Repr

def MayClaimImportableModule :
    ProjectionImplementationStatus → Prop
  | .implementedAndVerified => True
  | .proposedContract => False

structure RepositorySourceNamespace
    (RepositoryIdentity CommitIdentity ProvenanceIdentity : Type) where
  repositoryIdentity : RepositoryIdentity
  commitIdentity : CommitIdentity
  provenanceIdentity : ProvenanceIdentity
  providesModulePath : Prop
  noModulePath : ¬ providesModulePath
  providesPackageIdentity : Prop
  noPackageIdentity : ¬ providesPackageIdentity
  providesLexicalBinding : Prop
  noLexicalBinding : ¬ providesLexicalBinding
  providesGovernanceLanguage : Prop
  noGovernanceLanguage : ¬ providesGovernanceLanguage
  providesRuntimeCapability : Prop
  noRuntimeCapability : ¬ providesRuntimeCapability

structure CoreOwnedProjectionNamespace
    (OwnerIdentity ProjectionIdentity : Type) where
  ownerIdentity : OwnerIdentity
  projectionIdentity : ProjectionIdentity
  status : ProjectionImplementationStatus
  occupiesChildOwnedWendaoNamespace : Prop
  noChildNamespaceOccupation : ¬ occupiesChildOwnedWendaoNamespace
  occupiesGovernanceLanguageNamespace : Prop
  noLanguageNamespaceOccupation : ¬ occupiesGovernanceLanguageNamespace

structure ExportedProfileBinding
    (BindingIdentity ProfileIdentity : Type) where
  bindingIdentity : BindingIdentity
  profileIdentity : ProfileIdentity
  firstClassPooValue : Prop
  firstClassEstablished : firstClassPooValue

structure GovernanceLanguageReservation
    (NamespaceIdentity : Type) where
  namespaceIdentity : NamespaceIdentity
  explicitlyGovernanceLanguage : Prop
  governanceRoleEstablished : explicitlyGovernanceLanguage
  implementationExists : Prop
  notYetImplemented : ¬ implementationExists
  genericLangAliasAllowed : Prop
  noGenericLangAlias : ¬ genericLangAliasAllowed

structure ComposeLookupBoundary where
  resolvesRepositoryName : Prop
  resolvesModulePath : Prop
  resolvesPackageManagerState : Prop
  resolvesGlobalRegistry : Prop
  pureValueBoundary :
    ¬ resolvesRepositoryName ∧
      ¬ resolvesModulePath ∧
      ¬ resolvesPackageManagerState ∧
      ¬ resolvesGlobalRegistry

structure ExplicitImportAndBinding
    (ModuleNamespaceIdentity BindingIdentity ProfileIdentity : Type) where
  moduleNamespaceIdentity : ModuleNamespaceIdentity
  bindingIdentity : BindingIdentity
  profileIdentity : ProfileIdentity
  importExplicit : Prop
  explicitImportEstablished : importExplicit

structure ProfileNamespaceIdentityScheme
    (RepositoryCommitIdentity ProjectionIdentity BindingIdentity
      ProfileIdentity : Type) where
  identity :
    RepositoryCommitIdentity →
      ProjectionIdentity →
      BindingIdentity →
      ProfileIdentity
  commitChangeChangesProfileIdentity :
    ∀ commitA commitB projection binding,
      commitA ≠ commitB →
        identity commitA projection binding ≠
          identity commitB projection binding
  projectionChangeChangesProfileIdentity :
    ∀ commit projectionA projectionB binding,
      projectionA ≠ projectionB →
        identity commit projectionA binding ≠
          identity commit projectionB binding
  bindingChangeChangesProfileIdentity :
    ∀ commit projection bindingA bindingB,
      bindingA ≠ bindingB →
        identity commit projection bindingA ≠
          identity commit projection bindingB

theorem repositoryCannotSubstituteForModuleNamespace :
    ¬ MaySubstituteNamespaceRole
      .repositorySource .projectionModule := by
  simp [MaySubstituteNamespaceRole]

theorem repositoryCannotSubstituteForProfileBinding :
    ¬ MaySubstituteNamespaceRole
      .repositorySource .profileBinding := by
  simp [MaySubstituteNamespaceRole]

theorem moduleCannotSubstituteForGovernanceLanguage :
    ¬ MaySubstituteNamespaceRole
      .projectionModule .governanceLanguage := by
  simp [MaySubstituteNamespaceRole]

theorem profileBindingCannotSubstituteForGovernanceLanguage :
    ¬ MaySubstituteNamespaceRole
      .profileBinding .governanceLanguage := by
  simp [MaySubstituteNamespaceRole]

theorem proposedProjectionCannotClaimImportableModule :
    ¬ MayClaimImportableModule .proposedContract := by
  simp [MayClaimImportableModule]

theorem verifiedProjectionMayClaimImportableModule :
    MayClaimImportableModule .implementedAndVerified := by
  simp [MayClaimImportableModule]

theorem sourceRepositoryProvidesNoModulePath
    {RepositoryIdentity CommitIdentity ProvenanceIdentity : Type}
    (source :
      RepositorySourceNamespace
        RepositoryIdentity CommitIdentity ProvenanceIdentity) :
    ¬ source.providesModulePath :=
  source.noModulePath

theorem sourceRepositoryProvidesNoPackageIdentity
    {RepositoryIdentity CommitIdentity ProvenanceIdentity : Type}
    (source :
      RepositorySourceNamespace
        RepositoryIdentity CommitIdentity ProvenanceIdentity) :
    ¬ source.providesPackageIdentity :=
  source.noPackageIdentity

theorem sourceRepositoryProvidesNoLexicalBinding
    {RepositoryIdentity CommitIdentity ProvenanceIdentity : Type}
    (source :
      RepositorySourceNamespace
        RepositoryIdentity CommitIdentity ProvenanceIdentity) :
    ¬ source.providesLexicalBinding :=
  source.noLexicalBinding

theorem sourceRepositoryProvidesNoGovernanceLanguage
    {RepositoryIdentity CommitIdentity ProvenanceIdentity : Type}
    (source :
      RepositorySourceNamespace
        RepositoryIdentity CommitIdentity ProvenanceIdentity) :
    ¬ source.providesGovernanceLanguage :=
  source.noGovernanceLanguage

theorem sourceRepositoryProvidesNoRuntimeCapability
    {RepositoryIdentity CommitIdentity ProvenanceIdentity : Type}
    (source :
      RepositorySourceNamespace
        RepositoryIdentity CommitIdentity ProvenanceIdentity) :
    ¬ source.providesRuntimeCapability :=
  source.noRuntimeCapability

theorem coreProjectionDoesNotOccupyChildWendaoNamespace
    {OwnerIdentity ProjectionIdentity : Type}
    (projection :
      CoreOwnedProjectionNamespace OwnerIdentity ProjectionIdentity) :
    ¬ projection.occupiesChildOwnedWendaoNamespace :=
  projection.noChildNamespaceOccupation

theorem coreProjectionDoesNotOccupyGovernanceLanguageNamespace
    {OwnerIdentity ProjectionIdentity : Type}
    (projection :
      CoreOwnedProjectionNamespace OwnerIdentity ProjectionIdentity) :
    ¬ projection.occupiesGovernanceLanguageNamespace :=
  projection.noLanguageNamespaceOccupation

theorem exportedBindingIsFirstClassProfile
    {BindingIdentity ProfileIdentity : Type}
    (binding :
      ExportedProfileBinding BindingIdentity ProfileIdentity) :
    binding.firstClassPooValue :=
  binding.firstClassEstablished

theorem reservedLanguageIsExplicitlyGovernanceLanguage
    {NamespaceIdentity : Type}
    (reservation :
      GovernanceLanguageReservation NamespaceIdentity) :
    reservation.explicitlyGovernanceLanguage :=
  reservation.governanceRoleEstablished

theorem reservedGovernanceLanguageIsNotYetImplemented
    {NamespaceIdentity : Type}
    (reservation :
      GovernanceLanguageReservation NamespaceIdentity) :
    ¬ reservation.implementationExists :=
  reservation.notYetImplemented

theorem governanceLanguageRejectsGenericLangAlias
    {NamespaceIdentity : Type}
    (reservation :
      GovernanceLanguageReservation NamespaceIdentity) :
    ¬ reservation.genericLangAliasAllowed :=
  reservation.noGenericLangAlias

theorem composePerformsNoNamespaceLookup
    (boundary : ComposeLookupBoundary) :
    ¬ boundary.resolvesRepositoryName ∧
      ¬ boundary.resolvesModulePath ∧
      ¬ boundary.resolvesPackageManagerState ∧
      ¬ boundary.resolvesGlobalRegistry :=
  boundary.pureValueBoundary

theorem profileImportAndBindingAreExplicit
    {ModuleNamespaceIdentity BindingIdentity ProfileIdentity : Type}
    (projection :
      ExplicitImportAndBinding
        ModuleNamespaceIdentity BindingIdentity ProfileIdentity) :
    projection.importExplicit :=
  projection.explicitImportEstablished

theorem sourceCommitChangeCreatesNewProfileIdentity
    {RepositoryCommitIdentity ProjectionIdentity BindingIdentity
      ProfileIdentity : Type}
    (scheme :
      ProfileNamespaceIdentityScheme
        RepositoryCommitIdentity ProjectionIdentity BindingIdentity
        ProfileIdentity)
    (commitA commitB : RepositoryCommitIdentity)
    (projection : ProjectionIdentity)
    (binding : BindingIdentity)
    (changed : commitA ≠ commitB) :
    scheme.identity commitA projection binding ≠
      scheme.identity commitB projection binding :=
  scheme.commitChangeChangesProfileIdentity
    commitA commitB projection binding changed

theorem projectionChangeCreatesNewProfileIdentity
    {RepositoryCommitIdentity ProjectionIdentity BindingIdentity
      ProfileIdentity : Type}
    (scheme :
      ProfileNamespaceIdentityScheme
        RepositoryCommitIdentity ProjectionIdentity BindingIdentity
        ProfileIdentity)
    (commit : RepositoryCommitIdentity)
    (projectionA projectionB : ProjectionIdentity)
    (binding : BindingIdentity)
    (changed : projectionA ≠ projectionB) :
    scheme.identity commit projectionA binding ≠
      scheme.identity commit projectionB binding :=
  scheme.projectionChangeChangesProfileIdentity
    commit projectionA projectionB binding changed

theorem bindingChangeCreatesNewProfileIdentity
    {RepositoryCommitIdentity ProjectionIdentity BindingIdentity
      ProfileIdentity : Type}
    (scheme :
      ProfileNamespaceIdentityScheme
        RepositoryCommitIdentity ProjectionIdentity BindingIdentity
        ProfileIdentity)
    (commit : RepositoryCommitIdentity)
    (projection : ProjectionIdentity)
    (bindingA bindingB : BindingIdentity)
    (changed : bindingA ≠ bindingB) :
    scheme.identity commit projection bindingA ≠
      scheme.identity commit projection bindingB :=
  scheme.bindingChangeChangesProfileIdentity
    commit projection bindingA bindingB changed

end PooFlowProof.PooC3.NamespaceSeparation
