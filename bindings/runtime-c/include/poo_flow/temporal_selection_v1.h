// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
#ifndef POO_FLOW_TEMPORAL_SELECTION_V1_H
#define POO_FLOW_TEMPORAL_SELECTION_V1_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

/* The trusted host verifies separate authorizer and evaluator signatures.
 * Roles 1/2 verify exact request bytes; role 3 verifies/signs runtime receipts.
 * A verifier must authenticate a configured issuer, never accept a caller's
 * boolean. An evaluator attestation is not an independently checked theorem.
 */
typedef int (*poo_flow_temporal_verify_v1)(void *, uint32_t,
    const uint8_t *, size_t, const uint8_t[32]);
typedef int (*poo_flow_temporal_sign_v1)(void *, const uint8_t *, size_t, uint8_t[32]);
typedef struct poo_flow_temporal_store_v1 poo_flow_temporal_store_v1;
typedef struct {
  const char *subject, *scope, *predecessor, *revision, *proof, *policy;
  const char *generation, *cut, *projection, *journal, *model, *nonce, *operation;
  uint64_t expected_version, expires_unix;
  uint8_t authorization_signature[32], evaluation_signature[32];
} poo_flow_temporal_publish_v1;
enum {
  POO_FLOW_TEMPORAL_COMMITTED = 0, POO_FLOW_TEMPORAL_CONFLICT = 1,
  POO_FLOW_TEMPORAL_DENIED = 2, POO_FLOW_TEMPORAL_EXPIRED = 3,
  POO_FLOW_TEMPORAL_CORRUPT = 4, POO_FLOW_TEMPORAL_INVALID = 5,
  POO_FLOW_TEMPORAL_STORAGE_ERROR = 6, POO_FLOW_TEMPORAL_REPLAYED = 7,
  POO_FLOW_TEMPORAL_ABSENT = 8, POO_FLOW_TEMPORAL_BUDGET_EXHAUSTED = 9
};
typedef struct {
  uint32_t status;
  uint64_t version;
  uint8_t effect_signature[32];
} poo_flow_temporal_effect_v1;

int poo_flow_temporal_open_v1(const char *, poo_flow_temporal_verify_v1,
    poo_flow_temporal_sign_v1, void *, poo_flow_temporal_store_v1 **);
/* Trusted host fixes a required coordinator budget before exposing the store. */
int poo_flow_temporal_require_budget_v1(poo_flow_temporal_store_v1 *, const char *);
/* Host must serialize close against all in-flight handle operations. */
void poo_flow_temporal_close_v1(poo_flow_temporal_store_v1 *);
/* Serialize the exact projection signed by both authorities. A NULL buffer
 * queries its byte length; no truncation is permitted. */
int poo_flow_temporal_payload_v1(const poo_flow_temporal_publish_v1 *,
    uint8_t *, size_t, size_t *);
/* SQLite BEGIN IMMEDIATE + FULL synchronous commit couples the selected
 * pointer with a durable effect. Cross-process competition uses SQLite's lock.
 * Time is read inside the runtime; a caller cannot supply a favorable now. */
uint32_t poo_flow_temporal_publish_selection_v1(poo_flow_temporal_store_v1 *,
    const poo_flow_temporal_publish_v1 *, poo_flow_temporal_effect_v1 *);
/* Authenticated pointer snapshot. Caller owns the buffer (8192 bytes suffices
 * for every admitted request). The signature covers pointer version + payload.
 * Absence is a local store result, not a signed global nonexistence theorem. */
uint32_t poo_flow_temporal_observe_selection_v1(poo_flow_temporal_store_v1 *,
    const char *, const char *, uint8_t *, size_t, size_t *, poo_flow_temporal_effect_v1 *);
#ifdef __cplusplus
}
#endif
#endif
