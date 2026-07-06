namespace PooFlowProof.PooC3

structure CompositionReceiptFacts where
  profileRefsOk : Bool
  overridesScopedOk : Bool
  modulesOrderedOk : Bool
  scenarioGateOk : Bool
  noRuntimeExecution : Bool
deriving Repr, DecidableEq

def compositionReceiptAccepted (facts : CompositionReceiptFacts) : Prop :=
  facts.profileRefsOk = true
    ∧ facts.overridesScopedOk = true
    ∧ facts.modulesOrderedOk = true
    ∧ facts.scenarioGateOk = true
    ∧ facts.noRuntimeExecution = true

theorem compositionReceiptAcceptedByAllOk
    (facts : CompositionReceiptFacts)
    (hprofile : facts.profileRefsOk = true)
    (hoverrides : facts.overridesScopedOk = true)
    (hmodules : facts.modulesOrderedOk = true)
    (hscenario : facts.scenarioGateOk = true)
    (hruntime : facts.noRuntimeExecution = true) :
    compositionReceiptAccepted facts := by
  unfold compositionReceiptAccepted
  exact ⟨hprofile, hoverrides, hmodules, hscenario, hruntime⟩

theorem compositionReceiptRejectedByProfileRefs
    (facts : CompositionReceiptFacts)
    (hprofile : facts.profileRefsOk = false) :
    ¬ compositionReceiptAccepted facts := by
  intro h
  unfold compositionReceiptAccepted at h
  rw [hprofile] at h
  cases h.left

theorem compositionReceiptRejectedByOverrideScope
    (facts : CompositionReceiptFacts)
    (hoverrides : facts.overridesScopedOk = false) :
    ¬ compositionReceiptAccepted facts := by
  intro h
  unfold compositionReceiptAccepted at h
  rw [hoverrides] at h
  cases h.right.left

theorem compositionReceiptRejectedByModuleOrder
    (facts : CompositionReceiptFacts)
    (hmodules : facts.modulesOrderedOk = false) :
    ¬ compositionReceiptAccepted facts := by
  intro h
  unfold compositionReceiptAccepted at h
  rw [hmodules] at h
  cases h.right.right.left

theorem compositionReceiptRejectedByScenarioGate
    (facts : CompositionReceiptFacts)
    (hscenario : facts.scenarioGateOk = false) :
    ¬ compositionReceiptAccepted facts := by
  intro h
  unfold compositionReceiptAccepted at h
  rw [hscenario] at h
  cases h.right.right.right.left

theorem compositionReceiptRejectedByRuntimeExecution
    (facts : CompositionReceiptFacts)
    (hruntime : facts.noRuntimeExecution = false) :
    ¬ compositionReceiptAccepted facts := by
  intro h
  unfold compositionReceiptAccepted at h
  rw [hruntime] at h
  cases h.right.right.right.right

end PooFlowProof.PooC3
