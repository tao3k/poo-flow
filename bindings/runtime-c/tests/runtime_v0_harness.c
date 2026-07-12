#include "poo_flow/runtime_v0.h"

#include <assert.h>
#include <string.h>

static poo_flow_runtime_v0_bytes_view view(const char *text) {
  poo_flow_runtime_v0_bytes_view value = {
      (const uint8_t *)text, (uint64_t)strlen(text)};
  return value;
}

int main(void) {
  const char *schema = "poo-flow.organization-bundle.draft.3";
  poo_flow_runtime_v0_handle instance = {0};
  assert(poo_flow_runtime_v0_instance_create(&instance) == POO_FLOW_RUNTIME_V0_OK);

  poo_flow_runtime_v0_negotiate_request request = {0};
  request.struct_size = sizeof(request);
  request.abi_major = 0;
  request.abi_minor = 1;
  request.required_capabilities = POO_FLOW_RUNTIME_V0_CAP_CONTROL;
  request.optional_capabilities = POO_FLOW_RUNTIME_V0_CAP_CHECKPOINT;
  request.max_payload_bytes = 1024;
  request.bundle_schema = view(schema);
  request.runtime_identity = view("c-harness");
  poo_flow_runtime_v0_negotiate_result negotiated = {0};
  negotiated.struct_size = sizeof(negotiated);
  assert(poo_flow_runtime_v0_negotiate(instance, &request, &negotiated) ==
         POO_FLOW_RUNTIME_V0_OK);

  request.required_capabilities = UINT64_C(1) << 63;
  assert(poo_flow_runtime_v0_negotiate(instance, &request, &negotiated) ==
         POO_FLOW_RUNTIME_V0_UNSUPPORTED_CAPABILITY);
  request.required_capabilities = POO_FLOW_RUNTIME_V0_CAP_CONTROL;

  poo_flow_runtime_v0_bundle_descriptor bundle_desc = {0};
  bundle_desc.struct_size = sizeof(bundle_desc);
  bundle_desc.digest_algorithm = 1;
  memset(bundle_desc.digest, 0x5a, sizeof(bundle_desc.digest));
  bundle_desc.bundle_epoch = 9;
  bundle_desc.schema = view(schema);
  bundle_desc.canonical_packet = view("canonical-bundle-packet");
  poo_flow_runtime_v0_handle bundle = {0};
  assert(poo_flow_runtime_v0_bundle_open(instance, negotiated.profile,
                                         &bundle_desc, &bundle) ==
         POO_FLOW_RUNTIME_V0_OK);

  poo_flow_runtime_v0_session_descriptor session_desc = {0};
  session_desc.struct_size = sizeof(session_desc);
  session_desc.initial_sequence = 7;
  poo_flow_runtime_v0_handle session = {0};
  assert(poo_flow_runtime_v0_session_open(instance, bundle, &session_desc,
                                          &session) == POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_session_cancel(instance, session) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_session_cancel(instance, session) ==
         POO_FLOW_RUNTIME_V0_OK);

  poo_flow_runtime_v0_owned_bytes checkpoint = {0};
  assert(poo_flow_runtime_v0_session_checkpoint(instance, session, &checkpoint) ==
         POO_FLOW_RUNTIME_V0_OK);
  poo_flow_runtime_v0_handle restored = {0};
  poo_flow_runtime_v0_bytes_view checkpoint_view = {checkpoint.ptr, checkpoint.len};
  assert(poo_flow_runtime_v0_session_restore(instance, bundle, checkpoint_view,
                                             &restored) == POO_FLOW_RUNTIME_V0_OK);
  checkpoint.ptr[0] ^= 1;
  assert(poo_flow_runtime_v0_session_restore(instance, bundle, checkpoint_view,
                                             &restored) ==
         POO_FLOW_RUNTIME_V0_CHECKPOINT_INCOMPATIBLE);
  checkpoint.ptr[0] ^= 1;
  assert(poo_flow_runtime_v0_owned_bytes_release(instance, &checkpoint) ==
         POO_FLOW_RUNTIME_V0_OK);

  poo_flow_runtime_v0_handle other_instance = {0};
  assert(poo_flow_runtime_v0_instance_create(&other_instance) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_session_cancel(other_instance, session) ==
         POO_FLOW_RUNTIME_V0_CROSS_INSTANCE_HANDLE);
  assert(poo_flow_runtime_v0_bundle_release(instance, session) ==
         POO_FLOW_RUNTIME_V0_WRONG_HANDLE_KIND);

  assert(poo_flow_runtime_v0_session_close(instance, session, 1) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_session_release(instance, session) ==
         POO_FLOW_RUNTIME_V0_OK);
  poo_flow_runtime_v0_status released_status =
      poo_flow_runtime_v0_session_cancel(instance, session);
  assert(released_status == POO_FLOW_RUNTIME_V0_STALE_HANDLE ||
         released_status == POO_FLOW_RUNTIME_V0_ALREADY_RELEASED);
  assert(poo_flow_runtime_v0_session_close(instance, restored, 1) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_session_release(instance, restored) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_bundle_release(instance, bundle) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_profile_release(instance, negotiated.profile) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_instance_release(instance) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(poo_flow_runtime_v0_instance_release(other_instance) ==
         POO_FLOW_RUNTIME_V0_OK);
  return 0;
}
