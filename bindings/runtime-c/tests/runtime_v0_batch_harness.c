#include <poo_flow/runtime_v0.h>

#include <assert.h>
#include <stdlib.h>
#include <string.h>

static poo_flow_runtime_v0_bytes_view view(const char *text) {
  poo_flow_runtime_v0_bytes_view value = {
      (const uint8_t *)text, (uint64_t)strlen(text)};
  return value;
}

static poo_flow_runtime_v0_event_header event(uint64_t sequence,
                                               uint64_t offset,
                                               uint64_t length) {
  poo_flow_runtime_v0_event_header header = {0};
  header.layout_version = POO_FLOW_RUNTIME_V0_LAYOUT_VERSION;
  header.event_kind = 1;
  header.sequence = sequence;
  header.event_identity.low = sequence;
  header.correlation_identity.low = sequence + 100;
  header.authorization_identity.low = sequence + 200;
  header.payload_offset = offset;
  header.payload_length = length;
  return header;
}

int main(void) {
  const char *schema = POO_FLOW_RUNTIME_V0_BUNDLE_SCHEMA;
  poo_flow_runtime_v0_handle instance = {0};
  assert(poo_flow_runtime_v0_instance_create(&instance) == POO_FLOW_RUNTIME_V0_OK);
  poo_flow_runtime_v0_negotiate_request negotiate = {0};
  negotiate.struct_size = sizeof(negotiate);
  negotiate.abi_minor = POO_FLOW_RUNTIME_V0_ABI_MINOR;
  negotiate.required_capabilities = POO_FLOW_RUNTIME_V0_CAP_CONTROL |
      POO_FLOW_RUNTIME_V0_CAP_HOT_BATCH |
      POO_FLOW_RUNTIME_V0_CAP_BULK_BUFFER |
      POO_FLOW_RUNTIME_V0_CAP_CALLER_ARENA |
      POO_FLOW_RUNTIME_V0_CAP_PARTIAL_ACCEPTANCE;
  negotiate.bundle_schema = view(schema);
  negotiate.runtime_identity = view("batch-harness");
  poo_flow_runtime_v0_negotiate_result negotiated = {0};
  negotiated.struct_size = sizeof(negotiated);
  assert(poo_flow_runtime_v0_negotiate(instance, &negotiate, &negotiated) ==
         POO_FLOW_RUNTIME_V0_OK);

  poo_flow_runtime_v0_bundle_descriptor bundle_desc = {0};
  bundle_desc.struct_size = sizeof(bundle_desc);
  memset(bundle_desc.digest, 0x44, sizeof(bundle_desc.digest));
  bundle_desc.bundle_epoch = 3;
  bundle_desc.schema = view(schema);
  bundle_desc.canonical_packet = view("bundle");
  poo_flow_runtime_v0_handle bundle = {0};
  assert(poo_flow_runtime_v0_bundle_open(instance, negotiated.profile,
                                         &bundle_desc, &bundle) ==
         POO_FLOW_RUNTIME_V0_OK);
  poo_flow_runtime_v0_session_descriptor session_desc = {0};
  session_desc.struct_size = sizeof(session_desc);
  poo_flow_runtime_v0_handle session = {0};
  assert(poo_flow_runtime_v0_session_open(instance, bundle, &session_desc,
                                          &session) == POO_FLOW_RUNTIME_V0_OK);

  uint8_t *memory = aligned_alloc(16, 4096);
  assert(memory != NULL);
  memset(memory, 0x5a, 4096);
  poo_flow_runtime_v0_arena_descriptor arena_desc = {0};
  arena_desc.struct_size = sizeof(arena_desc);
  arena_desc.alignment = 16;
  arena_desc.ptr = memory;
  arena_desc.capacity = 4096;
  arena_desc.generation = 1;
  poo_flow_runtime_v0_handle arena = {0};
  assert(poo_flow_runtime_v0_arena_register(instance, &arena_desc, &arena) ==
         POO_FLOW_RUNTIME_V0_OK);

  poo_flow_runtime_v0_event_header first = event(1, 0, 16);
  poo_flow_runtime_v0_event_header second = event(2, 64, 32);
  poo_flow_runtime_v0_event_header overflow = event(3, UINT64_MAX - 7u, 16);
  poo_flow_runtime_v0_publish_request publish = {0};
  publish.struct_size = sizeof(publish);
  publish.arena = arena;
  publish.arena_generation = 1;
  publish.headers = &overflow;
  publish.header_stride = sizeof(overflow);
  publish.item_count = 1;
  poo_flow_runtime_v0_publish_result published = {0};
  published.struct_size = sizeof(published);
  assert(poo_flow_runtime_v0_publish_batch(instance, session, &publish,
                                           &published) ==
         POO_FLOW_RUNTIME_V0_PAYLOAD_BOUNDS);
  poo_flow_runtime_v0_event_header inputs[2] = {first, second};
  publish.headers = inputs;
  publish.item_count = 2;
  publish.header_stride = sizeof(inputs[0]) - 1u;
  assert(poo_flow_runtime_v0_publish_batch(instance, session, &publish,
                                           &published) ==
         POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR);
  publish.header_stride = sizeof(inputs[0]);
  publish.item_count = UINT64_MAX;
  assert(poo_flow_runtime_v0_publish_batch(instance, session, &publish,
                                           &published) ==
         POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR);
  publish.item_count = 1025;
  assert(poo_flow_runtime_v0_publish_batch(instance, session, &publish,
                                           &published) ==
         POO_FLOW_RUNTIME_V0_OUTSTANDING_WORK);
  publish.item_count = 2;
  inputs[1].sequence = 1;
  assert(poo_flow_runtime_v0_publish_batch(instance, session, &publish,
                                           &published) ==
         POO_FLOW_RUNTIME_V0_INVALID_STATE);
  inputs[1] = second;
  assert(poo_flow_runtime_v0_publish_batch(instance, session, &publish,
                                           &published) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(published.published_count == 2 && published.last_sequence == 2);
  poo_flow_runtime_v0_event_header out[2] = {{0}};
  poo_flow_runtime_v0_poll_request poll = {0};
  poll.struct_size = sizeof(poll);
  poll.arena = arena;
  poll.arena_generation = 1;
  poll.headers = out;
  poll.header_stride = sizeof(*out);
  poll.header_capacity = 1;
  poll.payload_capacity = 4096;
  poo_flow_runtime_v0_poll_result polled = {0};
  polled.struct_size = sizeof(polled);
  poll.header_stride = sizeof(*out) - 1u;
  assert(poo_flow_runtime_v0_poll_batch(instance, session, &poll, &polled) ==
         POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR);
  poll.header_stride = sizeof(*out);
  assert(poo_flow_runtime_v0_poll_batch(instance, session, &poll, &polled) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(polled.produced_count == 0 && polled.required_header_count == 2);
  poll.header_capacity = 2;
  assert(poo_flow_runtime_v0_poll_batch(instance, session, &poll, &polled) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(polled.produced_count == 2 && out[1].sequence == 2);
  assert(poo_flow_runtime_v0_arena_recycle(instance, arena, 1, 2) ==
         POO_FLOW_RUNTIME_V0_ARENA_BUSY);

  uint32_t statuses[2] = {0};
  uint8_t bitmap[1] = {0};
  poo_flow_runtime_v0_submit_request submit = {0};
  submit.struct_size = sizeof(submit);
  submit.arena = arena;
  submit.arena_generation = 1;
  submit.headers = out;
  submit.header_stride = sizeof(*out);
  submit.item_count = 2;
  submit.item_statuses = statuses;
  submit.item_status_capacity = 2;
  submit.accepted_bitmap = bitmap;
  submit.accepted_bitmap_bytes = 1;
  poo_flow_runtime_v0_submit_result submitted = {0};
  submitted.struct_size = sizeof(submitted);
  submit.header_stride = sizeof(*out) - 1u;
  assert(poo_flow_runtime_v0_submit_batch(instance, session, &submit,
                                          &submitted) ==
         POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR);
  submit.header_stride = sizeof(*out);
  submit.accepted_bitmap_bytes = 0;
  assert(poo_flow_runtime_v0_submit_batch(instance, session, &submit,
                                          &submitted) ==
         POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR);
  submit.accepted_bitmap_bytes = 1;
  submit.item_count = UINT64_MAX;
  submit.item_status_capacity = UINT64_MAX;
  submit.accepted_bitmap_bytes = UINT64_MAX;
  assert(poo_flow_runtime_v0_submit_batch(instance, session, &submit,
                                          &submitted) ==
         POO_FLOW_RUNTIME_V0_MALFORMED_DESCRIPTOR);
  submit.item_count = 2;
  submit.item_status_capacity = 2;
  submit.accepted_bitmap_bytes = 1;
  assert(poo_flow_runtime_v0_submit_batch(instance, session, &submit, &submitted) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(submitted.accepted_count == 2 && bitmap[0] == 3);
  submit.item_count = 1;
  assert(poo_flow_runtime_v0_submit_batch(instance, session, &submit, &submitted) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(statuses[0] == POO_FLOW_RUNTIME_V0_DUPLICATE_ACCEPTED);
  assert(poo_flow_runtime_v0_batch_ack(instance, session, polled.lease) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_arena_recycle(instance, arena, 1, 2) ==
         POO_FLOW_RUNTIME_V0_OK);
  publish.headers = &first;
  publish.item_count = 1;
  assert(poo_flow_runtime_v0_publish_batch(instance, session, &publish,
                                           &published) ==
         POO_FLOW_RUNTIME_V0_STALE_GENERATION);

  assert(poo_flow_runtime_v0_arena_release(instance, arena) ==
         POO_FLOW_RUNTIME_V0_OK);
  free(memory);
  assert(poo_flow_runtime_v0_session_close(instance, session, 1) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_session_release(instance, session) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_bundle_release(instance, bundle) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_profile_release(instance, negotiated.profile) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_instance_release(instance) ==
         POO_FLOW_RUNTIME_V0_OK);
  return 0;
}
