import PooFlowProof.PooC3.ScaleParametricModuleGraph

namespace PooFlowProof.PooC3.ContributorRepositoryQualification

abbrev CapabilityConstraint (Action : Type) :=
  ScaleParametricModuleGraph.CapabilityConstraint Action

structure ContributorAsset
    (ContributorIdentity SemanticOwnerIdentity AssetIdentity
      RevisionIdentity FacetIdentity : Type) where
  contributorIdentity : ContributorIdentity
  semanticOwnerIdentity : SemanticOwnerIdentity
  assetIdentity : AssetIdentity
  revisionIdentity : RevisionIdentity
  facets : FacetIdentity → Prop

abbrev ContributorCatalog
    (contributorCount industryCount : Nat)
    (Asset : Type) :=
  Fin contributorCount → Fin industryCount → Asset → Prop

def CatalogIncludes
    {contributorCount industryCount : Nat}
    {Asset : Type}
    (catalog : ContributorCatalog contributorCount industryCount Asset)
    (asset : Asset) : Prop :=
  ∃ contributor industry, catalog contributor industry asset

structure QualificationEnvelope
    (Asset Action FacetIdentity CoreContractIdentity : Type) where
  qualifies : Asset → Prop
  declaredFacet : Asset → FacetIdentity → Prop
  qualifiedFacet : Asset → FacetIdentity → Prop
  facetEvidence : Asset → FacetIdentity → Prop
  qualifiedCapability : Asset → CapabilityConstraint Action
  coreContractIdentity : CoreContractIdentity
  facetCoverage :
    ∀ asset facet,
      qualifies asset →
        declaredFacet asset facet →
          qualifiedFacet asset facet ∧
            facetEvidence asset facet
  stableAssetIdentity : Prop
  stableIdentityEstablished : stableAssetIdentity
  ownerIdentityPreserved : Prop
  ownerPreservationEstablished : ownerIdentityPreserved
  provenanceComplete : Prop
  provenanceEstablished : provenanceComplete
  importsAndCapabilitiesExplicit : Prop
  requirementsEstablished : importsAndCapabilitiesExplicit
  policyAndSecurityEvidenceComplete : Prop
  policyAndSecurityEvidenceEstablished :
    policyAndSecurityEvidenceComplete
  testsAndDomainEvidencePresent : Prop
  evidenceEstablished : testsAndDomainEvidencePresent

structure GovernanceRelations
    (Principal Asset Action Responsibility Evidence : Type) where
  owns : Principal → Asset → Prop
  maintains : Principal → Asset → Prop
  reviews : Principal → Asset → Prop
  approves : Principal → Asset → Prop
  publishes : Principal → Asset → Prop
  authorized : Principal → Asset → Action → Prop
  authorityEvidence : Evidence → Principal → Asset → Action → Prop
  responsibilityDeclared : Asset → Responsibility → Prop
  actionResponsibility : Asset → Action → Responsibility → Prop
  accountable : Principal → Asset → Responsibility → Prop
  responsibilityEvidence :
    Evidence → Principal → Asset → Responsibility → Prop
  authorizedHasEvidence :
    ∀ principal asset action,
      authorized principal asset action →
        ∃ evidence,
          authorityEvidence evidence principal asset action
  actionResponsibilityIsDeclared :
    ∀ asset action responsibility,
      actionResponsibility asset action responsibility →
        responsibilityDeclared asset responsibility
  responsibilityHasAccountableEvidence :
    ∀ asset responsibility,
      responsibilityDeclared asset responsibility →
        ∃ principal evidence,
          accountable principal asset responsibility ∧
            responsibilityEvidence
              evidence principal asset responsibility

def UseCompositionAdmission
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (userAuthority : CapabilityConstraint Action)
    (asset : Asset)
    (action : Action) : Prop :=
  qualification.qualifies asset ∧
    qualification.qualifiedCapability asset action ∧
    userAuthority action

def GovernedUseCompositionAdmission
    {Principal Asset Action Responsibility Evidence
      FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (governance :
      GovernanceRelations
        Principal Asset Action Responsibility Evidence)
    (userAuthority : CapabilityConstraint Action)
    (principal : Principal)
    (asset : Asset)
    (action : Action) : Prop :=
  UseCompositionAdmission qualification userAuthority asset action ∧
    governance.authorized principal asset action ∧
    ∃ responsibility,
      governance.actionResponsibility asset action responsibility

def InclusionAloneGrantsRuntimeAuthority
    {contributorCount industryCount : Nat}
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (catalog : ContributorCatalog contributorCount industryCount Asset)
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (userAuthority : CapabilityConstraint Action) : Prop :=
  ∀ asset action,
    CatalogIncludes catalog asset →
      UseCompositionAdmission qualification userAuthority asset action

structure QualificationReceipt
    (ContributorIdentity SemanticOwnerIdentity AssetIdentity
      RevisionIdentity FacetSetIdentity CoreContractIdentity
      CapabilityIdentity ProvenanceIdentity PolicyIdentity
      AuthorityEvidenceIdentity ResponsibilityEvidenceIdentity
      AccountabilityEvidenceIdentity DomainEvidenceIdentity : Type) where
  contributorIdentity : ContributorIdentity
  semanticOwnerIdentity : SemanticOwnerIdentity
  assetIdentity : AssetIdentity
  revisionIdentity : RevisionIdentity
  facetSetIdentity : FacetSetIdentity
  coreContractIdentity : CoreContractIdentity
  capabilityIdentity : CapabilityIdentity
  provenanceIdentity : ProvenanceIdentity
  policyIdentity : PolicyIdentity
  authorityEvidenceIdentity : AuthorityEvidenceIdentity
  responsibilityEvidenceIdentity : ResponsibilityEvidenceIdentity
  accountabilityEvidenceIdentity : AccountabilityEvidenceIdentity
  domainEvidenceIdentity : DomainEvidenceIdentity
  qualificationAdmitted : Prop
  admissionEstablished : qualificationAdmitted
  grantsAuthorityByRepositoryPresence : Prop
  noRepositoryAuthority :
    ¬ grantsAuthorityByRepositoryPresence

theorem catalogInclusionHasContributorAndIndustryWitness
    {contributorCount industryCount : Nat}
    {Asset : Type}
    (catalog : ContributorCatalog contributorCount industryCount Asset)
    (asset : Asset) :
    CatalogIncludes catalog asset ↔
      ∃ contributor industry, catalog contributor industry asset :=
  Iff.rfl

theorem emptyContributorCatalogIncludesNoAsset
    {industryCount : Nat}
    {Asset : Type}
    (catalog : ContributorCatalog 0 industryCount Asset)
    (asset : Asset) :
    ¬ CatalogIncludes catalog asset := by
  intro included
  obtain ⟨contributor, _, _⟩ := included
  exact Fin.elim0 contributor

theorem emptyIndustryCatalogIncludesNoAsset
    {contributorCount : Nat}
    {Asset : Type}
    (catalog : ContributorCatalog contributorCount 0 Asset)
    (asset : Asset) :
    ¬ CatalogIncludes catalog asset := by
  intro included
  obtain ⟨_, industry, _⟩ := included
  exact Fin.elim0 industry

theorem qualifiedAssetCoversEveryDeclaredFacet
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (asset : Asset)
    (facet : FacetIdentity)
    (qualified : qualification.qualifies asset)
    (declared : qualification.declaredFacet asset facet) :
    qualification.qualifiedFacet asset facet ∧
      qualification.facetEvidence asset facet :=
  qualification.facetCoverage asset facet qualified declared

theorem admittedActionIsQualified
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (userAuthority : CapabilityConstraint Action)
    (asset : Asset)
    (action : Action)
    (admitted :
      UseCompositionAdmission
        qualification userAuthority asset action) :
    qualification.qualifies asset ∧
      qualification.qualifiedCapability asset action :=
  ⟨admitted.1, admitted.2.1⟩

theorem admittedActionIsWithinUserAuthority
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (userAuthority : CapabilityConstraint Action)
    (asset : Asset)
    (action : Action)
    (admitted :
      UseCompositionAdmission
        qualification userAuthority asset action) :
    userAuthority action :=
  admitted.2.2

theorem admittedCapabilityRestrictsQualification
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (userAuthority : CapabilityConstraint Action)
    (asset : Asset) :
    ScaleParametricModuleGraph.RestrictsCapability
      (qualification.qualifiedCapability asset)
      (fun action =>
        UseCompositionAdmission
          qualification userAuthority asset action) := by
  intro action admitted
  exact admitted.2.1

theorem admittedCapabilityRestrictsUserAuthority
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (userAuthority : CapabilityConstraint Action)
    (asset : Asset) :
    ScaleParametricModuleGraph.RestrictsCapability
      userAuthority
      (fun action =>
        UseCompositionAdmission
          qualification userAuthority asset action) := by
  intro action admitted
  exact admitted.2.2

theorem unqualifiedAssetCannotBeAdmitted
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (userAuthority : CapabilityConstraint Action)
    (asset : Asset)
    (action : Action)
    (unqualified : ¬ qualification.qualifies asset) :
    ¬ UseCompositionAdmission
      qualification userAuthority asset action := by
  intro admitted
  exact unqualified admitted.1

theorem capabilityOutsideQualificationCannotBeAdmitted
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (userAuthority : CapabilityConstraint Action)
    (asset : Asset)
    (action : Action)
    (outside :
      ¬ qualification.qualifiedCapability asset action) :
    ¬ UseCompositionAdmission
      qualification userAuthority asset action := by
  intro admitted
  exact outside admitted.2.1

theorem capabilityOutsideUserAuthorityCannotBeAdmitted
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (userAuthority : CapabilityConstraint Action)
    (asset : Asset)
    (action : Action)
    (outside : ¬ userAuthority action) :
    ¬ UseCompositionAdmission
      qualification userAuthority asset action := by
  intro admitted
  exact outside admitted.2.2

theorem repositoryInclusionCannotBypassQualification
    {contributorCount industryCount : Nat}
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (catalog : ContributorCatalog contributorCount industryCount Asset)
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (userAuthority : CapabilityConstraint Action)
    (asset : Asset)
    (action : Action)
    (included : CatalogIncludes catalog asset)
    (unqualified : ¬ qualification.qualifies asset) :
    ¬ InclusionAloneGrantsRuntimeAuthority
      catalog qualification userAuthority := by
  intro implicitAuthority
  exact unqualified (implicitAuthority asset action included).1

theorem catalogScaleCannotAmplifyAdmittedCapability
    {contributorCount industryCount : Nat}
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (catalog :
      ContributorCatalog contributorCount industryCount Asset)
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (userAuthority : CapabilityConstraint Action)
    (asset : Asset)
    (action : Action)
    (_included : CatalogIncludes catalog asset)
    (admitted :
      UseCompositionAdmission
        qualification userAuthority asset action) :
    qualification.qualifiedCapability asset action ∧
      userAuthority action :=
  ⟨admitted.2.1, admitted.2.2⟩

theorem governedAdmissionHasExplicitAuthorization
    {Principal Asset Action Responsibility Evidence
      FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (governance :
      GovernanceRelations
        Principal Asset Action Responsibility Evidence)
    (userAuthority : CapabilityConstraint Action)
    (principal : Principal)
    (asset : Asset)
    (action : Action)
    (admitted :
      GovernedUseCompositionAdmission
        qualification governance userAuthority
        principal asset action) :
    governance.authorized principal asset action :=
  admitted.2.1

theorem governedAdmissionHasAuthorityEvidence
    {Principal Asset Action Responsibility Evidence
      FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (governance :
      GovernanceRelations
        Principal Asset Action Responsibility Evidence)
    (userAuthority : CapabilityConstraint Action)
    (principal : Principal)
    (asset : Asset)
    (action : Action)
    (admitted :
      GovernedUseCompositionAdmission
        qualification governance userAuthority
        principal asset action) :
    ∃ evidence,
      governance.authorityEvidence
        evidence principal asset action :=
  governance.authorizedHasEvidence
    principal asset action admitted.2.1

theorem governedAdmissionHasAccountableResponsibility
    {Principal Asset Action Responsibility Evidence
      FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (governance :
      GovernanceRelations
        Principal Asset Action Responsibility Evidence)
    (userAuthority : CapabilityConstraint Action)
    (principal : Principal)
    (asset : Asset)
    (action : Action)
    (admitted :
      GovernedUseCompositionAdmission
        qualification governance userAuthority
        principal asset action) :
    ∃ responsibility accountablePrincipal evidence,
      governance.actionResponsibility asset action responsibility ∧
        governance.accountable
          accountablePrincipal asset responsibility ∧
        governance.responsibilityEvidence
          evidence accountablePrincipal asset responsibility := by
  obtain ⟨responsibility, actionResponsibility⟩ := admitted.2.2
  have declared :
      governance.responsibilityDeclared asset responsibility :=
    governance.actionResponsibilityIsDeclared
      asset action responsibility actionResponsibility
  obtain ⟨accountablePrincipal, evidence,
      accountability, responsibilityEvidence⟩ :=
    governance.responsibilityHasAccountableEvidence
      asset responsibility declared
  exact
    ⟨responsibility, accountablePrincipal, evidence,
      actionResponsibility, accountability, responsibilityEvidence⟩

theorem ownerWithoutExplicitAuthorizationCannotBeGovernedAdmitted
    {Principal Asset Action Responsibility Evidence
      FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity)
    (governance :
      GovernanceRelations
        Principal Asset Action Responsibility Evidence)
    (userAuthority : CapabilityConstraint Action)
    (principal : Principal)
    (asset : Asset)
    (action : Action)
    (_owner : governance.owns principal asset)
    (notAuthorized :
      ¬ governance.authorized principal asset action) :
    ¬ GovernedUseCompositionAdmission
      qualification governance userAuthority
      principal asset action := by
  intro admitted
  exact notAuthorized admitted.2.1

theorem qualificationPreservesStableIdentityAndOwner
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity) :
    qualification.stableAssetIdentity ∧
      qualification.ownerIdentityPreserved :=
  ⟨qualification.stableIdentityEstablished,
    qualification.ownerPreservationEstablished⟩

theorem qualificationRequiresProvenanceAndExplicitRequirements
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity) :
    qualification.provenanceComplete ∧
      qualification.importsAndCapabilitiesExplicit :=
  ⟨qualification.provenanceEstablished,
    qualification.requirementsEstablished⟩

theorem qualificationRequiresPolicySecurityAndDomainEvidence
    {Asset Action FacetIdentity CoreContractIdentity : Type}
    (qualification :
      QualificationEnvelope
        Asset Action FacetIdentity CoreContractIdentity) :
    qualification.policyAndSecurityEvidenceComplete ∧
      qualification.testsAndDomainEvidencePresent :=
  ⟨qualification.policyAndSecurityEvidenceEstablished,
    qualification.evidenceEstablished⟩

theorem qualificationReceiptGrantsNoRepositoryAuthority
    {ContributorIdentity SemanticOwnerIdentity AssetIdentity
      RevisionIdentity FacetSetIdentity CoreContractIdentity
      CapabilityIdentity ProvenanceIdentity PolicyIdentity
      AuthorityEvidenceIdentity ResponsibilityEvidenceIdentity
      AccountabilityEvidenceIdentity DomainEvidenceIdentity : Type}
    (receipt :
      QualificationReceipt
        ContributorIdentity SemanticOwnerIdentity AssetIdentity
        RevisionIdentity FacetSetIdentity CoreContractIdentity
        CapabilityIdentity ProvenanceIdentity PolicyIdentity
        AuthorityEvidenceIdentity ResponsibilityEvidenceIdentity
        AccountabilityEvidenceIdentity DomainEvidenceIdentity) :
    ¬ receipt.grantsAuthorityByRepositoryPresence :=
  receipt.noRepositoryAuthority

end PooFlowProof.PooC3.ContributorRepositoryQualification
