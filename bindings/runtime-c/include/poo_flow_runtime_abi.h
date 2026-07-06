#ifndef POO_FLOW_RUNTIME_ABI_H
#define POO_FLOW_RUNTIME_ABI_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define POO_FLOW_GRAPH_START "__start__"
#define POO_FLOW_GRAPH_END "__end__"

typedef struct poo_flow_context poo_flow_context_t;
typedef struct poo_flow_graph_plan poo_flow_graph_plan_t;

typedef enum {
  POO_FLOW_STATUS_OK = 0,
  POO_FLOW_STATUS_INVALID_ARGUMENT = 1,
  POO_FLOW_STATUS_INVALID_MANIFEST = 2,
  POO_FLOW_STATUS_RUNTIME_REJECTED = 3,
  POO_FLOW_STATUS_INVALID_GRAPH = 4,
  POO_FLOW_STATUS_INTERNAL_ERROR = 255
} poo_flow_status_t;

typedef struct {
  uint8_t *ptr;
  size_t len;
} poo_flow_bytes_t;

poo_flow_context_t *poo_flow_context_new(void);
void poo_flow_context_free(poo_flow_context_t *ctx);

poo_flow_status_t poo_flow_validate_manifest(
    poo_flow_context_t *ctx,
    const uint8_t *manifest,
    size_t manifest_len,
    poo_flow_bytes_t *receipt_out);

poo_flow_status_t poo_flow_plan_runtime_handoff(
    poo_flow_context_t *ctx,
    const uint8_t *request,
    size_t request_len,
    poo_flow_bytes_t *handoff_out);

poo_flow_graph_plan_t *poo_flow_graph_plan_new(void);
void poo_flow_graph_plan_free(poo_flow_graph_plan_t *plan);

poo_flow_status_t poo_flow_graph_plan_set_step_limit(
    poo_flow_graph_plan_t *plan,
    size_t step_limit);

poo_flow_status_t poo_flow_graph_plan_add_node(
    poo_flow_graph_plan_t *plan,
    const char *node);

poo_flow_status_t poo_flow_graph_plan_set_node_action(
    poo_flow_graph_plan_t *plan,
    const char *node,
    const char *action);

poo_flow_status_t poo_flow_graph_plan_set_state_reducer(
    poo_flow_graph_plan_t *plan,
    const char *state_key,
    const char *reducer);

poo_flow_status_t poo_flow_graph_plan_add_edge(
    poo_flow_graph_plan_t *plan,
    const char *source,
    const char *target);

poo_flow_status_t poo_flow_graph_plan_add_conditional_route(
    poo_flow_graph_plan_t *plan,
    const char *source,
    const char *router,
    const char *route_key,
    const char *target);

poo_flow_status_t poo_flow_graph_plan_describe(
    poo_flow_graph_plan_t *plan,
    poo_flow_bytes_t *receipt_out);

poo_flow_status_t poo_flow_graph_plan_validate(
    poo_flow_graph_plan_t *plan,
    poo_flow_bytes_t *receipt_out);

poo_flow_status_t poo_flow_plan_runtime_graph_handoff(
    poo_flow_context_t *ctx,
    poo_flow_graph_plan_t *plan,
    const uint8_t *request,
    size_t request_len,
    poo_flow_bytes_t *handoff_out);

void poo_flow_bytes_free(poo_flow_bytes_t value);
const char *poo_flow_status_name(poo_flow_status_t status);

#ifdef __cplusplus
}
#endif

#endif
