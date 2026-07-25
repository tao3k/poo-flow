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
validator=$(resolve_runfile "${2:?validator path is required}")
budget_root=$(resolve_runfile "${3:?performance budget project root is required}")
poo_root=$(resolve_runfile "${4:?Gerbil POO root is required}")
utils_root=$(resolve_runfile "${5:?Gerbil Utils root is required}")
accepted_input=$(resolve_runfile "${6:?accepted input is required}")
regressed_input=$(resolve_runfile "${7:?regressed input is required}")

export GERBIL_LOADPATH="$budget_root/.gerbil/lib:$poo_root/.gerbil/lib:$utils_root/.gerbil/lib"

accepted_output="${TEST_TMPDIR:?TEST_TMPDIR is required}/accepted.json"
regressed_output="$TEST_TMPDIR/regressed.json"
regressed_diagnostic="$TEST_TMPDIR/regressed.diagnostic"

"$gxi" "$validator" "$accepted_input" "$accepted_output"
grep -F '"outcome":"accepted"' "$accepted_output" >/dev/null
grep -F '"baselineSpecCount":389' "$accepted_output" >/dev/null
grep -F '"candidateSpecCount":391' "$accepted_output" >/dev/null

set +e
"$gxi" "$validator" "$regressed_input" "$regressed_output" \
  >"$regressed_diagnostic" 2>&1
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
  printf 'validator accepted a regressed Scheme compile median\n' >&2
  exit 1
fi

grep -F '"outcome":"regressed"' "$regressed_output" >/dev/null
grep -F 'Scheme compile performance comparison did not pass' \
  "$regressed_diagnostic" >/dev/null
