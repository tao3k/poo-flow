import PooFlowProof.PooC3.ScenarioGap

namespace PooFlowProof

def GeneratedScenarioGapRuntimeRowFacts : ScenarioRuntimeRowFacts :=
  { planOk := true
    rejectionsOk := true
    acceptedOk := true }

def GeneratedScenarioGapRuntimeRowComplete : Bool := true

theorem GeneratedScenarioGapRuntimeRowComplete_ok :
    GeneratedScenarioGapRuntimeRowComplete = true := by
  rfl

theorem GeneratedScenarioGapRuntimeRowMatches :
    runtimeRowMatchesPlan GeneratedScenarioGapRuntimeRowFacts := by
  unfold runtimeRowMatchesPlan GeneratedScenarioGapRuntimeRowFacts
  decide

end PooFlowProof
