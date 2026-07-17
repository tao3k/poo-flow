#!/usr/bin/env bash
set -euo pipefail

compiler="${1:-${GERBIL_GCC:-}}"
if [[ -z "$compiler" ]]; then
  if command -v gcc-16 >/dev/null 2>&1; then
    compiler="$(command -v gcc-16)"
  else
    compiler="$(command -v cc)"
  fi
elif [[ "$compiler" != */* ]]; then
  compiler="$(command -v "$compiler")"
fi

native_target="$({
  cd /
  "$compiler" -march=native -### -x c -c /dev/null -o /dev/null 2>&1
})"

{
  uname -s
  uname -m
  "$compiler" --version | head -n 1
  printf '%s\n' "$native_target"
} | git hash-object --stdin
