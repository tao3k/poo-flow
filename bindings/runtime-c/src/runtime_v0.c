#include "poo_flow/runtime_v0.h"
#include "runtime_v0_internal.h"

#include <stdlib.h>
#include <string.h>

#define MAX_RESOURCES 256u
#define KIND_INSTANCE 1u
#define KIND_PROFILE 2u
#define KIND_BUNDLE 3u
#define KIND_SESSION 4u
#define KIND_BYTES 5u
#define KIND_ARENA 6u
#define KIND_LEASE 7u
#define STATE_OPEN 1u
#define STATE_CANCELLED 2u
#define STATE_CLOSED 3u
#define CHECKPOINT_MAGIC UINT64_C(0x504f4f4350303031)
#define MAX_PENDING_EVENTS 1024u

typedef struct {
  poo_flow_runtime_v0_event_header header;
  uint64_t arena_id;
  uint64_t arena_generation;
  uint8_t polled;
  uint8_t accepted;
  uint8_t acknowledged;
  uint8_t reserved[5];
} pending_event;

typedef struct {
  uint8_t alive;
  uint8_t released;
  uint16_t reserved;
  uint32_t kind;
  uint32_t generation;
  uint32_t state;
  uint64_t instance_id;
  uint64_t parent_id;
  uint64_t epoch;
  uint64_t sequence;
  uint64_t outstanding;
  uint8_t digest[POO_FLOW_RUNTIME_V0_DIGEST_BYTES];
  uint8_t *bytes;
  uint64_t bytes_len;
  uint8_t *arena_ptr;
  uint64_t arena_capacity;
  uint64_t arena_generation;
  uint64_t inflight_count;
  pending_event *pending;
  uint64_t pending_count;
  uint64_t pending_capacity;
  uint64_t poll_cursor;
  uint64_t lease_first_sequence;
  uint64_t lease_last_sequence;
} resource;

typedef struct {
  uint64_t magic;
  uint64_t epoch;
  uint64_t sequence;
  uint32_t state;
  uint32_t reserved;
  uint8_t digest[POO_FLOW_RUNTIME_V0_DIGEST_BYTES];
  uint64_t checksum;
} checkpoint_packet;

static resource resources[MAX_RESOURCES];
static uint64_t next_instance_id = 1;
static const char bundle_schema[] = POO_FLOW_RUNTIME_V0_BUNDLE_SCHEMA;

static poo_flow_runtime_v0_handle null_handle(void) {
  poo_flow_runtime_v0_handle value = {0, 0, 0, 0};
  return value;
}

static int bytes_equal(poo_flow_runtime_v0_bytes_view value, const char *text) {
  size_t len = strlen(text);
  return value.ptr != NULL && value.len == (uint64_t)len &&
         memcmp(value.ptr, text, len) == 0;
}

static uint64_t checksum_bytes(const uint8_t *bytes, uint64_t len) {
  uint64_t value = UINT64_C(1469598103934665603);
  for (uint64_t i = 0; i < len; ++i) {
    value ^= bytes[i];
    value *= UINT64_C(1099511628211);
  }
  return value;
}

static int power_of_two(uint32_t value) {
  return value != 0 && (value & (value - 1u)) == 0;
}

static int slice_in_bounds(uint64_t offset, uint64_t length, uint64_t capacity) {
  return offset <= capacity && length <= capacity - offset;
}

static uint64_t pending_lower_bound(resource *session, uint64_t sequence) {
  uint64_t left = 0;
  uint64_t right = session->pending_count;
  while (left < right) {
    uint64_t middle = left + (right - left) / 2;
    uint64_t observed = session->pending[middle].header.sequence;
    if (observed < sequence) left = middle + 1;
    else if (observed > sequence) right = middle;
    else return middle;
  }
  return left;
}

static resource *slot(uint64_t resource_id) {
  if (resource_id == 0 || resource_id > MAX_RESOURCES) return NULL;
  return &resources[resource_id - 1];
}

static poo_flow_runtime_v0_status resolve(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle handle,
    uint32_t kind, resource **out) {
  resource *entry = slot(handle.resource_id);
  if (handle.instance_id != instance.instance_id)
    return POO_FLOW_RUNTIME_V0_CROSS_INSTANCE_HANDLE;
  if (handle.kind != kind) return POO_FLOW_RUNTIME_V0_WRONG_HANDLE_KIND;
  if (entry == NULL || entry->generation != handle.generation)
    return POO_FLOW_RUNTIME_V0_STALE_HANDLE;
  if (entry->released) return POO_FLOW_RUNTIME_V0_ALREADY_RELEASED;
  if (!entry->alive) return POO_FLOW_RUNTIME_V0_STALE_HANDLE;
  if (entry->instance_id != instance.instance_id)
    return POO_FLOW_RUNTIME_V0_CROSS_INSTANCE_HANDLE;
  *out = entry;
  return POO_FLOW_RUNTIME_V0_OK;
}

static poo_flow_runtime_v0_status instance_entry(
    poo_flow_runtime_v0_handle instance, resource **out) {
  return resolve(instance, instance, KIND_INSTANCE, out);
}

static poo_flow_runtime_v0_status allocate_resource(
    uint64_t instance_id, uint32_t kind, poo_flow_runtime_v0_handle *out) {
  for (uint64_t i = 0; i < MAX_RESOURCES; ++i) {
    resource *entry = &resources[i];
    if (!entry->alive) {
      uint32_t generation = entry->generation + 1u;
      if (generation == 0) generation = 1;
      memset(entry, 0, sizeof(*entry));
      entry->alive = 1;
      entry->kind = kind;
      entry->generation = generation;
      entry->instance_id = instance_id;
      out->instance_id = instance_id;
      out->resource_id = i + 1;
      out->generation = generation;
      out->kind = kind;
      return POO_FLOW_RUNTIME_V0_OK;
    }
  }
  return POO_FLOW_RUNTIME_V0_ALLOCATION_FAILURE;
}

static poo_flow_runtime_v0_status release_resource(resource *entry) {
  if (entry->bytes != NULL) free(entry->bytes);
  if (entry->pending != NULL) free(entry->pending);
  entry->bytes = NULL;
  entry->bytes_len = 0;
  entry->pending = NULL;
  entry->pending_count = 0;
  entry->pending_capacity = 0;
  entry->released = 1;
  entry->alive = 0;
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_instance_create(
    poo_flow_runtime_v0_handle *instance_out) {
  if (instance_out == NULL) return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  poo_flow_runtime_v0_status status =
      allocate_resource(next_instance_id++, KIND_INSTANCE, instance_out);
  return status;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_instance_release(
    poo_flow_runtime_v0_handle instance) {
  resource *entry = NULL;
  poo_flow_runtime_v0_status status = instance_entry(instance, &entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  for (uint64_t i = 0; i < MAX_RESOURCES; ++i)
    if (resources[i].alive && resources[i].instance_id == instance.instance_id &&
        resources[i].kind != KIND_INSTANCE)
      return POO_FLOW_RUNTIME_V0_OUTSTANDING_WORK;
  return release_resource(entry);
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_negotiate(
    poo_flow_runtime_v0_handle instance,
    const poo_flow_runtime_v0_negotiate_request *request,
    poo_flow_runtime_v0_negotiate_result *result) {
  resource *ignored = NULL;
  poo_flow_runtime_v0_status status = instance_entry(instance, &ignored);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (request == NULL || result == NULL) return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  if (request->struct_size != sizeof(*request) ||
      result->struct_size != sizeof(*result) || request->reserved0 != 0)
    return POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR;
  if (request->abi_major != POO_FLOW_RUNTIME_V0_ABI_MAJOR ||
      request->abi_minor > POO_FLOW_RUNTIME_V0_ABI_MINOR)
    return POO_FLOW_RUNTIME_V0_INCOMPATIBLE_ABI;
  if (!bytes_equal(request->bundle_schema, bundle_schema))
    return POO_FLOW_RUNTIME_V0_INCOMPATIBLE_SCHEMA;
  const uint64_t supported = POO_FLOW_RUNTIME_V0_CAP_CONTROL |
                             POO_FLOW_RUNTIME_V0_CAP_CHECKPOINT |
                             POO_FLOW_RUNTIME_V0_CAP_HOT_BATCH |
                             POO_FLOW_RUNTIME_V0_CAP_BULK_BUFFER |
                             POO_FLOW_RUNTIME_V0_CAP_CALLER_ARENA |
                             POO_FLOW_RUNTIME_V0_CAP_PARTIAL_ACCEPTANCE;
  if ((request->required_capabilities & ~supported) != 0)
    return POO_FLOW_RUNTIME_V0_UNSUPPORTED_CAPABILITY;
  poo_flow_runtime_v0_handle profile = null_handle();
  status = allocate_resource(instance.instance_id, KIND_PROFILE, &profile);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  result->abi_major = POO_FLOW_RUNTIME_V0_ABI_MAJOR;
  result->abi_minor = POO_FLOW_RUNTIME_V0_ABI_MINOR;
  result->capabilities = supported &
      (request->required_capabilities | request->optional_capabilities);
  result->concurrency_profile = 0;
  result->reserved0 = 0;
  result->max_payload_bytes = request->max_payload_bytes;
  result->profile = profile;
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_profile_release(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle profile) {
  resource *entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, profile, KIND_PROFILE, &entry);
  return status == POO_FLOW_RUNTIME_V0_OK ? release_resource(entry) : status;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_bundle_open(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle profile,
    const poo_flow_runtime_v0_bundle_descriptor *descriptor,
    poo_flow_runtime_v0_handle *bundle_out) {
  resource *profile_entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, profile, KIND_PROFILE,
                                               &profile_entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (descriptor == NULL || bundle_out == NULL)
    return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  if (descriptor->struct_size != sizeof(*descriptor) || descriptor->reserved0 != 0 ||
      descriptor->canonical_packet.ptr == NULL || descriptor->canonical_packet.len == 0)
    return POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR;
  if (!bytes_equal(descriptor->schema, bundle_schema))
    return POO_FLOW_RUNTIME_V0_INCOMPATIBLE_SCHEMA;
  status = allocate_resource(instance.instance_id, KIND_BUNDLE, bundle_out);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  resource *entry = slot(bundle_out->resource_id);
  entry->parent_id = profile.resource_id;
  entry->epoch = descriptor->bundle_epoch;
  memcpy(entry->digest, descriptor->digest, sizeof(entry->digest));
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_bundle_release(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle bundle) {
  resource *entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, bundle, KIND_BUNDLE, &entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  for (uint64_t i = 0; i < MAX_RESOURCES; ++i)
    if (resources[i].alive && resources[i].kind == KIND_SESSION &&
        resources[i].parent_id == bundle.resource_id)
      return POO_FLOW_RUNTIME_V0_OUTSTANDING_WORK;
  return release_resource(entry);
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_session_open(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle bundle,
    const poo_flow_runtime_v0_session_descriptor *descriptor,
    poo_flow_runtime_v0_handle *session_out) {
  resource *bundle_entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, bundle, KIND_BUNDLE,
                                               &bundle_entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (descriptor == NULL || session_out == NULL)
    return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  if (descriptor->struct_size != sizeof(*descriptor) || descriptor->reserved0 != 0)
    return POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR;
  status = allocate_resource(instance.instance_id, KIND_SESSION, session_out);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  resource *entry = slot(session_out->resource_id);
  entry->pending = (pending_event *)calloc(MAX_PENDING_EVENTS,
                                           sizeof(*entry->pending));
  if (entry->pending == NULL) {
    release_resource(entry);
    return POO_FLOW_RUNTIME_V0_ALLOCATION_FAILURE;
  }
  entry->pending_capacity = MAX_PENDING_EVENTS;
  entry->state = STATE_OPEN;
  entry->parent_id = bundle.resource_id;
  entry->epoch = bundle_entry->epoch;
  entry->sequence = descriptor->initial_sequence;
  entry->outstanding = descriptor->outstanding_work;
  memcpy(entry->digest, bundle_entry->digest, sizeof(entry->digest));
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_session_cancel(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session) {
  resource *entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, session, KIND_SESSION, &entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (entry->state == STATE_CLOSED) return POO_FLOW_RUNTIME_V0_INVALID_STATE;
  entry->state = STATE_CANCELLED;
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_session_close(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    uint32_t disposition) {
  resource *entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, session, KIND_SESSION, &entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (entry->state == STATE_CLOSED) return POO_FLOW_RUNTIME_V0_INVALID_STATE;
  if (entry->outstanding != 0 && disposition == 0)
    return POO_FLOW_RUNTIME_V0_OUTSTANDING_WORK;
  entry->outstanding = 0;
  entry->state = STATE_CLOSED;
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_session_release(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session) {
  resource *entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, session, KIND_SESSION, &entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (entry->state != STATE_CLOSED) return POO_FLOW_RUNTIME_V0_INVALID_STATE;
  return release_resource(entry);
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_session_checkpoint(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    poo_flow_runtime_v0_owned_bytes *checkpoint_out) {
  resource *entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, session, KIND_SESSION, &entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (checkpoint_out == NULL) return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  checkpoint_packet *packet = (checkpoint_packet *)calloc(1, sizeof(*packet));
  if (packet == NULL) return POO_FLOW_RUNTIME_V0_ALLOCATION_FAILURE;
  packet->magic = CHECKPOINT_MAGIC;
  packet->epoch = entry->epoch;
  packet->sequence = entry->sequence;
  packet->state = entry->state;
  memcpy(packet->digest, entry->digest, sizeof(packet->digest));
  packet->checksum = checksum_bytes((const uint8_t *)packet,
                                    sizeof(*packet) - sizeof(packet->checksum));
  poo_flow_runtime_v0_handle owner = null_handle();
  status = allocate_resource(instance.instance_id, KIND_BYTES, &owner);
  if (status != POO_FLOW_RUNTIME_V0_OK) { free(packet); return status; }
  resource *bytes_entry = slot(owner.resource_id);
  bytes_entry->bytes = (uint8_t *)packet;
  bytes_entry->bytes_len = sizeof(*packet);
  checkpoint_out->ptr = (uint8_t *)packet;
  checkpoint_out->len = sizeof(*packet);
  checkpoint_out->capacity = sizeof(*packet);
  checkpoint_out->owner = owner;
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_session_restore(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle bundle,
    poo_flow_runtime_v0_bytes_view checkpoint,
    poo_flow_runtime_v0_handle *session_out) {
  resource *bundle_entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, bundle, KIND_BUNDLE,
                                               &bundle_entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (checkpoint.ptr == NULL || checkpoint.len != sizeof(checkpoint_packet) ||
      session_out == NULL) return POO_FLOW_RUNTIME_V0_CHECKPOINT_INCOMPATIBLE;
  checkpoint_packet packet;
  memcpy(&packet, checkpoint.ptr, sizeof(packet));
  uint64_t checksum = checksum_bytes((const uint8_t *)&packet,
                                     sizeof(packet) - sizeof(packet.checksum));
  if (packet.magic != CHECKPOINT_MAGIC || packet.reserved != 0 ||
      packet.checksum != checksum)
    return POO_FLOW_RUNTIME_V0_CHECKPOINT_INCOMPATIBLE;
  if (packet.epoch != bundle_entry->epoch ||
      memcmp(packet.digest, bundle_entry->digest, sizeof(packet.digest)) != 0)
    return POO_FLOW_RUNTIME_V0_BUNDLE_IDENTITY_MISMATCH;
  status = allocate_resource(instance.instance_id, KIND_SESSION, session_out);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  resource *entry = slot(session_out->resource_id);
  entry->pending = (pending_event *)calloc(MAX_PENDING_EVENTS,
                                           sizeof(*entry->pending));
  if (entry->pending == NULL) {
    release_resource(entry);
    return POO_FLOW_RUNTIME_V0_ALLOCATION_FAILURE;
  }
  entry->pending_capacity = MAX_PENDING_EVENTS;
  entry->state = packet.state == STATE_CLOSED ? STATE_OPEN : packet.state;
  entry->parent_id = bundle.resource_id;
  entry->epoch = packet.epoch;
  entry->sequence = packet.sequence;
  memcpy(entry->digest, packet.digest, sizeof(entry->digest));
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_arena_register(
    poo_flow_runtime_v0_handle instance,
    const poo_flow_runtime_v0_arena_descriptor *descriptor,
    poo_flow_runtime_v0_handle *arena_out) {
  resource *ignored = NULL;
  poo_flow_runtime_v0_status status = instance_entry(instance, &ignored);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (descriptor == NULL || arena_out == NULL)
    return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  if (descriptor->struct_size != sizeof(*descriptor) || descriptor->reserved0 != 0 ||
      descriptor->ptr == NULL || descriptor->capacity == 0 ||
      !power_of_two(descriptor->alignment) || descriptor->alignment < 16 ||
      ((uintptr_t)descriptor->ptr % descriptor->alignment) != 0)
    return POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR;
  status = allocate_resource(instance.instance_id, KIND_ARENA, arena_out);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  resource *entry = slot(arena_out->resource_id);
  entry->arena_ptr = descriptor->ptr;
  entry->arena_capacity = descriptor->capacity;
  entry->arena_generation = descriptor->generation;
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_arena_release(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle arena) {
  resource *entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, arena, KIND_ARENA, &entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (entry->inflight_count != 0) return POO_FLOW_RUNTIME_V0_ARENA_BUSY;
  entry->arena_ptr = NULL;
  entry->arena_capacity = 0;
  return release_resource(entry);
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_internal_publish(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    poo_flow_runtime_v0_handle arena, uint64_t arena_generation,
    const poo_flow_runtime_v0_event_header *header) {
  resource *session_entry = NULL;
  resource *arena_entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, session, KIND_SESSION,
                                               &session_entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  status = resolve(instance, arena, KIND_ARENA, &arena_entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (header == NULL) return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  if (arena_entry->arena_generation != arena_generation)
    return POO_FLOW_RUNTIME_V0_STALE_GENERATION;
  if (header->layout_version != POO_FLOW_RUNTIME_V0_LAYOUT_VERSION ||
      header->reserved0 != 0)
    return POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR;
  if (!slice_in_bounds(header->payload_offset, header->payload_length,
                       arena_entry->arena_capacity))
    return POO_FLOW_RUNTIME_V0_PAYLOAD_BOUNDS;
  if (session_entry->pending_count >= session_entry->pending_capacity)
    return POO_FLOW_RUNTIME_V0_OUTSTANDING_WORK;
  if (session_entry->pending_count != 0 &&
      header->sequence <= session_entry->pending[session_entry->pending_count - 1]
                              .header.sequence)
    return POO_FLOW_RUNTIME_V0_INVALID_STATE;
  pending_event *pending = &session_entry->pending[session_entry->pending_count++];
  memset(pending, 0, sizeof(*pending));
  pending->header = *header;
  pending->arena_id = arena.resource_id;
  pending->arena_generation = arena_generation;
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_poll_batch(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    const poo_flow_runtime_v0_poll_request *request,
    poo_flow_runtime_v0_poll_result *result) {
  resource *session_entry = NULL;
  resource *arena_entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, session, KIND_SESSION,
                                               &session_entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (request == NULL || result == NULL)
    return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  if (request->struct_size != sizeof(*request) || result->struct_size != sizeof(*result) ||
      request->reserved0 != 0 || result->reserved0 != 0 ||
      request->header_stride != sizeof(poo_flow_runtime_v0_event_header) ||
      (request->header_capacity != 0 && request->headers == NULL))
    return POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR;
  status = resolve(instance, request->arena, KIND_ARENA, &arena_entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (arena_entry->arena_generation != request->arena_generation)
    return POO_FLOW_RUNTIME_V0_STALE_GENERATION;
  uint64_t ready = 0, required_payload = 0;
  for (uint64_t i = session_entry->poll_cursor;
       i < session_entry->pending_count; ++i) {
    pending_event *pending = &session_entry->pending[i];
    if (pending->polled || pending->arena_id != request->arena.resource_id ||
        pending->arena_generation != request->arena_generation)
      break;
    ++ready;
    uint64_t end = pending->header.payload_offset + pending->header.payload_length;
    if (end > required_payload) required_payload = end;
  }
  result->required_header_count = ready;
  result->required_payload_bytes = required_payload;
  result->produced_count = 0;
  result->first_sequence = 0;
  result->last_sequence = 0;
  result->arena_generation = request->arena_generation;
  result->lease = null_handle();
  if (ready == 0) return POO_FLOW_RUNTIME_V0_OK;
  if (request->header_capacity < ready || request->payload_capacity < required_payload)
    return POO_FLOW_RUNTIME_V0_OK;
  poo_flow_runtime_v0_handle lease = null_handle();
  status = allocate_resource(instance.instance_id, KIND_LEASE, &lease);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  resource *lease_entry = slot(lease.resource_id);
  lease_entry->parent_id = request->arena.resource_id;
  lease_entry->epoch = request->arena_generation;
  lease_entry->outstanding = session.resource_id;
  uint64_t produced = 0;
  for (uint64_t i = session_entry->poll_cursor;
       i < session_entry->pending_count; ++i) {
    pending_event *pending = &session_entry->pending[i];
    if (pending->polled || pending->arena_id != request->arena.resource_id ||
        pending->arena_generation != request->arena_generation)
      break;
    poo_flow_runtime_v0_event_header *header_out =
        (poo_flow_runtime_v0_event_header *)
            ((uint8_t *)request->headers + produced * request->header_stride);
    *header_out = pending->header;
    pending->polled = 1;
    if (produced == 0) result->first_sequence = pending->header.sequence;
    result->last_sequence = pending->header.sequence;
    ++produced;
  }
  session_entry->poll_cursor += produced;
  lease_entry->sequence = produced;
  lease_entry->lease_first_sequence = result->first_sequence;
  lease_entry->lease_last_sequence = result->last_sequence;
  arena_entry->inflight_count += produced;
  result->produced_count = produced;
  result->lease = lease;
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_submit_batch(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    const poo_flow_runtime_v0_submit_request *request,
    poo_flow_runtime_v0_submit_result *result) {
  resource *session_entry = NULL;
  resource *arena_entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, session, KIND_SESSION,
                                               &session_entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (request == NULL || result == NULL)
    return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  uint64_t bitmap_required = request->item_count / 8u +
      (request->item_count % 8u != 0 ? 1u : 0u);
  if (request->struct_size != sizeof(*request) || result->struct_size != sizeof(*result) ||
      request->reserved0 != 0 || result->reserved0 != 0 ||
      request->header_stride != sizeof(poo_flow_runtime_v0_event_header) ||
      request->item_count > SIZE_MAX / request->header_stride ||
      (request->item_count != 0 && request->headers == NULL) ||
      request->item_status_capacity < request->item_count ||
      (request->item_count != 0 && request->item_statuses == NULL) ||
      request->accepted_bitmap_bytes < bitmap_required ||
      (bitmap_required != 0 && request->accepted_bitmap == NULL))
    return POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR;
  status = resolve(instance, request->arena, KIND_ARENA, &arena_entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (arena_entry->arena_generation != request->arena_generation)
    return POO_FLOW_RUNTIME_V0_STALE_GENERATION;
  for (uint64_t i = 0; i < request->item_count; ++i) {
    const poo_flow_runtime_v0_event_header *header =
        (const poo_flow_runtime_v0_event_header *)
            ((const uint8_t *)request->headers + i * request->header_stride);
    const poo_flow_runtime_v0_event_header *previous = i == 0 ? NULL :
        (const poo_flow_runtime_v0_event_header *)
            ((const uint8_t *)request->headers +
             (i - 1u) * request->header_stride);
    if ((previous != NULL && previous->sequence >= header->sequence) ||
        header->layout_version != POO_FLOW_RUNTIME_V0_LAYOUT_VERSION ||
        header->reserved0 != 0 ||
        !slice_in_bounds(header->payload_offset, header->payload_length,
                         arena_entry->arena_capacity))
      return POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR;
  }
  memset(request->accepted_bitmap, 0, bitmap_required);
  result->accepted_count = 0;
  result->rejected_count = 0;
  result->accepted_watermark = session_entry->sequence;
  uint64_t pending_index = request->item_count == 0
      ? session_entry->pending_count
      : pending_lower_bound(session_entry, request->headers->sequence);
  for (uint64_t i = 0; i < request->item_count; ++i) {
    const poo_flow_runtime_v0_event_header *header =
        (const poo_flow_runtime_v0_event_header *)
            ((const uint8_t *)request->headers + i * request->header_stride);
    while (pending_index < session_entry->pending_count &&
           session_entry->pending[pending_index].header.sequence < header->sequence)
      ++pending_index;
    pending_event *pending =
        pending_index < session_entry->pending_count &&
        session_entry->pending[pending_index].header.sequence == header->sequence
            ? &session_entry->pending[pending_index]
            : NULL;
    uint32_t item_status = POO_FLOW_RUNTIME_V0_OK;
    if (pending == NULL || !pending->polled ||
        pending->arena_id != request->arena.resource_id ||
        pending->arena_generation != request->arena_generation ||
        pending->header.correlation_identity.high !=
            header->correlation_identity.high ||
        pending->header.correlation_identity.low !=
            header->correlation_identity.low) {
      item_status = POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
    } else if (pending->accepted) {
      item_status = POO_FLOW_RUNTIME_V0_DUPLICATE_ACCEPTED;
    } else {
      pending->accepted = 1;
      request->accepted_bitmap[i / 8u] |= (uint8_t)(1u << (i % 8u));
      ++result->accepted_count;
    }
    request->item_statuses[i] = item_status;
    if (item_status != POO_FLOW_RUNTIME_V0_OK) ++result->rejected_count;
    if (pending != NULL) ++pending_index;
  }
  uint64_t watermark = session_entry->sequence;
  for (uint64_t i = 0; i < session_entry->pending_count; ++i) {
    pending_event *pending = &session_entry->pending[i];
    if (!pending->accepted) break;
    if (pending->header.sequence > watermark) watermark = pending->header.sequence;
  }
  session_entry->sequence = watermark;
  result->accepted_watermark = watermark;
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_batch_ack(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    poo_flow_runtime_v0_handle lease) {
  resource *session_entry = NULL;
  resource *lease_entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, session, KIND_SESSION,
                                               &session_entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  status = resolve(instance, lease, KIND_LEASE, &lease_entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (lease_entry->outstanding != session.resource_id)
    return POO_FLOW_RUNTIME_V0_WRONG_HANDLE_KIND;
  resource *arena_entry = slot(lease_entry->parent_id);
  if (arena_entry == NULL || !arena_entry->alive || arena_entry->kind != KIND_ARENA)
    return POO_FLOW_RUNTIME_V0_STALE_HANDLE;
  if (arena_entry->inflight_count < lease_entry->sequence)
    return POO_FLOW_RUNTIME_V0_INTERNAL_INVARIANT;
  arena_entry->inflight_count -= lease_entry->sequence;
  for (uint64_t i = 0; i < session_entry->pending_count; ++i)
    if (session_entry->pending[i].accepted && !session_entry->pending[i].acknowledged &&
        session_entry->pending[i].arena_id == lease_entry->parent_id &&
        session_entry->pending[i].header.sequence >=
            lease_entry->lease_first_sequence &&
        session_entry->pending[i].header.sequence <=
            lease_entry->lease_last_sequence)
      session_entry->pending[i].acknowledged = 1;
  uint64_t consumed = 0;
  while (consumed < session_entry->pending_count &&
         session_entry->pending[consumed].acknowledged)
    ++consumed;
  if (consumed != 0) {
    memmove(session_entry->pending, session_entry->pending + consumed,
            (session_entry->pending_count - consumed) *
                sizeof(*session_entry->pending));
    session_entry->pending_count -= consumed;
    session_entry->poll_cursor = session_entry->poll_cursor >= consumed
        ? session_entry->poll_cursor - consumed
        : 0;
  }
  return release_resource(lease_entry);
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_arena_recycle(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle arena,
    uint64_t expected_generation, uint64_t next_generation) {
  resource *entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, arena, KIND_ARENA, &entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  if (entry->arena_generation != expected_generation)
    return POO_FLOW_RUNTIME_V0_STALE_GENERATION;
  if (next_generation <= expected_generation)
    return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  if (entry->inflight_count != 0) return POO_FLOW_RUNTIME_V0_ARENA_BUSY;
  entry->arena_generation = next_generation;
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_owned_bytes_release(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_owned_bytes *value) {
  if (value == NULL) return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  resource *entry = NULL;
  poo_flow_runtime_v0_status status = resolve(instance, value->owner, KIND_BYTES, &entry);
  if (status != POO_FLOW_RUNTIME_V0_OK) return status;
  release_resource(entry);
  value->ptr = NULL; value->len = 0; value->capacity = 0;
  return POO_FLOW_RUNTIME_V0_OK;
}

poo_flow_runtime_v0_status poo_flow_runtime_v0_error_message(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_status status,
    poo_flow_runtime_v0_owned_bytes *message_out) {
  resource *ignored = NULL;
  poo_flow_runtime_v0_status resolved = instance_entry(instance, &ignored);
  if (resolved != POO_FLOW_RUNTIME_V0_OK) return resolved;
  if (message_out == NULL) return POO_FLOW_RUNTIME_V0_INVALID_ARGUMENT;
  const char *name = poo_flow_runtime_v0_status_name(status);
  size_t len = strlen(name);
  uint8_t *bytes = (uint8_t *)malloc(len);
  if (bytes == NULL) return POO_FLOW_RUNTIME_V0_ALLOCATION_FAILURE;
  memcpy(bytes, name, len);
  poo_flow_runtime_v0_handle owner = null_handle();
  resolved = allocate_resource(instance.instance_id, KIND_BYTES, &owner);
  if (resolved != POO_FLOW_RUNTIME_V0_OK) { free(bytes); return resolved; }
  resource *entry = slot(owner.resource_id);
  entry->bytes = bytes; entry->bytes_len = len;
  message_out->ptr = bytes; message_out->len = len; message_out->capacity = len;
  message_out->owner = owner;
  return POO_FLOW_RUNTIME_V0_OK;
}

const char *poo_flow_runtime_v0_status_name(poo_flow_runtime_v0_status status) {
  static const char *names[] = {
    "ok", "invalid-argument", "incompatible-abi", "incompatible-schema",
    "unsupported-capability", "malformed-descriptor", "wrong-handle-kind",
    "stale-handle", "cross-instance-handle", "already-released",
    "invalid-state", "bundle-identity-mismatch", "checkpoint-incompatible",
    "cancelled", "outstanding-work", "allocation-failure", "internal-invariant",
    "duplicate-accepted", "payload-bounds", "stale-generation", "arena-busy"
  };
  return status <= POO_FLOW_RUNTIME_V0_ARENA_BUSY ? names[status] : "unknown";
}
