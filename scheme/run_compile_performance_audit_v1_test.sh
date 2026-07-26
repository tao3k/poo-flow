#!/usr/bin/env bash
set -euo pipefail

resolve_runfile() {
  local path=$1
  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "${TEST_SRCDIR:?TEST_SRCDIR is required}" "$path"
  fi
}

gxi=$(resolve_runfile "${1:?gxi path is required}")
runner=$(resolve_runfile "${2:?audit runner path is required}")
resource_guard=$(resolve_runfile "${3:?resource guard path is required}")
fake_bazel=$(resolve_runfile "${4:?fake Bazel path is required}")
baseline_receipt=$(resolve_runfile "${5:?baseline receipt is required}")
candidate_receipt=$(resolve_runfile "${6:?candidate receipt is required}")
validator=$(resolve_runfile "${7:?validator path is required}")
budget_root=$(resolve_runfile "${8:?performance budget project root is required}")
poo_root=$(resolve_runfile "${9:?Gerbil POO root is required}")
utils_root=$(resolve_runfile "${10:?Gerbil Utils root is required}")

export GERBIL_BAZEL_GUARD_RUNNABLE_PROCESSES=1
export GERBIL_BAZEL_GUARD_PROCESS_TABLE_SNAPSHOT='1 0 1'

root="${TEST_TMPDIR:?TEST_TMPDIR is required}/audit"
baseline_workspace="$root/baseline"
candidate_workspace="$root/candidate"
output_storage="$root/output-storage"
output_directory="$root/output-alias"

mkdir -p "$baseline_workspace" "$candidate_workspace" "$output_storage"
ln -s "$output_storage" "$output_directory"
canonical_output_directory=$(cd "$output_directory" && pwd -P)
cp "$baseline_receipt" "$baseline_workspace/compile.receipt.json"
cp "$candidate_receipt" "$candidate_workspace/compile.receipt.json"

"$gxi" "$runner" \
  "$gxi" \
  "$resource_guard" \
  "$fake_bazel" \
  "$baseline_workspace" \
  "$candidate_workspace" \
  baseline-revision \
  candidate-revision \
  host-session/fixture \
  Linux-X64 \
  "$output_directory" \
  3 \
  500

for side in baseline candidate; do
  [[ -d "$output_directory/${side}-output-base" ]]
  [[ -f "$output_directory/${side}-output-base/.shutdown" ]]
  for sample_index in 1 2 3; do
    [[ -d "$output_directory/${side}-${sample_index}/root-cache" ]]
    [[ ! -e "$output_directory/${side}-${sample_index}/output-base" ]]
    [[ -f "$output_directory/${side}-${sample_index}/compile.receipt.json" ]]
    grep -F '"outcome":"ready"' \
      "$output_directory/${side}-${sample_index}/host-admission.json" >/dev/null
  done
done
grep -F '"strategy":"explicit-shutdown"' \
  "$output_directory/server-lifecycle.json" >/dev/null
grep -F '"state":"armed"' \
  "$output_directory/server-lifecycle.json" >/dev/null
grep -F '"cleanupTrigger":"dynamic-wind"' \
  "$output_directory/server-lifecycle.json" >/dev/null

failure_output_storage="$root/failure-output-storage"
failure_output_directory="$root/failure-output-alias"
mkdir -p "$failure_output_storage"
ln -s "$failure_output_storage" "$failure_output_directory"

if FAKE_BAZEL_FAIL_SYMLINK_FRAGMENT="candidate-1/bazel-" \
  "$gxi" "$runner" \
    "$gxi" \
    "$resource_guard" \
    "$fake_bazel" \
    "$baseline_workspace" \
    "$candidate_workspace" \
    baseline-revision \
    candidate-revision \
    host-session/fixture \
    Linux-X64 \
    "$failure_output_directory" \
    3 \
    500
then
  printf 'expected candidate cold sample failure\n' >&2
  exit 1
fi

grep -F '"outcome":"failed-build"' \
  "$failure_output_directory/candidate-1/compile.receipt.json" >/dev/null
grep -F '"failure-exit-code":10' \
  "$failure_output_directory/candidate-1/compile.receipt.json" >/dev/null
grep -F '"rawProcessStatus":256' \
  "$failure_output_directory/candidate-1/failure.context.json" >/dev/null
grep -F '"terminalReceiptObserved":true' \
  "$failure_output_directory/candidate-1/failure.context.json" >/dev/null
grep -F 'POO_FLOW_PROJECT_BUILD_RECEIPT' \
  "$failure_output_directory/candidate-1/build.log" >/dev/null
[[ -f "$failure_output_directory/baseline-output-base/.shutdown" ]]
[[ -f "$failure_output_directory/candidate-output-base/.shutdown" ]]
grep -F '"state":"armed"' \
  "$failure_output_directory/server-lifecycle.json" >/dev/null
grep -F '"cleanupTrigger":"dynamic-wind"' \
  "$failure_output_directory/server-lifecycle.json" >/dev/null

pressure_output_storage="$root/pressure-output-storage"
pressure_output_directory="$root/pressure-output-alias"
mkdir -p "$pressure_output_storage"
ln -s "$pressure_output_storage" "$pressure_output_directory"

host_cpu_count=$(
  POO_FLOW_TEST_HOST_RECEIPT="$output_directory/baseline-1/resource-guard.receipt.json" \
    "$gxi" -e \
    '(begin (import :std/text/json) (display (hash-ref (call-with-input-file (getenv "POO_FLOW_TEST_HOST_RECEIPT") read-json) "logicalCpuCount")))'
)
pressure_runnable_count=$((host_cpu_count + 1))

if GERBIL_BAZEL_GUARD_RUNNABLE_PROCESSES="$pressure_runnable_count" \
  "$gxi" "$runner" \
    "$gxi" \
    "$resource_guard" \
    "$fake_bazel" \
    "$baseline_workspace" \
    "$candidate_workspace" \
    baseline-revision \
    candidate-revision \
    host-session/fixture \
    Linux-X64 \
    "$pressure_output_directory" \
    3 \
    500
then
  printf 'expected host admission failure\n' >&2
  exit 1
fi

grep -F '"outcome":"blocked-host-pressure"' \
  "$pressure_output_directory/baseline-1/host-admission.json" >/dev/null
grep -F '"runnable-pressure-exceeds-logical-capacity"' \
  "$pressure_output_directory/baseline-1/host-admission.json" >/dev/null
grep -F '"phase":"host-admission"' \
  "$pressure_output_directory/baseline-1/failure.context.json" >/dev/null
[[ ! -e "$pressure_output_directory/baseline-1/build.log" ]]
[[ -f "$pressure_output_directory/baseline-output-base/.shutdown" ]]
[[ -f "$pressure_output_directory/candidate-output-base/.shutdown" ]]

export GERBIL_LOADPATH="$budget_root/.gerbil/lib:$poo_root/.gerbil/lib:$utils_root/.gerbil/lib"

"$gxi" "$validator" \
  "$output_directory/comparison-input.json" \
  "$output_directory/comparison-receipt.json"

grep -F '"outcome":"accepted"' \
  "$output_directory/comparison-receipt.json" >/dev/null
grep -F '"sampleCount":3' \
  "$output_directory/comparison-receipt.json" >/dev/null
grep -F '"baselineSpecCount":389' \
  "$output_directory/comparison-receipt.json" >/dev/null
grep -F '"candidateSpecCount":391' \
  "$output_directory/comparison-receipt.json" >/dev/null
grep -F '"actionCount":0' \
  "$output_directory/warm-noop-receipt.json" >/dev/null
grep -F "\"outputDirectory\":\"$canonical_output_directory\"" \
  "$output_directory/audit-receipt.json" >/dev/null
