#ifndef POO_FLOW_RUNTIME_WASM_H
#define POO_FLOW_RUNTIME_WASM_H

#include <stdint.h>

#include "poo_flow/runtime_v0.h"

#ifdef __cplusplus
extern "C" {
#endif

enum {
  PFW_WASM_STATUS_INVALID_ARGUMENT = UINT32_C(0xffff0001),
  PFW_WASM_STATUS_INVALID_SLOT = UINT32_C(0xffff0002),
  PFW_WASM_STATUS_SLOT_EXHAUSTED = UINT32_C(0xffff0003),
};

uint32_t pfw_handle_capacity(void);
uint32_t pfw_instance_create(uint32_t *instance_slot_out);
uint32_t pfw_instance_release(uint32_t instance_slot);
uint32_t pfw_negotiate(
    uint32_t instance_slot,
    const poo_flow_runtime_v0_negotiate_request *request,
    poo_flow_runtime_v0_negotiate_result *result,
    uint32_t *profile_slot_out);
uint32_t pfw_profile_release(uint32_t instance_slot, uint32_t profile_slot);
uint32_t pfw_bundle_open(
    uint32_t instance_slot,
    uint32_t profile_slot,
    const poo_flow_runtime_v0_bundle_descriptor *descriptor,
    uint32_t *bundle_slot_out);
uint32_t pfw_bundle_release(uint32_t instance_slot, uint32_t bundle_slot);
uint32_t pfw_session_open(
    uint32_t instance_slot,
    uint32_t bundle_slot,
    const poo_flow_runtime_v0_session_descriptor *descriptor,
    uint32_t *session_slot_out);
uint32_t pfw_session_cancel(uint32_t instance_slot, uint32_t session_slot);
uint32_t pfw_session_close(
    uint32_t instance_slot,
    uint32_t session_slot,
    uint32_t disposition);
uint32_t pfw_session_release(uint32_t instance_slot, uint32_t session_slot);
uint32_t pfw_arena_register(
    uint32_t instance_slot,
    const poo_flow_runtime_v0_arena_descriptor *descriptor,
    uint32_t *arena_slot_out);
uint32_t pfw_arena_recycle(
    uint32_t instance_slot,
    uint32_t arena_slot,
    uint64_t expected_generation,
    uint64_t next_generation);
uint32_t pfw_arena_release(uint32_t instance_slot, uint32_t arena_slot);
uint32_t pfw_publish_batch(
    uint32_t instance_slot,
    uint32_t session_slot,
    uint32_t arena_slot,
    const poo_flow_runtime_v0_publish_request *request,
    poo_flow_runtime_v0_publish_result *result);
uint32_t pfw_poll_batch(
    uint32_t instance_slot,
    uint32_t session_slot,
    uint32_t arena_slot,
    const poo_flow_runtime_v0_poll_request *request,
    poo_flow_runtime_v0_poll_result *result,
    uint32_t *lease_slot_out);
uint32_t pfw_submit_batch(
    uint32_t instance_slot,
    uint32_t session_slot,
    uint32_t arena_slot,
    const poo_flow_runtime_v0_submit_request *request,
    poo_flow_runtime_v0_submit_result *result);
uint32_t pfw_batch_ack(
    uint32_t instance_slot,
    uint32_t session_slot,
    uint32_t lease_slot);

#ifdef __cplusplus
}
#endif

#endif
