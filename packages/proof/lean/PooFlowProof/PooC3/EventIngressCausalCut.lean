import PooFlowProof.PooC3.ExplicitEntropyDerivation

namespace PooFlowProof.PooC3.EventIngressCausalCut

inductive IngressOutcomeKind where
  | arrivalCandidate
  | admitted
  | suspended
  | rejected
  | quarantined
  deriving DecidableEq, Repr

def AdmitsPureEventInput : IngressOutcomeKind → Prop
  | .admitted => True
  | .arrivalCandidate => False
  | .suspended => False
  | .rejected => False
  | .quarantined => False

structure IngressChecks where
  identityValid : Prop
  integrityValid : Prop
  schemaValid : Prop
  provenanceTrusted : Prop
  causalityCovered : Prop
  confidentialityAllowed : Prop

def IngressChecksHold (checks : IngressChecks) : Prop :=
  checks.identityValid ∧
    checks.integrityValid ∧
    checks.schemaValid ∧
    checks.provenanceTrusted ∧
    checks.causalityCovered ∧
    checks.confidentialityAllowed

structure EventEnvelope
    (EventIdentity DeliveryIdentity AttemptIdentity PayloadDigest
      SchemaIdentity ProvenanceIdentity : Type) where
  eventIdentity : EventIdentity
  deliveryIdentity : DeliveryIdentity
  attemptIdentity : AttemptIdentity
  payloadDigest : PayloadDigest
  schemaIdentity : SchemaIdentity
  provenanceIdentity : ProvenanceIdentity

structure IngressAdmissionReceipt
    (EventIdentity DeliveryIdentity AttemptIdentity PayloadDigest
      SchemaIdentity ProvenanceIdentity ReceiptIdentity : Type) where
  envelope :
    EventEnvelope
      EventIdentity DeliveryIdentity AttemptIdentity PayloadDigest
      SchemaIdentity ProvenanceIdentity
  checks : IngressChecks
  checksHold : IngressChecksHold checks
  outcome : IngressOutcomeKind
  admittedOutcome : outcome = .admitted
  receiptIdentity : ReceiptIdentity

structure DeduplicationReceipt
    (EventIdentity DeliveryIdentity DeduplicationIdentity : Type) where
  canonicalEventIdentity : EventIdentity
  duplicateDeliveryIdentity : DeliveryIdentity
  projectedEventIdentity : EventIdentity
  preservesEventIdentity :
    projectedEventIdentity = canonicalEventIdentity
  deduplicationIdentity : DeduplicationIdentity

structure ImmutableCausalCut
    (EventIdentity CutIdentity : Type) where
  events : List EventIdentity
  cutIdentity : CutIdentity
  immutableInput : Prop
  immutabilityEstablished : immutableInput
  causalParent : EventIdentity → EventIdentity → Prop
  everyParentCovered :
    ∀ event ∈ events,
      ∀ parent,
        causalParent parent event →
          parent ∈ events

structure CausalClosureSuspension (EventIdentity SuspensionIdentity : Type) where
  missingParents : List EventIdentity
  missingParentsNonempty : missingParents ≠ []
  suspensionIdentity : SuspensionIdentity
  pureEvaluationAllowed : Prop
  noPureEvaluation : ¬ pureEvaluationAllowed

structure WatermarkCoverageEvidence
    (SourceIdentity Position CoverageIdentity : Type) where
  sourceIdentity : SourceIdentity
  coveredThrough : Position
  coverageIdentity : CoverageIdentity
  coverageEstablished : Prop
  coverageProof : coverageEstablished
  closesCausalCut : Prop
  closureRequiresCoverage :
    closesCausalCut → coverageEstablished

inductive AcknowledgementStage where
  | transportReceived
  | ingressAdmitted
  | durablyRecorded
  | effectCommitted
  deriving DecidableEq, Repr

def ClaimsEffectCommit : AcknowledgementStage → Prop
  | .effectCommitted => True
  | .transportReceived => False
  | .ingressAdmitted => False
  | .durablyRecorded => False

structure AcknowledgementReceipt
    (EventIdentity AcknowledgementIdentity : Type) where
  eventIdentity : EventIdentity
  stage : AcknowledgementStage
  acknowledgementIdentity : AcknowledgementIdentity

inductive LateEventOutcomeKind where
  | newCut
  | quarantined
  | rejected
  | suspended
  deriving DecidableEq, Repr

def SilentlyMutatesClosedCut : LateEventOutcomeKind → Prop
  | .newCut => False
  | .quarantined => False
  | .rejected => False
  | .suspended => False

structure CausalCutIdentityScheme
    (AdmittedEventSetIdentity CutIdentity : Type) where
  identity : AdmittedEventSetIdentity → CutIdentity
  admittedSetChangeChangesCut :
    ∀ eventSetA eventSetB,
      eventSetA ≠ eventSetB →
        identity eventSetA ≠ identity eventSetB

structure CausalCutReplay
    (CutIdentity TemporalObservationIdentity EntropyIdentity Result : Type) where
  cutIdentity : CutIdentity
  temporalObservationIdentity : TemporalObservationIdentity
  entropyIdentity : EntropyIdentity
  originalResult : Result
  replayResult : Result
  replayStable : replayResult = originalResult

theorem transportArrivalIsNotPureInput :
    ¬ AdmitsPureEventInput .arrivalCandidate := by
  simp [AdmitsPureEventInput]

theorem admittedEnvelopeMayBecomePureInput :
    AdmitsPureEventInput .admitted := by
  simp [AdmitsPureEventInput]

theorem suspendedIngressFailsClosed :
    ¬ AdmitsPureEventInput .suspended := by
  simp [AdmitsPureEventInput]

theorem rejectedIngressFailsClosed :
    ¬ AdmitsPureEventInput .rejected := by
  simp [AdmitsPureEventInput]

theorem quarantinedIngressFailsClosed :
    ¬ AdmitsPureEventInput .quarantined := by
  simp [AdmitsPureEventInput]

theorem admittedEnvelopeCarriesAllIngressChecks
    {EventIdentity DeliveryIdentity AttemptIdentity PayloadDigest
      SchemaIdentity ProvenanceIdentity ReceiptIdentity : Type}
    (receipt :
      IngressAdmissionReceipt
        EventIdentity DeliveryIdentity AttemptIdentity PayloadDigest
        SchemaIdentity ProvenanceIdentity ReceiptIdentity) :
    IngressChecksHold receipt.checks :=
  receipt.checksHold

theorem duplicateDeliveryPreservesEventIdentity
    {EventIdentity DeliveryIdentity DeduplicationIdentity : Type}
    (receipt :
      DeduplicationReceipt
        EventIdentity DeliveryIdentity DeduplicationIdentity) :
    receipt.projectedEventIdentity =
      receipt.canonicalEventIdentity :=
  receipt.preservesEventIdentity

theorem causalCutIsImmutable
    {EventIdentity CutIdentity : Type}
    (cut : ImmutableCausalCut EventIdentity CutIdentity) :
    cut.immutableInput :=
  cut.immutabilityEstablished

theorem causalCutCoversEveryParent
    {EventIdentity CutIdentity : Type}
    (cut : ImmutableCausalCut EventIdentity CutIdentity) :
    ∀ event ∈ cut.events,
      ∀ parent,
        cut.causalParent parent event →
          parent ∈ cut.events :=
  cut.everyParentCovered

theorem missingCausalParentsSuspendEvaluation
    {EventIdentity SuspensionIdentity : Type}
    (suspension :
      CausalClosureSuspension EventIdentity SuspensionIdentity) :
    ¬ suspension.pureEvaluationAllowed :=
  suspension.noPureEvaluation

theorem causalSuspensionNamesMissingParents
    {EventIdentity SuspensionIdentity : Type}
    (suspension :
      CausalClosureSuspension EventIdentity SuspensionIdentity) :
    suspension.missingParents ≠ [] :=
  suspension.missingParentsNonempty

theorem watermarkClosureRequiresCoverage
    {SourceIdentity Position CoverageIdentity : Type}
    (watermark :
      WatermarkCoverageEvidence
        SourceIdentity Position CoverageIdentity)
    (closes : watermark.closesCausalCut) :
    watermark.coverageEstablished :=
  watermark.closureRequiresCoverage closes

theorem transportReceiptDoesNotClaimEffectCommit :
    ¬ ClaimsEffectCommit .transportReceived := by
  simp [ClaimsEffectCommit]

theorem admissionAckDoesNotClaimEffectCommit :
    ¬ ClaimsEffectCommit .ingressAdmitted := by
  simp [ClaimsEffectCommit]

theorem durableRecordAckDoesNotClaimEffectCommit :
    ¬ ClaimsEffectCommit .durablyRecorded := by
  simp [ClaimsEffectCommit]

theorem effectCommitAckClaimsEffectCommit :
    ClaimsEffectCommit .effectCommitted := by
  simp [ClaimsEffectCommit]

theorem lateEventNeverSilentlyMutatesClosedCut
    (outcome : LateEventOutcomeKind) :
    ¬ SilentlyMutatesClosedCut outcome := by
  cases outcome <;> simp [SilentlyMutatesClosedCut]

theorem admittedEventSetChangeCreatesNewCutIdentity
    {AdmittedEventSetIdentity CutIdentity : Type}
    (scheme :
      CausalCutIdentityScheme
        AdmittedEventSetIdentity CutIdentity)
    (eventSetA eventSetB : AdmittedEventSetIdentity)
    (changed : eventSetA ≠ eventSetB) :
    scheme.identity eventSetA ≠ scheme.identity eventSetB :=
  scheme.admittedSetChangeChangesCut eventSetA eventSetB changed

theorem sameCausalCutReplayIsStable
    {CutIdentity TemporalObservationIdentity EntropyIdentity Result : Type}
    (replay :
      CausalCutReplay
        CutIdentity TemporalObservationIdentity EntropyIdentity Result) :
    replay.replayResult = replay.originalResult :=
  replay.replayStable

end PooFlowProof.PooC3.EventIngressCausalCut
