import PooFlowProof.PooC3.AdmissionFairnessIsolation

namespace PooFlowProof.PooC3.ExplicitTemporalObservations

inductive ClockRole where
  | wallClock
  | monotonic
  | logicalVersion
  | authoritativeService
  deriving DecidableEq, Repr

inductive TemporalInputKind where
  | explicitObservation
  | missingObservation
  | implicitLiveRead
  deriving DecidableEq, Repr

def AdmitsPureTemporalEvaluation : TemporalInputKind → Prop
  | .explicitObservation => True
  | .missingObservation => False
  | .implicitLiveRead => False

def RequiresTemporalSuspension : TemporalInputKind → Prop
  | .explicitObservation => False
  | .missingObservation => True
  | .implicitLiveRead => False

def SupportsElapsedDuration : ClockRole → Prop
  | .monotonic => True
  | .wallClock => False
  | .logicalVersion => False
  | .authoritativeService => False

structure TimeObservation
    (Domain Instant ProvenanceIdentity ObservationIdentity : Type) where
  domain : Domain
  instant : Instant
  provenanceIdentity : ProvenanceIdentity
  observationIdentity : ObservationIdentity
  immutableInput : Prop
  immutabilityEstablished : immutableInput

structure PureTemporalEvaluation
    (Domain Instant ProvenanceIdentity ObservationIdentity : Type) where
  observation :
    TimeObservation
      Domain Instant ProvenanceIdentity ObservationIdentity
  readsLiveClock : Prop
  noLiveClockRead : ¬ readsLiveClock

inductive CrossDomainComparisonKind where
  | sameDomain
  | explicitConversion
  | unproven
  deriving DecidableEq, Repr

def AdmitsTemporalComparison : CrossDomainComparisonKind → Prop
  | .sameDomain => True
  | .explicitConversion => True
  | .unproven => False

structure ClockConversionEvidence
    (Domain Instant ConversionIdentity : Type) where
  sourceDomain : Domain
  targetDomain : Domain
  sourceInstant : Instant
  convertedInstant : Instant
  conversionIdentity : ConversionIdentity
  validConversion : Prop
  conversionEstablished : validConversion

structure TemporalReplay
    (InputIdentity ObservationIdentity PolicyIdentity Decision : Type) where
  inputIdentity : InputIdentity
  observationIdentity : ObservationIdentity
  policyIdentity : PolicyIdentity
  originalDecision : Decision
  replayDecision : Decision
  sameObservationReplay :
    replayDecision = originalDecision

structure TemporalIdentityScheme
    (InputIdentity ObservationIdentity PolicyIdentity EvaluationIdentity : Type)
    where
  identity :
    InputIdentity →
      ObservationIdentity →
      PolicyIdentity →
      EvaluationIdentity
  observationChangeChangesIdentity :
    ∀ input observationA observationB policy,
      observationA ≠ observationB →
        identity input observationA policy ≠
          identity input observationB policy

structure AuthoritativeTimeEvidence
    (ServiceIdentity ProvenanceIdentity ObservationIdentity : Type) where
  serviceIdentity : ServiceIdentity
  provenanceIdentity : ProvenanceIdentity
  observationIdentity : ObservationIdentity
  provenanceTrusted : Prop
  trustEstablished : provenanceTrusted

structure TemporalProposal (ProposalIdentity : Type) where
  proposalIdentity : ProposalIdentity
  carriesTerminationAuthority : Prop
  carriesFenceAuthority : Prop
  carriesReclamationAuthority : Prop
  noTerminationAuthority : ¬ carriesTerminationAuthority
  noFenceAuthority : ¬ carriesFenceAuthority
  noReclamationAuthority : ¬ carriesReclamationAuthority

structure DeadlineEvaluation
    (Domain Instant ObservationIdentity Decision : Type) where
  observationDomain : Domain
  deadlineDomain : Domain
  observedInstant : Instant
  deadlineInstant : Instant
  observationIdentity : ObservationIdentity
  decision : Decision
  domainsComparable : Prop
  comparisonEstablished : domainsComparable

theorem explicitObservationAdmitsPureEvaluation :
    AdmitsPureTemporalEvaluation .explicitObservation := by
  simp [AdmitsPureTemporalEvaluation]

theorem missingObservationFailsClosed :
    ¬ AdmitsPureTemporalEvaluation .missingObservation := by
  simp [AdmitsPureTemporalEvaluation]

theorem missingObservationRequiresSuspension :
    RequiresTemporalSuspension .missingObservation := by
  simp [RequiresTemporalSuspension]

theorem implicitLiveTimeReadIsRejected :
    ¬ AdmitsPureTemporalEvaluation .implicitLiveRead := by
  simp [AdmitsPureTemporalEvaluation]

theorem pureEvaluationReadsNoLiveClock
    {Domain Instant ProvenanceIdentity ObservationIdentity : Type}
    (evaluation :
      PureTemporalEvaluation
        Domain Instant ProvenanceIdentity ObservationIdentity) :
    ¬ evaluation.readsLiveClock :=
  evaluation.noLiveClockRead

theorem timeObservationCarriesImmutability
    {Domain Instant ProvenanceIdentity ObservationIdentity : Type}
    (observation :
      TimeObservation
        Domain Instant ProvenanceIdentity ObservationIdentity) :
    observation.immutableInput :=
  observation.immutabilityEstablished

theorem wallClockDoesNotProveElapsedDuration :
    ¬ SupportsElapsedDuration .wallClock := by
  simp [SupportsElapsedDuration]

theorem monotonicClockSupportsElapsedDuration :
    SupportsElapsedDuration .monotonic := by
  simp [SupportsElapsedDuration]

theorem logicalVersionIsNotElapsedDuration :
    ¬ SupportsElapsedDuration .logicalVersion := by
  simp [SupportsElapsedDuration]

theorem unprovenCrossDomainComparisonFailsClosed :
    ¬ AdmitsTemporalComparison .unproven := by
  simp [AdmitsTemporalComparison]

theorem sameDomainComparisonIsAdmitted :
    AdmitsTemporalComparison .sameDomain := by
  simp [AdmitsTemporalComparison]

theorem explicitClockConversionIsAdmitted :
    AdmitsTemporalComparison .explicitConversion := by
  simp [AdmitsTemporalComparison]

theorem conversionCarriesValidationEvidence
    {Domain Instant ConversionIdentity : Type}
    (conversion :
      ClockConversionEvidence Domain Instant ConversionIdentity) :
    conversion.validConversion :=
  conversion.conversionEstablished

theorem replayWithSameObservationIsStable
    {InputIdentity ObservationIdentity PolicyIdentity Decision : Type}
    (replay :
      TemporalReplay
        InputIdentity ObservationIdentity PolicyIdentity Decision) :
    replay.replayDecision = replay.originalDecision :=
  replay.sameObservationReplay

theorem changedObservationCreatesNewEvaluationIdentity
    {InputIdentity ObservationIdentity PolicyIdentity EvaluationIdentity : Type}
    (scheme :
      TemporalIdentityScheme
        InputIdentity ObservationIdentity PolicyIdentity EvaluationIdentity)
    (input : InputIdentity)
    (observationA observationB : ObservationIdentity)
    (policy : PolicyIdentity)
    (changed : observationA ≠ observationB) :
    scheme.identity input observationA policy ≠
      scheme.identity input observationB policy :=
  scheme.observationChangeChangesIdentity
    input observationA observationB policy changed

theorem authoritativeServiceTimeCarriesTrustedProvenance
    {ServiceIdentity ProvenanceIdentity ObservationIdentity : Type}
    (evidence :
      AuthoritativeTimeEvidence
        ServiceIdentity ProvenanceIdentity ObservationIdentity) :
    evidence.provenanceTrusted :=
  evidence.trustEstablished

theorem temporalProposalCarriesNoTerminationAuthority
    {ProposalIdentity : Type}
    (proposal : TemporalProposal ProposalIdentity) :
    ¬ proposal.carriesTerminationAuthority :=
  proposal.noTerminationAuthority

theorem temporalProposalCarriesNoFenceAuthority
    {ProposalIdentity : Type}
    (proposal : TemporalProposal ProposalIdentity) :
    ¬ proposal.carriesFenceAuthority :=
  proposal.noFenceAuthority

theorem temporalProposalCarriesNoReclamationAuthority
    {ProposalIdentity : Type}
    (proposal : TemporalProposal ProposalIdentity) :
    ¬ proposal.carriesReclamationAuthority :=
  proposal.noReclamationAuthority

theorem deadlineEvaluationCarriesComparableDomains
    {Domain Instant ObservationIdentity Decision : Type}
    (evaluation :
      DeadlineEvaluation Domain Instant ObservationIdentity Decision) :
    evaluation.domainsComparable :=
  evaluation.comparisonEstablished

end PooFlowProof.PooC3.ExplicitTemporalObservations
