set shell := ["bash", "-euo", "pipefail", "-c"]

bazel := env_var_or_default("BAZEL", "bazel")
scheme_compile := "//scheme:compile"
scheme_tests := "//scheme:tests"
scheme_performance_tests := "//scheme:performance_tests"
runtime_c_library := "//bindings/runtime-c:runtime_c_library"
runtime_c_tests := "//bindings/runtime-c:runtime_c_tests"
runtime_c_sanitizer_tests := "//bindings/runtime-c:runtime_c_sanitizer_tests"
runtime_c_leak_test := "//bindings/runtime-c:runtime_c_leak_test"
bundle_v1_library := "//bindings/runtime-c/bundle-v1:bundle_v1"
bundle_v1_tests := "//bindings/runtime-c/bundle-v1:bundle_v1_tests"
gerbil_toolchain_type := "//tools/bazel:gerbil_toolchain_type"

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
    {{ bazel }} build {{ scheme_compile }}

# Build the runtime-C library target.
[group('build')]
build-runtime-c:
    {{ bazel }} build {{ runtime_c_library }}

# Build the Bundle v1 C library target.
[group('build')]
build-bundle-v1:
    {{ bazel }} build {{ bundle_v1_library }}

# Show the registered Gerbil implementation selected for the host platform.
[group('build')]
toolchain:
    {{ bazel }} build --toolchain_resolution_debug={{ gerbil_toolchain_type }} {{ scheme_compile }}

# Run the ordinary Scheme acceptance suite.
[group('test')]
test:
    {{ bazel }} test --test_output=errors {{ scheme_tests }}

# Run the ordinary runtime-C acceptance suite.
[group('test')]
test-runtime-c:
    {{ bazel }} test --test_output=errors {{ runtime_c_tests }}

# Run the Bundle v1 acceptance suite.
[group('test')]
test-bundle-v1:
    {{ bazel }} test --test_output=errors {{ bundle_v1_tests }}

# Run the explicit runtime-C sanitizer gate.
[group('test')]
test-runtime-c-sanitizers:
    {{ bazel }} test --test_output=errors {{ runtime_c_sanitizer_tests }}

# Run the explicit runtime-C leak gate.
[group('test')]
test-runtime-c-leaks:
    {{ bazel }} test --test_output=errors {{ runtime_c_leak_test }}

# Run the explicit performance gate, which is intentionally outside test.
[group('test')]
test-performance:
    {{ bazel }} test --test_output=errors {{ scheme_performance_tests }}

# Run the maintained query, build, and ordinary-test convergence gate.
[group('check')]
check: query build test
