import PooFlowProof.PooC3.ActiveHeadPublication
import PooFlowProof.PooC3.MultiScopePublicationAtomicity

namespace PooFlowProof.PooC3.PublicationActivationCompletion

open PooFlowProof.PooC3.ActiveHeadPublication
open PooFlowProof.PooC3.MultiScopePublicationAtomicity

structure HeadTransitionReceipt
    (Scope Generation Version ReceiptIdentity : Type) where
  scopeIdentity : Scope
  publishedGeneration : Generation
  authoritativeVersion : Version
  receiptIdentity : ReceiptIdentity

structure HeadTransitionReceiptFromCommit
    (Scope Generation Version ReceiptIdentity
      HeadAdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type) where
  receipt :
    HeadTransitionReceipt Scope Generation Version ReceiptIdentity
  commit :
    ConditionalHeadCommit
      Scope Generation Version HeadAdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity
  scopeMatches :
    receipt.scopeIdentity = commit.after.scopeIdentity
  generationMatches :
    receipt.publishedGeneration = commit.after.selectedGeneration
  versionMatches :
    receipt.authoritativeVersion = commit.after.authoritativeVersion

structure HeadTransitionReceiptFromAtomicHeadSet
    (Scope Generation Version ReceiptIdentity
      AtomicAdapterProtocol AtomicWitnessIdentity : Type) where
  receipt :
    HeadTransitionReceipt Scope Generation Version ReceiptIdentity
  atomicityWitness :
    RuntimeAtomicityWitness
      Scope Generation Version AtomicAdapterProtocol AtomicWitnessIdentity
  projectedEntryPresent :
    (receipt.scopeIdentity,
      receipt.publishedGeneration,
      receipt.authoritativeVersion) ∈ atomicityWitness.after.entries

structure HeadObservation
    (Consumer Scope Generation Version
      PublicationReceiptIdentity ObservationReceiptIdentity : Type) where
  consumerIdentity : Consumer
  publication :
    HeadTransitionReceipt
      Scope Generation Version PublicationReceiptIdentity
  observationReceiptIdentity : ObservationReceiptIdentity
  observedGeneration : Generation
  generationMatches :
    observedGeneration = publication.publishedGeneration

structure GenerationPreparationReceipt
    (Consumer Scope Generation Version
      PublicationReceiptIdentity ObservationReceiptIdentity
      ArtifactIdentity PreparationReceiptIdentity : Type) where
  observation :
    HeadObservation
      Consumer Scope Generation Version
      PublicationReceiptIdentity ObservationReceiptIdentity
  preparedArtifactIdentity : ArtifactIdentity
  preparationReceiptIdentity : PreparationReceiptIdentity
  preparedGeneration : Generation
  generationMatches :
    preparedGeneration = observation.observedGeneration

structure LocalActivationReceipt
    (Consumer Scope Generation Version
      PublicationReceiptIdentity ObservationReceiptIdentity
      ArtifactIdentity PreparationReceiptIdentity
      ActivationEpoch ActivationReceiptIdentity : Type) where
  preparation :
    GenerationPreparationReceipt
      Consumer Scope Generation Version
      PublicationReceiptIdentity ObservationReceiptIdentity
      ArtifactIdentity PreparationReceiptIdentity
  activationEpoch : ActivationEpoch
  activationReceiptIdentity : ActivationReceiptIdentity
  activatedGeneration : Generation
  generationMatches :
    activatedGeneration = preparation.preparedGeneration

structure RolloutCompletionReceipt
    (Consumer Scope Generation Version
      PublicationReceiptIdentity ObservationReceiptIdentity
      ArtifactIdentity PreparationReceiptIdentity
      ActivationEpoch ActivationReceiptIdentity
      CompletionReceiptIdentity : Type) where
  completionReceiptIdentity : CompletionReceiptIdentity
  requiredConsumers : List Consumer
  activations :
    List
      (LocalActivationReceipt
        Consumer Scope Generation Version
        PublicationReceiptIdentity ObservationReceiptIdentity
        ArtifactIdentity PreparationReceiptIdentity
        ActivationEpoch ActivationReceiptIdentity)
  requiredConsumersActivated :
    ∀ consumer ∈ requiredConsumers,
      ∃ activation ∈ activations,
        activation.preparation.observation.consumerIdentity = consumer

inductive ActivationEvidenceKind where
  | publicationCommitted
  | consumerObserved
  | generationPrepared
  | locallyActivated
  | rolloutCompleted
  deriving DecidableEq, Repr

def EstablishesLocalActivation : ActivationEvidenceKind → Prop
  | .locallyActivated => True
  | .rolloutCompleted => True
  | .publicationCommitted => False
  | .consumerObserved => False
  | .generationPrepared => False

def EstablishesRolloutCompletion : ActivationEvidenceKind → Prop
  | .rolloutCompleted => True
  | .publicationCommitted => False
  | .consumerObserved => False
  | .generationPrepared => False
  | .locallyActivated => False

theorem publicationDoesNotEstablishLocalActivation :
    ¬ EstablishesLocalActivation .publicationCommitted := by
  simp [EstablishesLocalActivation]

theorem observationDoesNotEstablishLocalActivation :
    ¬ EstablishesLocalActivation .consumerObserved := by
  simp [EstablishesLocalActivation]

theorem preparationAloneDoesNotEstablishLocalActivation :
    ¬ EstablishesLocalActivation .generationPrepared := by
  simp [EstablishesLocalActivation]

theorem activationDoesNotEstablishRolloutCompletion :
    ¬ EstablishesRolloutCompletion .locallyActivated := by
  simp [EstablishesRolloutCompletion]

theorem localActivationCarriesHeadObservation
    {Consumer Scope Generation Version
      PublicationReceiptIdentity ObservationReceiptIdentity
      ArtifactIdentity PreparationReceiptIdentity
      ActivationEpoch ActivationReceiptIdentity : Type}
    (activation :
      LocalActivationReceipt
        Consumer Scope Generation Version
        PublicationReceiptIdentity ObservationReceiptIdentity
        ArtifactIdentity PreparationReceiptIdentity
        ActivationEpoch ActivationReceiptIdentity) :
    ∃ observation :
        HeadObservation
          Consumer Scope Generation Version
          PublicationReceiptIdentity ObservationReceiptIdentity,
      observation = activation.preparation.observation := by
  exact ⟨activation.preparation.observation, rfl⟩

theorem localActivationCarriesPreparationReceipt
    {Consumer Scope Generation Version
      PublicationReceiptIdentity ObservationReceiptIdentity
      ArtifactIdentity PreparationReceiptIdentity
      ActivationEpoch ActivationReceiptIdentity : Type}
    (activation :
      LocalActivationReceipt
        Consumer Scope Generation Version
        PublicationReceiptIdentity ObservationReceiptIdentity
        ArtifactIdentity PreparationReceiptIdentity
        ActivationEpoch ActivationReceiptIdentity) :
    ∃ preparation :
        GenerationPreparationReceipt
          Consumer Scope Generation Version
          PublicationReceiptIdentity ObservationReceiptIdentity
          ArtifactIdentity PreparationReceiptIdentity,
      preparation = activation.preparation := by
  exact ⟨activation.preparation, rfl⟩

theorem rolloutCompletionRequiresActivationEvidence
    {Consumer Scope Generation Version
      PublicationReceiptIdentity ObservationReceiptIdentity
      ArtifactIdentity PreparationReceiptIdentity
      ActivationEpoch ActivationReceiptIdentity
      CompletionReceiptIdentity : Type}
    (completion :
      RolloutCompletionReceipt
        Consumer Scope Generation Version
        PublicationReceiptIdentity ObservationReceiptIdentity
        ArtifactIdentity PreparationReceiptIdentity
        ActivationEpoch ActivationReceiptIdentity
        CompletionReceiptIdentity) :
    ∀ consumer ∈ completion.requiredConsumers,
      ∃ activation ∈ completion.activations,
        activation.preparation.observation.consumerIdentity = consumer :=
  completion.requiredConsumersActivated

theorem headTransitionReceiptCarriesConditionalCommit
    {Scope Generation Version ReceiptIdentity
      HeadAdapterProtocol ObservationReceipt
      Policy ProposalIdentity AuthorizationIdentity
      Effect EffectReceiptIdentity : Type}
    (bridge :
      HeadTransitionReceiptFromCommit
        Scope Generation Version ReceiptIdentity
        HeadAdapterProtocol ObservationReceipt
        Policy ProposalIdentity AuthorizationIdentity
        Effect EffectReceiptIdentity) :
    ∃ commit :
        ConditionalHeadCommit
          Scope Generation Version HeadAdapterProtocol ObservationReceipt
          Policy ProposalIdentity AuthorizationIdentity
          Effect EffectReceiptIdentity,
      commit = bridge.commit := by
  exact ⟨bridge.commit, rfl⟩

theorem headTransitionReceiptBelongsToAtomicHeadSetProjection
    {Scope Generation Version ReceiptIdentity
      AtomicAdapterProtocol AtomicWitnessIdentity : Type}
    (bridge :
      HeadTransitionReceiptFromAtomicHeadSet
        Scope Generation Version ReceiptIdentity
        AtomicAdapterProtocol AtomicWitnessIdentity) :
    (bridge.receipt.scopeIdentity,
      bridge.receipt.publishedGeneration,
      bridge.receipt.authoritativeVersion) ∈
        bridge.atomicityWitness.after.entries :=
  bridge.projectedEntryPresent

end PooFlowProof.PooC3.PublicationActivationCompletion
