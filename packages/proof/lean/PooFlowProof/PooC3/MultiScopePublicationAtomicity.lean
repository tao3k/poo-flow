import PooFlowProof.PooC3.ActiveHeadPublication

namespace PooFlowProof.PooC3.MultiScopePublicationAtomicity

open PooFlowProof.PooC3.ActiveHeadPublication

inductive ScopeRelation where
  | independent
  | ordered
  | coupled
  deriving DecidableEq, Repr

structure PublicationBarrier
    (Scope BarrierIdentity : Type) where
  barrierIdentity : BarrierIdentity
  scopes : List Scope
  ready : Scope → Prop
  allReady : ∀ scope ∈ scopes, ready scope

structure HeadSetSnapshot
    (Scope Generation Version : Type) where
  entries : List (Scope × Generation × Version)

structure RuntimeAtomicityWitness
    (Scope Generation Version AdapterProtocol WitnessIdentity : Type) where
  witnessIdentity : WitnessIdentity
  adapterProtocolIdentity : AdapterProtocol
  before : HeadSetSnapshot Scope Generation Version
  after : HeadSetSnapshot Scope Generation Version
  atomicRelation :
    HeadSetSnapshot Scope Generation Version →
      HeadSetSnapshot Scope Generation Version →
        Prop
  atomicityHolds : atomicRelation before after

structure CoupledTransitionAdmission
    (Scope Generation Version BarrierIdentity
      AdapterProtocol WitnessIdentity : Type) where
  barrier : PublicationBarrier Scope BarrierIdentity
  atomicityWitness :
    RuntimeAtomicityWitness
      Scope Generation Version AdapterProtocol WitnessIdentity
  barrierScopesMatch :
    barrier.scopes =
      atomicityWitness.before.entries.map (fun entry => entry.1)

structure AtomicHeadEntryCommit
    (Scope Generation Version HeadAdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type) where
  headCommit :
    ConditionalHeadCommit
      Scope Generation Version HeadAdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity

structure CoupledHeadSetCommitAdmission
    (Scope Generation Version BarrierIdentity
      AtomicAdapterProtocol AtomicWitnessIdentity
      HeadAdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type) where
  atomicAdmission :
    CoupledTransitionAdmission
      Scope Generation Version BarrierIdentity
      AtomicAdapterProtocol AtomicWitnessIdentity
  entryCommits :
    List
      (AtomicHeadEntryCommit
        Scope Generation Version HeadAdapterProtocol ObservationReceipt
        Policy ProposalIdentity AuthorizationIdentity
        Effect EffectReceiptIdentity)
  afterProjectionMatches :
    atomicAdmission.atomicityWitness.after.entries =
      entryCommits.map (fun entry =>
        (entry.headCommit.after.scopeIdentity,
          entry.headCommit.after.selectedGeneration,
          entry.headCommit.after.authoritativeVersion))

inductive PublicationEvidenceKind where
  | readinessBarrier
  | independentHeadCommits
  | orderedTransitionPlan
  | sequentialWritesWithCompensation
  | runtimeAtomicityWitness
  deriving DecidableEq, Repr

def EstablishesReadiness : PublicationEvidenceKind → Prop
  | .readinessBarrier => True
  | .independentHeadCommits => False
  | .orderedTransitionPlan => False
  | .sequentialWritesWithCompensation => False
  | .runtimeAtomicityWitness => False

def EstablishesMultiHeadAtomicity : PublicationEvidenceKind → Prop
  | .runtimeAtomicityWitness => True
  | .readinessBarrier => False
  | .independentHeadCommits => False
  | .orderedTransitionPlan => False
  | .sequentialWritesWithCompensation => False

def AdmittedForCoupledPolicy : PublicationEvidenceKind → Prop
  | .runtimeAtomicityWitness => True
  | .readinessBarrier => False
  | .independentHeadCommits => False
  | .orderedTransitionPlan => False
  | .sequentialWritesWithCompensation => False

theorem barrierEstablishesReadiness
    {Scope BarrierIdentity : Type}
    (barrier : PublicationBarrier Scope BarrierIdentity) :
    ∀ scope ∈ barrier.scopes, barrier.ready scope :=
  barrier.allReady

theorem barrierDoesNotEstablishAtomicity :
    ¬ EstablishesMultiHeadAtomicity .readinessBarrier := by
  simp [EstablishesMultiHeadAtomicity]

theorem independentCommitsDoNotEstablishAtomicity :
    ¬ EstablishesMultiHeadAtomicity .independentHeadCommits := by
  simp [EstablishesMultiHeadAtomicity]

theorem orderingDoesNotEstablishAtomicity :
    ¬ EstablishesMultiHeadAtomicity .orderedTransitionPlan := by
  simp [EstablishesMultiHeadAtomicity]

theorem compensationDoesNotEstablishAtomicity :
    ¬ EstablishesMultiHeadAtomicity
      .sequentialWritesWithCompensation := by
  simp [EstablishesMultiHeadAtomicity]

theorem runtimeWitnessEstablishesAtomicity :
    EstablishesMultiHeadAtomicity .runtimeAtomicityWitness := by
  simp [EstablishesMultiHeadAtomicity]

theorem barrierAloneFailsClosedForCoupledPolicy :
    ¬ AdmittedForCoupledPolicy .readinessBarrier := by
  simp [AdmittedForCoupledPolicy]

theorem coupledAdmissionRequiresRuntimeAtomicityWitness
    {Scope Generation Version BarrierIdentity
      AdapterProtocol WitnessIdentity : Type}
    (admission :
      CoupledTransitionAdmission
        Scope Generation Version BarrierIdentity
        AdapterProtocol WitnessIdentity) :
    ∃ witness :
        RuntimeAtomicityWitness
          Scope Generation Version AdapterProtocol WitnessIdentity,
      witness = admission.atomicityWitness := by
  exact ⟨admission.atomicityWitness, rfl⟩

theorem atomicHeadSetProjectionComesFromConditionalCommits
    {Scope Generation Version BarrierIdentity
      AtomicAdapterProtocol AtomicWitnessIdentity
      HeadAdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type}
    (admission :
      CoupledHeadSetCommitAdmission
        Scope Generation Version BarrierIdentity
        AtomicAdapterProtocol AtomicWitnessIdentity
        HeadAdapterProtocol ObservationReceipt
        Policy ProposalIdentity AuthorizationIdentity
        Effect EffectReceiptIdentity) :
    admission.atomicAdmission.atomicityWitness.after.entries =
      admission.entryCommits.map (fun entry =>
        (entry.headCommit.after.scopeIdentity,
          entry.headCommit.after.selectedGeneration,
          entry.headCommit.after.authoritativeVersion)) :=
  admission.afterProjectionMatches

end PooFlowProof.PooC3.MultiScopePublicationAtomicity
