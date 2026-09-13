namespace PooFlowProof.PooC3.ResourceConcurrencyControl

inductive AccessRole where
  | observeRead
  | writeReplace
  | append
  | commutativeUpdate
  | compareAndSwap
  | exclusiveCommit
  deriving DecidableEq, Repr

structure ResourceScopeProjection
    (Resource Scope Policy : Type) where
  resourceIdentity : Resource
  scope : Scope
  role : AccessRole
  policyIdentity : Policy

structure ResourceVersionObservation
    (Resource Version Digest ObservationIdentity : Type) where
  resourceIdentity : Resource
  version : Version
  contentDigest : Digest
  observationIdentity : ObservationIdentity
  generation : Nat

structure ConcurrencyPrecondition
    (Resource Scope Policy Version Digest ObservationIdentity : Type) where
  scopeProjection : ResourceScopeProjection Resource Scope Policy
  observation :
    ResourceVersionObservation Resource Version Digest ObservationIdentity
  expectedVersion : Version
  expectedGeneration : Nat
  resourceBound :
    observation.resourceIdentity = scopeProjection.resourceIdentity
  versionBound :
    expectedVersion = observation.version
  generationBound :
    expectedGeneration = observation.generation

structure RuntimeResourceState
    (Resource Scope Version : Type) where
  resourceIdentity : Resource
  scope : Scope
  currentVersion : Version
  generation : Nat

structure AtomicEnforcement
    (Resource Scope Policy Version Digest ObservationIdentity : Type) where
  precondition :
    ConcurrencyPrecondition
      Resource Scope Policy Version Digest ObservationIdentity
  before : RuntimeResourceState Resource Scope Version
  resourceMatches :
    before.resourceIdentity =
      precondition.scopeProjection.resourceIdentity
  scopeMatches :
    before.scope = precondition.scopeProjection.scope
  versionMatches :
    before.currentVersion = precondition.expectedVersion
  generationMatches :
    before.generation = precondition.expectedGeneration

structure MutationCommit
    (Resource Scope Policy Version Digest ObservationIdentity : Type) where
  enforcement :
    AtomicEnforcement
      Resource Scope Policy Version Digest ObservationIdentity
  after : RuntimeResourceState Resource Scope Version
  resourcePreserved :
    after.resourceIdentity = enforcement.before.resourceIdentity
  scopePreserved :
    after.scope = enforcement.before.scope
  versionAdvanced :
    after.currentVersion ≠ enforcement.before.currentVersion
  generationAdvanced :
    enforcement.before.generation < after.generation

inductive ConcurrencyEvidenceKind where
  | versionObservation
  | concurrencyPrecondition
  | atomicEnforcement
  deriving DecidableEq, Repr

def GrantsCommitAuthority : ConcurrencyEvidenceKind → Prop
  | .atomicEnforcement => True
  | .versionObservation => False
  | .concurrencyPrecondition => False

theorem versionObservationDoesNotGrantCommitAuthority :
    ¬ GrantsCommitAuthority .versionObservation := by
  simp [GrantsCommitAuthority]

theorem preconditionDoesNotGrantCommitAuthority :
    ¬ GrantsCommitAuthority .concurrencyPrecondition := by
  simp [GrantsCommitAuthority]

theorem atomicEnforcementGrantsCommitAuthority :
    GrantsCommitAuthority .atomicEnforcement := by
  simp [GrantsCommitAuthority]

theorem commitRequiresAtomicEnforcement
    {Resource Scope Policy Version Digest ObservationIdentity : Type}
    (commit :
      MutationCommit
        Resource Scope Policy Version Digest ObservationIdentity) :
    ∃ enforcement :
        AtomicEnforcement
          Resource Scope Policy Version Digest ObservationIdentity,
      enforcement = commit.enforcement := by
  exact ⟨commit.enforcement, rfl⟩

theorem staleVersionCannotCommit
    {Resource Scope Policy Version Digest ObservationIdentity : Type}
    (commit :
      MutationCommit
        Resource Scope Policy Version Digest ObservationIdentity)
    (stale :
      commit.enforcement.before.currentVersion ≠
        commit.enforcement.precondition.expectedVersion) :
    False :=
  stale commit.enforcement.versionMatches

theorem staleGenerationCannotCommit
    {Resource Scope Policy Version Digest ObservationIdentity : Type}
    (commit :
      MutationCommit
        Resource Scope Policy Version Digest ObservationIdentity)
    (stale :
      commit.enforcement.before.generation ≠
        commit.enforcement.precondition.expectedGeneration) :
    False :=
  stale commit.enforcement.generationMatches

theorem wrongResourceCannotCommit
    {Resource Scope Policy Version Digest ObservationIdentity : Type}
    (commit :
      MutationCommit
        Resource Scope Policy Version Digest ObservationIdentity)
    (wrong :
      commit.enforcement.before.resourceIdentity ≠
        commit.enforcement.precondition.scopeProjection.resourceIdentity) :
    False :=
  wrong commit.enforcement.resourceMatches

theorem wrongScopeCannotCommit
    {Resource Scope Policy Version Digest ObservationIdentity : Type}
    (commit :
      MutationCommit
        Resource Scope Policy Version Digest ObservationIdentity)
    (wrong :
      commit.enforcement.before.scope ≠
        commit.enforcement.precondition.scopeProjection.scope) :
    False :=
  wrong commit.enforcement.scopeMatches

theorem committedMutationAdvancesGeneration
    {Resource Scope Policy Version Digest ObservationIdentity : Type}
    (commit :
      MutationCommit
        Resource Scope Policy Version Digest ObservationIdentity) :
    commit.enforcement.before.generation < commit.after.generation :=
  commit.generationAdvanced

theorem detachedCheckThenWriteDoesNotEstablishSafety :
    ¬ GrantsCommitAuthority .concurrencyPrecondition :=
  preconditionDoesNotGrantCommitAuthority

end PooFlowProof.PooC3.ResourceConcurrencyControl
