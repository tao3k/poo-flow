import PooFlowProof.PooC3.Enterprise.Admission
import PooFlowProof.PooC3.Enterprise.Delegation
import PooFlowProof.PooC3.Enterprise.ResponsibilityTransfer
import PooFlowProof.PooC3.Enterprise.TenantOrganization

namespace PooFlowProof.PooC3.Enterprise.Assurance

structure Claims where
  governedAdmissionEstablished : Prop
  governanceChecksEstablished : Prop
  quorumEstablished : Prop
  separationOfDutiesEstablished : Prop
  evidenceFreshnessEstablished : Prop
  delegationAttenuationEstablished : Prop
  responsibilityAccountabilityEstablished : Prop
  responsibilityTransferSafetyEstablished : Prop
  tenantOrganizationIsolationEstablished : Prop

def Admitted (claims : Claims) : Prop :=
  claims.governedAdmissionEstablished ∧
    claims.governanceChecksEstablished ∧
    claims.quorumEstablished ∧
    claims.separationOfDutiesEstablished ∧
    claims.evidenceFreshnessEstablished ∧
    claims.delegationAttenuationEstablished ∧
    claims.responsibilityAccountabilityEstablished ∧
    claims.responsibilityTransferSafetyEstablished ∧
    claims.tenantOrganizationIsolationEstablished

theorem admittedClaimsExposeEveryEnterpriseObligation
    (claims : Claims)
    (admitted : Admitted claims) :
    claims.governedAdmissionEstablished ∧
      claims.governanceChecksEstablished ∧
      claims.quorumEstablished ∧
      claims.separationOfDutiesEstablished ∧
      claims.evidenceFreshnessEstablished ∧
      claims.delegationAttenuationEstablished ∧
      claims.responsibilityAccountabilityEstablished ∧
      claims.responsibilityTransferSafetyEstablished ∧
      claims.tenantOrganizationIsolationEstablished :=
  admitted

theorem missingFreshnessBlocksAssurance
    (claims : Claims)
    (missing : ¬ claims.evidenceFreshnessEstablished) :
    ¬ Admitted claims := by
  intro admitted
  exact missing admitted.2.2.2.2.1

theorem missingResponsibilityAccountabilityBlocksAssurance
    (claims : Claims)
    (missing : ¬ claims.responsibilityAccountabilityEstablished) :
    ¬ Admitted claims := by
  intro admitted
  exact missing admitted.2.2.2.2.2.2.1

theorem missingTenantOrganizationIsolationBlocksAssurance
    (claims : Claims)
    (missing : ¬ claims.tenantOrganizationIsolationEstablished) :
    ¬ Admitted claims := by
  intro admitted
  exact missing admitted.2.2.2.2.2.2.2.2

end PooFlowProof.PooC3.Enterprise.Assurance
