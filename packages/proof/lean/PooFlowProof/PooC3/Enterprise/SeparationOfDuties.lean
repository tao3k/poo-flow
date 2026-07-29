import PooFlowProof.PooC3.GovernanceDecisionAuthority

namespace PooFlowProof.PooC3.Enterprise.SeparationOfDuties

structure ApprovalDiscipline (Principal : Type) where
  quorum : GovernanceDecisionAuthority.QuorumEvidence Principal
  separation :
    GovernanceDecisionAuthority.SeparationOfDuties Principal

theorem approvingPrincipalsAreDistinct
    {Principal : Type}
    (discipline : ApprovalDiscipline Principal) :
    discipline.quorum.approvingPrincipals.Nodup :=
  GovernanceDecisionAuthority.quorumCarriesDistinctPrincipals
    discipline.quorum

theorem quorumThresholdIsSatisfied
    {Principal : Type}
    (discipline : ApprovalDiscipline Principal) :
    discipline.quorum.thresholdSatisfied :=
  GovernanceDecisionAuthority.quorumCarriesThresholdEvidence
    discipline.quorum

theorem proposerCannotApprove
    {Principal : Type}
    (discipline : ApprovalDiscipline Principal) :
    discipline.separation.proposer ≠ discipline.separation.approver :=
  GovernanceDecisionAuthority.proposerAndApproverAreSeparated
    discipline.separation

theorem approverCannotExecute
    {Principal : Type}
    (discipline : ApprovalDiscipline Principal) :
    discipline.separation.approver ≠ discipline.separation.executor :=
  GovernanceDecisionAuthority.approverAndExecutorAreSeparated
    discipline.separation

end PooFlowProof.PooC3.Enterprise.SeparationOfDuties
