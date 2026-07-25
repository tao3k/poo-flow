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
validator=$(resolve_runfile "${2:?validator path is required}")
budget_root=$(resolve_runfile "${3:?performance budget project root is required}")
poo_root=$(resolve_runfile "${4:?Gerbil POO root is required}")
utils_root=$(resolve_runfile "${5:?Gerbil Utils root is required}")
shift 5

export GERBIL_LOADPATH="$budget_root/.gerbil/lib:$poo_root/.gerbil/lib:$utils_root/.gerbil/lib"

exec "$gxi" "$validator" "$@"
