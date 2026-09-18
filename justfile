# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
#
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

set shell := ["bash", "-euo", "pipefail", "-c"]

export GERBIL_BUILD_CORES := env_var_or_default("GERBIL_BUILD_CORES", "12")

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
aitia_native_library := justfile_directory() + "/.gerbil/native/libpoo_flow_aitia.dylib"
aitia_python_dir := contribution_source_root + "/lambda-aitia/bindings/python"
python_runtime_test_environment := "//gerbil:python_runtime_test_environment"
composition_lifecycle_tests := "tests/unit/test_composition_lifecycle_arrival.py tests/unit/test_composition_lifecycle_benchmark.py tests/unit/test_composition_lifecycle_workload.py"
cedar_workspace := "bindings/cedar-gerbil/Cargo.toml"
contribution_test_path := justfile_directory() + "/.gerbil/contributions/lambda-episteme/module-test"
contribution_test_library_path := contribution_test_path + "/lib"
contribution_source_root := justfile_directory() + "/packages"
gerbil_homebrew_runtime := `if gsc -v 2>&1 | grep -F '/opt/homebrew/Cellar/' >/dev/null; then printf true; else printf false; fi`
# Keep the Homebrew/Gambit workaround scoped to each child command. A Nix
# Gerbil runtime retains its own compiler, SDK and linker environment.
gerbil_darwin_cc := "/usr/bin/clang -Wno-ignored-optimization-argument -Wno-unused-command-line-argument"
gerbil_darwin_env := if os() == "macos" { if gerbil_homebrew_runtime == "true" { "env -u SDKROOT BUILD_OBJ_CC_PARAM='" + gerbil_darwin_cc + "' BUILD_DYN_CC_PARAM='" + gerbil_darwin_cc + "' BUILD_DYN_LD_OPTIONS_PARAM='-bundle -undefined dynamic_lookup' BUILD_EXE_CC_PARAM='" + gerbil_darwin_cc + "'" } else { "env" } } else { "env" }
poo_flow_gerbil_path := env_var_or_default("GERBIL_PATH", justfile_directory() + "/.gerbil")
poo_flow_library_path := env_var_or_default("GERBIL_LOADPATH", poo_flow_gerbil_path + "/lib")
gerbil_parser_dir := env_var_or_default("GERBIL_PARSER_DIR", justfile_directory() + "/../gerbil-parser")
governance_tla := justfile_directory() + "/packages/proof/tla/GovernanceCore.tla"
governance_tlc_config := justfile_directory() + "/packages/proof/tla/GovernanceCore.cfg"
governance_tlc_receipt := justfile_directory() + "/.ci/governance/tlc-receipt.ss"
healthcare_temporal_tla := justfile_directory() + "/packages/proof/tla/HealthcarePrescriptionCausality.tla"
healthcare_temporal_tlc_config := justfile_directory() + "/packages/proof/tla/HealthcarePrescriptionCausality.cfg"
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
    cd "{{ contribution_source_root }}/{{ contribution }}" && GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ poo_flow_library_path }}" exec {{ gerbil_darwin_env }} gerbil build </dev/null

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
    trap 'rm -rf -- "$test_root"' EXIT
    runner="./run-contribute-test.ss"
    if test "{{ contribution }}" = "lambda-aitia"; then runner="./packages/lambda-aitia/run-test.ss"; fi
    test_directory="packages/{{ contribution }}/t/{{ module }}"
    test -d "$test_directory"
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="$test_root" GERBIL_LOADPATH="{{ contribution_source_root }}/{{ contribution }}:{{ justfile_directory() }}:$test_root/lib:{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=5s 120s gxi "$runner" "$test_directory"

# Replay a previously compiled exact test under the opt-in native heap monitor.
[group('test')]
observe-contribute-import-memory contribution="lambda-aitia" module="sdlc" test_file="unit/nasa-certification-test.ss":
    case "{{ contribution }}" in lambda-episteme|lambda-aitia) ;; *) echo "unsupported contribution: {{ contribution }}" >&2; exit 64 ;; esac
    test -f "packages/{{ contribution }}/t/{{ module }}/{{ test_file }}"
    echo "[poo-flow-observability] phase=import-observer-start owner={{ contribution }} module={{ module }} test={{ test_file }} budget=15s"
    GERBIL_PATH="{{ justfile_directory() }}/.gerbil/contributions/{{ contribution }}/atomic-test" GERBIL_LOADPATH="{{ justfile_directory() }}/.gerbil/contributions/{{ contribution }}/atomic-test/lib:{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=2s 15s gxi ./observe-contribute-import.ss "{{ contribution }}" "{{ module }}" "{{ test_file }}"

# Execute one exact test file. Source admission belongs to the native gxtest
# lifecycle and is enabled declaratively by its POO Testing Profile.
[group('test')]
test-contribute-atomic contribution="lambda-aitia" module="sdlc" test_file="unit/nasa-certification-test.ss":
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ contribution }}" in lambda-episteme|lambda-aitia) ;; *) echo "unsupported contribution: {{ contribution }}" >&2; exit 64 ;; esac
    test_root="$(mktemp -d "${TMPDIR:-/tmp}/poo-flow-{{ contribution }}-atomic-test.XXXXXX")"
    trap 'rm -rf -- "$test_root"' EXIT
    runner="./run-contribute-test.ss"
    if test "{{ contribution }}" = "lambda-aitia"; then runner="./packages/lambda-aitia/run-test.ss"; fi
    test_path="packages/{{ contribution }}/t/{{ module }}/{{ test_file }}"
    test -f "$test_path"
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="$test_root" GERBIL_LOADPATH="{{ contribution_source_root }}/{{ contribution }}:{{ justfile_directory() }}:$test_root/lib:{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=3s 60s gxi "$runner" "$test_path"

# Keep the 10k scale fixture out of the 1 GiB ordinary unit-test worker. This
# dedicated gate owns its benchmark budget and emits the full native receipt.
[group('test')]
test-standards-resolution-performance:
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=3s 90s gerbil test -v t/performance/standards-resolution-performance-test.ss

# Keep the 10k Sources Lock fixture outside the ordinary unit-test worker. The
# Scenario measures canonical construction separately from indexed lookup.
[group('test')]
test-sources-lock-performance:
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ justfile_directory() }}/.gerbil" GERBIL_LOADPATH="{{ poo_flow_library_path }}" {{ gerbil_darwin_env }} timeout --foreground --signal=TERM --kill-after=3s 90s gerbil test -v t/performance/sources-lock-performance-test.ss

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

# Establish gerbil-parser's isolated package environment once. Its POO Flow
# dependency is a local development link, never a reverse production edge.
_prepare-gerbil-parser:
    test -f "{{ gerbil_parser_dir }}/gerbil.pkg"
    if test ! -e "{{ gerbil_parser_dir }}/.gerbil/pkg/github.com/tao3k/poo-flow"; then cd "{{ gerbil_parser_dir }}" && gerbil pkg link github.com/tao3k/poo-flow "{{ justfile_directory() }}"; fi
    test "$(cd "{{ gerbil_parser_dir }}/.gerbil/pkg/github.com/tao3k/poo-flow" && pwd -P)" = "$(cd "{{ justfile_directory() }}" && pwd -P)"
    cd "{{ gerbil_parser_dir }}" && gerbil build

# Qualify Case-owned GQL Sources from the parser owner's package environment.
# Lambda stays independent of gerbil-parser; parser acceptance is not execution.
[group('check')]
check-healthcare-gql: _prepare-gerbil-parser
    GERBIL_PATH="{{ gerbil_parser_dir }}/.gerbil" GERBIL_LOADPATH="{{ contribution_test_library_path }}:{{ poo_flow_library_path }}" gerbil interactive -e '(begin (import (only-in :std/misc/ports read-all-as-string) (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/assurance healthcare-case-qualification-gql-paths) (only-in :gerbil-parser/languages/gql/iso-39075-2024/parser parse-gql-iso-39075-2024) (only-in :gerbil-parser/src/runtime/artifact parse-artifact-success? parse-artifact-valid? parse-artifact-roundtrip)) (let loop ((paths (healthcare-case-qualification-gql-paths)) (receipts (quote ()))) (if (null? paths) (begin (for-each displayln (reverse receipts)) (exit 0)) (let* ((path (car paths)) (source (call-with-input-file path read-all-as-string)) (artifact (parse-gql-iso-39075-2024 source)) (accepted? (and (parse-artifact-success? artifact) (parse-artifact-valid? artifact) (equal? source (parse-artifact-roundtrip artifact))))) (unless accepted? (displayln (list (cons (quote source) path) (cons (quote accepted) #f))) (exit 1)) (loop (cdr paths) (cons (list (cons (quote source) path) (cons (quote accepted) #t) (cons (quote roundtrip) #t)) receipts))))))'

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

# Full aggregation is an explicit integration qualification, never the default
# local or pull-request proof gate.
[group('check')]
check-lean-all:
    cd "{{ lean_proof_dir }}" && lake build PooFlowProof

# Preserve the focused syntax-only gate for parser development.
[group('check')]
check-governance-tla: _prepare-gerbil-parser
    cd "{{ gerbil_parser_dir }}" && POO_FLOW_GOVERNANCE_TLA="{{ governance_tla }}" gerbil env gerbil interactive -e '(begin (import (only-in :std/misc/ports read-all-as-string) :gerbil-parser/languages/tla-plus/v1/parser :gerbil-parser/src/runtime/artifact) (let* ((source (call-with-input-file (getenv "POO_FLOW_GOVERNANCE_TLA") read-all-as-string)) (artifact (parse-tla-plus-v1 source)) (accepted? (and (parse-artifact-success? artifact) (parse-artifact-valid? artifact))) (roundtrip? (and accepted? (equal? source (parse-artifact-roundtrip artifact))))) (displayln (list (cons (quote contract) +tla-plus-syntax-contract+) (cons (quote accepted) accepted?) (cons (quote roundtrip) roundtrip?) (cons (quote diagnostics) (parse-artifact-ref artifact (quote diagnostics))))) (exit (if (and accepted? roundtrip?) 0 1))))'

# One parser-owned API performs native parsing, byte-exact roundtrip and
# official TLC model checking, then publishes one typed Gerbil receipt.
[group('check')]
check-governance-model: _prepare-gerbil-parser
    mkdir -p "$(dirname "{{ governance_tlc_receipt }}")"
    cd "{{ gerbil_parser_dir }}" && POO_FLOW_GOVERNANCE_TLA="{{ governance_tla }}" POO_FLOW_GOVERNANCE_TLC_CONFIG="{{ governance_tlc_config }}" POO_FLOW_GOVERNANCE_TLC_RECEIPT="{{ governance_tlc_receipt }}" gerbil env gerbil interactive -e '(begin (import (only-in :gerbil-parser/languages/tla-plus/v1/qualification qualify-tla-plus-model tla-plus-model-receipt-admitted tla-plus-model-receipt-output tla-plus-model-receipt->alist)) (let* ((receipt (qualify-tla-plus-model (getenv "POO_FLOW_GOVERNANCE_TLA") (getenv "POO_FLOW_GOVERNANCE_TLC_CONFIG") workers: 1)) (datum (tla-plus-model-receipt->alist receipt))) (display (tla-plus-model-receipt-output receipt)) (call-with-output-file (getenv "POO_FLOW_GOVERNANCE_TLC_RECEIPT") (lambda (port) (write datum port) (newline port))) (write datum) (newline) (exit (if (tla-plus-model-receipt-admitted receipt) 0 1))))'

# Explicit semantic alias; both names route to the same parser-owned API.
[group('check')]
check-governance-tlc: check-governance-model

# Qualify the bounded wrong-prescription temporal model as native TLA+ source.
# This gate owns parsing, contract validation and byte-exact roundtrip only.
[group('check')]
check-healthcare-temporal-tla: _prepare-gerbil-parser
    cd "{{ gerbil_parser_dir }}" && POO_FLOW_HEALTHCARE_TEMPORAL_TLA="{{ healthcare_temporal_tla }}" gerbil env gerbil interactive -e '(begin (import (only-in :std/misc/ports read-all-as-string) :gerbil-parser/languages/tla-plus/v1/parser :gerbil-parser/src/runtime/artifact) (let* ((source (call-with-input-file (getenv "POO_FLOW_HEALTHCARE_TEMPORAL_TLA") read-all-as-string)) (artifact (parse-tla-plus-v1 source)) (accepted? (and (parse-artifact-success? artifact) (parse-artifact-valid? artifact))) (roundtrip? (and accepted? (equal? source (parse-artifact-roundtrip artifact))))) (displayln (list (cons (quote contract) +tla-plus-syntax-contract+) (cons (quote accepted) accepted?) (cons (quote roundtrip) roundtrip?) (cons (quote diagnostics) (parse-artifact-ref artifact (quote diagnostics))))) (exit (if (and accepted? roundtrip?) 0 1))))'

# TLC is a later assurance gate, not a prerequisite for ordinary Scheme builds
# or unit tests.  The devenv-owned binary makes this explicit gate reproducible.
[group('check')]
check-healthcare-temporal-model: check-healthcare-temporal-tla
    mkdir -p "$(dirname "{{ healthcare_temporal_tlc_receipt }}")"
    cd "{{ gerbil_parser_dir }}" && PATH="{{ justfile_directory() }}/.devenv/profile/bin:$PATH" POO_FLOW_HEALTHCARE_TEMPORAL_TLA="{{ healthcare_temporal_tla }}" POO_FLOW_HEALTHCARE_TEMPORAL_TLC_CONFIG="{{ healthcare_temporal_tlc_config }}" POO_FLOW_HEALTHCARE_TEMPORAL_TLC_RECEIPT="{{ healthcare_temporal_tlc_receipt }}" gerbil env gerbil interactive -e '(begin (import (only-in :gerbil-parser/languages/tla-plus/v1/qualification qualify-tla-plus-model tla-plus-model-receipt-admitted tla-plus-model-receipt-output tla-plus-model-receipt->alist)) (let* ((receipt (qualify-tla-plus-model (getenv "POO_FLOW_HEALTHCARE_TEMPORAL_TLA") (getenv "POO_FLOW_HEALTHCARE_TEMPORAL_TLC_CONFIG") workers: 1)) (datum (tla-plus-model-receipt->alist receipt))) (display (tla-plus-model-receipt-output receipt)) (call-with-output-file (getenv "POO_FLOW_HEALTHCARE_TEMPORAL_TLC_RECEIPT") (lambda (port) (write datum port) (newline port))) (write datum) (newline) (exit (if (tla-plus-model-receipt-admitted receipt) 0 1))))'

# Exact bounded model for the AI-assisted prescription Case.  The parser owner
# performs parse, byte-roundtrip and TLC execution and emits the typed receipt.
[group('check')]
check-healthcare-ai-temporal-model: _prepare-gerbil-parser
    PATH="{{ justfile_directory() }}/.devenv/profile/bin:$PATH" GERBIL_PATH="{{ gerbil_parser_dir }}/.gerbil" GERBIL_LOADPATH="{{ contribution_test_library_path }}:{{ poo_flow_library_path }}" gerbil interactive -e '(begin (import (only-in :clan/poo/object .ref) (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/assurance HealthcareCaseQualificationMetadata healthcare-case-qualification-path) (only-in :gerbil-parser/languages/tla-plus/v1/qualification qualify-tla-plus-model tla-plus-model-receipt-admitted tla-plus-model-receipt-output tla-plus-model-receipt->alist)) (let* ((receipt (qualify-tla-plus-model (healthcare-case-qualification-path (quote tla-source)) (healthcare-case-qualification-path (quote tla-config)) workers: (.ref HealthcareCaseQualificationMetadata (quote tlc-workers)))) (datum (tla-plus-model-receipt->alist receipt)) (path (healthcare-case-qualification-path (quote tlc-receipt)))) (display (tla-plus-model-receipt-output receipt)) (create-directory* (path-directory path)) (call-with-output-file path (lambda (port) (write datum port) (newline port))) (write datum) (newline) (exit (if (tla-plus-model-receipt-admitted receipt) 0 1))))'

# Only this exact qualification may combine the independent Scheme, parser,
# TLC and Lean evidence into the assurance digest consumed by Cedar. MRR is a
# downstream Rust library consumer of the parser FFI, never a Scheme subprocess.
[group('check')]
check-healthcare-case-assurance: build-contribute check-healthcare-gql check-healthcare-lean check-healthcare-ai-temporal-model
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="{{ contribution_test_path }}" GERBIL_LOADPATH="{{ contribution_test_library_path }}:{{ poo_flow_library_path }}" timeout --foreground --signal=TERM --kill-after=3s 20s gxi ./run-contribute-test.ss "packages/lambda-episteme/t/ontology/qualification/healthcare-case-assurance.ss"

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
