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
fake_bazel=$(resolve_runfile "${3:?fake Bazel path is required}")
baseline_receipt=$(resolve_runfile "${4:?baseline receipt is required}")
candidate_receipt=$(resolve_runfile "${5:?candidate receipt is required}")
validator=$(resolve_runfile "${6:?validator path is required}")
budget_root=$(resolve_runfile "${7:?performance budget project root is required}")
poo_root=$(resolve_runfile "${8:?Gerbil POO root is required}")
utils_root=$(resolve_runfile "${9:?Gerbil Utils root is required}")

root="${TEST_TMPDIR:?TEST_TMPDIR is required}/audit"
baseline_workspace="$root/baseline"
candidate_workspace="$root/candidate"
output_directory="$root/output"

mkdir -p "$baseline_workspace" "$candidate_workspace"
cp "$baseline_receipt" "$baseline_workspace/compile.receipt.json"
cp "$candidate_receipt" "$candidate_workspace/compile.receipt.json"

"$gxi" "$runner" \
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
  for sample_index in 1 2 3; do
    [[ -d "$output_directory/${side}-${sample_index}/root-cache" ]]
    [[ ! -e "$output_directory/${side}-${sample_index}/output-base" ]]
    [[ -f "$output_directory/${side}-${sample_index}/compile.receipt.json" ]]
  done
done

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
