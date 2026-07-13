#include "poo_flow/bundle_v1.h"

#include <cstring>

static_assert(sizeof(poo_flow_bundle_v1_descriptor) == 256,
              "C++ sees a different Bundle v1 descriptor");

int main() {
  return std::strcmp(poo_flow_bundle_v1_status_name(POO_FLOW_BUNDLE_V1_OK),
                     "ok") == 0
             ? 0
             : 1;
}
