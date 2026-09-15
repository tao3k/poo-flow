# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
#
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

set shell := ["bash", "-euo", "pipefail", "-c"]

devenv_exec := ".devenv/devenv-profile-exec"
bazel := devenv_exec + " bazelisk"
gerbil_compile := "//gerbil:compile"
gerbil_dev_compile := "//gerbil:dev_compile"
gerbil_capability_tests := "//t/qualification/gerbil-bazel:tests"
module_system_owner_tests := "//t/qualification/module-system:owner_map_tests"
runtime_c_library := "//bindings/runtime-c:runtime_c_library"
runtime_c_tests := "//bindings/runtime-c:runtime_c_tests"
runtime_c_sanitizer_tests := "//bindings/runtime-c:runtime_c_sanitizer_tests"
runtime_c_leak_test := "//bindings/runtime-c:runtime_c_leak_test"
bundle_v1_library := "//bindings/runtime-c/bundle-v1:bundle_v1"
bundle_v1_tests := "//bindings/runtime-c/bundle-v1:bundle_v1_tests"
gerbil_toolchain_type := "@gerbil_bazel//gerbil:toolchain_type"
python_runtime_dir := "packages/python-runtime"
python_runtime_test_environment := "//gerbil:python_runtime_test_environment"
composition_lifecycle_tests := "tests/unit/test_composition_lifecycle_arrival.py tests/unit/test_composition_lifecycle_benchmark.py tests/unit/test_composition_lifecycle_workload.py"
cedar_workspace := "bindings/cedar-gerbil/Cargo.toml"
contribution_test_path := justfile_directory() + "/.gerbil/contributions/lambda-episteme/module-test"
contribution_test_library_path := contribution_test_path + "/lib"
contribution_atomic_test_path := justfile_directory() + "/.gerbil/contributions/lambda-episteme/atomic-test"
contribution_atomic_test_library_path := contribution_atomic_test_path + "/lib"
poo_flow_library_path := justfile_directory() + "/.gerbil/lib"

# Show the maintained developer entrypoints.
[group('discovery')]
default:
    @just --list

# Query the complete Bazel target graph without executing actions.
[group('discovery')]
query:
    {{ bazel }} query //...

# Resolve and build the canonical Scheme project through build.ss.
[group('build')]
build:
    gerbil build

# Build one top-level contribution inside POO Flow's package environment.
[group('build')]
build-contribute contribution="lambda-episteme":
    test "{{ contribution }}" = "lambda-episteme"
    echo "[poo-flow-contribute] phase=target-selected owner={{ contribution }} lane=production budget=45s"
    GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ poo_flow_library_path }}" exec timeout --foreground --signal=TERM --kill-after=3s 45s gxi ./build-contribute.ss </dev/null

# Compile contribution-only fixtures without adding them to production closure.
[group('test')]
build-contribute-tests contribution="lambda-episteme" module="sdlc" test_file="":
    #!/usr/bin/env bash
    set -euo pipefail
    test "{{ contribution }}" = "lambda-episteme"
    echo "[poo-flow-contribute] phase=target-selected owner={{ contribution }} lane=test module={{ module }} test={{ test_file }}"
    if [[ -n "{{ test_file }}" ]]; then test_image="{{ contribution_atomic_test_path }}"; test_library="{{ contribution_atomic_test_library_path }}"; else test_image="{{ contribution_test_path }}"; test_library="{{ contribution_test_library_path }}"; fi
    mkdir -p "$test_image"
    if [[ -n "{{ test_file }}" ]]; then phase_budget=20s; elif [[ "{{ module }}" = "all" ]]; then phase_budget=45s; else phase_budget=30s; fi
    POO_FLOW_CONTRIBUTE_TEST_MODULE="{{ module }}" POO_FLOW_CONTRIBUTE_TEST_FILE="{{ test_file }}" GERBIL_PATH="$test_image" GERBIL_LOADPATH="$test_library:{{ poo_flow_library_path }}" timeout --foreground --signal=TERM --kill-after=3s "$phase_budget" gxi ./build-contribute-tests.ss

# Execute only one contribution-owned t/<module-name>/ tree from the shared
# contribution test image.  Build and test remain separate native phases.
[group('test')]
test-contribute contribution="lambda-episteme" module="sdlc":
    test "{{ contribution }}" = "lambda-episteme"
    echo "[poo-flow-contribute] phase=test-start owner={{ contribution }} module={{ module }} scope=module"
    GERBIL_PATH="{{ contribution_test_path }}" GERBIL_LOADPATH="{{ contribution_test_library_path }}:{{ poo_flow_library_path }}" timeout --foreground --signal=TERM --kill-after=5s 60s gxtest -v "{{ contribution }}/t/{{ module }}/..."

# Execute one exact test file within one contribution module.
[group('test')]
observe-contribute-atomic contribution="lambda-episteme" module="sdlc" test_file="unit/nasa-certification-test.ss":
    test "{{ contribution }}" = "lambda-episteme"
    test -f "{{ contribution }}/t/{{ module }}/{{ test_file }}"
    echo "[poo-flow-observability] phase=source-start owner={{ contribution }} module={{ module }} test={{ test_file }}"
    # Source scan and dynamic import are separately reported; 15s covers the
    # measured 5.5s SDLC import while retaining a bounded atomic preflight.
    GERBIL_PATH="{{ contribution_atomic_test_path }}" GERBIL_LOADPATH="{{ contribution_atomic_test_library_path }}:{{ poo_flow_library_path }}" timeout --foreground --signal=TERM --kill-after=2s 15s gxi ./observe-contribute-test.ss "{{ contribution }}" "{{ module }}" "{{ test_file }}"

# Run the opt-in deep heap diagnostic when the ordinary atomic preflight ends
# at import-start. The native POO monitor terminates runaway lazy-slot growth.
[group('test')]
observe-contribute-import-memory contribution="lambda-episteme" module="sdlc" test_file="unit/nasa-certification-test.ss":
    test "{{ contribution }}" = "lambda-episteme"
    test -f "{{ contribution }}/t/{{ module }}/{{ test_file }}"
    echo "[poo-flow-observability] phase=import-observer-start owner={{ contribution }} module={{ module }} test={{ test_file }} budget=15s"
    GERBIL_PATH="{{ contribution_atomic_test_path }}" GERBIL_LOADPATH="{{ contribution_atomic_test_library_path }}:{{ poo_flow_library_path }}" timeout --foreground --signal=TERM --kill-after=2s 15s gxi ./observe-contribute-import.ss "{{ contribution }}" "{{ module }}" "{{ test_file }}"

# Execute one exact test file after its reader-only POO authoring preflight.
[group('test')]
test-contribute-atomic contribution="lambda-episteme" module="sdlc" test_file="unit/nasa-certification-test.ss":
    test "{{ contribution }}" = "lambda-episteme"
    test -f "{{ contribution }}/t/{{ module }}/{{ test_file }}"
    just observe-contribute-atomic "{{ contribution }}" "{{ module }}" "{{ test_file }}"
    echo "[poo-flow-contribute] phase=test-start owner={{ contribution }} module={{ module }} scope=file test={{ test_file }}"
    GERBIL_PATH="{{ contribution_atomic_test_path }}" GERBIL_LOADPATH="{{ contribution_atomic_test_library_path }}:{{ poo_flow_library_path }}" timeout --foreground --signal=TERM --kill-after=3s 20s gxtest -v "{{ contribution }}/t/{{ module }}/{{ test_file }}"
    echo "[poo-flow-contribute] phase=test-complete owner={{ contribution }} module={{ module }} scope=file test={{ test_file }}"

# Compile one module test root and then execute that module.
[group('check')]
check-contribute contribution="lambda-episteme" module="sdlc":
    just build-contribute-tests "{{ contribution }}" "{{ module }}"
    just test-contribute "{{ contribution }}" "{{ module }}"

# Compile one module test root and then execute one exact test file.
[group('check')]
check-contribute-atomic contribution="lambda-episteme" module="sdlc" test_file="unit/nasa-certification-test.ss":
    just build-contribute-tests "{{ contribution }}" "{{ module }}" "{{ test_file }}"
    just test-contribute-atomic "{{ contribution }}" "{{ module }}" "{{ test_file }}"

# Install the dependency revisions declared by gerbil.pkg.
[group('dependency')]
deps:
    gerbil deps --install

# Clean only native Gerbil package build artifacts.
[group('build')]
clean:
    gerbil clean

# Run the cold native lifecycle in order; stop on the first failure.
[group('check')]
rebuild:
    just clean
    just deps
    just build
    just test

# Incrementally build the canonical Scheme project through a persistent Bazel development root.
[group('build')]
build-dev:
    {{ bazel }} run {{ gerbil_dev_compile }}

# Build the runtime-C library target.
[group('build')]
build-runtime-c:
    {{ bazel }} build {{ runtime_c_library }}

# Build the Bundle v1 C library target.
[group('build')]
build-bundle-v1:
    {{ bazel }} build {{ bundle_v1_library }}

# Build the single Lean-linked Cedar Runtime Host at an explicit output path (Nix: $out/bin/cedarRuntimeHost).
[group('build')]
build-cedar-runtime-host out:
    {{ devenv_exec }} tools/ci/build-cedar-runtime-host "{{ out }}"

# Show the registered Gerbil implementation selected for the host platform.
[group('build')]
toolchain:
    {{ bazel }} build --toolchain_resolution_debug={{ gerbil_toolchain_type }} {{ gerbil_compile }}

# Run the package's single native Scheme test entrypoint.
[group('test')]
test:
    gerbil env ./unit-tests.ss

# Run wall-clock performance scenarios through the native ASP scheduler,
# outside the ordinary unit-test batches.
[group('test')]
test-performance:
    gerbil env ./performance-tests.ss

# Run only hermetic Bazel qualifications; `just test` owns Scheme unit tests.
[group('test')]
test-bazel:
    just test-gerbil-capability
    just test-module-system-ownership
    just test-external-bazel-module

# Validate the shared Gerbil toolchain and dependency-install capabilities.
[group('test')]
test-gerbil-capability:
    {{ bazel }} test --test_output=errors {{ gerbil_capability_tests }}

# Validate POO Flow as a clean external Bzlmod dependency.
[group('test')]
test-external-bazel-module:
    {{ devenv_exec }} python3 -m unittest discover -s t/qualification/external_bazel -p 'external_module_test.py' -v
    {{ devenv_exec }} python3 t/qualification/external_bazel/external_module.py

# Validate the single source-owned RFC45 module-system ownership map.
[group('test')]
test-module-system-ownership:
    {{ bazel }} test --test_output=errors {{ module_system_owner_tests }}

# Run the ordinary runtime-C acceptance suite.
[group('test')]
test-runtime-c:
    {{ bazel }} test --test_output=errors {{ runtime_c_tests }}

# Run the Bundle v1 acceptance suite.
[group('test')]
test-bundle-v1:
    {{ bazel }} test --test_output=errors {{ bundle_v1_tests }}

# Qualify an explicitly supplied Cedar Runtime Host artifact.
[group('test')]
test-cedar-runtime-host host:
    POO_FLOW_CEDAR_RUNTIME_HOST="{{ host }}" {{ devenv_exec }} cargo test --locked --manifest-path {{ cedar_workspace }} -p poo-flow-cedar-authority --features native-runtime-host-qualification --test runtime_host --test authorization

# Run the focused composition-lifecycle Python gate.
[group('test')]
test-python-composition-lifecycle:
    cd {{ python_runtime_dir }} && uv run --group dev pytest -q {{ composition_lifecycle_tests }}

# Run the complete Python suite in the Bazel-declared Gerbil project environment.
[group('test')]
test-python:
    {{ bazel }} run {{ python_runtime_test_environment }} -- uv run --group dev pytest -q

# Run the explicit runtime-C sanitizer gate.
[group('test')]
test-runtime-c-sanitizers:
    {{ bazel }} test --test_output=errors {{ runtime_c_sanitizer_tests }}

# Run the explicit runtime-C leak gate.
[group('test')]
test-runtime-c-leaks:
    {{ bazel }} test --test_output=errors {{ runtime_c_leak_test }}

# Run the native Scheme build and ordinary-test convergence gate.
[group('check')]
check: build test

# Validate the repository and published-package license contract.
[group('check')]
check-license-contract:
    python3 scripts/check_license_contract.py
    python3 -m unittest discover -s scripts/tests -p 'test_*.py'

# Verify that dependency resolution is represented by the tracked lock.
[group('dependency')]
lock-check:
    {{ bazel }} mod deps --lockfile_mode=error

# Refresh this host's native Bazel lock; CI merges Linux and Darwin evaluations.
[group('dependency')]
bazel-update:
    {{ bazel }} mod deps --lockfile_mode=update

# Normalize MODULE.bazel declarations while explicitly updating the lock.
[group('dependency')]
mod-tidy:
    {{ bazel }} mod tidy --lockfile_mode=update
