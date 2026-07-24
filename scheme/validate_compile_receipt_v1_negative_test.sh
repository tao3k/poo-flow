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
receipt=$(resolve_runfile "${3:?receipt path is required}")
contract_projection=$(resolve_runfile "${4:?contract projection path is required}")
invalid_projection=${TEST_TMPDIR:?TEST_TMPDIR is required}/invalid-contract.json
diagnostic_path=$TEST_TMPDIR/validator.diagnostic

expected_revision=f45a4ef3bfecd2af39e114ed736ce9082cbb8244
invalid_revision=0000000000000000000000000000000000000000
sed "s/$expected_revision/$invalid_revision/g" \
  "$contract_projection" >"$invalid_projection"

set +e
"$gxi" "$validator" "$receipt" "$invalid_projection" \
  >"$diagnostic_path" 2>&1
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
  printf 'validator accepted a contract projection with a mismatched revision\n' >&2
  exit 1
fi
grep -F 'dependency source revision mismatch' "$diagnostic_path" >/dev/null
