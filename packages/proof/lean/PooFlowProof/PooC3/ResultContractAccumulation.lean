namespace PooFlowProof.PooC3.ResultContractAccumulation

universe u

structure ContractSet (Obligation : Type u) where
  contains : Obligation → Prop

def accumulate
    {Obligation : Type u}
    (left right : ContractSet Obligation) :
    ContractSet Obligation :=
  { contains := fun obligation =>
      left.contains obligation ∨ right.contains obligation }

def Valid
    {Obligation Value : Type u}
    (satisfies : Value → Obligation → Prop)
    (contracts : ContractSet Obligation)
    (value : Value) : Prop :=
  (obligation : Obligation) →
  contracts.contains obligation →
  satisfies value obligation

theorem accumulationPreservesLeft
    {Obligation : Type u}
    (left right : ContractSet Obligation)
    {obligation : Obligation}
    (present : left.contains obligation) :
    (accumulate left right).contains obligation :=
  Or.inl present

theorem accumulationPreservesRight
    {Obligation : Type u}
    (left right : ContractSet Obligation)
    {obligation : Obligation}
    (present : right.contains obligation) :
    (accumulate left right).contains obligation :=
  Or.inr present

theorem accumulationOrderIndependent
    {Obligation : Type u}
    (left right : ContractSet Obligation)
    (obligation : Obligation) :
    (accumulate left right).contains obligation ↔
      (accumulate right left).contains obligation := by
  constructor
  · intro present
    cases present with
    | inl leftPresent => exact Or.inr leftPresent
    | inr rightPresent => exact Or.inl rightPresent
  · intro present
    cases present with
    | inl rightPresent => exact Or.inr rightPresent
    | inr leftPresent => exact Or.inl leftPresent

theorem accumulationDeduplicatesIdentity
    {Obligation : Type u}
    (contracts : ContractSet Obligation)
    (obligation : Obligation) :
    (accumulate contracts contracts).contains obligation ↔
      contracts.contains obligation := by
  constructor
  · intro present
    cases present with
    | inl leftPresent => exact leftPresent
    | inr rightPresent => exact rightPresent
  · intro present
    exact Or.inl present

theorem validAccumulationIff
    {Obligation Value : Type u}
    (satisfies : Value → Obligation → Prop)
    (left right : ContractSet Obligation)
    (value : Value) :
    Valid satisfies (accumulate left right) value ↔
      Valid satisfies left value ∧ Valid satisfies right value := by
  constructor
  · intro valid
    exact
      ⟨fun obligation present =>
          valid obligation (Or.inl present),
        fun obligation present =>
          valid obligation (Or.inr present)⟩
  · intro valid obligation present
    cases present with
    | inl leftPresent =>
        exact valid.left obligation leftPresent
    | inr rightPresent =>
        exact valid.right obligation rightPresent

inductive Compatibility where
  | canonicallyCompatible
  | provenIncompatible (evidenceIdentity : Nat)
  | unknown
deriving Repr, DecidableEq

def IsCompositionConflict : Compatibility → Prop
  | Compatibility.provenIncompatible _ => True
  | Compatibility.canonicallyCompatible => False
  | Compatibility.unknown => False

theorem unknownCompatibilityIsNotConflict :
    ¬ IsCompositionConflict Compatibility.unknown := by
  intro conflict
  exact conflict

theorem compositionConflictRequiresEvidence
    (compatibility : Compatibility)
    (conflict : IsCompositionConflict compatibility) :
    ∃ evidenceIdentity,
      compatibility =
        Compatibility.provenIncompatible evidenceIdentity := by
  cases compatibility with
  | canonicallyCompatible =>
      exact False.elim conflict
  | provenIncompatible evidenceIdentity =>
      exact ⟨evidenceIdentity, rfl⟩
  | unknown =>
      exact False.elim conflict

structure WeakeningAuthorization (Authority : Type u) where
  authority : Authority
  authorityIdentity : Nat
  decisionIdentity : Nat
deriving Repr, DecidableEq

structure AuthorizedWeakening
    (Obligation Authority : Type u) where
  original : ContractSet Obligation
  weakened : ContractSet Obligation
  authorization : WeakeningAuthorization Authority
  originalSemanticIdentity : Nat
  weakenedSemanticIdentity : Nat
  identityChanged :
    weakenedSemanticIdentity ≠ originalSemanticIdentity
  blameIdentity : Nat
  blameMatchesAuthority :
    blameIdentity = authorization.authorityIdentity

structure RemovedObligation
    {Obligation Authority : Type u}
    (weakening : AuthorizedWeakening Obligation Authority)
    (obligation : Obligation) : Prop where
  presentBefore : weakening.original.contains obligation
  absentAfter : ¬ weakening.weakened.contains obligation

theorem weakeningRequiresIndependentAuthority
    {Obligation Authority : Type u}
    (weakening : AuthorizedWeakening Obligation Authority) :
    ∃ authorization : WeakeningAuthorization Authority,
      weakening.authorization = authorization := by
  exact ⟨weakening.authorization, rfl⟩

theorem weakeningChangesSemanticIdentity
    {Obligation Authority : Type u}
    (weakening : AuthorizedWeakening Obligation Authority) :
    weakening.weakenedSemanticIdentity ≠
      weakening.originalSemanticIdentity :=
  weakening.identityChanged

theorem removedObligationBlamesWeakeningAuthority
    {Obligation Authority : Type u}
    {weakening : AuthorizedWeakening Obligation Authority}
    {obligation : Obligation}
    (_removed : RemovedObligation weakening obligation) :
    weakening.blameIdentity =
      weakening.authorization.authorityIdentity :=
  weakening.blameMatchesAuthority

inductive ContractFailure (Obligation : Type u) where
  | compositionConflict (evidenceIdentity : Nat)
  | valueViolation (obligation : Obligation)
deriving Repr, DecidableEq

theorem compositionConflictIsNotValueViolation
    {Obligation : Type u}
    (evidenceIdentity : Nat)
    (obligation : Obligation) :
    (ContractFailure.compositionConflict evidenceIdentity :
        ContractFailure Obligation) ≠
      ContractFailure.valueViolation obligation := by
  intro equality
  cases equality

end PooFlowProof.PooC3.ResultContractAccumulation
