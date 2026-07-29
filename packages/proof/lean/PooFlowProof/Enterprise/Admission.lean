import PooFlowProof.Enterprise.Core
import PooFlowProof.Enterprise.EvidenceFreshness
import PooFlowProof.Enterprise.SeparationOfDuties

namespace PooFlowProof.Enterprise.Admission

open PooFlowProof.PooC3

structure Admitted
    (Principal Asset Action Responsibility Evidence FacetIdentity
      CoreContractIdentity : Type) where
  context :
    Core.GovernanceContext
      Principal Asset Action Responsibility Evidence FacetIdentity
      CoreContractIdentity
  baseAdmission : Core.BaseAdmission context
  decisionKind :
    GovernanceDecisionAuthority.GovernanceDecisionKind
  decisionMayRequestScopedCapability :
    GovernanceDecisionAuthority.MayRequestScopedCapability decisionKind
  governanceChecks : GovernanceDecisionAuthority.GovernanceChecks
  governanceChecksHold :
    GovernanceDecisionAuthority.GovernanceChecksHold governanceChecks
  approval : SeparationOfDuties.ApprovalDiscipline Principal
  freshness : EvidenceFreshness.Checks
  freshnessHolds : EvidenceFreshness.Hold freshness

theorem requiresBaseAdmission
    {Principal Asset Action Responsibility Evidence FacetIdentity
      CoreContractIdentity : Type}
    (admission :
      Admitted
        Principal Asset Action Responsibility Evidence FacetIdentity
        CoreContractIdentity) :
    Core.BaseAdmission admission.context :=
  admission.baseAdmission

theorem requiresEveryGovernanceCheck
    {Principal Asset Action Responsibility Evidence FacetIdentity
      CoreContractIdentity : Type}
    (admission :
      Admitted
        Principal Asset Action Responsibility Evidence FacetIdentity
        CoreContractIdentity) :
    GovernanceDecisionAuthority.GovernanceChecksHold
      admission.governanceChecks :=
  admission.governanceChecksHold

theorem requiresFreshEvidence
    {Principal Asset Action Responsibility Evidence FacetIdentity
      CoreContractIdentity : Type}
    (admission :
      Admitted
        Principal Asset Action Responsibility Evidence FacetIdentity
        CoreContractIdentity) :
    EvidenceFreshness.Hold admission.freshness :=
  admission.freshnessHolds

theorem expiredDecisionCannotBeAdmitted
    {Principal Asset Action Responsibility Evidence FacetIdentity
      CoreContractIdentity : Type}
    (admission :
      Admitted
        Principal Asset Action Responsibility Evidence FacetIdentity
        CoreContractIdentity)
    (expired : admission.decisionKind = .expired) :
    False := by
  have mayRequest := admission.decisionMayRequestScopedCapability
  rw [expired] at mayRequest
  exact
    GovernanceDecisionAuthority.expiredDecisionFailsClosed
      mayRequest

theorem revokedDecisionCannotBeAdmitted
    {Principal Asset Action Responsibility Evidence FacetIdentity
      CoreContractIdentity : Type}
    (admission :
      Admitted
        Principal Asset Action Responsibility Evidence FacetIdentity
        CoreContractIdentity)
    (revoked : admission.decisionKind = .revoked) :
    False := by
  have mayRequest := admission.decisionMayRequestScopedCapability
  rw [revoked] at mayRequest
  exact
    GovernanceDecisionAuthority.revokedDecisionFailsClosed
      mayRequest

end PooFlowProof.Enterprise.Admission
