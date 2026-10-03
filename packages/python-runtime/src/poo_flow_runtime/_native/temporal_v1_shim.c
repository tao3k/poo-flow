// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
// Included after runtime_v0_shim.c; reuse its platform library operations.
#include <poo_flow/temporal_selection_v1.h>

typedef struct {
  void *library;
  int (*open)(const char *, poo_flow_temporal_verify_v1,
              poo_flow_temporal_sign_v1, void *, poo_flow_temporal_store_v1 **);
  int (*require_budget)(poo_flow_temporal_store_v1 *, const char *);
  void (*close)(poo_flow_temporal_store_v1 *);
  int (*payload)(const poo_flow_temporal_publish_v1 *, uint8_t *, size_t, size_t *);
  uint32_t (*publish)(poo_flow_temporal_store_v1 *,
                      const poo_flow_temporal_publish_v1 *, poo_flow_temporal_effect_v1 *);
  uint32_t (*observe)(poo_flow_temporal_store_v1 *, const char *, const char *,
                      uint8_t *, size_t, size_t *, poo_flow_temporal_effect_v1 *);
} poo_flow_python_temporal_api_v1;

void poo_flow_python_temporal_unbind_v1(poo_flow_python_temporal_api_v1 *api) {
  if (!api) return;
  if (api->library) POO_FLOW_LIBRARY_CLOSE((poo_flow_library_handle)api->library);
  memset(api, 0, sizeof(*api));
}

int poo_flow_python_temporal_bind_v1(const char *path, poo_flow_python_temporal_api_v1 *api) {
  if (!path || !api) return 0;
  memset(api, 0, sizeof(*api));
  api->library = (void *)POO_FLOW_LIBRARY_OPEN(path);
  if (!api->library) return 0;
#define TEMPORAL_BIND(field, symbol_name) do { \
  void *symbol = (void *)POO_FLOW_LIBRARY_SYMBOL((poo_flow_library_handle)api->library, symbol_name); \
  if (!symbol || sizeof(api->field) != sizeof(symbol)) { \
    poo_flow_python_temporal_unbind_v1(api); return 0; \
  } \
  memcpy(&api->field, &symbol, sizeof(symbol)); \
} while (0)
  TEMPORAL_BIND(open, "poo_flow_temporal_open_v1");
  TEMPORAL_BIND(require_budget, "poo_flow_temporal_require_budget_v1");
  TEMPORAL_BIND(close, "poo_flow_temporal_close_v1");
  TEMPORAL_BIND(payload, "poo_flow_temporal_payload_v1");
  TEMPORAL_BIND(publish, "poo_flow_temporal_publish_selection_v1");
  TEMPORAL_BIND(observe, "poo_flow_temporal_observe_selection_v1");
#undef TEMPORAL_BIND
  return 1;
}
