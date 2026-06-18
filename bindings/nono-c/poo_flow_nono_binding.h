/*
 * POO Flow nono C binding contract.
 *
 * This header is the C-facing adapter surface for the Scheme
 * `poo-flow.agent-sandbox-nono-c-binding.v1` manifest. It does not implement
 * nono; it pins the generated nono C ABI into names and structs a runtime
 * bridge can compile against.
 */

#ifndef POO_FLOW_NONO_BINDING_H
#define POO_FLOW_NONO_BINDING_H

#include <stdbool.h>
#include <stdint.h>

#include "nono.h"

#define POO_FLOW_NONO_BINDING_SCHEMA "poo-flow.agent-sandbox-nono-c-binding.v1"
#define POO_FLOW_NONO_BINDING_LIBRARY "nono_ffi"
#define POO_FLOW_NONO_BINDING_HEADER "poo_flow_nono_binding.h"
#define POO_FLOW_NONO_UPSTREAM_HEADER "nono.h"

typedef enum PooFlowNonoAccessMode {
  POO_FLOW_NONO_ACCESS_READ = NONO_ACCESS_MODE_READ,
  POO_FLOW_NONO_ACCESS_WRITE = NONO_ACCESS_MODE_WRITE,
  POO_FLOW_NONO_ACCESS_READ_WRITE = NONO_ACCESS_MODE_READ_WRITE
} PooFlowNonoAccessMode;

typedef enum PooFlowNonoNetworkMode {
  POO_FLOW_NONO_NETWORK_BLOCKED = NONO_NETWORK_MODE_BLOCKED,
  POO_FLOW_NONO_NETWORK_ALLOW_ALL = NONO_NETWORK_MODE_ALLOW_ALL,
  POO_FLOW_NONO_NETWORK_PROXY_ONLY = NONO_NETWORK_MODE_PROXY_ONLY
} PooFlowNonoNetworkMode;

typedef struct PooFlowNonoMountGrant {
  const char *path;
  uint32_t access_mode;
  bool is_file;
} PooFlowNonoMountGrant;

typedef struct PooFlowNonoNetworkGrant {
  uint32_t network_mode;
  uint16_t proxy_port;
  bool has_proxy_port;
} PooFlowNonoNetworkGrant;

typedef struct PooFlowNonoBindingApi {
  char *(*last_error)(void);
  void (*clear_error)(void);
  void (*string_free)(char *);
  char *(*version)(void);
  struct NonoCapabilitySet *(*capability_set_new)(void);
  void (*capability_set_free)(struct NonoCapabilitySet *);
  enum NonoErrorCode (*capability_set_allow_path)(struct NonoCapabilitySet *,
                                                  const char *,
                                                  uint32_t);
  enum NonoErrorCode (*capability_set_allow_file)(struct NonoCapabilitySet *,
                                                  const char *,
                                                  uint32_t);
  enum NonoErrorCode (*capability_set_set_network_mode)(struct NonoCapabilitySet *,
                                                        uint32_t);
  enum NonoErrorCode (*capability_set_set_proxy_port)(struct NonoCapabilitySet *,
                                                      uint16_t);
  enum NonoErrorCode (*capability_set_allow_command)(struct NonoCapabilitySet *,
                                                     const char *);
  enum NonoErrorCode (*capability_set_block_command)(struct NonoCapabilitySet *,
                                                     const char *);
  enum NonoErrorCode (*capability_set_add_platform_rule)(struct NonoCapabilitySet *,
                                                         const char *);
  void (*capability_set_deduplicate)(struct NonoCapabilitySet *);
  struct NonoQueryContext *(*query_context_new)(const struct NonoCapabilitySet *);
  void (*query_context_free)(struct NonoQueryContext *);
  enum NonoErrorCode (*query_context_query_path)(const struct NonoQueryContext *,
                                                 const char *,
                                                 uint32_t,
                                                 struct NonoQueryResult *);
  enum NonoErrorCode (*query_context_query_network)(const struct NonoQueryContext *,
                                                    struct NonoQueryResult *);
  enum NonoErrorCode (*sandbox_apply)(const struct NonoCapabilitySet *);
  bool (*sandbox_is_supported)(void);
  struct NonoSupportInfo (*sandbox_support_info)(void);
  struct NonoSandboxState *(*sandbox_state_from_caps)(const struct NonoCapabilitySet *);
  void (*sandbox_state_free)(struct NonoSandboxState *);
  char *(*sandbox_state_to_json)(const struct NonoSandboxState *);
  struct NonoSandboxState *(*sandbox_state_from_json)(const char *);
  struct NonoCapabilitySet *(*sandbox_state_to_caps)(const struct NonoSandboxState *);
} PooFlowNonoBindingApi;

static inline bool
poo_flow_nono_access_mode_supported(uint32_t mode)
{
  return mode == POO_FLOW_NONO_ACCESS_READ ||
         mode == POO_FLOW_NONO_ACCESS_WRITE ||
         mode == POO_FLOW_NONO_ACCESS_READ_WRITE;
}

static inline bool
poo_flow_nono_network_mode_supported(uint32_t mode)
{
  return mode == POO_FLOW_NONO_NETWORK_BLOCKED ||
         mode == POO_FLOW_NONO_NETWORK_ALLOW_ALL ||
         mode == POO_FLOW_NONO_NETWORK_PROXY_ONLY;
}

#endif /* POO_FLOW_NONO_BINDING_H */
