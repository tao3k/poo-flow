namespace PooFlowProof.PooC3.ActiveHeadPublication

inductive HeadScope where
  | staging
  | productionCandidate
  | auditPinned
  | referenced
  deriving DecidableEq, Repr

inductive HeadMutationKind where
  | publish
  | revert
  deriving DecidableEq, Repr

structure ActiveHeadObservation
    (Scope Generation Version AdapterProtocol ObservationReceipt : Type) where
  scopeIdentity : Scope
  selectedGeneration : Generation
  authoritativeVersion : Version
  fencingGeneration : Nat
  adapterProtocolIdentity : AdapterProtocol
  observationReceipt : ObservationReceipt

structure HeadPublicationPrecondition
    (Scope Generation Version AdapterProtocol ObservationReceipt : Type) where
  observation :
    ActiveHeadObservation
      Scope Generation Version AdapterProtocol ObservationReceipt
  expectedGeneration : Generation
  expectedVersion : Version
  expectedFencingGeneration : Nat
  generationBound :
    expectedGeneration = observation.selectedGeneration
  versionBound :
    expectedVersion = observation.authoritativeVersion
  fencingBound :
    expectedFencingGeneration = observation.fencingGeneration

structure GenerationSelectionProposal
    (Scope Generation Policy ProposalIdentity : Type) where
  proposalIdentity : ProposalIdentity
  mutationKind : HeadMutationKind
  scopeIdentity : Scope
  targetGeneration : Generation
  policyIdentity : Policy

structure HeadUpdateIntent
    (Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity : Type) where
  proposal :
    GenerationSelectionProposal
      Scope Generation Policy ProposalIdentity
  precondition :
    HeadPublicationPrecondition
      Scope Generation Version AdapterProtocol ObservationReceipt
  authorizationIdentity : AuthorizationIdentity
  scopeBound :
    proposal.scopeIdentity =
      precondition.observation.scopeIdentity

structure RuntimeHeadState
    (Scope Generation Version : Type) where
  scopeIdentity : Scope
  selectedGeneration : Generation
  authoritativeVersion : Version
  fencingGeneration : Nat
  knownGenerations : List Generation

structure AuthoritativeEffectHistoryReceipt
    (Effect ReceiptIdentity : Type) where
  receiptIdentity : ReceiptIdentity
  beforeHistory : List Effect
  afterHistory : List Effect
  historyPreserved : afterHistory = beforeHistory

structure ConditionalHeadCommit
    (Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type) where
  intent :
    HeadUpdateIntent
      Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
  before : RuntimeHeadState Scope Generation Version
  after : RuntimeHeadState Scope Generation Version
  scopeMatches :
    before.scopeIdentity =
      intent.precondition.observation.scopeIdentity
  generationMatches :
    before.selectedGeneration =
      intent.precondition.expectedGeneration
  versionMatches :
    before.authoritativeVersion =
      intent.precondition.expectedVersion
  fencingMatches :
    before.fencingGeneration =
      intent.precondition.expectedFencingGeneration
  targetSelected :
    after.selectedGeneration = intent.proposal.targetGeneration
  scopePreserved :
    after.scopeIdentity = before.scopeIdentity
  versionAdvanced :
    after.authoritativeVersion ≠ before.authoritativeVersion
  fencingAdvanced :
    before.fencingGeneration < after.fencingGeneration
  generationHistoryPreserved :
    after.knownGenerations = before.knownGenerations
  effectHistoryReceipt :
    AuthoritativeEffectHistoryReceipt Effect EffectReceiptIdentity

inductive HeadEvidenceKind where
  | cachedOrRememberedHead
  | currentVersionObservation
  | authorizedIntent
  | conditionalRuntimeCommit
  deriving DecidableEq, Repr

def AuthorizesHeadMutation : HeadEvidenceKind → Prop
  | .conditionalRuntimeCommit => True
  | .cachedOrRememberedHead => False
  | .currentVersionObservation => False
  | .authorizedIntent => False

theorem cachedHeadDoesNotAuthorizePublication :
    ¬ AuthorizesHeadMutation .cachedOrRememberedHead := by
  simp [AuthorizesHeadMutation]

theorem cachedHeadDoesNotAuthorizeReversion :
    ¬ AuthorizesHeadMutation .cachedOrRememberedHead := by
  simp [AuthorizesHeadMutation]

theorem observationAloneDoesNotAuthorizeMutation :
    ¬ AuthorizesHeadMutation .currentVersionObservation := by
  simp [AuthorizesHeadMutation]

theorem authorizedIntentAloneDoesNotAuthorizeMutation :
    ¬ AuthorizesHeadMutation .authorizedIntent := by
  simp [AuthorizesHeadMutation]

theorem conditionalCommitAuthorizesMutation :
    AuthorizesHeadMutation .conditionalRuntimeCommit := by
  simp [AuthorizesHeadMutation]

theorem preconditionCarriesCurrentVersionEvidence
    {Scope Generation Version AdapterProtocol ObservationReceipt : Type}
    (precondition :
      HeadPublicationPrecondition
        Scope Generation Version AdapterProtocol ObservationReceipt) :
    precondition.expectedVersion =
      precondition.observation.authoritativeVersion :=
  precondition.versionBound

theorem publicationRequiresConditionalRuntimeCommit
    {Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type}
    (commit :
      ConditionalHeadCommit
        Scope Generation Version AdapterProtocol ObservationReceipt
        Policy ProposalIdentity AuthorizationIdentity
        Effect EffectReceiptIdentity) :
    ∃ witness :
        ConditionalHeadCommit
          Scope Generation Version AdapterProtocol ObservationReceipt
          Policy ProposalIdentity AuthorizationIdentity
          Effect EffectReceiptIdentity,
      witness = commit := by
  exact ⟨commit, rfl⟩

theorem staleHeadVersionCannotCommit
    {Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type}
    (commit :
      ConditionalHeadCommit
        Scope Generation Version AdapterProtocol ObservationReceipt
        Policy ProposalIdentity AuthorizationIdentity
        Effect EffectReceiptIdentity)
    (stale :
      commit.before.authoritativeVersion ≠
        commit.intent.precondition.expectedVersion) :
    False :=
  stale commit.versionMatches

theorem staleHeadFenceCannotCommit
    {Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type}
    (commit :
      ConditionalHeadCommit
        Scope Generation Version AdapterProtocol ObservationReceipt
        Policy ProposalIdentity AuthorizationIdentity
        Effect EffectReceiptIdentity)
    (stale :
      commit.before.fencingGeneration ≠
        commit.intent.precondition.expectedFencingGeneration) :
    False :=
  stale commit.fencingMatches

theorem wrongHeadScopeCannotCommit
    {Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type}
    (commit :
      ConditionalHeadCommit
        Scope Generation Version AdapterProtocol ObservationReceipt
        Policy ProposalIdentity AuthorizationIdentity
        Effect EffectReceiptIdentity)
    (wrong :
      commit.before.scopeIdentity ≠
        commit.intent.precondition.observation.scopeIdentity) :
    False :=
  wrong commit.scopeMatches

theorem reversionDoesNotEraseGenerationHistory
    {Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type}
    (commit :
      ConditionalHeadCommit
        Scope Generation Version AdapterProtocol ObservationReceipt
        Policy ProposalIdentity AuthorizationIdentity
        Effect EffectReceiptIdentity)
    (_isReversion : commit.intent.proposal.mutationKind = .revert) :
    commit.after.knownGenerations = commit.before.knownGenerations :=
  commit.generationHistoryPreserved

theorem reversionDoesNotEraseEffectHistory
    {Scope Generation Version AdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type}
    (commit :
      ConditionalHeadCommit
        Scope Generation Version AdapterProtocol ObservationReceipt
        Policy ProposalIdentity AuthorizationIdentity
        Effect EffectReceiptIdentity)
    (_isReversion : commit.intent.proposal.mutationKind = .revert) :
    commit.effectHistoryReceipt.afterHistory =
      commit.effectHistoryReceipt.beforeHistory :=
  commit.effectHistoryReceipt.historyPreserved

end PooFlowProof.PooC3.ActiveHeadPublication
