# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
#
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

set shell := ["bash", "-euo", "pipefail", "-c"]

export GERBIL_BUILD_CORES := env_var_or_default("GERBIL_BUILD_CORES", "12")

# Test processes are bounded before any Scheme profile module can load. The
# ASP POO Testing profile remains the policy and receipt owner inside the
# process; this launch option is the fail-closed pre-import boundary.
gerbil_test_max_heap := env_var_or_default("GERBIL_TEST_MAX_HEAP", "1G")
gerbil_test_debug := env_var_or_default("GERBIL_TEST_DEBUG", "q")
gerbil_test_runtime_options := "-:max-heap=" + gerbil_test_max_heap + ",debug=" + gerbil_test_debug

bazel := env_var_or_default("BAZEL", "bazelisk")
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
aitia_native_library := justfile_directory() + "/.gerbil/native/libpoo_flow_aitia.dylib"
aitia_python_dir := contribution_source_root + "/lambda-aitia/bindings/python"
python_runtime_test_environment := "//gerbil:python_runtime_test_environment"
composition_lifecycle_tests := "tests/unit/test_composition_lifecycle_arrival.py tests/unit/test_composition_lifecycle_benchmark.py tests/unit/test_composition_lifecycle_workload.py"
cedar_workspace := "bindings/cedar-gerbil/Cargo.toml"
contribution_test_path := justfile_directory() + "/.gerbil/contributions/lambda-episteme/module-test"
contribution_test_library_path := contribution_test_path + "/lib"
contribution_source_root := justfile_directory() + "/packages"
gerbil_homebrew_runtime := `gerbil_executable="$(command -v gerbil 2>/dev/null || true)"; if [ -n "$gerbil_executable" ] && realpath "$gerbil_executable" | grep -F '/opt/homebrew/Cellar/' >/dev/null; then printf true; else printf false; fi`
homebrew_openssl_prefix := `if command -v brew >/dev/null 2>&1; then brew --prefix openssl@3 2>/dev/null || true; fi`
darwin_openssl_prefix := env_var_or_default("OPENSSL_PREFIX", homebrew_openssl_prefix)
# Preserve the configured/user-selected compiler. For Homebrew Gerbil on
# Darwin, keep Nix SDK/header/library variables out of child builds and make
# GCC's collect2 resolve the Apple system linker instead of a Nix-provided ld.
# Restore only the explicit Homebrew OpenSSL include/library roots required by
# Gerbil's crypto modules; never inherit ambient CPATH or LIBRARY_PATH values.
# A Nix Gerbil runtime retains its own compiler and linker environment.
gerbil_darwin_env := if os() == "macos" { if gerbil_homebrew_runtime == "true" { "env -u SDKROOT -u DEVELOPER_DIR -u CPATH -u LIBRARY_PATH -u C_INCLUDE_PATH -u CPLUS_INCLUDE_PATH -u MACOSX_DEPLOYMENT_TARGET -u DYLD_LIBRARY_PATH -u DYLD_FALLBACK_LIBRARY_PATH COMPILER_PATH=/usr/bin CPATH='" + darwin_openssl_prefix + "/include' LIBRARY_PATH='" + darwin_openssl_prefix + "/lib'" } else { "env" } } else { "env" }
poo_flow_gerbil_path := env_var_or_default("GERBIL_PATH", justfile_directory() + "/.gerbil")
poo_flow_library_path := env_var_or_default("GERBIL_LOADPATH", poo_flow_gerbil_path + "/lib")
gerbil_parser_dir := env_var_or_default("GERBIL_PARSER_DIR", justfile_directory() + "/../gerbil-parser")
gerbil_parser_path := poo_flow_gerbil_path
gerbil_parser_library_path := gerbil_parser_dir + ":" + contribution_source_root + "/lambda-episteme:" + justfile_directory() + ":" + poo_flow_library_path
fhir_validator_jar := env_var_or_default("FHIR_VALIDATOR_JAR", "")
governance_tla := justfile_directory() + "/packages/proof/tla/GovernanceCore.tla"
governance_tlc_config := justfile_directory() + "/packages/proof/tla/GovernanceCore.cfg"
governance_tlc_receipt := justfile_directory() + "/.ci/governance/tlc-receipt.ss"
semantic_query_tla := justfile_directory() + "/packages/proof/tla/NativeSemanticQuery.tla"
semantic_query_tlc_config := justfile_directory() + "/packages/proof/tla/NativeSemanticQuery.cfg"
semantic_query_tlc_receipt := justfile_directory() + "/.ci/native-semantic-query/tlc-receipt.ss"
healthcare_temporal_tla := justfile_directory() + "/packages/proof/tla/HealthcarePrescriptionCausality.tla"
healthcare_temporal_tlc_config := justfile_directory() + "/packages/proof/tla/HealthcarePrescriptionCausality.cfg"
healthcare_migration_tla := justfile_directory() + "/packages/proof/tla/HealthcareStandardMigration.tla"
healthcare_migration_tlc_config := justfile_directory() + "/packages/proof/tla/HealthcareStandardMigration.cfg"
healthcare_migration_tlc_receipt := justfile_directory() + "/.ci/healthcare-standard-migration/tlc-receipt.ss"
healthcare_temporal_tlc_receipt := justfile_directory() + "/.ci/healthcare-temporal/tlc-receipt.ss"
lean_proof_dir := justfile_directory() + "/packages/proof/lean"

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
    GERBIL_BUILD_VERBOSE=1 {{ gerbil_darwin_env }} gerbil build

# Build one packaged contribution inside POO Flow's package environment.
[group('build')]
build-contribute contribution="lambda-episteme":
    case "{{ contribution }}" in lambda-episteme|lambda-aitia) ;; *) echo "unsupported contribution: {{ contribution }}" >&2; exit 64 ;; esac
    cd "{{ contribution_source_root }}/{{ contribution }}" && GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ justfile_directory() }}:{{ poo_flow_library_path }}" exec {{ gerbil_darwin_env }} gerbil build </dev/null

# Clean one contribution through its native gxpkg package entry.
[group('build')]
clean-contribute contribution="lambda-episteme":
    case "{{ contribution }}" in lambda-episteme|lambda-aitia) ;; *) echo "unsupported contribution: {{ contribution }}" >&2; exit 64 ;; esac
    cd "{{ contribution_source_root }}/{{ contribution }}" && GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} gerbil clean

# Execute one contribution-owned t/<module-name>/ tree directly with gxtest.
[group('test')]
test-contribute contribution="lambda-aitia" module="sdlc":
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ contribution }}" in lambda-episteme|lambda-aitia) ;; *) echo "unsupported contribution: {{ contribution }}" >&2; exit 64 ;; esac
    test_root="$(mktemp -d "${TMPDIR:-/tmp}/poo-flow-{{ contribution }}-module-test.XXXXXX")"
    trap 'find "$test_root" -depth -delete' EXIT
    if test "{{ contribution }}" = "lambda-aitia"; then
        cd "{{ contribution_source_root }}/lambda-aitia"
        runner="./run-test.ss"
        test_directory="t/{{ module }}"
    else
        runner="./run-contribute-test.ss"
        test_directory="packages/{{ contribution }}/t/{{ module }}"
    fi
    test -d "$test_directory"
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="$test_root" GERBIL_LOADPATH="{{ contribution_source_root }}/{{ contribution }}:{{ justfile_directory() }}:$test_root/lib:{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=5s 120s gxi {{ gerbil_test_runtime_options }} "$runner" "$test_directory"

# Replay a previously compiled exact test under the opt-in native heap monitor.
[group('test')]
observe-contribute-import-memory contribution="lambda-aitia" module="sdlc" test_file="unit/nasa-certification-test.ss":
    case "{{ contribution }}" in lambda-episteme|lambda-aitia) ;; *) echo "unsupported contribution: {{ contribution }}" >&2; exit 64 ;; esac
    test -f "packages/{{ contribution }}/t/{{ module }}/{{ test_file }}"
    echo "[poo-flow-observability] phase=import-observer-start owner={{ contribution }} module={{ module }} test={{ test_file }} budget=15s"
    GERBIL_PATH="{{ justfile_directory() }}/.gerbil/contributions/{{ contribution }}/atomic-test" GERBIL_LOADPATH="{{ justfile_directory() }}/.gerbil/contributions/{{ contribution }}/atomic-test/lib:{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=2s 15s gxi {{ gerbil_test_runtime_options }} ./observe-contribute-import.ss "{{ contribution }}" "{{ module }}" "{{ test_file }}"

# Execute one exact test file. Source admission belongs to the native gxtest
# lifecycle and is enabled declaratively by its POO Testing Profile.
[group('test')]
test-contribute-atomic contribution="lambda-aitia" module="sdlc" test_file="unit/nasa-certification-test.ss":
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ contribution }}" in lambda-episteme|lambda-aitia) ;; *) echo "unsupported contribution: {{ contribution }}" >&2; exit 64 ;; esac
    test_root="$(mktemp -d "${TMPDIR:-/tmp}/poo-flow-{{ contribution }}-atomic-test.XXXXXX")"
    trap 'find "$test_root" -depth -delete' EXIT
    if test "{{ contribution }}" = "lambda-aitia"; then
        cd "{{ contribution_source_root }}/lambda-aitia"
        runner="./run-test.ss"
        test_path="t/{{ module }}/{{ test_file }}"
    else
        runner="./run-contribute-test.ss"
        test_path="packages/{{ contribution }}/t/{{ module }}/{{ test_file }}"
    fi
    test -f "$test_path"
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="$test_root" GERBIL_LOADPATH="{{ contribution_source_root }}/{{ contribution }}:{{ justfile_directory() }}:$test_root/lib:{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=3s 60s gxi {{ gerbil_test_runtime_options }} "$runner" "$test_path"

# Execute the root-owned, mechanism-only cross-contribution qualification.
[group('test')]
test-standards-multi-industry-profile-composition:
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ contribution_source_root }}/lambda-aitia:{{ contribution_source_root }}/lambda-episteme:{{ justfile_directory() }}:{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=3s 60s gerbil {{ gerbil_test_runtime_options }} test -v 3 t/qualification/standards-multi-industry/profile-composition-test.ss

# Keep the 10k scale fixture out of the ordinary unit-test worker. This
# dedicated gate owns its benchmark budget and emits the full native receipt.
[group('test')]
test-standards-resolution-performance:
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=3s 90s gerbil {{ gerbil_test_runtime_options }} test -v 3 t/performance/standards-resolution-performance-test.ss

# Keep the 10k Sources Lock fixture outside the ordinary unit-test worker. The
# Scenario measures canonical construction separately from indexed lookup.
[group('test')]
test-sources-lock-performance:
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=3s 90s gerbil {{ gerbil_test_runtime_options }} test -v 3 t/performance/sources-lock-performance-test.ss

# Let gxtest qualify source first, then build the admitted contribution.
[group('check')]
check-contribute contribution="lambda-aitia" module="sdlc":
    just test-contribute "{{ contribution }}" "{{ module }}"
    just build-contribute "{{ contribution }}"

# Let gxtest qualify one source file first, then build the contribution.
[group('check')]
check-contribute-atomic contribution="lambda-aitia" module="sdlc" test_file="unit/nasa-certification-test.ss":
    just test-contribute-atomic "{{ contribution }}" "{{ module }}" "{{ test_file }}"
    just build-contribute "{{ contribution }}"

# Aitia owns the SDLC and GitOps composition and its integration closure.
[group('check')]
check-aitia-integration:
    just build-contribute lambda-aitia
    cd "{{ contribution_source_root }}/lambda-aitia" && GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} ./integration-build.ss compile
    just test-contribute lambda-aitia bindings
    just test-contribute lambda-aitia integration

# Build the self-contained Aitia Scheme-native library and its Aitia-owned consumers.
[group('check')]
check-aitia-native:
    just build-contribute lambda-aitia
    cd "{{ contribution_source_root }}/lambda-aitia" && GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} ./integration-build.ss compile
    mkdir -p "{{ justfile_directory() }}/.gerbil/native"
    cd "{{ contribution_source_root }}/lambda-aitia" && GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} python3 tools/build-native-library.py --output "{{ aitia_native_library }}"
    cc -std=c11 -Wall -Wextra -Werror -pedantic -I"{{ contribution_source_root }}/lambda-aitia/bindings/c/include" "{{ contribution_source_root }}/lambda-aitia/bindings/c/tests/aitia-header-harness.c" -o "{{ justfile_directory() }}/.gerbil/native/aitia_header_harness"
    "{{ justfile_directory() }}/.gerbil/native/aitia_header_harness"
    cc -std=c11 -Wall -Wextra -Werror -pedantic -I"{{ contribution_source_root }}/lambda-aitia/bindings/c/include" "{{ contribution_source_root }}/lambda-aitia/bindings/c/tests/aitia-dynamic-harness.c" -o "{{ justfile_directory() }}/.gerbil/native/aitia_dynamic_harness"
    "{{ justfile_directory() }}/.gerbil/native/aitia_dynamic_harness" "{{ aitia_native_library }}"
    just test-contribute lambda-aitia bindings
    cd "{{ aitia_python_dir }}" && {{ gerbil_darwin_env }} uv lock --check
    cd "{{ aitia_python_dir }}" && {{ gerbil_darwin_env }} uv run --locked --extra test python src/lambda_aitia/_native/_build.py
    cd "{{ aitia_python_dir }}" && LAMBDA_AITIA_NATIVE_LIBRARY="{{ aitia_native_library }}" {{ gerbil_darwin_env }} uv run --locked --extra test pytest
    cd "{{ contribution_source_root }}/lambda-aitia" && just build-python-wheel "{{ aitia_native_library }}"

# Install the dependency revisions declared by gerbil.pkg.
[group('dependency')]
deps:
    {{ gerbil_darwin_env }} gerbil deps --install

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
    tools/ci/build-cedar-runtime-host "{{ out }}"

# Show the registered Gerbil implementation selected for the host platform.
[group('build')]
toolchain:
    {{ bazel }} build --toolchain_resolution_debug={{ gerbil_toolchain_type }} {{ gerbil_compile }}

# Run the package's single native Scheme test entrypoint.
[group('test')]
test:
    @echo "[poo-flow-test-runtime] maxHeap={{ gerbil_test_max_heap }} debug={{ gerbil_test_debug }} scope=worker-process"
    gerbil {{ gerbil_test_runtime_options }} env ./unit-tests.ss

# Run wall-clock performance scenarios through the native ASP scheduler,
# outside the ordinary unit-test batches.
[group('test')]
test-performance:
    @echo "[poo-flow-test-runtime] maxHeap={{ gerbil_test_max_heap }} debug={{ gerbil_test_debug }} scope=worker-process"
    gerbil {{ gerbil_test_runtime_options }} env ./performance-tests.ss

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
    POO_FLOW_CEDAR_RUNTIME_HOST="{{ host }}" cargo test --locked --manifest-path {{ cedar_workspace }} -p poo-flow-cedar-authority --features native-runtime-host-qualification --test runtime_host --test authorization

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

# Admit gerbil-parser through POO Flow's current V19 dependency environment.
# The sibling remains the parser source owner; qualification imports only the
# demanded modules and never builds a second stale package cache.
_prepare-gerbil-parser:
    test -f "{{ gerbil_parser_dir }}/gerbil.pkg"
    GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ gerbil_parser_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=3s 60s gerbil interactive -e '(begin (import :gerbil-parser/src/runtime/artifact) (displayln "gerbil-parser-v19-ready"))'

# Qualify Case-owned GQL Sources from the parser owner's package environment.
# Lambda stays independent of gerbil-parser; parser acceptance is not execution.
[group('check')]
check-healthcare-gql: _prepare-gerbil-parser
    cd "{{ contribution_source_root }}/lambda-episteme" && GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ contribution_test_library_path }}:{{ gerbil_parser_library_path }}" gerbil interactive -e '(begin (import (only-in :std/misc/ports read-all-as-string) (only-in :poo-flow/src/modules/query/gql poo-flow-query->gql) (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/assurance healthcare-case-qualification-gql-paths) (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/reasoning HealthcareCaseProfileRelationsQuery HealthcareProfileImpactQuery HealthcarePrescriptionCausalTrajectoryQuery) (only-in :gerbil-parser/languages/gql/iso-39075-2024/parser +gql-syntax-contract+ parse-gql-iso-39075-2024) (only-in :gerbil-parser/src/runtime/artifact parse-artifact-ref parse-artifact-success? parse-artifact-valid? parse-artifact-roundtrip)) (let loop ((queries (list HealthcareCaseProfileRelationsQuery HealthcareProfileImpactQuery HealthcarePrescriptionCausalTrajectoryQuery)) (paths (healthcare-case-qualification-gql-paths)) (receipts (quote ()))) (if (null? paths) (begin (for-each displayln (reverse receipts)) (exit 0)) (let* ((query (car queries)) (path (car paths)) (expected (call-with-input-file path read-all-as-string)) (source (poo-flow-query->gql query)) (artifact (parse-gql-iso-39075-2024 source)) (accepted? (and (equal? source expected) (parse-artifact-success? artifact) (parse-artifact-valid? artifact) (equal? source (parse-artifact-roundtrip artifact))))) (unless accepted? (displayln (list (cons (quote source) path) (cons (quote exact-projection) (equal? source expected)) (cons (quote accepted) #f))) (exit 1)) (loop (cdr queries) (cdr paths) (cons (list (cons (quote source) path) (cons (quote parser) (quote gerbil-parser)) (cons (quote syntax-contract) +gql-syntax-contract+) (cons (quote source-content-id) (parse-artifact-ref artifact (quote sourceDigest))) (cons (quote grammar-content-id) (parse-artifact-ref artifact (quote grammarDigest))) (cons (quote exact-projection) #t) (cons (quote accepted) #t) (cons (quote roundtrip) #t)) receipts))))))'

# Parse the domain-owned legacy message through the parser source owner, then
# require exact equality with Lambda's retained projection.
[group('check')]
check-healthcare-hl7v2-migration: _prepare-gerbil-parser
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ contribution_source_root }}/lambda-episteme:{{ gerbil_parser_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=3s 60s gerbil {{ gerbil_test_runtime_options }} test -v 3 t/qualification/healthcare-hl7v2-migration/parser-receipt-test.ss

# Qualify parser-owned FHIRPath syntax without claiming evaluator semantics.
[group('check')]
check-healthcare-fhirpath-syntax: _prepare-gerbil-parser
    GERBIL_PARSER_DIR="{{ gerbil_parser_dir }}" GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ contribution_source_root }}/lambda-episteme:{{ gerbil_parser_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=3s 60s gerbil {{ gerbil_test_runtime_options }} test -v 3 t/qualification/healthcare-fhirpath-syntax/parser-receipt-test.ss

# Replay the pinned external Validator from its local JAR/package cache. The
# test verifies the binary digest and compares decoded OperationOutcome JSON.
[group('check')]
check-healthcare-fhir-reference-validator:
    test -n "{{ fhir_validator_jar }}" && test -f "{{ fhir_validator_jar }}"
    FHIR_VALIDATOR_JAR="{{ fhir_validator_jar }}" GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=5s 90s gerbil {{ gerbil_test_runtime_options }} test -v 3 t/qualification/healthcare-fhir-reference-validator/replay-test.ss

# Build one Lean module and exactly its import closure.  This is the normal
# proof-development gate; it never traverses the PooFlowProof aggregate root.
[group('check')]
check-lean-module module:
    [[ "{{ module }}" =~ ^PooFlowProof(\.[A-Za-z0-9_]+)+$ ]]
    cd "{{ lean_proof_dir }}" && lake build "{{ module }}"

# The Healthcare Case composes native POO Module proof libraries. GQL and TLA+
# remain independent gates owned by their parser/model-checker lifecycles.
[group('check')]
check-healthcare-lean:
    cd "{{ lean_proof_dir }}" && lake build PooFlowScenarioHealthcareProof
    GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ contribution_test_library_path }}:{{ poo_flow_library_path }}" gerbil interactive -e '(begin (import (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/assurance healthcare-publish-lean-refinement-receipt!)) (displayln (healthcare-publish-lean-refinement-receipt!)))'

[group('check')]
check-governance-lean:
    cd "{{ lean_proof_dir }}" && lake build PooFlowModuleGovernanceProof

# Prove the shared Object/Entity/Element/Relation/Query ownership laws without
# traversing the repository-wide Lean aggregate.
[group('check')]
check-native-semantic-query-lean:
    cd "{{ lean_proof_dir }}" && lake build PooFlowProof.PooC3.NativeSemanticQueryModel

# Parser admission and TLC remain separate evidence over the same model.
[group('check')]
check-native-semantic-query-tla: _prepare-gerbil-parser
    GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ gerbil_parser_library_path }}" POO_FLOW_NATIVE_SEMANTIC_QUERY_TLA="{{ semantic_query_tla }}" gerbil interactive -e '(begin (import (only-in :std/misc/ports read-all-as-string) :gerbil-parser/languages/tla-plus/v1/parser :gerbil-parser/src/runtime/artifact) (let* ((source (call-with-input-file (getenv "POO_FLOW_NATIVE_SEMANTIC_QUERY_TLA") read-all-as-string)) (artifact (parse-tla-plus-v1 source)) (accepted? (and (parse-artifact-success? artifact) (parse-artifact-valid? artifact))) (roundtrip? (and accepted? (equal? source (parse-artifact-roundtrip artifact))))) (displayln (list (cons (quote contract) +tla-plus-syntax-contract+) (cons (quote accepted) accepted?) (cons (quote roundtrip) roundtrip?) (cons (quote diagnostics) (parse-artifact-ref artifact (quote diagnostics))))) (exit (if (and accepted? roundtrip?) 0 1))))'

# Run TLC directly as an independent state-space gate.  Parser admission is a
# different part of the three-part TLA+ closure and cannot substitute for this.
[group('check')]
check-native-semantic-query-tlc:
    cd "$(dirname "{{ semantic_query_tla }}")" && PATH="{{ justfile_directory() }}/.devenv/profile/bin:$PATH" tlc -config "{{ semantic_query_tlc_config }}" "{{ semantic_query_tla }}"

[group('check')]
check-native-semantic-query-model: check-native-semantic-query-lean check-native-semantic-query-tla
    mkdir -p "$(dirname "{{ semantic_query_tlc_receipt }}")"
    PATH="{{ justfile_directory() }}/.devenv/profile/bin:$PATH" GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ gerbil_parser_library_path }}" POO_FLOW_NATIVE_SEMANTIC_QUERY_TLA="{{ semantic_query_tla }}" POO_FLOW_NATIVE_SEMANTIC_QUERY_TLC_CONFIG="{{ semantic_query_tlc_config }}" POO_FLOW_NATIVE_SEMANTIC_QUERY_TLC_RECEIPT="{{ semantic_query_tlc_receipt }}" gerbil interactive -e '(begin (import (only-in :gerbil-parser/languages/tla-plus/v1/qualification qualify-tla-plus-model tla-plus-model-receipt-admitted tla-plus-model-receipt-output tla-plus-model-receipt->alist)) (let* ((receipt (qualify-tla-plus-model (getenv "POO_FLOW_NATIVE_SEMANTIC_QUERY_TLA") (getenv "POO_FLOW_NATIVE_SEMANTIC_QUERY_TLC_CONFIG") workers: 1)) (datum (tla-plus-model-receipt->alist receipt))) (display (tla-plus-model-receipt-output receipt)) (call-with-output-file (getenv "POO_FLOW_NATIVE_SEMANTIC_QUERY_TLC_RECEIPT") (lambda (port) (write datum port) (newline port))) (write datum) (newline) (exit (if (tla-plus-model-receipt-admitted receipt) 0 1))))'

# Full aggregation is an explicit integration qualification, never the default
# local or pull-request proof gate.
[group('check')]
check-lean-all:
    cd "{{ lean_proof_dir }}" && lake build PooFlowProof

# Preserve the focused syntax-only gate for parser development.
[group('check')]
check-governance-tla: _prepare-gerbil-parser
    GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ gerbil_parser_library_path }}" POO_FLOW_GOVERNANCE_TLA="{{ governance_tla }}" gerbil interactive -e '(begin (import (only-in :std/misc/ports read-all-as-string) :gerbil-parser/languages/tla-plus/v1/parser :gerbil-parser/src/runtime/artifact) (let* ((source (call-with-input-file (getenv "POO_FLOW_GOVERNANCE_TLA") read-all-as-string)) (artifact (parse-tla-plus-v1 source)) (accepted? (and (parse-artifact-success? artifact) (parse-artifact-valid? artifact))) (roundtrip? (and accepted? (equal? source (parse-artifact-roundtrip artifact))))) (displayln (list (cons (quote contract) +tla-plus-syntax-contract+) (cons (quote accepted) accepted?) (cons (quote roundtrip) roundtrip?) (cons (quote diagnostics) (parse-artifact-ref artifact (quote diagnostics))))) (exit (if (and accepted? roundtrip?) 0 1))))'

# One parser-owned API performs native parsing, byte-exact roundtrip and
# official TLC model checking, then publishes one typed Gerbil receipt.
[group('check')]
check-governance-model: _prepare-gerbil-parser
    mkdir -p "$(dirname "{{ governance_tlc_receipt }}")"
    PATH="{{ justfile_directory() }}/.devenv/profile/bin:$PATH" GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ gerbil_parser_library_path }}" POO_FLOW_GOVERNANCE_TLA="{{ governance_tla }}" POO_FLOW_GOVERNANCE_TLC_CONFIG="{{ governance_tlc_config }}" POO_FLOW_GOVERNANCE_TLC_RECEIPT="{{ governance_tlc_receipt }}" gerbil interactive -e '(begin (import (only-in :gerbil-parser/languages/tla-plus/v1/qualification qualify-tla-plus-model tla-plus-model-receipt-admitted tla-plus-model-receipt-output tla-plus-model-receipt->alist)) (let* ((receipt (qualify-tla-plus-model (getenv "POO_FLOW_GOVERNANCE_TLA") (getenv "POO_FLOW_GOVERNANCE_TLC_CONFIG") workers: 1)) (datum (tla-plus-model-receipt->alist receipt))) (display (tla-plus-model-receipt-output receipt)) (call-with-output-file (getenv "POO_FLOW_GOVERNANCE_TLC_RECEIPT") (lambda (port) (write datum port) (newline port))) (write datum) (newline) (exit (if (tla-plus-model-receipt-admitted receipt) 0 1))))'

# Explicit semantic alias; both names route to the same parser-owned API.
[group('check')]
check-governance-tlc: check-governance-model

# Qualify the bounded wrong-prescription temporal model as native TLA+ source.
# This gate owns parsing, contract validation and byte-exact roundtrip only.
[group('check')]
check-healthcare-temporal-tla: _prepare-gerbil-parser
    GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ gerbil_parser_library_path }}" POO_FLOW_HEALTHCARE_TEMPORAL_TLA="{{ healthcare_temporal_tla }}" gerbil interactive -e '(begin (import (only-in :std/misc/ports read-all-as-string) :gerbil-parser/languages/tla-plus/v1/parser :gerbil-parser/src/runtime/artifact) (let* ((source (call-with-input-file (getenv "POO_FLOW_HEALTHCARE_TEMPORAL_TLA") read-all-as-string)) (artifact (parse-tla-plus-v1 source)) (accepted? (and (parse-artifact-success? artifact) (parse-artifact-valid? artifact))) (roundtrip? (and accepted? (equal? source (parse-artifact-roundtrip artifact))))) (displayln (list (cons (quote contract) +tla-plus-syntax-contract+) (cons (quote accepted) accepted?) (cons (quote roundtrip) roundtrip?) (cons (quote diagnostics) (parse-artifact-ref artifact (quote diagnostics))))) (exit (if (and accepted? roundtrip?) 0 1))))'

# TLC is a later assurance gate, not a prerequisite for ordinary Scheme builds
# or unit tests.  The devenv-owned binary makes this explicit gate reproducible.
[group('check')]
check-healthcare-temporal-model: check-healthcare-temporal-tla
    mkdir -p "$(dirname "{{ healthcare_temporal_tlc_receipt }}")"
    PATH="{{ justfile_directory() }}/.devenv/profile/bin:$PATH" GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ gerbil_parser_library_path }}" POO_FLOW_HEALTHCARE_TEMPORAL_TLA="{{ healthcare_temporal_tla }}" POO_FLOW_HEALTHCARE_TEMPORAL_TLC_CONFIG="{{ healthcare_temporal_tlc_config }}" POO_FLOW_HEALTHCARE_TEMPORAL_TLC_RECEIPT="{{ healthcare_temporal_tlc_receipt }}" gerbil interactive -e '(begin (import (only-in :gerbil-parser/languages/tla-plus/v1/qualification qualify-tla-plus-model tla-plus-model-receipt-admitted tla-plus-model-receipt-output tla-plus-model-receipt->alist)) (let* ((receipt (qualify-tla-plus-model (getenv "POO_FLOW_HEALTHCARE_TEMPORAL_TLA") (getenv "POO_FLOW_HEALTHCARE_TEMPORAL_TLC_CONFIG") workers: 1)) (datum (tla-plus-model-receipt->alist receipt))) (display (tla-plus-model-receipt-output receipt)) (call-with-output-file (getenv "POO_FLOW_HEALTHCARE_TEMPORAL_TLC_RECEIPT") (lambda (port) (write datum port) (newline port))) (write datum) (newline) (exit (if (tla-plus-model-receipt-admitted receipt) 0 1))))'

# Exact bounded model for the AI-assisted prescription Case.  The parser owner
# performs parse, byte-roundtrip and TLC execution and emits the typed receipt.
[group('check')]
check-healthcare-ai-temporal-model: _prepare-gerbil-parser
    PATH="{{ justfile_directory() }}/.devenv/profile/bin:$PATH" GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ contribution_test_library_path }}:{{ gerbil_parser_library_path }}" gerbil interactive -e '(begin (import (only-in :clan/poo/object .ref) (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/assurance HealthcareCaseQualificationMetadata healthcare-case-qualification-path) (only-in :gerbil-parser/languages/tla-plus/v1/qualification qualify-tla-plus-model tla-plus-model-receipt-admitted tla-plus-model-receipt-output tla-plus-model-receipt->alist)) (let* ((receipt (qualify-tla-plus-model (healthcare-case-qualification-path (quote tla-source)) (healthcare-case-qualification-path (quote tla-config)) workers: (.ref HealthcareCaseQualificationMetadata (quote tlc-workers)))) (datum (tla-plus-model-receipt->alist receipt)) (path (healthcare-case-qualification-path (quote tlc-receipt)))) (display (tla-plus-model-receipt-output receipt)) (create-directory* (path-directory path)) (call-with-output-file path (lambda (port) (write datum port) (newline port))) (write datum) (newline) (exit (if (tla-plus-model-receipt-admitted receipt) 0 1))))'

# The migration Feature owns a bounded temporal model; parser/TLC produce the
# formal-model governance evidence without entering an ordinary Scheme build.
[group('check')]
check-healthcare-standard-migration-model: _prepare-gerbil-parser
    mkdir -p "$(dirname "{{ healthcare_migration_tlc_receipt }}")"
    PATH="{{ justfile_directory() }}/.devenv/profile/bin:$PATH" GERBIL_PATH="{{ gerbil_parser_path }}" GERBIL_LOADPATH="{{ gerbil_parser_library_path }}" POO_FLOW_HEALTHCARE_MIGRATION_TLA="{{ healthcare_migration_tla }}" POO_FLOW_HEALTHCARE_MIGRATION_TLC_CONFIG="{{ healthcare_migration_tlc_config }}" POO_FLOW_HEALTHCARE_MIGRATION_TLC_RECEIPT="{{ healthcare_migration_tlc_receipt }}" gerbil interactive -e '(begin (import (only-in :gerbil-parser/languages/tla-plus/v1/qualification qualify-tla-plus-model tla-plus-model-receipt-admitted tla-plus-model-receipt-output tla-plus-model-receipt->alist)) (let* ((receipt (qualify-tla-plus-model (getenv "POO_FLOW_HEALTHCARE_MIGRATION_TLA") (getenv "POO_FLOW_HEALTHCARE_MIGRATION_TLC_CONFIG") workers: 1)) (datum (tla-plus-model-receipt->alist receipt))) (display (tla-plus-model-receipt-output receipt)) (call-with-output-file (getenv "POO_FLOW_HEALTHCARE_MIGRATION_TLC_RECEIPT") (lambda (port) (write datum port) (newline port))) (write datum) (newline) (exit (if (tla-plus-model-receipt-admitted receipt) 0 1))))'

# Lean refines the exact TLA+ digest and publishes named migration theorems.
[group('check')]
check-healthcare-standard-migration-lean:
    cd "{{ lean_proof_dir }}" && lake build PooFlowScenarioHealthcareProof

# Source-byte and impact-map qualification rejects stale downstream Lean proof
# bindings whenever the upstream TLA+ model changes.
[group('check')]
check-healthcare-standard-migration-proof-impact: check-healthcare-standard-migration-model check-healthcare-standard-migration-lean
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ justfile_directory() }}/.gerbil/contributions/lambda-episteme/standard-migration-impact" GERBIL_LOADPATH="{{ contribution_source_root }}/lambda-episteme:{{ justfile_directory() }}:{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=3s 60s gerbil {{ gerbil_test_runtime_options }} test -v 3 t/qualification/healthcare-standard-migration-assurance/impact-test.ss

[group('check')]
check-healthcare-standard-migration-assurance: check-healthcare-standard-migration-proof-impact

# Only this exact qualification may combine the independent Scheme, parser,
# TLC and Lean evidence into the assurance digest consumed by Cedar. MRR is a
# downstream Rust library consumer of the parser FFI, never a Scheme subprocess.
[group('check')]
check-healthcare-case-assurance: build-contribute check-healthcare-gql check-healthcare-lean check-healthcare-ai-temporal-model
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ contribution_test_path }}" GERBIL_LOADPATH="{{ contribution_test_library_path }}:{{ poo_flow_library_path }}" timeout --foreground --signal=TERM --kill-after=3s 20s gxi {{ gerbil_test_runtime_options }} ./run-contribute-test.ss "packages/lambda-episteme/t/ontology/qualification/healthcare-case-assurance.ss"

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
