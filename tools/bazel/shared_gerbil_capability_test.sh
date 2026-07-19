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

if [[ ! -f "$receipt" ]]; then
  printf 'shared Gerbil receipt is missing: %s\n' "$receipt" >&2
  exit 1
fi

if ! receipt_json=$(jq -c . "$receipt"); then
  printf 'shared Gerbil receipt is not valid JSON: %s\n' "$receipt" >&2
  exit 1
fi

schema=$(jq -r '.schema // "<missing>"' "$receipt")
dependency_policy=$(jq -r '.dependencyPolicy // "<missing>"' "$receipt")
dependency_state=$(jq -c '.dependencyState // null' "$receipt")
dependency_roots=$(jq -c '.dependencyRoots // null' "$receipt")

receipt_mismatch() {
  local field=${1:?field is required}
  local expected=${2:?expected value is required}
  local actual=${3:?actual value is required}
  printf 'shared Gerbil receipt mismatch: field=%s expected=%s actual=%s\n' \
    "$field" "$expected" "$actual" >&2
  printf 'receipt=%s\n' "$receipt_json" >&2
  exit 1
}

case "$schema" in
  gerbil-bazel.local-toolchain-receipt.v1)
    [[ "$dependency_policy" == "host-only" ]] ||
      receipt_mismatch dependencyPolicy host-only "$dependency_policy"
    ;;
  gerbil-bazel.prebuilt-toolchain-receipt.v1)
    [[ "$dependency_policy" == "declared-roots" ]] ||
      receipt_mismatch dependencyPolicy declared-roots "$dependency_policy"
    if ! jq -e '
      .dependencyRoots
      | type == "array" and length > 0
        and all(.[]; type == "string" and length > 0)
    ' "$receipt" >/dev/null; then
      receipt_mismatch dependencyRoots non-empty-string-array "$dependency_roots"
    fi
    ;;
  *)
    receipt_mismatch schema supported-toolchain-receipt "$schema"
    ;;
esac

if ! jq -e '
  .dependencyState | type == "object" and length == 0
' "$receipt" >/dev/null; then
  receipt_mismatch dependencyState empty-object "$dependency_state"
fi
