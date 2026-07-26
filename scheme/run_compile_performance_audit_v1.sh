#!/usr/bin/env bash
set -euo pipefail

runfiles_root=${RUNFILES_DIR:-${TEST_SRCDIR:-"${BASH_SOURCE[0]}.runfiles"}}

resolve_runfile() {
  local path=$1
  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$runfiles_root" "$path"
  fi
}

gxi=$(resolve_runfile "${1:?gxi path is required}")
runner=$(resolve_runfile "${2:?audit runner path is required}")
resource_guard=$(resolve_runfile "${3:?resource guard path is required}")
shift 3

exec "$gxi" "$runner" "$gxi" "$resource_guard" "$@"
