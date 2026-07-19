#!/usr/bin/env bash
set -euo pipefail

resolve_runfile() {
  local key=${1:?runfile key is required}
  if [[ -n "${RUNFILES_DIR:-}" ]]; then
    printf '%s\n' "$RUNFILES_DIR/$key"
  elif [[ -n "${RUNFILES_MANIFEST_FILE:-}" ]]; then
    awk -v key="$key" '$1 == key {sub($1 " ", ""); print; exit}' "$RUNFILES_MANIFEST_FILE"
  else
    printf 'Bazel runfiles environment is unavailable\n' >&2
    return 1
  fi
}

receipt=$(resolve_runfile "${1:?toolchain receipt runfile key is required}")

test -f "$receipt"
if ! grep -F '"schema": "gerbil-bazel.local-toolchain-receipt.v1"' "$receipt" >/dev/null &&
   ! grep -F '"schema": "gerbil-bazel.prebuilt-toolchain-receipt.v1"' "$receipt" >/dev/null; then
  printf 'unsupported shared Gerbil receipt schema\n' >&2
  exit 1
fi
grep -F '"dependencyPolicy": "host-only"' "$receipt" >/dev/null
grep -F '"dependencyState": {}' "$receipt" >/dev/null
