namespace PooFlowProof.PooC3.EvaluationContextNarrowing

universe u

structure PureEvaluationContextPolicy
    (Capability Adapter Disclosure : Type u) where
  allowsCapability : Capability → Prop
  allowsAdapter : Adapter → Prop
  allowsDisclosure : Disclosure → Prop

structure LiveEvaluationContext
    (Capability Adapter Disclosure : Type u) where
  policy : PureEvaluationContextPolicy Capability Adapter Disclosure
  remainingBudget : Nat
  deadline : Nat
  remainingContinuations : Nat
  cancelled : Prop

structure Narrows
    {Capability Adapter Disclosure : Type u}
    (child parent :
      LiveEvaluationContext Capability Adapter Disclosure) : Prop where
  capabilitySubset :
    (capability : Capability) →
    child.policy.allowsCapability capability →
    parent.policy.allowsCapability capability
  adapterSubset :
    (adapter : Adapter) →
    child.policy.allowsAdapter adapter →
    parent.policy.allowsAdapter adapter
  disclosureSubset :
    (disclosure : Disclosure) →
    child.policy.allowsDisclosure disclosure →
    parent.policy.allowsDisclosure disclosure
  budgetConserved :
    child.remainingBudget ≤ parent.remainingBudget
  deadlineNarrowed :
    child.deadline ≤ parent.deadline
  continuationsConserved :
    child.remainingContinuations ≤ parent.remainingContinuations
  parentCancellationPropagates :
    parent.cancelled → child.cancelled

structure ExecutionDemand
    (Capability Adapter Disclosure : Type u) where
  capability : Capability
  adapter : Adapter
  disclosure : Disclosure
  budgetCost : Nat
  completesBy : Nat
  continuationUses : Nat

structure Admitted
    {Capability Adapter Disclosure : Type u}
    (context : LiveEvaluationContext Capability Adapter Disclosure)
    (demand : ExecutionDemand Capability Adapter Disclosure) : Prop where
  capabilityAllowed :
    context.policy.allowsCapability demand.capability
  adapterAllowed :
    context.policy.allowsAdapter demand.adapter
  disclosureAllowed :
    context.policy.allowsDisclosure demand.disclosure
  budgetAvailable :
    demand.budgetCost ≤ context.remainingBudget
  completesWithinDeadline :
    demand.completesBy ≤ context.deadline
  continuationsAvailable :
    demand.continuationUses ≤ context.remainingContinuations
  notCancelled :
    ¬ context.cancelled

theorem narrowingIsReflexive
    {Capability Adapter Disclosure : Type u}
    (context :
      LiveEvaluationContext Capability Adapter Disclosure) :
    Narrows context context := by
  exact
    { capabilitySubset := fun _ allowed => allowed
      adapterSubset := fun _ allowed => allowed
      disclosureSubset := fun _ allowed => allowed
      budgetConserved := Nat.le_refl _
      deadlineNarrowed := Nat.le_refl _
      continuationsConserved := Nat.le_refl _
      parentCancellationPropagates := fun cancelled => cancelled }

theorem narrowingIsTransitive
    {Capability Adapter Disclosure : Type u}
    {child middle parent :
      LiveEvaluationContext Capability Adapter Disclosure}
    (childToMiddle : Narrows child middle)
    (middleToParent : Narrows middle parent) :
    Narrows child parent := by
  exact
    { capabilitySubset := fun capability allowed =>
        middleToParent.capabilitySubset capability
          (childToMiddle.capabilitySubset capability allowed)
      adapterSubset := fun adapter allowed =>
        middleToParent.adapterSubset adapter
          (childToMiddle.adapterSubset adapter allowed)
      disclosureSubset := fun disclosure allowed =>
        middleToParent.disclosureSubset disclosure
          (childToMiddle.disclosureSubset disclosure allowed)
      budgetConserved :=
        Nat.le_trans
          childToMiddle.budgetConserved
          middleToParent.budgetConserved
      deadlineNarrowed :=
        Nat.le_trans
          childToMiddle.deadlineNarrowed
          middleToParent.deadlineNarrowed
      continuationsConserved :=
        Nat.le_trans
          childToMiddle.continuationsConserved
          middleToParent.continuationsConserved
      parentCancellationPropagates := fun parentCancelled =>
        childToMiddle.parentCancellationPropagates
          (middleToParent.parentCancellationPropagates parentCancelled) }

theorem childAdmissionImpliesParentAdmission
    {Capability Adapter Disclosure : Type u}
    {child parent :
      LiveEvaluationContext Capability Adapter Disclosure}
    {demand : ExecutionDemand Capability Adapter Disclosure}
    (narrowing : Narrows child parent)
    (admitted : Admitted child demand) :
    Admitted parent demand := by
  exact
    { capabilityAllowed :=
        narrowing.capabilitySubset demand.capability
          admitted.capabilityAllowed
      adapterAllowed :=
        narrowing.adapterSubset demand.adapter
          admitted.adapterAllowed
      disclosureAllowed :=
        narrowing.disclosureSubset demand.disclosure
          admitted.disclosureAllowed
      budgetAvailable :=
        Nat.le_trans admitted.budgetAvailable narrowing.budgetConserved
      completesWithinDeadline :=
        Nat.le_trans
          admitted.completesWithinDeadline
          narrowing.deadlineNarrowed
      continuationsAvailable :=
        Nat.le_trans
          admitted.continuationsAvailable
          narrowing.continuationsConserved
      notCancelled := fun parentCancelled =>
        admitted.notCancelled
          (narrowing.parentCancellationPropagates parentCancelled) }

theorem childBudgetCannotExceedParent
    {Capability Adapter Disclosure : Type u}
    {child parent :
      LiveEvaluationContext Capability Adapter Disclosure}
    (narrowing : Narrows child parent) :
    child.remainingBudget ≤ parent.remainingBudget :=
  narrowing.budgetConserved

theorem childContinuationsCannotExceedParent
    {Capability Adapter Disclosure : Type u}
    {child parent :
      LiveEvaluationContext Capability Adapter Disclosure}
    (narrowing : Narrows child parent) :
    child.remainingContinuations ≤ parent.remainingContinuations :=
  narrowing.continuationsConserved

theorem parentCancellationCancelsChild
    {Capability Adapter Disclosure : Type u}
    {child parent :
      LiveEvaluationContext Capability Adapter Disclosure}
    (narrowing : Narrows child parent)
    (parentCancelled : parent.cancelled) :
    child.cancelled :=
  narrowing.parentCancellationPropagates parentCancelled

end PooFlowProof.PooC3.EvaluationContextNarrowing
