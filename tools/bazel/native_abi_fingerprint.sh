#!/usr/bin/env bash
set -euo pipefail

compiler="${1:-${GERBIL_GCC:-}}"
architecture_profile="${2:-${GERBIL_ARCH_PROFILE:-native}}"
case "$architecture_profile" in
  native | portable) ;;
  *)
    printf 'unsupported Gerbil architecture profile: %s\n' "$architecture_profile" >&2
    exit 64
    ;;
esac

if [[ -z "$compiler" ]]; then
  if command -v gcc-16 >/dev/null 2>&1; then
    compiler="$(command -v gcc-16)"
  else
    compiler="$(command -v cc)"
  fi
elif [[ "$compiler" != */* ]]; then
  compiler="$(command -v "$compiler")"
fi

compiler_target_args=()
if [[ "$architecture_profile" == "native" ]]; then
  compiler_target_args=(-march=native)
fi
native_target="$({
  cd /
  "$compiler" "${compiler_target_args[@]}" -### -x c -c /dev/null -o /dev/null 2>&1
})"

{
  printf '%s\n' "$architecture_profile"
  uname -s
  uname -m
  "$compiler" --version | head -n 1
  printf '%s\n' "$native_target"
} | git hash-object --stdin
