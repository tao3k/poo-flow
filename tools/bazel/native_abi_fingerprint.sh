#!/usr/bin/env bash

set -euo pipefail

compiler="${1:-}"
architecture_profile="${2:-native}"

if [[ -z "$compiler" ]]; then
  printf 'usage: %s <compiler> [native|portable]\n' "$0" >&2
  exit 64
fi

if [[ ! -x "$compiler" ]]; then
  printf 'compiler is not executable: %s\n' "$compiler" >&2
  exit 69
fi

case "$architecture_profile" in
  native | portable)
    ;;
  *)
    printf 'unsupported Gerbil architecture profile: %s\n' "$architecture_profile" >&2
    exit 64
    ;;
esac

if [[ "$architecture_profile" == "native" ]]; then
  compiler_diagnostics="$("$compiler" -march=native -### -x c -c /dev/null -o /dev/null 2>&1)"
else
  compiler_diagnostics="$("$compiler" -### -x c -c /dev/null -o /dev/null 2>&1)"
fi

# GCC and compatible drivers include randomized cc*.s temporary paths in
# `-###` diagnostics. They are execution noise, not ABI capabilities. The
# fixed source path prevents workspace and runner locations from perturbing an
# otherwise identical capability key.
canonical_diagnostics="$({
  printf '%s\n' "$compiler_diagnostics"
  "$compiler" --version | sed -n '1p'
  "$compiler" -dumpmachine
  printf 'architecture-profile=%s\n' "$architecture_profile"
} | LC_ALL=C sed -E \
  -e 's#([^[:space:]\"]*/)?cc[[:alnum:]_.-]+\.s#<compiler-temp>.s#g')"

if command -v sha256sum >/dev/null 2>&1; then
  printf '%s' "$canonical_diagnostics" | sha256sum | cut -c1-40
elif command -v shasum >/dev/null 2>&1; then
  printf '%s' "$canonical_diagnostics" | shasum -a 256 | cut -c1-40
else
  printf 'neither sha256sum nor shasum is available\n' >&2
  exit 69
fi
