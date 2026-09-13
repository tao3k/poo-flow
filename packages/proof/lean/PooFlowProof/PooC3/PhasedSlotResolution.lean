namespace PooFlowProof.PooC3.PhasedSlotResolution

universe u

inductive ResolutionPhase where
  | structuralProjection
  | semanticAdmission
  | priorityResolution
  | canonicalCombination
  | contractAssembly
  | semanticEvaluation
  | runtimeAuthorization
  | disclosure
deriving Repr, DecidableEq

structure StructuralProjection (Metadata : Type u) where
  metadata : Metadata

structure SemanticAdmission (Metadata : Type u) where
  structural : StructuralProjection Metadata
  admittedViewIdentity : Nat

structure PriorityResolution (Metadata Candidates : Type u) where
  admission : SemanticAdmission Metadata
  activeCandidates : List Candidates
  shadowedCandidates : List Candidates

structure CanonicalCombination (Metadata Candidates Combined : Type u) where
  priority : PriorityResolution Metadata Candidates
  combined : Combined

structure ContractAssembly
    (Metadata Candidates Combined Contract : Type u) where
  combination : CanonicalCombination Metadata Candidates Combined
  contract : Contract

structure SemanticEvaluation
    (Metadata Candidates Combined Contract Value : Type u) where
  assembly : ContractAssembly Metadata Candidates Combined Contract
  value : Value

structure RuntimeAuthorization
    (Metadata Candidates Combined Contract Value : Type u) where
  evaluation :
    SemanticEvaluation Metadata Candidates Combined Contract Value
  effectBoundaryIdentity : Nat
  authorizationReceiptIdentity : Nat

structure Disclosure
    (Metadata Candidates Combined Contract Value : Type u) where
  authorization :
    RuntimeAuthorization Metadata Candidates Combined Contract Value
  disclosureProjectionIdentity : Nat

inductive ResolutionFailure where
  | structuralProjection
  | semanticAdmission
  | priorityConflict
  | canonicalCombination
  | contractViolation
  | semanticConflict
  | semanticCycle
  | runtimeAuthorization
  | runtimeEffect
  | disclosurePolicy
deriving Repr, DecidableEq

inductive MissingValueReason where
  | noContribution
  | explicitlyFiltered
deriving Repr, DecidableEq

inductive ResolutionOutcome (Value : Type u) where
  | resolved (value : Value)
  | missing (reason : MissingValueReason)
  | failed (failure : ResolutionFailure)
deriving Repr, DecidableEq

theorem evaluationRequiresContractAssembly
    {Metadata Candidates Combined Contract Value : Type u}
    (evaluation :
      SemanticEvaluation Metadata Candidates Combined Contract Value) :
    ∃ assembly : ContractAssembly Metadata Candidates Combined Contract,
      evaluation.assembly = assembly := by
  exact ⟨evaluation.assembly, rfl⟩

theorem disclosureRequiresRuntimeAuthorization
    {Metadata Candidates Combined Contract Value : Type u}
    (disclosure :
      Disclosure Metadata Candidates Combined Contract Value) :
    ∃ authorization :
        RuntimeAuthorization Metadata Candidates Combined Contract Value,
      disclosure.authorization = authorization := by
  exact ⟨disclosure.authorization, rfl⟩

def priorityOfDisclosure
    {Metadata Candidates Combined Contract Value : Type u}
    (disclosure :
      Disclosure Metadata Candidates Combined Contract Value) :
    PriorityResolution Metadata Candidates :=
  disclosure.authorization.evaluation.assembly.combination.priority

def structuralOfDisclosure
    {Metadata Candidates Combined Contract Value : Type u}
    (disclosure :
      Disclosure Metadata Candidates Combined Contract Value) :
    StructuralProjection Metadata :=
  (priorityOfDisclosure disclosure).admission.structural

theorem disclosureCarriesStructuralProjection
    {Metadata Candidates Combined Contract Value : Type u}
    (disclosure :
      Disclosure Metadata Candidates Combined Contract Value) :
    ∃ structural : StructuralProjection Metadata,
      structuralOfDisclosure disclosure = structural := by
  exact ⟨structuralOfDisclosure disclosure, rfl⟩

theorem shadowedCandidatesRemainPreEvaluation
    {Metadata Candidates : Type u}
    (priority : PriorityResolution Metadata Candidates) :
    ∃ shadowed : List Candidates,
      priority.shadowedCandidates = shadowed := by
  exact ⟨priority.shadowedCandidates, rfl⟩

theorem failureCannotBeMissing
    {Value : Type u}
    (failure : ResolutionFailure)
    (reason : MissingValueReason) :
    (ResolutionOutcome.failed failure : ResolutionOutcome Value) ≠
      ResolutionOutcome.missing reason := by
  intro equality
  cases equality

theorem structuralFailureIsNotSemanticConflict :
    ResolutionFailure.structuralProjection ≠
      ResolutionFailure.semanticConflict := by
  decide

theorem runtimeAuthorizationFailureIsNotSemanticConflict :
    ResolutionFailure.runtimeAuthorization ≠
      ResolutionFailure.semanticConflict := by
  decide

theorem runtimeEffectFailureIsNotMissing
    {Value : Type u}
    (reason : MissingValueReason) :
    (ResolutionOutcome.failed ResolutionFailure.runtimeEffect :
        ResolutionOutcome Value) ≠
      ResolutionOutcome.missing reason :=
  failureCannotBeMissing ResolutionFailure.runtimeEffect reason

end PooFlowProof.PooC3.PhasedSlotResolution
