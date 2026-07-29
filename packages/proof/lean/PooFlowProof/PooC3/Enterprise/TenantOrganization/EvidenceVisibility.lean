namespace PooFlowProof.PooC3.Enterprise.TenantOrganization.EvidenceVisibility

structure Decision (Tenant Evidence PolicyEvidence FederationEvidence : Type) where
  sourceTenant : Tenant
  recipientTenant : Tenant
  evidence : Evidence
  policyEvidence : PolicyEvidence
  federationEvidence : FederationEvidence
  policyAllowsDisclosure : Prop
  crossTenant : Prop
  federationAllowsDisclosure : Prop
  crossTenantRequiresFederation :
    crossTenant → federationAllowsDisclosure
  redactionRequirementsSatisfied : Prop

def Admitted
    {Tenant Evidence PolicyEvidence FederationEvidence : Type}
    (decision :
      Decision Tenant Evidence PolicyEvidence FederationEvidence) : Prop :=
  decision.policyAllowsDisclosure ∧
    (decision.crossTenant → decision.federationAllowsDisclosure) ∧
    decision.redactionRequirementsSatisfied

theorem crossTenantDisclosureRequiresFederationEvidence
    {Tenant Evidence PolicyEvidence FederationEvidence : Type}
    (decision :
      Decision Tenant Evidence PolicyEvidence FederationEvidence)
    (admitted : Admitted decision)
    (crossTenant : decision.crossTenant) :
    decision.federationAllowsDisclosure :=
  admitted.2.1 crossTenant

theorem policyDenialBlocksEvidenceVisibility
    {Tenant Evidence PolicyEvidence FederationEvidence : Type}
    (decision :
      Decision Tenant Evidence PolicyEvidence FederationEvidence)
    (denied : ¬ decision.policyAllowsDisclosure) :
    ¬ Admitted decision := by
  intro admitted
  exact denied admitted.1

end PooFlowProof.PooC3.Enterprise.TenantOrganization.EvidenceVisibility
