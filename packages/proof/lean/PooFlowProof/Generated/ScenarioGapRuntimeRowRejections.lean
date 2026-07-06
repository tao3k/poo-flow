import PooFlowProof.PooC3.ScenarioGap

namespace PooFlowProof.PooC3

private theorem generatedRuntimeRowRejectedByPlan
    (facts : ScenarioRuntimeRowFacts)
    (hplan : facts.planOk = false) :
    ¬ runtimeRowMatchesPlan facts := by
  intro h
  unfold runtimeRowMatchesPlan at h
  rw [hplan] at h
  cases h.left

private theorem generatedRuntimeRowRejectedByRejections
    (facts : ScenarioRuntimeRowFacts)
    (hrejections : facts.rejectionsOk = false) :
    ¬ runtimeRowMatchesPlan facts := by
  intro h
  unfold runtimeRowMatchesPlan at h
  rw [hrejections] at h
  cases h.right.left

private theorem generatedRuntimeRowRejectedByAccepted
    (facts : ScenarioRuntimeRowFacts)
    (haccepted : facts.acceptedOk = false) :
    ¬ runtimeRowMatchesPlan facts := by
  intro h
  unfold runtimeRowMatchesPlan at h
  rw [haccepted] at h
  cases h.right.right

def GeneratedScenarioGapMissingKindRuntimeRowFacts : ScenarioRuntimeRowFacts where
  planOk := true
  rejectionsOk := true
  acceptedOk := false

theorem GeneratedScenarioGapMissingKindRuntimeRowRejected :
    ¬ runtimeRowMatchesPlan GeneratedScenarioGapMissingKindRuntimeRowFacts :=
  generatedRuntimeRowRejectedByAccepted
    GeneratedScenarioGapMissingKindRuntimeRowFacts
    rfl

def GeneratedScenarioGapWrongPlanRuntimeRowFacts : ScenarioRuntimeRowFacts where
  planOk := false
  rejectionsOk := true
  acceptedOk := true

theorem GeneratedScenarioGapWrongPlanRuntimeRowRejected :
    ¬ runtimeRowMatchesPlan GeneratedScenarioGapWrongPlanRuntimeRowFacts :=
  generatedRuntimeRowRejectedByPlan
    GeneratedScenarioGapWrongPlanRuntimeRowFacts
    rfl

def GeneratedScenarioGapRejectedKindRuntimeRowFacts : ScenarioRuntimeRowFacts where
  planOk := true
  rejectionsOk := false
  acceptedOk := true

theorem GeneratedScenarioGapRejectedKindRuntimeRowRejected :
    ¬ runtimeRowMatchesPlan GeneratedScenarioGapRejectedKindRuntimeRowFacts :=
  generatedRuntimeRowRejectedByRejections
    GeneratedScenarioGapRejectedKindRuntimeRowFacts
    rfl

end PooFlowProof.PooC3
