/* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
 * SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later */
#ifndef POO_FLOW_SEMANTIC_V1_H
#define POO_FLOW_SEMANTIC_V1_H
#include <stdint.h>
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef struct { int32_t status; uint8_t *data; size_t length; } poo_flow_semantic_result;
/* One process-global, thread-affine AOT instance. Closing is terminal.
 * No Gambit objects cross this ABI. Input is borrowed for the call. Result is
 * initialized empty by the caller and released only with result_release.
 * Operation is a NUL-terminated UTF-8 string of at most 128 bytes. The caller
 * provides valid readable pointers for their declared sizes. */
int32_t poo_flow_semantic_v1_open(void);
int32_t poo_flow_semantic_v1_call(const char *operation, const uint8_t *input,
                                size_t length, poo_flow_semantic_result *result);
int32_t poo_flow_semantic_v1_close(void);
void poo_flow_semantic_v1_result_release(poo_flow_semantic_result *result);
/* 0 success, 1 closed/unavailable, 2 wrong thread, 3 invalid transport,
 * 4 semantic input/operation rejection, 5 allocation failure. */
#ifdef __cplusplus
}
#endif
#endif
