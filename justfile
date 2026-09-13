set shell := ["bash", "-euo", "pipefail", "-c"]

bazel := "bazelisk"
devenv_exec := ".devenv/devenv-profile-exec"
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

# Validate the shared Gerbil toolchain and dependency-install capabilities.
[group('test')]
test-gerbil-capability:
    {{ bazel }} test --test_output=errors {{ gerbil_capability_tests }}

# Validate POO Flow as a clean external Bzlmod dependency.
[group('test')]
test-external-bazel-module:
    python3 -m unittest discover -s t/qualification/external_bazel -p 'external_module_test.py' -v
    python3 t/qualification/external_bazel/external_module.py

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

# Verify that dependency resolution is represented by the tracked lock.
[group('dependency')]
lock-check:
    {{ bazel }} mod deps --lockfile_mode=error

# Refresh the host-platform module-extension evaluation with Bazel's native
# lock update mode. Cross-platform CI merges Linux and Darwin evaluations.
[group('dependency')]
bazel-update:
    {{ bazel }} mod deps --lockfile_mode=update

# Normalize MODULE.bazel declarations while explicitly updating the lock.
[group('dependency')]
mod-tidy:
    {{ bazel }} mod tidy --lockfile_mode=update
