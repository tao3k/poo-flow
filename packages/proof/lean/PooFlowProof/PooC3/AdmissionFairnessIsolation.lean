import PooFlowProof.PooC3.DistributedEvaluatorDelegation

namespace PooFlowProof.PooC3.AdmissionFairnessIsolation

open PooFlowProof.PooC3.DistributedEvaluatorDelegation

inductive ResourceAdmissionKind where
  | admitted
  | queued
  | suspended
  | rejected
  deriving DecidableEq, Repr

def ConsumesExecutionResources : ResourceAdmissionKind → Prop
  | .admitted => True
  | .queued => False
  | .suspended => False
  | .rejected => False

def IsExplicitBackpressure : ResourceAdmissionKind → Prop
  | .admitted => False
  | .queued => True
  | .suspended => True
  | .rejected => True

structure HierarchicalResourceBudget
    (Scope Dimension : Type) where
  parentScope : Scope
  childScopes : List Scope
  parentCapacity : Dimension → Nat
  admittedChildAggregate : Dimension → Nat
  aggregateWithinParent :
    ∀ dimension,
      admittedChildAggregate dimension ≤ parentCapacity dimension

structure ReservationIsolation
    (Tenant Dimension : Type) where
  tenant : Tenant
  reserved : Dimension → Nat
  consumed : Dimension → Nat
  consumptionWithinReservation :
    ∀ dimension, consumed dimension ≤ reserved dimension

structure BoundedQueueAdmission
    (Demand QueueIdentity CapacitySnapshot : Type) where
  demand : Demand
  queueIdentity : QueueIdentity
  capacitySnapshot : CapacitySnapshot
  queueDepth : Nat
  queueBound : Nat
  bounded : queueDepth ≤ queueBound
  outcome : ResourceAdmissionKind
  queuedOutcomeRequiresBackpressure :
    outcome = .queued → IsExplicitBackpressure outcome

structure ConditionalFairness (Demand : Type) where
  demand : Demand
  continuouslyEligible : Prop
  finiteEligibleCompetition : Prop
  schedulerMakesProgress : Prop
  eventuallyScheduled : Prop
  fairnessGuarantee :
    continuouslyEligible →
      finiteEligibleCompetition →
      schedulerMakesProgress →
      eventuallyScheduled

structure SchedulingSemanticIsolation
    (SemanticResolution SchedulingDecision : Type) where
  semanticBeforeScheduling : SemanticResolution
  schedulingDecision : SchedulingDecision
  semanticAfterScheduling : SemanticResolution
  schedulingPreservesResolution :
    semanticAfterScheduling = semanticBeforeScheduling

structure PrioritySeparation
    (SlotContributionPriority RuntimeSchedulingPriority : Type) where
  slotContributionPriority : SlotContributionPriority
  runtimeSchedulingPriority : RuntimeSchedulingPriority
  semanticPriorityOwner : Prop
  runtimePriorityOwner : Prop
  ownersSeparated : semanticPriorityOwner ∧ runtimePriorityOwner

structure AdmissionSuspensionHandoff
    (DemandIdentity ObservationCut PolicyIdentity ResumeToken : Type) where
  outcome : ResourceAdmissionKind
  suspendedOutcome : outcome = .suspended
  suspension :
    PortableSuspension
      DemandIdentity ObservationCut PolicyIdentity ResumeToken

structure ResourceReleaseReceipt
    (Demand ResourceIdentity ReceiptIdentity : Type) where
  demand : Demand
  resourceIdentity : ResourceIdentity
  receiptIdentity : ReceiptIdentity
  released : Prop
  releaseEstablished : released
  remainsConsumed : Prop
  noRemainingConsumption : ¬ remainsConsumed

theorem admittedDemandConsumesResources :
    ConsumesExecutionResources .admitted := by
  simp [ConsumesExecutionResources]

theorem queuedDemandDoesNotConsumeExecutionResources :
    ¬ ConsumesExecutionResources .queued := by
  simp [ConsumesExecutionResources]

theorem suspendedDemandDoesNotConsumeExecutionResources :
    ¬ ConsumesExecutionResources .suspended := by
  simp [ConsumesExecutionResources]

theorem rejectedDemandDoesNotConsumeExecutionResources :
    ¬ ConsumesExecutionResources .rejected := by
  simp [ConsumesExecutionResources]

theorem queueIsExplicitBackpressure :
    IsExplicitBackpressure .queued := by
  simp [IsExplicitBackpressure]

theorem suspensionIsExplicitBackpressure :
    IsExplicitBackpressure .suspended := by
  simp [IsExplicitBackpressure]

theorem rejectionIsExplicitBackpressure :
    IsExplicitBackpressure .rejected := by
  simp [IsExplicitBackpressure]

theorem hierarchicalAllocationConservesParentCapacity
    {Scope Dimension : Type}
    (budget : HierarchicalResourceBudget Scope Dimension) :
    ∀ dimension,
      budget.admittedChildAggregate dimension ≤
        budget.parentCapacity dimension :=
  budget.aggregateWithinParent

theorem tenantConsumptionStaysWithinReservation
    {Tenant Dimension : Type}
    (isolation : ReservationIsolation Tenant Dimension) :
    ∀ dimension,
      isolation.consumed dimension ≤ isolation.reserved dimension :=
  isolation.consumptionWithinReservation

theorem admissionQueueIsBounded
    {Demand QueueIdentity CapacitySnapshot : Type}
    (admission :
      BoundedQueueAdmission Demand QueueIdentity CapacitySnapshot) :
    admission.queueDepth ≤ admission.queueBound :=
  admission.bounded

theorem queuedOutcomeCarriesBackpressure
    {Demand QueueIdentity CapacitySnapshot : Type}
    (admission :
      BoundedQueueAdmission Demand QueueIdentity CapacitySnapshot)
    (queued : admission.outcome = .queued) :
    IsExplicitBackpressure admission.outcome :=
  admission.queuedOutcomeRequiresBackpressure queued

theorem fairnessRequiresEligibilityCompetitionAndProgress
    {Demand : Type}
    (fairness : ConditionalFairness Demand)
    (eligible : fairness.continuouslyEligible)
    (finiteCompetition : fairness.finiteEligibleCompetition)
    (progress : fairness.schedulerMakesProgress) :
    fairness.eventuallyScheduled :=
  fairness.fairnessGuarantee eligible finiteCompetition progress

theorem schedulingCannotChangeSemanticResolution
    {SemanticResolution SchedulingDecision : Type}
    (isolation :
      SchedulingSemanticIsolation
        SemanticResolution SchedulingDecision) :
    isolation.semanticAfterScheduling =
      isolation.semanticBeforeScheduling :=
  isolation.schedulingPreservesResolution

theorem slotAndRuntimePriorityHaveDistinctOwners
    {SlotContributionPriority RuntimeSchedulingPriority : Type}
    (separation :
      PrioritySeparation
        SlotContributionPriority RuntimeSchedulingPriority) :
    separation.semanticPriorityOwner ∧ separation.runtimePriorityOwner :=
  separation.ownersSeparated

theorem backpressureSuspensionCarriesPortableState
    {DemandIdentity ObservationCut PolicyIdentity ResumeToken : Type}
    (handoff :
      AdmissionSuspensionHandoff
        DemandIdentity ObservationCut PolicyIdentity ResumeToken) :
    ∃ suspension :
        PortableSuspension
          DemandIdentity ObservationCut PolicyIdentity ResumeToken,
      suspension = handoff.suspension := by
  exact ⟨handoff.suspension, rfl⟩

theorem backpressureSuspensionCarriesNoActionAuthority
    {DemandIdentity ObservationCut PolicyIdentity ResumeToken : Type}
    (handoff :
      AdmissionSuspensionHandoff
        DemandIdentity ObservationCut PolicyIdentity ResumeToken) :
    ¬ handoff.suspension.carriesActionAuthority :=
  handoff.suspension.noActionAuthority

theorem resourceReleaseIsObservable
    {Demand ResourceIdentity ReceiptIdentity : Type}
    (receipt :
      ResourceReleaseReceipt Demand ResourceIdentity ReceiptIdentity) :
    receipt.released :=
  receipt.releaseEstablished

theorem releasedResourceIsNotStillConsumed
    {Demand ResourceIdentity ReceiptIdentity : Type}
    (receipt :
      ResourceReleaseReceipt Demand ResourceIdentity ReceiptIdentity) :
    ¬ receipt.remainsConsumed :=
  receipt.noRemainingConsumption

end PooFlowProof.PooC3.AdmissionFairnessIsolation
