#ifndef POO_FLOW_PROOF_FFI_H
#define POO_FLOW_PROOF_FFI_H

#include <stdint.h>

#define POO_FLOW_PROOF_ABI_VERSION 1u
#define POO_FLOW_PROOF_OBLIGATION_SCHEMA_VERSION 1u
#define POO_FLOW_PROOF_TAG_WIDTH_UINT32 32u
#define POO_FLOW_PROOF_OBLIGATION_COUNT 10u

#define POO_FLOW_OBLIGATION_UI_CONFIG_WELL_FORMED (1u << 0)
#define POO_FLOW_OBLIGATION_UI_PROFILE_POLICY_LINKED (1u << 1)
#define POO_FLOW_OBLIGATION_LOOP_STRATEGY_PLAN_WELL_FORMED (1u << 2)
#define POO_FLOW_OBLIGATION_EXECUTION_POLICY_CAPABILITY_BOUNDED (1u << 3)
#define POO_FLOW_OBLIGATION_POLICY_STRATEGY_DETERMINISTIC (1u << 4)
#define POO_FLOW_OBLIGATION_RUNTIME_COMMAND_INERT (1u << 5)
#define POO_FLOW_OBLIGATION_WORKFLOW_AGREEMENT_LINKED (1u << 6)
#define POO_FLOW_OBLIGATION_SANDBOX_BOUNDARY_LINKED (1u << 7)
#define POO_FLOW_OBLIGATION_RUNTIME_HANDOFF_OWNER_LINKED (1u << 8)
#define POO_FLOW_OBLIGATION_PROOF_CASE_VECTOR_COMPLETE (1u << 9)

#define POO_FLOW_PROOF_REQUIRED_OBLIGATION_MASK \
  (POO_FLOW_OBLIGATION_UI_CONFIG_WELL_FORMED | \
   POO_FLOW_OBLIGATION_UI_PROFILE_POLICY_LINKED | \
   POO_FLOW_OBLIGATION_LOOP_STRATEGY_PLAN_WELL_FORMED | \
   POO_FLOW_OBLIGATION_EXECUTION_POLICY_CAPABILITY_BOUNDED | \
   POO_FLOW_OBLIGATION_POLICY_STRATEGY_DETERMINISTIC | \
   POO_FLOW_OBLIGATION_RUNTIME_COMMAND_INERT | \
   POO_FLOW_OBLIGATION_WORKFLOW_AGREEMENT_LINKED | \
   POO_FLOW_OBLIGATION_SANDBOX_BOUNDARY_LINKED | \
   POO_FLOW_OBLIGATION_RUNTIME_HANDOFF_OWNER_LINKED | \
   POO_FLOW_OBLIGATION_PROOF_CASE_VECTOR_COMPLETE)

uint32_t poo_flow_proof_abi_version_raw(void);
uint32_t poo_flow_proof_obligation_schema_version_raw(void);
uint32_t poo_flow_proof_tag_width_raw(void);
uint32_t poo_flow_proof_obligation_count_raw(void);
uint32_t poo_flow_proof_required_obligation_mask_raw(void);
uint32_t poo_flow_proof_ui_config_well_formed_bit_raw(void);
uint32_t poo_flow_proof_ui_profile_policy_linked_bit_raw(void);
uint32_t poo_flow_proof_loop_strategy_plan_well_formed_bit_raw(void);
uint32_t poo_flow_proof_execution_policy_capability_bounded_bit_raw(void);
uint32_t poo_flow_proof_runtime_command_inert_bit_raw(void);
uint32_t poo_flow_proof_policy_strategy_deterministic_bit_raw(void);
uint32_t poo_flow_proof_workflow_agreement_linked_bit_raw(void);
uint32_t poo_flow_proof_sandbox_boundary_linked_bit_raw(void);
uint32_t poo_flow_proof_runtime_handoff_owner_linked_bit_raw(void);
uint32_t poo_flow_proof_proof_case_vector_complete_bit_raw(void);

#endif
