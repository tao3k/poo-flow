#ifndef POO_FLOW_PROOF_FFI_H
#define POO_FLOW_PROOF_FFI_H

#include <stdint.h>

#define POO_FLOW_PROOF_ABI_VERSION 1u
#define POO_FLOW_PROOF_TAG_WIDTH_UINT32 32u
#define POO_FLOW_PROOF_OBLIGATION_COUNT 5u

#define POO_FLOW_OBLIGATION_UI_CONFIG_WELL_FORMED (1u << 0)
#define POO_FLOW_OBLIGATION_RUNTIME_COMMAND_INERT (1u << 1)
#define POO_FLOW_OBLIGATION_POLICY_STRATEGY_DETERMINISTIC (1u << 2)
#define POO_FLOW_OBLIGATION_WORKFLOW_AGREEMENT_LINKED (1u << 3)
#define POO_FLOW_OBLIGATION_SANDBOX_BOUNDARY_LINKED (1u << 4)

#define POO_FLOW_PROOF_REQUIRED_OBLIGATION_MASK \
  (POO_FLOW_OBLIGATION_UI_CONFIG_WELL_FORMED | \
   POO_FLOW_OBLIGATION_RUNTIME_COMMAND_INERT | \
   POO_FLOW_OBLIGATION_POLICY_STRATEGY_DETERMINISTIC | \
   POO_FLOW_OBLIGATION_WORKFLOW_AGREEMENT_LINKED | \
   POO_FLOW_OBLIGATION_SANDBOX_BOUNDARY_LINKED)

uint32_t poo_flow_proof_abi_version_raw(void);
uint32_t poo_flow_proof_tag_width_raw(void);
uint32_t poo_flow_proof_obligation_count_raw(void);
uint32_t poo_flow_proof_required_obligation_mask_raw(void);
uint32_t poo_flow_proof_ui_config_well_formed_bit_raw(void);
uint32_t poo_flow_proof_runtime_command_inert_bit_raw(void);
uint32_t poo_flow_proof_policy_strategy_deterministic_bit_raw(void);
uint32_t poo_flow_proof_workflow_agreement_linked_bit_raw(void);
uint32_t poo_flow_proof_sandbox_boundary_linked_bit_raw(void);

#endif
