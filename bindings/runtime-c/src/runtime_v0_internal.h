#ifndef POO_FLOW_RUNTIME_V0_INTERNAL_H
#define POO_FLOW_RUNTIME_V0_INTERNAL_H

#include "poo_flow/runtime_v0.h"

/* Private producer boundary.  Never installed for runtime consumers. */
poo_flow_runtime_v0_status poo_flow_runtime_v0_internal_publish(
    poo_flow_runtime_v0_handle instance, poo_flow_runtime_v0_handle session,
    poo_flow_runtime_v0_handle arena, uint64_t arena_generation,
    const poo_flow_runtime_v0_event_header *header);

#endif
