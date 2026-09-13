import PooFlowProof.PooC3.PrincipalKeyLifecycle

namespace PooFlowProof.PooC3.CrossDomainFederation

inductive FederationOutcomeKind where
  | candidate
  | agreed
  | incompatible
  | expired
  | revoked
  deriving DecidableEq, Repr

def MayEnterLocalFederationAdmission : FederationOutcomeKind → Prop
  | .agreed => True
  | .candidate => False
  | .incompatible => False
  | .expired => False
  | .revoked => False

def CreatesGlobalRootAuthority : FederationOutcomeKind → Prop
  | .candidate => False
  | .agreed => False
  | .incompatible => False
  | .expired => False
  | .revoked => False

structure DomainOwnership
    (DomainIdentity OwnershipEvidenceIdentity : Type) where
  domainIdentity : DomainIdentity
  ownershipEvidenceIdentity : OwnershipEvidenceIdentity
  retainsIdentityOwnership : Prop
  retainsPolicyOwnership : Prop
  retainsResourceOwnership : Prop
  retainsCapabilityIssuance : Prop
  retainsGovernance : Prop
  ownershipRetained :
    retainsIdentityOwnership ∧
      retainsPolicyOwnership ∧
      retainsResourceOwnership ∧
      retainsCapabilityIssuance ∧
      retainsGovernance

structure FederationCompatibilityChecks where
  requirementMatchesOffer : Prop
  contractIdentitiesMatch : Prop
  trustAnchorsAccepted : Prop
  disclosureAllowed : Prop
  evidenceRequirementsMet : Prop
  capabilityConstraintsMet : Prop
  responsibilityAllocated : Prop
  temporalRequirementsHold : Prop

def FederationChecksHold (checks : FederationCompatibilityChecks) : Prop :=
  checks.requirementMatchesOffer ∧
    checks.contractIdentitiesMatch ∧
    checks.trustAnchorsAccepted ∧
    checks.disclosureAllowed ∧
    checks.evidenceRequirementsMet ∧
    checks.capabilityConstraintsMet ∧
    checks.responsibilityAllocated ∧
    checks.temporalRequirementsHold

structure FederationAgreement
    (ImportingDomain RemoteDomain RequirementIdentity OfferIdentity
      PolicyIdentity EvidenceCutIdentity AgreementIdentity : Type) where
  importingDomain : ImportingDomain
  remoteDomain : RemoteDomain
  requirementIdentity : RequirementIdentity
  offerIdentity : OfferIdentity
  policyIdentity : PolicyIdentity
  evidenceCutIdentity : EvidenceCutIdentity
  checks : FederationCompatibilityChecks
  checksHold : FederationChecksHold checks
  agreementIdentity : AgreementIdentity

structure CapabilityAttenuation
    (CapabilityIdentity Scope ActionRole Expiry DelegationDepth : Type) where
  sourceCapabilityIdentity : CapabilityIdentity
  attenuatedCapabilityIdentity : CapabilityIdentity
  sourceScope : Scope
  attenuatedScope : Scope
  sourceActionRole : ActionRole
  attenuatedActionRole : ActionRole
  sourceExpiry : Expiry
  attenuatedExpiry : Expiry
  sourceDelegationDepth : DelegationDepth
  attenuatedDelegationDepth : DelegationDepth
  scopeNotAmplified : Prop
  actionNotAmplified : Prop
  expiryNotExtended : Prop
  delegationDepthNotIncreased : Prop
  attenuationEstablished :
    scopeNotAmplified ∧
      actionNotAmplified ∧
      expiryNotExtended ∧
      delegationDepthNotIncreased

structure FederationDisclosureProjection
    (RemoteEvidenceIdentity ProjectionIdentity : Type) where
  remoteEvidenceIdentity : RemoteEvidenceIdentity
  projectionIdentity : ProjectionIdentity
  importsRemoteInternalGraph : Prop
  noImplicitGraphImport : ¬ importsRemoteInternalGraph
  importsRemoteCapabilities : Prop
  noImplicitCapabilityImport : ¬ importsRemoteCapabilities

structure ResponsibilityAllocation
    (RequirementOwner OfferOwner IncidentOwner RevocationOwner
      RetentionOwner ResponsibilityIdentity : Type) where
  requirementOwner : RequirementOwner
  offerOwner : OfferOwner
  incidentOwner : IncidentOwner
  revocationOwner : RevocationOwner
  retentionOwner : RetentionOwner
  responsibilityIdentity : ResponsibilityIdentity
  allocationComplete : Prop
  completenessEstablished : allocationComplete

structure FederationRevocation
    (AgreementIdentity RevocationIdentity : Type) where
  agreementIdentity : AgreementIdentity
  revocationIdentity : RevocationIdentity
  continuedLocalUseAllowed : Prop
  revokedAgreementFailsClosed : ¬ continuedLocalUseAllowed

structure OwnershipTransferAttempt
    (DomainIdentity TransferContractIdentity AuthorityIdentity : Type) where
  domainIdentity : DomainIdentity
  transferContractIdentity : TransferContractIdentity
  authorityIdentity : AuthorityIdentity
  exactTransferContract : Prop
  transferAuthorityValid : Prop
  ownershipTransferred : Prop
  transferRequiresContractAndAuthority :
    ownershipTransferred →
      exactTransferContract ∧ transferAuthorityValid

structure FederationIdentityScheme
    (RequirementIdentity OfferIdentity EvidenceCutIdentity PolicyIdentity
      AgreementIdentity : Type) where
  identity :
    RequirementIdentity →
      OfferIdentity →
      EvidenceCutIdentity →
      PolicyIdentity →
      AgreementIdentity
  requirementChangeChangesAgreement :
    ∀ requirementA requirementB offer cut policy,
      requirementA ≠ requirementB →
        identity requirementA offer cut policy ≠
          identity requirementB offer cut policy
  offerChangeChangesAgreement :
    ∀ requirement offerA offerB cut policy,
      offerA ≠ offerB →
        identity requirement offerA cut policy ≠
          identity requirement offerB cut policy
  cutChangeChangesAgreement :
    ∀ requirement offer cutA cutB policy,
      cutA ≠ cutB →
        identity requirement offer cutA policy ≠
          identity requirement offer cutB policy

theorem federationNeverCreatesGlobalRoot
    (outcome : FederationOutcomeKind) :
    ¬ CreatesGlobalRootAuthority outcome := by
  cases outcome <;> simp [CreatesGlobalRootAuthority]

theorem agreedFederationMayEnterLocalAdmission :
    MayEnterLocalFederationAdmission .agreed := by
  simp [MayEnterLocalFederationAdmission]

theorem candidateFederationFailsClosed :
    ¬ MayEnterLocalFederationAdmission .candidate := by
  simp [MayEnterLocalFederationAdmission]

theorem expiredFederationFailsClosed :
    ¬ MayEnterLocalFederationAdmission .expired := by
  simp [MayEnterLocalFederationAdmission]

theorem revokedFederationFailsClosed :
    ¬ MayEnterLocalFederationAdmission .revoked := by
  simp [MayEnterLocalFederationAdmission]

theorem domainRetainsAllOwnershipRoles
    {DomainIdentity OwnershipEvidenceIdentity : Type}
    (ownership :
      DomainOwnership DomainIdentity OwnershipEvidenceIdentity) :
    ownership.retainsIdentityOwnership ∧
      ownership.retainsPolicyOwnership ∧
      ownership.retainsResourceOwnership ∧
      ownership.retainsCapabilityIssuance ∧
      ownership.retainsGovernance :=
  ownership.ownershipRetained

theorem agreementCarriesEveryCompatibilityCheck
    {ImportingDomain RemoteDomain RequirementIdentity OfferIdentity
      PolicyIdentity EvidenceCutIdentity AgreementIdentity : Type}
    (agreement :
      FederationAgreement
        ImportingDomain RemoteDomain RequirementIdentity OfferIdentity
        PolicyIdentity EvidenceCutIdentity AgreementIdentity) :
    FederationChecksHold agreement.checks :=
  agreement.checksHold

theorem attenuationNeverAmplifiesScope
    {CapabilityIdentity Scope ActionRole Expiry DelegationDepth : Type}
    (attenuation :
      CapabilityAttenuation
        CapabilityIdentity Scope ActionRole Expiry DelegationDepth) :
    attenuation.scopeNotAmplified :=
  attenuation.attenuationEstablished.1

theorem attenuationNeverAmplifiesAction
    {CapabilityIdentity Scope ActionRole Expiry DelegationDepth : Type}
    (attenuation :
      CapabilityAttenuation
        CapabilityIdentity Scope ActionRole Expiry DelegationDepth) :
    attenuation.actionNotAmplified :=
  attenuation.attenuationEstablished.2.1

theorem attenuationNeverExtendsExpiry
    {CapabilityIdentity Scope ActionRole Expiry DelegationDepth : Type}
    (attenuation :
      CapabilityAttenuation
        CapabilityIdentity Scope ActionRole Expiry DelegationDepth) :
    attenuation.expiryNotExtended :=
  attenuation.attenuationEstablished.2.2.1

theorem attenuationNeverIncreasesDelegationDepth
    {CapabilityIdentity Scope ActionRole Expiry DelegationDepth : Type}
    (attenuation :
      CapabilityAttenuation
        CapabilityIdentity Scope ActionRole Expiry DelegationDepth) :
    attenuation.delegationDepthNotIncreased :=
  attenuation.attenuationEstablished.2.2.2

theorem federationProjectionDoesNotImportRemoteGraph
    {RemoteEvidenceIdentity ProjectionIdentity : Type}
    (projection :
      FederationDisclosureProjection
        RemoteEvidenceIdentity ProjectionIdentity) :
    ¬ projection.importsRemoteInternalGraph :=
  projection.noImplicitGraphImport

theorem federationProjectionDoesNotImportRemoteCapabilities
    {RemoteEvidenceIdentity ProjectionIdentity : Type}
    (projection :
      FederationDisclosureProjection
        RemoteEvidenceIdentity ProjectionIdentity) :
    ¬ projection.importsRemoteCapabilities :=
  projection.noImplicitCapabilityImport

theorem federationResponsibilityIsExplicit
    {RequirementOwner OfferOwner IncidentOwner RevocationOwner
      RetentionOwner ResponsibilityIdentity : Type}
    (allocation :
      ResponsibilityAllocation
        RequirementOwner OfferOwner IncidentOwner RevocationOwner
        RetentionOwner ResponsibilityIdentity) :
    allocation.allocationComplete :=
  allocation.completenessEstablished

theorem federationRevocationFailsClosed
    {AgreementIdentity RevocationIdentity : Type}
    (revocation :
      FederationRevocation AgreementIdentity RevocationIdentity) :
    ¬ revocation.continuedLocalUseAllowed :=
  revocation.revokedAgreementFailsClosed

theorem ownershipTransferRequiresExactContractAndAuthority
    {DomainIdentity TransferContractIdentity AuthorityIdentity : Type}
    (attempt :
      OwnershipTransferAttempt
        DomainIdentity TransferContractIdentity AuthorityIdentity)
    (transferred : attempt.ownershipTransferred) :
    attempt.exactTransferContract ∧ attempt.transferAuthorityValid :=
  attempt.transferRequiresContractAndAuthority transferred

theorem requirementChangeCreatesNewAgreementIdentity
    {RequirementIdentity OfferIdentity EvidenceCutIdentity PolicyIdentity
      AgreementIdentity : Type}
    (scheme :
      FederationIdentityScheme
        RequirementIdentity OfferIdentity EvidenceCutIdentity PolicyIdentity
        AgreementIdentity)
    (requirementA requirementB : RequirementIdentity)
    (offer : OfferIdentity)
    (cut : EvidenceCutIdentity)
    (policy : PolicyIdentity)
    (changed : requirementA ≠ requirementB) :
    scheme.identity requirementA offer cut policy ≠
      scheme.identity requirementB offer cut policy :=
  scheme.requirementChangeChangesAgreement
    requirementA requirementB offer cut policy changed

theorem offerChangeCreatesNewAgreementIdentity
    {RequirementIdentity OfferIdentity EvidenceCutIdentity PolicyIdentity
      AgreementIdentity : Type}
    (scheme :
      FederationIdentityScheme
        RequirementIdentity OfferIdentity EvidenceCutIdentity PolicyIdentity
        AgreementIdentity)
    (requirement : RequirementIdentity)
    (offerA offerB : OfferIdentity)
    (cut : EvidenceCutIdentity)
    (policy : PolicyIdentity)
    (changed : offerA ≠ offerB) :
    scheme.identity requirement offerA cut policy ≠
      scheme.identity requirement offerB cut policy :=
  scheme.offerChangeChangesAgreement
    requirement offerA offerB cut policy changed

theorem federationCutChangeCreatesNewAgreementIdentity
    {RequirementIdentity OfferIdentity EvidenceCutIdentity PolicyIdentity
      AgreementIdentity : Type}
    (scheme :
      FederationIdentityScheme
        RequirementIdentity OfferIdentity EvidenceCutIdentity PolicyIdentity
        AgreementIdentity)
    (requirement : RequirementIdentity)
    (offer : OfferIdentity)
    (cutA cutB : EvidenceCutIdentity)
    (policy : PolicyIdentity)
    (changed : cutA ≠ cutB) :
    scheme.identity requirement offer cutA policy ≠
      scheme.identity requirement offer cutB policy :=
  scheme.cutChangeChangesAgreement
    requirement offer cutA cutB policy changed

end PooFlowProof.PooC3.CrossDomainFederation
