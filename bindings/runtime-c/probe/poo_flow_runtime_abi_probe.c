#include "poo_flow_runtime_abi.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct poo_flow_context {
  uint64_t next_receipt_id;
};

typedef struct {
  char *name;
  char *action;
} graph_node_t;

typedef struct {
  char *source;
  char *target;
} graph_edge_t;

typedef struct {
  char *source;
  char *router;
  char *route_key;
  char *target;
} graph_conditional_route_t;

typedef struct {
  char *state_key;
  char *reducer;
} graph_state_reducer_t;

struct poo_flow_graph_plan {
  size_t step_limit;
  graph_node_t *nodes;
  size_t node_count;
  size_t node_capacity;
  graph_edge_t *edges;
  size_t edge_count;
  size_t edge_capacity;
  graph_conditional_route_t *conditional_routes;
  size_t conditional_route_count;
  size_t conditional_route_capacity;
  graph_state_reducer_t *state_reducers;
  size_t state_reducer_count;
  size_t state_reducer_capacity;
};

static uint64_t digest_bytes(uint64_t digest, const void *data, size_t len) {
  const uint8_t *bytes = (const uint8_t *)data;
  for (size_t i = 0; i < len; i += 1) {
    digest ^= (uint64_t)bytes[i];
    digest *= 1099511628211ULL;
  }
  return digest;
}

static uint64_t digest_string(uint64_t digest, const char *value) {
  if (value == NULL) {
    static const char null_marker[] = "<null>";
    return digest_bytes(digest, null_marker, sizeof(null_marker));
  }
  return digest_bytes(digest, value, strlen(value) + 1);
}

static uint64_t digest_size(uint64_t digest, size_t value) {
  uint64_t normalized = (uint64_t)value;
  uint8_t bytes[8];
  for (size_t i = 0; i < sizeof(bytes); i += 1) {
    bytes[i] = (uint8_t)((normalized >> (i * 8)) & 0xffU);
  }
  return digest_bytes(digest, bytes, sizeof(bytes));
}

static uint64_t graph_plan_digest(poo_flow_graph_plan_t *plan) {
  uint64_t digest = 1469598103934665603ULL;
  if (plan == NULL) {
    return digest_string(digest, "<null-plan>");
  }

  digest = digest_size(digest, plan->step_limit);
  digest = digest_size(digest, plan->node_count);
  for (size_t i = 0; i < plan->node_count; i += 1) {
    digest = digest_string(digest, plan->nodes[i].name);
    digest = digest_string(digest, plan->nodes[i].action);
  }

  digest = digest_size(digest, plan->state_reducer_count);
  for (size_t i = 0; i < plan->state_reducer_count; i += 1) {
    digest = digest_string(digest, plan->state_reducers[i].state_key);
    digest = digest_string(digest, plan->state_reducers[i].reducer);
  }

  digest = digest_size(digest, plan->edge_count);
  for (size_t i = 0; i < plan->edge_count; i += 1) {
    digest = digest_string(digest, plan->edges[i].source);
    digest = digest_string(digest, plan->edges[i].target);
  }

  digest = digest_size(digest, plan->conditional_route_count);
  for (size_t i = 0; i < plan->conditional_route_count; i += 1) {
    digest = digest_string(digest, plan->conditional_routes[i].source);
    digest = digest_string(digest, plan->conditional_routes[i].router);
    digest = digest_string(digest, plan->conditional_routes[i].route_key);
    digest = digest_string(digest, plan->conditional_routes[i].target);
  }

  return digest;
}

static void clear_bytes(poo_flow_bytes_t *value) {
  if (value == NULL) {
    return;
  }

  value->ptr = NULL;
  value->len = 0;
}

static char *copy_string(const char *value) {
  if (value == NULL || value[0] == '\0') {
    return NULL;
  }

  size_t len = strlen(value);
  char *copy = (char *)malloc(len + 1);
  if (copy == NULL) {
    return NULL;
  }

  memcpy(copy, value, len + 1);
  return copy;
}

static int reserve_nodes(poo_flow_graph_plan_t *plan, size_t count) {
  if (count <= plan->node_capacity) {
    return 1;
  }

  size_t capacity = plan->node_capacity == 0 ? 4 : plan->node_capacity * 2;
  while (capacity < count) {
    capacity *= 2;
  }

  graph_node_t *nodes =
      (graph_node_t *)realloc(plan->nodes, capacity * sizeof(*nodes));
  if (nodes == NULL) {
    return 0;
  }

  plan->nodes = nodes;
  plan->node_capacity = capacity;
  return 1;
}

static int reserve_edges(poo_flow_graph_plan_t *plan, size_t count) {
  if (count <= plan->edge_capacity) {
    return 1;
  }

  size_t capacity = plan->edge_capacity == 0 ? 4 : plan->edge_capacity * 2;
  while (capacity < count) {
    capacity *= 2;
  }

  graph_edge_t *edges =
      (graph_edge_t *)realloc(plan->edges, capacity * sizeof(*edges));
  if (edges == NULL) {
    return 0;
  }

  plan->edges = edges;
  plan->edge_capacity = capacity;
  return 1;
}

static int reserve_conditional_routes(
    poo_flow_graph_plan_t *plan,
    size_t count) {
  if (count <= plan->conditional_route_capacity) {
    return 1;
  }

  size_t capacity = plan->conditional_route_capacity == 0
                        ? 4
                        : plan->conditional_route_capacity * 2;
  while (capacity < count) {
    capacity *= 2;
  }

  graph_conditional_route_t *routes =
      (graph_conditional_route_t *)realloc(
          plan->conditional_routes,
          capacity * sizeof(*routes));
  if (routes == NULL) {
    return 0;
  }

  plan->conditional_routes = routes;
  plan->conditional_route_capacity = capacity;
  return 1;
}

static int reserve_state_reducers(poo_flow_graph_plan_t *plan, size_t count) {
  if (count <= plan->state_reducer_capacity) {
    return 1;
  }

  size_t capacity = plan->state_reducer_capacity == 0
                        ? 4
                        : plan->state_reducer_capacity * 2;
  while (capacity < count) {
    capacity *= 2;
  }

  graph_state_reducer_t *reducers =
      (graph_state_reducer_t *)realloc(
          plan->state_reducers,
          capacity * sizeof(*reducers));
  if (reducers == NULL) {
    return 0;
  }

  plan->state_reducers = reducers;
  plan->state_reducer_capacity = capacity;
  return 1;
}

static int graph_plan_has_node(poo_flow_graph_plan_t *plan, const char *node) {
  if (plan == NULL || node == NULL) {
    return 0;
  }

  for (size_t i = 0; i < plan->node_count; i += 1) {
    if (strcmp(plan->nodes[i].name, node) == 0) {
      return 1;
    }
  }

  return 0;
}

static int graph_plan_has_duplicate_node(poo_flow_graph_plan_t *plan) {
  if (plan == NULL) {
    return 0;
  }

  for (size_t i = 0; i < plan->node_count; i += 1) {
    for (size_t j = i + 1; j < plan->node_count; j += 1) {
      if (strcmp(plan->nodes[i].name, plan->nodes[j].name) == 0) {
        return 1;
      }
    }
  }

  return 0;
}

static int graph_plan_all_nodes_have_actions(poo_flow_graph_plan_t *plan) {
  if (plan == NULL) {
    return 0;
  }

  for (size_t i = 0; i < plan->node_count; i += 1) {
    if (plan->nodes[i].action == NULL || plan->nodes[i].action[0] == '\0') {
      return 0;
    }
  }

  return 1;
}

static int graph_plan_endpoint_is_valid(
    poo_flow_graph_plan_t *plan,
    const char *endpoint) {
  if (endpoint == NULL) {
    return 0;
  }
  if (strcmp(endpoint, POO_FLOW_GRAPH_START) == 0 ||
      strcmp(endpoint, POO_FLOW_GRAPH_END) == 0) {
    return 1;
  }
  return graph_plan_has_node(plan, endpoint);
}

static size_t graph_plan_node_index(
    poo_flow_graph_plan_t *plan,
    const char *node) {
  if (plan == NULL || node == NULL) {
    return 0;
  }

  for (size_t i = 0; i < plan->node_count; i += 1) {
    if (strcmp(plan->nodes[i].name, node) == 0) {
      return i;
    }
  }

  return plan->node_count;
}

static size_t graph_plan_state_reducer_index(
    poo_flow_graph_plan_t *plan,
    const char *state_key) {
  if (plan == NULL || state_key == NULL) {
    return 0;
  }

  for (size_t i = 0; i < plan->state_reducer_count; i += 1) {
    if (strcmp(plan->state_reducers[i].state_key, state_key) == 0) {
      return i;
    }
  }

  return plan->state_reducer_count;
}

static int graph_plan_all_nodes_reachable_from_start(
    poo_flow_graph_plan_t *plan) {
  int *reachable = (int *)calloc(plan->node_count, sizeof(*reachable));
  if (reachable == NULL) {
    return -1;
  }

  for (size_t i = 0; i < plan->edge_count; i += 1) {
    if (strcmp(plan->edges[i].source, POO_FLOW_GRAPH_START) == 0) {
      size_t target = graph_plan_node_index(plan, plan->edges[i].target);
      if (target < plan->node_count) {
        reachable[target] = 1;
      }
    }
  }

  int changed = 1;
  while (changed) {
    changed = 0;
    for (size_t i = 0; i < plan->edge_count; i += 1) {
      size_t source = graph_plan_node_index(plan, plan->edges[i].source);
      size_t target = graph_plan_node_index(plan, plan->edges[i].target);
      if (source < plan->node_count && target < plan->node_count &&
          reachable[source] && !reachable[target]) {
        reachable[target] = 1;
        changed = 1;
      }
    }

    for (size_t i = 0; i < plan->conditional_route_count; i += 1) {
      graph_conditional_route_t *route = &plan->conditional_routes[i];
      size_t source = graph_plan_node_index(plan, route->source);
      size_t target = graph_plan_node_index(plan, route->target);
      if (source < plan->node_count && target < plan->node_count &&
          reachable[source] && !reachable[target]) {
        reachable[target] = 1;
        changed = 1;
      }
    }
  }

  int ok = 1;
  for (size_t i = 0; i < plan->node_count; i += 1) {
    if (!reachable[i]) {
      ok = 0;
      break;
    }
  }

  free(reachable);
  return ok;
}

static int graph_plan_all_nodes_can_reach_end(poo_flow_graph_plan_t *plan) {
  int *can_reach_end = (int *)calloc(plan->node_count, sizeof(*can_reach_end));
  if (can_reach_end == NULL) {
    return -1;
  }

  for (size_t i = 0; i < plan->edge_count; i += 1) {
    if (strcmp(plan->edges[i].target, POO_FLOW_GRAPH_END) == 0) {
      size_t source = graph_plan_node_index(plan, plan->edges[i].source);
      if (source < plan->node_count) {
        can_reach_end[source] = 1;
      }
    }
  }

  int changed = 1;
  while (changed) {
    changed = 0;
    for (size_t i = 0; i < plan->edge_count; i += 1) {
      size_t source = graph_plan_node_index(plan, plan->edges[i].source);
      size_t target = graph_plan_node_index(plan, plan->edges[i].target);
      if (source < plan->node_count && target < plan->node_count &&
          can_reach_end[target] && !can_reach_end[source]) {
        can_reach_end[source] = 1;
        changed = 1;
      }
    }

    for (size_t i = 0; i < plan->conditional_route_count; i += 1) {
      graph_conditional_route_t *route = &plan->conditional_routes[i];
      size_t source = graph_plan_node_index(plan, route->source);
      size_t target = graph_plan_node_index(plan, route->target);
      if (source < plan->node_count && target < plan->node_count &&
          can_reach_end[target] && !can_reach_end[source]) {
        can_reach_end[source] = 1;
        changed = 1;
      }
    }
  }

  int ok = 1;
  for (size_t i = 0; i < plan->node_count; i += 1) {
    if (!can_reach_end[i]) {
      ok = 0;
      break;
    }
  }

  free(can_reach_end);
  return ok;
}

static poo_flow_status_t graph_plan_validation_status(
    poo_flow_graph_plan_t *plan) {
  if (plan == NULL || plan->node_count == 0 || plan->step_limit == 0) {
    return POO_FLOW_STATUS_INVALID_GRAPH;
  }
  if (graph_plan_has_duplicate_node(plan)) {
    return POO_FLOW_STATUS_INVALID_GRAPH;
  }
  if (!graph_plan_all_nodes_have_actions(plan)) {
    return POO_FLOW_STATUS_INVALID_GRAPH;
  }

  int has_start_edge = 0;
  int has_end_edge = 0;
  for (size_t i = 0; i < plan->edge_count; i += 1) {
    if (!graph_plan_endpoint_is_valid(plan, plan->edges[i].source) ||
        !graph_plan_endpoint_is_valid(plan, plan->edges[i].target)) {
      return POO_FLOW_STATUS_INVALID_GRAPH;
    }
    if (strcmp(plan->edges[i].source, POO_FLOW_GRAPH_START) == 0) {
      has_start_edge = 1;
    }
    if (strcmp(plan->edges[i].target, POO_FLOW_GRAPH_END) == 0) {
      has_end_edge = 1;
    }
  }

  for (size_t i = 0; i < plan->conditional_route_count; i += 1) {
    graph_conditional_route_t *route = &plan->conditional_routes[i];
    if (!graph_plan_endpoint_is_valid(plan, route->source) ||
        !graph_plan_endpoint_is_valid(plan, route->target)) {
      return POO_FLOW_STATUS_INVALID_GRAPH;
    }
  }

  if (!has_start_edge || !has_end_edge) {
    return POO_FLOW_STATUS_INVALID_GRAPH;
  }

  int reachable_from_start = graph_plan_all_nodes_reachable_from_start(plan);
  int can_reach_end = graph_plan_all_nodes_can_reach_end(plan);
  if (reachable_from_start < 0 || can_reach_end < 0) {
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }
  if (!reachable_from_start || !can_reach_end) {
    return POO_FLOW_STATUS_INVALID_GRAPH;
  }

  return POO_FLOW_STATUS_OK;
}

static poo_flow_status_t make_receipt(
    poo_flow_context_t *ctx,
    const char *kind,
    size_t payload_len,
    poo_flow_bytes_t *out) {
  if (ctx == NULL || kind == NULL || out == NULL) {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  clear_bytes(out);

  int needed = snprintf(
      NULL,
      0,
      "poo-flow-receipt.v1\nkind=%s\nreceipt-id=%llu\npayload-bytes=%zu\n",
      kind,
      (unsigned long long)ctx->next_receipt_id,
      payload_len);

  if (needed < 0) {
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  size_t len = (size_t)needed;
  uint8_t *buffer = (uint8_t *)malloc(len + 1);
  if (buffer == NULL) {
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  int written = snprintf(
      (char *)buffer,
      len + 1,
      "poo-flow-receipt.v1\nkind=%s\nreceipt-id=%llu\npayload-bytes=%zu\n",
      kind,
      (unsigned long long)ctx->next_receipt_id,
      payload_len);

  if (written < 0 || (size_t)written != len) {
    free(buffer);
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  ctx->next_receipt_id += 1;
  out->ptr = buffer;
  out->len = len;
  return POO_FLOW_STATUS_OK;
}

static poo_flow_status_t make_graph_receipt(
    poo_flow_context_t *ctx,
    poo_flow_graph_plan_t *plan,
    const char *kind,
    size_t payload_len,
    poo_flow_bytes_t *out) {
  if (plan == NULL || kind == NULL || out == NULL) {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  clear_bytes(out);

  uint64_t receipt_id = ctx == NULL ? 0 : ctx->next_receipt_id;
  uint64_t digest = graph_plan_digest(plan);
  int needed = snprintf(
      NULL,
      0,
      "poo-flow-receipt.v1\n"
      "kind=%s\n"
      "receipt-id=%llu\n"
      "payload-bytes=%zu\n"
      "nodes=%zu\n"
      "node-actions=%zu\n"
      "state-reducers=%zu\n"
      "edges=%zu\n"
      "conditional-routes=%zu\n"
      "step-limit=%zu\n"
      "plan-digest=%016llx\n",
      kind,
      (unsigned long long)receipt_id,
      payload_len,
      plan->node_count,
      plan->node_count,
      plan->state_reducer_count,
      plan->edge_count,
      plan->conditional_route_count,
      plan->step_limit,
      (unsigned long long)digest);

  if (needed < 0) {
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  size_t len = (size_t)needed;
  uint8_t *buffer = (uint8_t *)malloc(len + 1);
  if (buffer == NULL) {
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  int written = snprintf(
      (char *)buffer,
      len + 1,
      "poo-flow-receipt.v1\n"
      "kind=%s\n"
      "receipt-id=%llu\n"
      "payload-bytes=%zu\n"
      "nodes=%zu\n"
      "node-actions=%zu\n"
      "state-reducers=%zu\n"
      "edges=%zu\n"
      "conditional-routes=%zu\n"
      "step-limit=%zu\n"
      "plan-digest=%016llx\n",
      kind,
      (unsigned long long)receipt_id,
      payload_len,
      plan->node_count,
      plan->node_count,
      plan->state_reducer_count,
      plan->edge_count,
      plan->conditional_route_count,
      plan->step_limit,
      (unsigned long long)digest);

  if (written < 0 || (size_t)written != len) {
    free(buffer);
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  if (ctx != NULL) {
    ctx->next_receipt_id += 1;
  }

  out->ptr = buffer;
  out->len = len;
  return POO_FLOW_STATUS_OK;
}

poo_flow_context_t *poo_flow_context_new(void) {
  poo_flow_context_t *ctx = (poo_flow_context_t *)calloc(1, sizeof(*ctx));
  if (ctx == NULL) {
    return NULL;
  }

  ctx->next_receipt_id = 1;
  return ctx;
}

void poo_flow_context_free(poo_flow_context_t *ctx) {
  free(ctx);
}

poo_flow_status_t poo_flow_validate_manifest(
    poo_flow_context_t *ctx,
    const uint8_t *manifest,
    size_t manifest_len,
    poo_flow_bytes_t *receipt_out) {
  if (ctx == NULL || receipt_out == NULL) {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  clear_bytes(receipt_out);

  if (manifest == NULL || manifest_len == 0) {
    return POO_FLOW_STATUS_INVALID_MANIFEST;
  }

  return make_receipt(ctx, "manifest-validation", manifest_len, receipt_out);
}

poo_flow_status_t poo_flow_plan_runtime_handoff(
    poo_flow_context_t *ctx,
    const uint8_t *request,
    size_t request_len,
    poo_flow_bytes_t *handoff_out) {
  if (ctx == NULL || handoff_out == NULL) {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  clear_bytes(handoff_out);

  if (request == NULL || request_len == 0) {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  return make_receipt(ctx, "runtime-handoff", request_len, handoff_out);
}

poo_flow_graph_plan_t *poo_flow_graph_plan_new(void) {
  poo_flow_graph_plan_t *plan =
      (poo_flow_graph_plan_t *)calloc(1, sizeof(*plan));
  if (plan == NULL) {
    return NULL;
  }

  plan->step_limit = 100;
  return plan;
}

void poo_flow_graph_plan_free(poo_flow_graph_plan_t *plan) {
  if (plan == NULL) {
    return;
  }

  for (size_t i = 0; i < plan->node_count; i += 1) {
    free(plan->nodes[i].name);
    free(plan->nodes[i].action);
  }
  for (size_t i = 0; i < plan->edge_count; i += 1) {
    free(plan->edges[i].source);
    free(plan->edges[i].target);
  }
  for (size_t i = 0; i < plan->conditional_route_count; i += 1) {
    free(plan->conditional_routes[i].source);
    free(plan->conditional_routes[i].router);
    free(plan->conditional_routes[i].route_key);
    free(plan->conditional_routes[i].target);
  }
  for (size_t i = 0; i < plan->state_reducer_count; i += 1) {
    free(plan->state_reducers[i].state_key);
    free(plan->state_reducers[i].reducer);
  }

  free(plan->nodes);
  free(plan->edges);
  free(plan->conditional_routes);
  free(plan->state_reducers);
  free(plan);
}

poo_flow_status_t poo_flow_graph_plan_set_step_limit(
    poo_flow_graph_plan_t *plan,
    size_t step_limit) {
  if (plan == NULL || step_limit == 0) {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  plan->step_limit = step_limit;
  return POO_FLOW_STATUS_OK;
}

poo_flow_status_t poo_flow_graph_plan_add_node(
    poo_flow_graph_plan_t *plan,
    const char *node) {
  if (plan == NULL || node == NULL || node[0] == '\0') {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  if (!reserve_nodes(plan, plan->node_count + 1)) {
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  if (graph_plan_has_node(plan, node)) {
    return POO_FLOW_STATUS_INVALID_GRAPH;
  }

  char *node_copy = copy_string(node);
  char *action_copy = copy_string(node);
  if (node_copy == NULL || action_copy == NULL) {
    free(node_copy);
    free(action_copy);
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  plan->nodes[plan->node_count].name = node_copy;
  plan->nodes[plan->node_count].action = action_copy;
  plan->node_count += 1;
  return POO_FLOW_STATUS_OK;
}

poo_flow_status_t poo_flow_graph_plan_set_node_action(
    poo_flow_graph_plan_t *plan,
    const char *node,
    const char *action) {
  if (plan == NULL || node == NULL || action == NULL ||
      node[0] == '\0' || action[0] == '\0') {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  size_t node_index = graph_plan_node_index(plan, node);
  if (node_index >= plan->node_count) {
    return POO_FLOW_STATUS_INVALID_GRAPH;
  }

  char *action_copy = copy_string(action);
  if (action_copy == NULL) {
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  free(plan->nodes[node_index].action);
  plan->nodes[node_index].action = action_copy;
  return POO_FLOW_STATUS_OK;
}

poo_flow_status_t poo_flow_graph_plan_set_state_reducer(
    poo_flow_graph_plan_t *plan,
    const char *state_key,
    const char *reducer) {
  if (plan == NULL || state_key == NULL || reducer == NULL ||
      state_key[0] == '\0' || reducer[0] == '\0') {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  size_t reducer_index = graph_plan_state_reducer_index(plan, state_key);
  if (reducer_index < plan->state_reducer_count) {
    char *reducer_copy = copy_string(reducer);
    if (reducer_copy == NULL) {
      return POO_FLOW_STATUS_INTERNAL_ERROR;
    }

    free(plan->state_reducers[reducer_index].reducer);
    plan->state_reducers[reducer_index].reducer = reducer_copy;
    return POO_FLOW_STATUS_OK;
  }

  if (!reserve_state_reducers(plan, plan->state_reducer_count + 1)) {
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  char *state_key_copy = copy_string(state_key);
  char *reducer_copy = copy_string(reducer);
  if (state_key_copy == NULL || reducer_copy == NULL) {
    free(state_key_copy);
    free(reducer_copy);
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  graph_state_reducer_t *state_reducer =
      &plan->state_reducers[plan->state_reducer_count];
  state_reducer->state_key = state_key_copy;
  state_reducer->reducer = reducer_copy;
  plan->state_reducer_count += 1;
  return POO_FLOW_STATUS_OK;
}

poo_flow_status_t poo_flow_graph_plan_add_edge(
    poo_flow_graph_plan_t *plan,
    const char *source,
    const char *target) {
  if (plan == NULL || source == NULL || target == NULL ||
      source[0] == '\0' || target[0] == '\0') {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  if (!reserve_edges(plan, plan->edge_count + 1)) {
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  char *source_copy = copy_string(source);
  char *target_copy = copy_string(target);
  if (source_copy == NULL || target_copy == NULL) {
    free(source_copy);
    free(target_copy);
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  plan->edges[plan->edge_count].source = source_copy;
  plan->edges[plan->edge_count].target = target_copy;
  plan->edge_count += 1;
  return POO_FLOW_STATUS_OK;
}

poo_flow_status_t poo_flow_graph_plan_add_conditional_route(
    poo_flow_graph_plan_t *plan,
    const char *source,
    const char *router,
    const char *route_key,
    const char *target) {
  if (plan == NULL || source == NULL || router == NULL ||
      route_key == NULL || target == NULL || source[0] == '\0' ||
      router[0] == '\0' || route_key[0] == '\0' || target[0] == '\0') {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  if (!reserve_conditional_routes(plan, plan->conditional_route_count + 1)) {
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  char *source_copy = copy_string(source);
  char *router_copy = copy_string(router);
  char *route_key_copy = copy_string(route_key);
  char *target_copy = copy_string(target);
  if (source_copy == NULL || router_copy == NULL ||
      route_key_copy == NULL || target_copy == NULL) {
    free(source_copy);
    free(router_copy);
    free(route_key_copy);
    free(target_copy);
    return POO_FLOW_STATUS_INTERNAL_ERROR;
  }

  graph_conditional_route_t *route =
      &plan->conditional_routes[plan->conditional_route_count];
  route->source = source_copy;
  route->router = router_copy;
  route->route_key = route_key_copy;
  route->target = target_copy;
  plan->conditional_route_count += 1;
  return POO_FLOW_STATUS_OK;
}

poo_flow_status_t poo_flow_graph_plan_describe(
    poo_flow_graph_plan_t *plan,
    poo_flow_bytes_t *receipt_out) {
  if (plan == NULL || receipt_out == NULL) {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  return make_graph_receipt(
      NULL,
      plan,
      "runtime-graph-plan",
      0,
      receipt_out);
}

poo_flow_status_t poo_flow_graph_plan_validate(
    poo_flow_graph_plan_t *plan,
    poo_flow_bytes_t *receipt_out) {
  if (plan == NULL || receipt_out == NULL) {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  clear_bytes(receipt_out);

  poo_flow_status_t status = graph_plan_validation_status(plan);
  if (status != POO_FLOW_STATUS_OK) {
    return status;
  }

  return make_graph_receipt(
      NULL,
      plan,
      "runtime-graph-validation",
      0,
      receipt_out);
}

poo_flow_status_t poo_flow_plan_runtime_graph_handoff(
    poo_flow_context_t *ctx,
    poo_flow_graph_plan_t *plan,
    const uint8_t *request,
    size_t request_len,
    poo_flow_bytes_t *handoff_out) {
  if (ctx == NULL || plan == NULL || handoff_out == NULL) {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  clear_bytes(handoff_out);

  if (request == NULL || request_len == 0 || plan->node_count == 0) {
    return POO_FLOW_STATUS_INVALID_ARGUMENT;
  }

  poo_flow_status_t status = graph_plan_validation_status(plan);
  if (status != POO_FLOW_STATUS_OK) {
    return status;
  }

  return make_graph_receipt(
      ctx,
      plan,
      "runtime-graph-handoff",
      request_len,
      handoff_out);
}

void poo_flow_bytes_free(poo_flow_bytes_t value) {
  free(value.ptr);
}

const char *poo_flow_status_name(poo_flow_status_t status) {
  switch (status) {
    case POO_FLOW_STATUS_OK:
      return "ok";
    case POO_FLOW_STATUS_INVALID_ARGUMENT:
      return "invalid-argument";
    case POO_FLOW_STATUS_INVALID_MANIFEST:
      return "invalid-manifest";
    case POO_FLOW_STATUS_RUNTIME_REJECTED:
      return "runtime-rejected";
    case POO_FLOW_STATUS_INVALID_GRAPH:
      return "invalid-graph";
    case POO_FLOW_STATUS_INTERNAL_ERROR:
      return "internal-error";
    default:
      return "unknown";
  }
}
