import PooFlowProof.PooC3.ExplicitTemporalObservations

namespace PooFlowProof.PooC3.ExplicitEntropyDerivation

open PooFlowProof.PooC3.DistributedCacheAdmission

inductive EntropyInputKind where
  | deterministicNoEntropy
  | explicitSemanticEntropy
  | missingSemanticEntropy
  | implicitLiveRandomness
  deriving DecidableEq, Repr

def AdmitsPureDerivation : EntropyInputKind → Prop
  | .deterministicNoEntropy => True
  | .explicitSemanticEntropy => True
  | .missingSemanticEntropy => False
  | .implicitLiveRandomness => False

def RequiresEntropySuspension : EntropyInputKind → Prop
  | .deterministicNoEntropy => False
  | .explicitSemanticEntropy => False
  | .missingSemanticEntropy => True
  | .implicitLiveRandomness => False

structure SemanticEntropyObservation
    (EntropyIdentity EntropyMaterial ProvenanceIdentity : Type) where
  entropyIdentity : EntropyIdentity
  entropyMaterial : EntropyMaterial
  provenanceIdentity : ProvenanceIdentity
  immutableInput : Prop
  immutabilityEstablished : immutableInput

structure DeterministicDerivation
    (SemanticCutIdentity Result ResultIdentity : Type) where
  semanticCutIdentity : SemanticCutIdentity
  originalResult : Result
  replayResult : Result
  originalResultIdentity : ResultIdentity
  replayResultIdentity : ResultIdentity
  replayResultStable : replayResult = originalResult
  replayIdentityStable :
    replayResultIdentity = originalResultIdentity

structure SemanticEntropyDerivation
    (SemanticCutIdentity EntropyIdentity PurposeIdentity ResultIdentity : Type)
    where
  semanticCutIdentity : SemanticCutIdentity
  entropyIdentity : EntropyIdentity
  purposeIdentity : PurposeIdentity
  resultIdentity : ResultIdentity
  readsLiveRandomness : Prop
  noLiveRandomnessRead : ¬ readsLiveRandomness

structure DerivationIdentityScheme
    (SemanticCutIdentity EntropyIdentity PurposeIdentity ResultIdentity : Type)
    where
  identity :
    SemanticCutIdentity →
      EntropyIdentity →
      PurposeIdentity →
      ResultIdentity
  cutChangeChangesIdentity :
    ∀ cutA cutB entropy purpose,
      cutA ≠ cutB →
        identity cutA entropy purpose ≠
          identity cutB entropy purpose
  entropyChangeChangesIdentity :
    ∀ cut entropyA entropyB purpose,
      entropyA ≠ entropyB →
        identity cut entropyA purpose ≠
          identity cut entropyB purpose
  purposeChangeChangesIdentity :
    ∀ cut entropy purposeA purposeB,
      purposeA ≠ purposeB →
        identity cut entropy purposeA ≠
          identity cut entropy purposeB

structure OperationalRandomnessUse
    (OperationIdentity RandomnessReceiptIdentity : Type) where
  operationIdentity : OperationIdentity
  randomnessReceiptIdentity : RandomnessReceiptIdentity
  affectsSemanticResult : Prop
  doesNotAffectSemanticResult : ¬ affectsSemanticResult
  affectsSemanticCacheKey : Prop
  doesNotAffectSemanticCacheKey : ¬ affectsSemanticCacheKey

structure EntropyConflictQuarantine
    (SemanticKey ExpectedDigest ObservedDigest ConflictIdentity : Type) where
  conflict :
    DeterminismConflict
      SemanticKey ExpectedDigest ObservedDigest ConflictIdentity

theorem deterministicDerivationNeedsNoEntropy :
    AdmitsPureDerivation .deterministicNoEntropy := by
  simp [AdmitsPureDerivation]

theorem explicitSemanticEntropyAdmitsDerivation :
    AdmitsPureDerivation .explicitSemanticEntropy := by
  simp [AdmitsPureDerivation]

theorem missingSemanticEntropyFailsClosed :
    ¬ AdmitsPureDerivation .missingSemanticEntropy := by
  simp [AdmitsPureDerivation]

theorem missingSemanticEntropyRequiresSuspension :
    RequiresEntropySuspension .missingSemanticEntropy := by
  simp [RequiresEntropySuspension]

theorem implicitLiveRandomnessIsRejected :
    ¬ AdmitsPureDerivation .implicitLiveRandomness := by
  simp [AdmitsPureDerivation]

theorem semanticEntropyCarriesImmutableIdentity
    {EntropyIdentity EntropyMaterial ProvenanceIdentity : Type}
    (observation :
      SemanticEntropyObservation
        EntropyIdentity EntropyMaterial ProvenanceIdentity) :
    observation.immutableInput :=
  observation.immutabilityEstablished

theorem sameSemanticCutReplaysSameResult
    {SemanticCutIdentity Result ResultIdentity : Type}
    (derivation :
      DeterministicDerivation
        SemanticCutIdentity Result ResultIdentity) :
    derivation.replayResult = derivation.originalResult :=
  derivation.replayResultStable

theorem sameSemanticCutReplaysSameResultIdentity
    {SemanticCutIdentity Result ResultIdentity : Type}
    (derivation :
      DeterministicDerivation
        SemanticCutIdentity Result ResultIdentity) :
    derivation.replayResultIdentity =
      derivation.originalResultIdentity :=
  derivation.replayIdentityStable

theorem semanticDerivationReadsNoLiveRandomness
    {SemanticCutIdentity EntropyIdentity PurposeIdentity ResultIdentity : Type}
    (derivation :
      SemanticEntropyDerivation
        SemanticCutIdentity EntropyIdentity PurposeIdentity ResultIdentity) :
    ¬ derivation.readsLiveRandomness :=
  derivation.noLiveRandomnessRead

theorem semanticCutChangeCreatesNewResultIdentity
    {SemanticCutIdentity EntropyIdentity PurposeIdentity ResultIdentity : Type}
    (scheme :
      DerivationIdentityScheme
        SemanticCutIdentity EntropyIdentity PurposeIdentity ResultIdentity)
    (cutA cutB : SemanticCutIdentity)
    (entropy : EntropyIdentity)
    (purpose : PurposeIdentity)
    (changed : cutA ≠ cutB) :
    scheme.identity cutA entropy purpose ≠
      scheme.identity cutB entropy purpose :=
  scheme.cutChangeChangesIdentity cutA cutB entropy purpose changed

theorem entropyChangeCreatesNewResultIdentity
    {SemanticCutIdentity EntropyIdentity PurposeIdentity ResultIdentity : Type}
    (scheme :
      DerivationIdentityScheme
        SemanticCutIdentity EntropyIdentity PurposeIdentity ResultIdentity)
    (cut : SemanticCutIdentity)
    (entropyA entropyB : EntropyIdentity)
    (purpose : PurposeIdentity)
    (changed : entropyA ≠ entropyB) :
    scheme.identity cut entropyA purpose ≠
      scheme.identity cut entropyB purpose :=
  scheme.entropyChangeChangesIdentity
    cut entropyA entropyB purpose changed

theorem purposeChangeSeparatesDerivedIdentity
    {SemanticCutIdentity EntropyIdentity PurposeIdentity ResultIdentity : Type}
    (scheme :
      DerivationIdentityScheme
        SemanticCutIdentity EntropyIdentity PurposeIdentity ResultIdentity)
    (cut : SemanticCutIdentity)
    (entropy : EntropyIdentity)
    (purposeA purposeB : PurposeIdentity)
    (changed : purposeA ≠ purposeB) :
    scheme.identity cut entropy purposeA ≠
      scheme.identity cut entropy purposeB :=
  scheme.purposeChangeChangesIdentity
    cut entropy purposeA purposeB changed

theorem operationalRandomnessCannotChangeSemanticResult
    {OperationIdentity RandomnessReceiptIdentity : Type}
    (use :
      OperationalRandomnessUse
        OperationIdentity RandomnessReceiptIdentity) :
    ¬ use.affectsSemanticResult :=
  use.doesNotAffectSemanticResult

theorem operationalRandomnessCannotChangeSemanticCacheKey
    {OperationIdentity RandomnessReceiptIdentity : Type}
    (use :
      OperationalRandomnessUse
        OperationIdentity RandomnessReceiptIdentity) :
    ¬ use.affectsSemanticCacheKey :=
  use.doesNotAffectSemanticCacheKey

theorem entropyDeterminismConflictRequiresQuarantine
    {SemanticKey ExpectedDigest ObservedDigest ConflictIdentity : Type}
    (evidence :
      EntropyConflictQuarantine
        SemanticKey ExpectedDigest ObservedDigest ConflictIdentity) :
    evidence.conflict.quarantineRequired :=
  evidence.conflict.quarantineEstablished

end PooFlowProof.PooC3.ExplicitEntropyDerivation
