#include <poo_flow/runtime_v0.h>

#include <assert.h>
#include <string.h>

int main(void) {
  poo_flow_runtime_v0_handle instance = {0};
  assert(poo_flow_runtime_v0_instance_create(&instance) ==
         POO_FLOW_RUNTIME_V0_OK);
  assert(strcmp(poo_flow_runtime_v0_status_name(POO_FLOW_RUNTIME_V0_OK),
                "ok") == 0);
  assert(poo_flow_runtime_v0_instance_release(instance) ==
         POO_FLOW_RUNTIME_V0_OK);
  return 0;
}
