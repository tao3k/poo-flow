import PooFlowProof.PooC3.ActiveHeadPublication

namespace PooFlowProof.PooC3.GovernedRolloutCohorts

open PooFlowProof.PooC3.ActiveHeadPublication

structure RolloutDefinition
    (RolloutIdentity Scope Generation Rule Revision Policy : Type) where
  rolloutIdentity : RolloutIdentity
  sourceGeneration : Generation
  targetGeneration : Generation
  assignmentRule : Rule
  ruleRevision : Revision
  policyIdentity : Policy
  plannedHeadTransitions : List (Scope × Generation)

structure CohortAssignmentInput
    (RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity : Type)
    where
  rolloutIdentity : RolloutIdentity
  subjectIdentity : SubjectIdentity
  assignmentRule : Rule
  ruleRevision : Revision
  evidenceIdentity : EvidenceIdentity

structure DeterministicCohortAssigner
    (RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
      Cohort AssignmentIdentity : Type) where
  assign :
    RolloutIdentity → SubjectIdentity → Rule → Revision →
      EvidenceIdentity → Cohort
  semanticIdentity :
    RolloutIdentity → SubjectIdentity → Rule → Revision →
      EvidenceIdentity → AssignmentIdentity
  ruleChangeChangesIdentity :
    ∀ rollout subject ruleA ruleB revision evidence,
      ruleA ≠ ruleB →
        semanticIdentity rollout subject ruleA revision evidence ≠
          semanticIdentity rollout subject ruleB revision evidence
  revisionChangeChangesIdentity :
    ∀ rollout subject rule revisionA revisionB evidence,
      revisionA ≠ revisionB →
        semanticIdentity rollout subject rule revisionA evidence ≠
          semanticIdentity rollout subject rule revisionB evidence

structure CohortAssignmentReceipt
    (RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
      Cohort AssignmentIdentity : Type)
    (assigner :
      DeterministicCohortAssigner
        RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
        Cohort AssignmentIdentity) where
  input :
    CohortAssignmentInput
      RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
  assignedCohort : Cohort
  assignmentIdentity : AssignmentIdentity
  cohortMatches :
    assignedCohort =
      assigner.assign
        input.rolloutIdentity
        input.subjectIdentity
        input.assignmentRule
        input.ruleRevision
        input.evidenceIdentity
  identityMatches :
    assignmentIdentity =
      assigner.semanticIdentity
        input.rolloutIdentity
        input.subjectIdentity
        input.assignmentRule
        input.ruleRevision
        input.evidenceIdentity

structure AuthorizedRolloutTransition
    (RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
      Cohort AssignmentIdentity
      Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type)
    (assigner :
      DeterministicCohortAssigner
        RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
        Cohort AssignmentIdentity) where
  assignmentReceipt :
    CohortAssignmentReceipt
      RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
      Cohort AssignmentIdentity assigner
  headCommit :
    ConditionalHeadCommit
      Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity

inductive RolloutEvidenceKind where
  | pureDefinition
  | immutableAssignmentReceipt
  | authorizedHeadTransition
  deriving DecidableEq, Repr

def AuthorizesHeadTransition : RolloutEvidenceKind → Prop
  | .authorizedHeadTransition => True
  | .pureDefinition => False
  | .immutableAssignmentReceipt => False

theorem pureDefinitionDoesNotAuthorizeTransition :
    ¬ AuthorizesHeadTransition .pureDefinition := by
  simp [AuthorizesHeadTransition]

theorem assignmentReceiptDoesNotAuthorizeTransition :
    ¬ AuthorizesHeadTransition .immutableAssignmentReceipt := by
  simp [AuthorizesHeadTransition]

theorem authorizedTransitionCarriesLiveAuthority :
    AuthorizesHeadTransition .authorizedHeadTransition := by
  simp [AuthorizesHeadTransition]

theorem cohortAssignmentStableAcrossReplay
    {RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
      Cohort AssignmentIdentity : Type}
    {assigner :
      DeterministicCohortAssigner
        RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
        Cohort AssignmentIdentity}
    (left right :
      CohortAssignmentReceipt
        RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
        Cohort AssignmentIdentity assigner)
    (sameInput : left.input = right.input) :
    left.assignedCohort = right.assignedCohort := by
  calc
    left.assignedCohort =
        assigner.assign
          left.input.rolloutIdentity
          left.input.subjectIdentity
          left.input.assignmentRule
          left.input.ruleRevision
          left.input.evidenceIdentity :=
      left.cohortMatches
    _ =
        assigner.assign
          right.input.rolloutIdentity
          right.input.subjectIdentity
          right.input.assignmentRule
          right.input.ruleRevision
          right.input.evidenceIdentity := by
      rw [sameInput]
    _ = right.assignedCohort := right.cohortMatches.symm

theorem assignmentIdentityStableAcrossReplay
    {RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
      Cohort AssignmentIdentity : Type}
    {assigner :
      DeterministicCohortAssigner
        RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
        Cohort AssignmentIdentity}
    (left right :
      CohortAssignmentReceipt
        RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
        Cohort AssignmentIdentity assigner)
    (sameInput : left.input = right.input) :
    left.assignmentIdentity = right.assignmentIdentity := by
  calc
    left.assignmentIdentity =
        assigner.semanticIdentity
          left.input.rolloutIdentity
          left.input.subjectIdentity
          left.input.assignmentRule
          left.input.ruleRevision
          left.input.evidenceIdentity :=
      left.identityMatches
    _ =
        assigner.semanticIdentity
          right.input.rolloutIdentity
          right.input.subjectIdentity
          right.input.assignmentRule
          right.input.ruleRevision
          right.input.evidenceIdentity := by
      rw [sameInput]
    _ = right.assignmentIdentity := right.identityMatches.symm

theorem ruleChangeCreatesNewAssignmentIdentity
    {RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
      Cohort AssignmentIdentity : Type}
    (assigner :
      DeterministicCohortAssigner
        RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
        Cohort AssignmentIdentity)
    (rollout : RolloutIdentity)
    (subject : SubjectIdentity)
    (ruleA ruleB : Rule)
    (revision : Revision)
    (evidence : EvidenceIdentity)
    (changed : ruleA ≠ ruleB) :
    assigner.semanticIdentity rollout subject ruleA revision evidence ≠
      assigner.semanticIdentity rollout subject ruleB revision evidence :=
  assigner.ruleChangeChangesIdentity
    rollout subject ruleA ruleB revision evidence changed

theorem revisionChangeCreatesNewAssignmentIdentity
    {RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
      Cohort AssignmentIdentity : Type}
    (assigner :
      DeterministicCohortAssigner
        RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
        Cohort AssignmentIdentity)
    (rollout : RolloutIdentity)
    (subject : SubjectIdentity)
    (rule : Rule)
    (revisionA revisionB : Revision)
    (evidence : EvidenceIdentity)
    (changed : revisionA ≠ revisionB) :
    assigner.semanticIdentity rollout subject rule revisionA evidence ≠
      assigner.semanticIdentity rollout subject rule revisionB evidence :=
  assigner.revisionChangeChangesIdentity
    rollout subject rule revisionA revisionB evidence changed

theorem rolloutDefinitionCarriesExplicitHeadTransitions
    {RolloutIdentity Scope Generation Rule Revision Policy : Type}
    (definition :
      RolloutDefinition
        RolloutIdentity Scope Generation Rule Revision Policy) :
    ∃ transitions : List (Scope × Generation),
      transitions = definition.plannedHeadTransitions := by
  exact ⟨definition.plannedHeadTransitions, rfl⟩

theorem authorizedRolloutTransitionCarriesConditionalHeadCommit
    {RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
      Cohort AssignmentIdentity
      Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type}
    {assigner :
      DeterministicCohortAssigner
        RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
        Cohort AssignmentIdentity}
    (transition :
      AuthorizedRolloutTransition
        RolloutIdentity SubjectIdentity Rule Revision EvidenceIdentity
        Cohort AssignmentIdentity
        Scope Generation Version AdapterProtocol ObservationReceipt
        Policy ProposalIdentity AuthorizationIdentity
        Effect EffectReceiptIdentity assigner) :
    ∃ commit :
        ConditionalHeadCommit
          Scope Generation Version AdapterProtocol ObservationReceipt
          Policy ProposalIdentity AuthorizationIdentity
          Effect EffectReceiptIdentity,
      commit = transition.headCommit := by
  exact ⟨transition.headCommit, rfl⟩

end PooFlowProof.PooC3.GovernedRolloutCohorts
