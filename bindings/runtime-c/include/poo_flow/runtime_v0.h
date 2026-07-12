#ifndef POO_FLOW_RUNTIME_V0_H
#define POO_FLOW_RUNTIME_V0_H

#include <stdint.h>
#include "poo_flow/runtime_v0_contract.h"

#ifdef __cplusplus
extern "C" {
#endif

#define POO_FLOW_RUNTIME_V0_DIGEST_BYTES 32u
typedef struct {
  uint64_t high;
  uint64_t low;
} poo_flow_runtime_v0_compact_id;

typedef struct {
  uint16_t layout_version;
  uint16_t event_kind;
  uint32_t flags;
  uint64_t sequence;
  poo_flow_runtime_v0_compact_id event_identity;
  poo_flow_runtime_v0_compact_id correlation_identity;
  poo_flow_runtime_v0_compact_id authorization_identity;
  uint64_t payload_offset;
  uint64_t payload_length;
  uint64_t deadline_mono_ns;
  uint32_t required_evidence_bits;
  uint32_t reserved0;
} poo_flow_runtime_v0_event_header;

_Static_assert(sizeof(poo_flow_runtime_v0_event_header) ==
                   POO_FLOW_RUNTIME_V0_EVENT_HEADER_BYTES,
               "runtime v0 event header must remain 96 bytes");

typedef uint32_t poo_flow_runtime_v0_status;
enum {
  POO_FLOW_RUNTIME_V0_OK = 0,
  POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT = 1,
  POO_FLOW_RUNTIME_V0_INCOMPATIBLE_ABI = 2,
  POO_FLOW_RUNTIME_V0_INCOMPATIBLE_SCHEMA = 3,
  POO_FLOW_RUNTIME_V0_UNSUPPORTED_CAPABILITY = 4,
  POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR = 5,
  POO_FLOW_RUNTIME_V0_WRONG_HANDLE_KIND = 6,
  POO_FLOW_RUNTIME_V0_STALE_HANDLE = 7,
  POO_FLOW_RUNTIME_V0_CROSS_INSTANCE_HANDLE = 8,
  POO_FLOW_RUNTIME_V0_ALREADY_RELEASED = 9,
  POO_FLOW_RUNTIME_V0_INVALID_STATE = 10,
  POO_FLOW_RUNTIME_V0_BUNDLE_IDENTITY_MISMATCH = 11,
  POO_FLOW_RUNTIME_V0_CHECKPOINT_INCOMPATIBLE = 12,
  POO_FLOW_RUNTIME_V0_CANCELLED = 13,
  POO_FLOW_RUNTIME_V0_OUTSTANDING_WORK = 14,
  POO_FLOW_RUNTIME_V0_ALLOCATION_FAILURE = 15,
  POO_FLOW_RUNTIME_V0_INTERNAL_INVARIANT = 16,
  POO_FLOW_RUNTIME_V0_DUPLICATE_ACCEPTED = 17,
  POO_FLOW_RUNTIME_V0_PAYLOAD_BOUNDS = 18,
  POO_FLOW_RUNTIME_V0_STALE_GENERATION = 19,
  POO_FLOW_RUNTIME_V0_ARENA_BUSY = 20
};

typedef struct {
  uint64_t instance_id;
  uint64_t resource_id;
  uint32_t generation;
  uint32_t kind;
} poo_flow_runtime_v0_handle;

typedef struct {
  const uint8_t *ptr;
  uint64_t len;
} poo_flow_runtime_v0_bytes_view;

typedef struct {
  uint8_t *ptr;
  uint64_t len;
  uint64_t capacity;
  poo_flow_runtime_v0_handle owner;
} poo_flow_runtime_v0_owned_bytes;

typedef struct {
  uint32_t struct_size;
  uint16_t abi_major;
  uint16_t abi_minor;
  uint64_t required_capabilities;
  uint64_t optional_capabilities;
  uint32_t concurrency_profile;
  uint32_t reserved0;
  uint64_t max_payload_bytes;
  poo_flow_runtime_v0_bytes_view bundle_schema;
  poo_flow_runtime_v0_bytes_view runtime_identity;
} poo_flow_runtime_v0_negotiate_request;

typedef struct {
  uint32_t struct_size;
  uint16_t abi_major;
  uint16_t abi_minor;
  uint64_t capabilities;
  uint32_t concurrency_profile;
  uint32_t reserved0;
  uint64_t max_payload_bytes;
  poo_flow_runtime_v0_handle profile;
} poo_flow_runtime_v0_negotiate_result;

typedef struct {
  uint32_t struct_size;
  uint32_t digest_algorithm;
  uint8_t digest[POO_FLOW_RUNTIME_V0_DIGEST_BYTES];
  uint64_t bundle_epoch;
  poo_flow_runtime_v0_bytes_view schema;
  poo_flow_runtime_v0_bytes_view canonical_packet;
  uint64_t reserved0;
} poo_flow_runtime_v0_bundle_descriptor;

typedef struct {
  uint32_t struct_size;
  uint32_t close_disposition;
  uint64_t initial_sequence;
  uint64_t outstanding_work;
  uint64_t reserved0;
} poo_flow_runtime_v0_session_descriptor;

typedef struct {
  uint32_t struct_size;
  uint32_t alignment;
  uint8_t *ptr;
  uint64_t capacity;
  uint64_t generation;
  uint64_t reserved0;
} poo_flow_runtime_v0_arena_descriptor;

typedef struct {
  uint32_t struct_size;
  uint32_t reserved0;
  poo_flow_runtime_v0_handle arena;
  uint64_t arena_generation;
  poo_flow_runtime_v0_event_header *headers;
  uint64_t header_stride;
  uint64_t header_capacity;
  uint64_t payload_capacity;
} poo_flow_runtime_v0_poll_request;

typedef struct {
  uint32_t struct_size;
  uint32_t reserved0;
  poo_flow_runtime_v0_handle lease;
  uint64_t arena_generation;
  uint64_t produced_count;
  uint64_t required_header_count;
  uint64_t required_payload_bytes;
  uint64_t first_sequence;
  uint64_t last_sequence;
} poo_flow_runtime_v0_poll_result;

typedef struct {
  uint32_t struct_size;
  uint32_t reserved0;
  poo_flow_runtime_v0_handle arena;
  uint64_t arena_generation;
  const poo_flow_runtime_v0_event_header *headers;
  uint64_t header_stride;
  uint64_t item_count;
  uint32_t *item_statuses;
  uint64_t item_status_capacity;
  uint8_t *accepted_bitmap;
  uint64_t accepted_bitmap_bytes;
} poo_flow_runtime_v0_submit_request;

typedef struct {
  uint32_t struct_size;
  uint32_t reserved0;
  uint64_t accepted_count;
  uint64_t rejected_count;
  uint64_t accepted_watermark;
} poo_flow_runtime_v0_submit_result;

poo_flow_runtime_v0_status poo_flow_runtime_v0_instance_create(
    poo_flow_runtime_v0_handle *instance_out);
poo_flow_runtime_v0_status poo_flow_runtime_v0_instance_release(
    poo_flow_runtime_v0_handle instance);
poo_flow_runtime_v0_status poo_flow_runtime_v0_negotiate(
    poo_flow_runtime_v0_handle instance,
    const poo_flow_runtime_v0_negotiate_request *request,
    poo_flow_runtime_v0_negotiate_result *result);
poo_flow_runtime_v0_status poo_flow_runtime_v0_profile_release(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle profile);
poo_flow_runtime_v0_status poo_flow_runtime_v0_bundle_open(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle profile,
    const poo_flow_runtime_v0_bundle_descriptor *descriptor,
    poo_flow_runtime_v0_handle *bundle_out);
poo_flow_runtime_v0_status poo_flow_runtime_v0_bundle_release(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle bundle);
poo_flow_runtime_v0_status poo_flow_runtime_v0_session_open(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle bundle,
    const poo_flow_runtime_v0_session_descriptor *descriptor,
    poo_flow_runtime_v0_handle *session_out);
poo_flow_runtime_v0_status poo_flow_runtime_v0_session_cancel(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session);
poo_flow_runtime_v0_status poo_flow_runtime_v0_session_close(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    uint32_t disposition);
poo_flow_runtime_v0_status poo_flow_runtime_v0_session_release(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session);
poo_flow_runtime_v0_status poo_flow_runtime_v0_session_checkpoint(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    poo_flow_runtime_v0_owned_bytes *checkpoint_out);
poo_flow_runtime_v0_status poo_flow_runtime_v0_session_restore(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle bundle,
    poo_flow_runtime_v0_bytes_view checkpoint,
    poo_flow_runtime_v0_handle *session_out);
poo_flow_runtime_v0_status poo_flow_runtime_v0_arena_register(
    poo_flow_runtime_v0_handle instance,
    const poo_flow_runtime_v0_arena_descriptor *descriptor,
    poo_flow_runtime_v0_handle *arena_out);
poo_flow_runtime_v0_status poo_flow_runtime_v0_arena_release(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle arena);
poo_flow_runtime_v0_status poo_flow_runtime_v0_poll_batch(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    const poo_flow_runtime_v0_poll_request *request,
    poo_flow_runtime_v0_poll_result *result);
poo_flow_runtime_v0_status poo_flow_runtime_v0_submit_batch(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    const poo_flow_runtime_v0_submit_request *request,
    poo_flow_runtime_v0_submit_result *result);
poo_flow_runtime_v0_status poo_flow_runtime_v0_batch_ack(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    poo_flow_runtime_v0_handle lease);
poo_flow_runtime_v0_status poo_flow_runtime_v0_arena_recycle(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle arena,
    uint64_t expected_generation, uint64_t next_generation);
poo_flow_runtime_v0_status poo_flow_runtime_v0_owned_bytes_release(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_owned_bytes *value);
poo_flow_runtime_v0_status poo_flow_runtime_v0_error_message(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_status status,
    poo_flow_runtime_v0_owned_bytes *message_out);
const char *poo_flow_runtime_v0_status_name(poo_flow_runtime_v0_status status);

#ifdef __cplusplus
}
#endif

#endif
