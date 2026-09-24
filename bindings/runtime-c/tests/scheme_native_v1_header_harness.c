// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
//
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

#include <stddef.h>

#include "poo_flow/scheme_native_v1.h"

_Static_assert(POO_FLOW_SCHEME_NATIVE_ABI_VERSION == 1u,
               "Scheme-native ABI version drift");
_Static_assert(offsetof(poo_flow_scheme_result_v1, status) == 0u,
               "result status must be the leading field");
_Static_assert(offsetof(poo_flow_scheme_result_v1, payload) >
                   offsetof(poo_flow_scheme_result_v1, status),
               "result payload layout drift");
_Static_assert(offsetof(poo_flow_scheme_result_v1, length) >
                   offsetof(poo_flow_scheme_result_v1, payload),
               "result length layout drift");

int main(void) { return 0; }
