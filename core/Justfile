# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

set shell := ["bash", "-euo", "pipefail", "-c"]

# V19 std/make defaults to zero workers unless this is explicitly provided.
export GERBIL_BUILD_CORES := env_var_or_default("GERBIL_BUILD_CORES", `getconf _NPROCESSORS_ONLN`)

gerbil_test_max_heap := env_var_or_default("GERBIL_TEST_MAX_HEAP", "1G")
gerbil_test_debug := env_var_or_default("GERBIL_TEST_DEBUG", "q")
gerbil_test_runtime_options := "-:max-heap=" + gerbil_test_max_heap + ",debug=" + gerbil_test_debug

default:
    @just --list

build:
    GERBIL_BUILD_VERBOSE=1 env -u SDKROOT gerbil build

test-file path:
    #!/usr/bin/env bash
    set -euo pipefail
    test -f "{{ path }}"
    log="$(mktemp)"
    trap 'rm -f "$log"' EXIT
    env -u SDKROOT timeout --foreground --signal=TERM --kill-after=5s 120s gerbil {{ gerbil_test_runtime_options }} env gxtest "{{ path }}" 2>&1 | tee "$log"
    if grep -E 'ERROR (CHECK|CASE|HARNESS)|Heap overflow|Stack overflow' "$log" >/dev/null; then exit 1; fi
    grep -F 'MODULE-OK {{ path }}' "$log" >/dev/null
    grep -F 'HARNESS-OK' "$log" >/dev/null
    grep -x 'OK' "$log" >/dev/null

# One native harness amortizes Gerbil startup and module loading across files.
test:
    #!/usr/bin/env bash
    set -euo pipefail
    files=(t/core-test.ss t/poo-clos-*-test.ss t/extension-graph-*-test.ss t/contribution-*-test.ss t/module-schema-*-test.ss t/module-option-objects-test.ss t/module-interface-test.ss t/module-graph-test.ss t/module-source-test.ss t/module-load-path-test.ss t/module-context-test.ss t/module-loader-backend-test.ss t/module-catalog-test.ss t/module-diagnostics-test.ss t/semantic-module-test.ss t/profile-composition-test.ss t/observability-*-test.ss t/slot-presentation-test.ss)
    log="$(mktemp)"
    trap 'rm -f "$log"' EXIT
    env -u SDKROOT timeout --foreground --signal=TERM --kill-after=5s 120s gerbil {{ gerbil_test_runtime_options }} env gxtest "${files[@]}" 2>&1 | tee "$log"
    if grep -E 'ERROR (CHECK|CASE|HARNESS)|Heap overflow|Stack overflow' "$log" >/dev/null; then exit 1; fi
    for file in "${files[@]}"; do grep -F "MODULE-OK $file" "$log" >/dev/null; done
    grep -F 'HARNESS-OK' "$log" >/dev/null
    grep -x 'OK' "$log" >/dev/null

# Opt-in wall/user/system timing while preserving the same bounded test path.
test-profile:
    time just test

# Bounded, opt-in CLOS dispatch profiling outside the unit-test harness.
benchmark-dispatch:
    env -u SDKROOT timeout --foreground --signal=TERM --kill-after=5s 120s gerbil {{ gerbil_test_runtime_options }} env gxi t/poo-clos-dispatch-benchmark.ss

benchmark-slot:
    env -u SDKROOT timeout --foreground --signal=TERM --kill-after=5s 120s gerbil {{ gerbil_test_runtime_options }} env gxi t/poo-clos-slot-benchmark.ss

benchmark-effective-slots:
    env -u SDKROOT timeout --foreground --signal=TERM --kill-after=5s 120s gerbil {{ gerbil_test_runtime_options }} env gxi t/poo-clos-effective-slot-benchmark.ss

# Dependent class redefinition includes native C4 preflight and live commit.
benchmark-redefinition:
    env -u SDKROOT timeout --foreground --signal=TERM --kill-after=5s 120s gerbil {{ gerbil_test_runtime_options }} env gxi t/poo-clos-redefinition-benchmark.ss
