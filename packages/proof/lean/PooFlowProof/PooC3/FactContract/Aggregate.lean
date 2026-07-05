import PooFlowProof.PooC3.FactContract.Session
import PooFlowProof.PooC3.FactContract.UserInterface

namespace PooFlowProof.PooC3.FactContract

def allFactKeyContracts : List FactKeyContract :=
  sessionHandoffFactKeyContracts ++ uiScenarioFactKeyContracts

def allSchemeFactKeys : List SchemeFactKey :=
  sessionHandoffSchemeFactKeys ++ uiScenarioSchemeFactKeys

def allSchemeFactExternalNames : List String :=
  allSchemeFactKeys.map SchemeFactKey.externalName

theorem all_contract_keys_exact :
    factKeyContractKeys allFactKeyContracts = allSchemeFactKeys := by
  unfold allFactKeyContracts allSchemeFactKeys factKeyContractKeys
  rw [List.map_append]
  rfl

theorem all_scheme_fact_keys_nodup :
    allSchemeFactKeys.Nodup := by
  native_decide

theorem all_scheme_fact_external_names_nodup :
    allSchemeFactExternalNames.Nodup := by
  native_decide

theorem all_contracts_well_typed :
    ∀ contract,
      contract ∈ allFactKeyContracts ->
      contract.wellTyped := by
  intro contract member
  simp [allFactKeyContracts] at member
  rcases member with member | member
  · exact session_handoff_contracts_well_typed contract member
  · exact ui_scenario_contracts_well_typed contract member

theorem all_contracts_exactly_typed :
    ∀ contract,
      contract ∈ allFactKeyContracts ->
      contract.exactlyTyped := by
  intro contract member
  simp [allFactKeyContracts] at member
  rcases member with member | member
  · exact session_handoff_contracts_exactly_typed contract member
  · exact ui_scenario_contracts_exactly_typed contract member

end PooFlowProof.PooC3.FactContract
