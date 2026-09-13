import PooFlowProof.PooC3.ResourceConcurrencyControl

namespace PooFlowProof.PooC3.ObservationSetConsistency

open PooFlowProof.PooC3.ResourceConcurrencyControl

inductive ConsistencyRole where
  | independent
  | singleAdapterSnapshot
  | causalCut
  | watermarkBounded
  | freshnessBoundedBestEffort
  deriving DecidableEq, Repr

structure TimedObservation
    (Resource Version Digest ObservationIdentity : Type) where
  value :
    ResourceVersionObservation
      Resource Version Digest ObservationIdentity
  observedAt : Nat

structure ObservationConsistencyContract
    (Resource Version Digest ObservationIdentity : Type) where
  role : ConsistencyRole
  related :
    TimedObservation Resource Version Digest ObservationIdentity →
      TimedObservation Resource Version Digest ObservationIdentity →
        Prop
  versionDomain :
    Resource → Resource → Prop
  freshnessBound : Nat
  skewBound : Nat

structure ObservationSetCandidate
    (Resource Version Digest ObservationIdentity : Type) where
  observations :
    List (TimedObservation Resource Version Digest ObservationIdentity)

structure ValidatedObservationSet
    (Resource Version Digest ObservationIdentity SetIdentity : Type) where
  setIdentity : SetIdentity
  observations :
    List (TimedObservation Resource Version Digest ObservationIdentity)
  contract :
    ObservationConsistencyContract
      Resource Version Digest ObservationIdentity
  referenceTime : Nat
  nonempty : observations ≠ []
  pairwiseConsistent : observations.Pairwise contract.related
  freshEnough :
    ∀ observation ∈ observations,
      referenceTime ≤ observation.observedAt + contract.freshnessBound
  skewBounded :
    ∀ left ∈ observations,
      ∀ right ∈ observations,
        left.observedAt ≤ right.observedAt + contract.skewBound

structure SemanticGenerationInput
    (Resource Version Digest ObservationIdentity SetIdentity : Type) where
  observationSet :
    ValidatedObservationSet
      Resource Version Digest ObservationIdentity SetIdentity

structure VersionComparabilityWitness
    (Resource Version DomainIdentity : Type) where
  domainIdentity : DomainIdentity
  leftResource : Resource
  rightResource : Resource
  leftVersion : Version
  rightVersion : Version
  resourceDomain : Resource → Resource → Prop
  versionRelation : Version → Version → Prop
  resourcesComparable : resourceDomain leftResource rightResource
  versionsRelated : versionRelation leftVersion rightVersion

inductive ObservationEvidenceKind where
  | contentAddressedObservations
  | identicalTimestamps
  | declaredConsistencyContract
  | validatedObservationSet
  deriving DecidableEq, Repr

def EstablishesCrossResourceConsistency :
    ObservationEvidenceKind → Prop
  | .validatedObservationSet => True
  | .contentAddressedObservations => False
  | .identicalTimestamps => False
  | .declaredConsistencyContract => False

def EstablishesSemanticFreshness :
    ObservationEvidenceKind → Prop
  | .validatedObservationSet => True
  | .contentAddressedObservations => False
  | .identicalTimestamps => False
  | .declaredConsistencyContract => False

theorem contentAddressedObservationsDoNotEstablishConsistency :
    ¬ EstablishesCrossResourceConsistency
      .contentAddressedObservations := by
  simp [EstablishesCrossResourceConsistency]

theorem identicalTimestampsDoNotEstablishConsistency :
    ¬ EstablishesCrossResourceConsistency .identicalTimestamps := by
  simp [EstablishesCrossResourceConsistency]

theorem contractAloneDoesNotEstablishConsistency :
    ¬ EstablishesCrossResourceConsistency
      .declaredConsistencyContract := by
  simp [EstablishesCrossResourceConsistency]

theorem contractAloneDoesNotEstablishFreshness :
    ¬ EstablishesSemanticFreshness .declaredConsistencyContract := by
  simp [EstablishesSemanticFreshness]

theorem validatedSetEstablishesConsistency :
    EstablishesCrossResourceConsistency .validatedObservationSet := by
  simp [EstablishesCrossResourceConsistency]

theorem validatedSetEstablishesFreshness :
    EstablishesSemanticFreshness .validatedObservationSet := by
  simp [EstablishesSemanticFreshness]

theorem validatedSetCarriesExplicitContract
    {Resource Version Digest ObservationIdentity SetIdentity : Type}
    (set :
      ValidatedObservationSet
        Resource Version Digest ObservationIdentity SetIdentity) :
    ∃ contract :
        ObservationConsistencyContract
          Resource Version Digest ObservationIdentity,
      contract = set.contract := by
  exact ⟨set.contract, rfl⟩

theorem validatedSetCarriesConsistencyWitness
    {Resource Version Digest ObservationIdentity SetIdentity : Type}
    (set :
      ValidatedObservationSet
        Resource Version Digest ObservationIdentity SetIdentity) :
    set.observations.Pairwise set.contract.related :=
  set.pairwiseConsistent

theorem validatedSetCarriesFreshnessWitness
    {Resource Version Digest ObservationIdentity SetIdentity : Type}
    (set :
      ValidatedObservationSet
        Resource Version Digest ObservationIdentity SetIdentity) :
    ∀ observation ∈ set.observations,
      set.referenceTime ≤
        observation.observedAt + set.contract.freshnessBound :=
  set.freshEnough

theorem semanticGenerationRequiresValidatedSet
    {Resource Version Digest ObservationIdentity SetIdentity : Type}
    (input :
      SemanticGenerationInput
        Resource Version Digest ObservationIdentity SetIdentity) :
    ∃ set :
        ValidatedObservationSet
          Resource Version Digest ObservationIdentity SetIdentity,
      set = input.observationSet := by
  exact ⟨input.observationSet, rfl⟩

theorem versionComparabilityCarriesDeclaredDomain
    {Resource Version DomainIdentity : Type}
    (witness :
      VersionComparabilityWitness Resource Version DomainIdentity) :
    ∃ domain : Resource → Resource → Prop,
      ∃ relation : Version → Version → Prop,
        domain witness.leftResource witness.rightResource ∧
          relation witness.leftVersion witness.rightVersion := by
  exact
    ⟨witness.resourceDomain, witness.versionRelation,
      witness.resourcesComparable, witness.versionsRelated⟩

end PooFlowProof.PooC3.ObservationSetConsistency
