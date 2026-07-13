#!/bin/sh
set -eu

library=$1
allowlist=$2
temporary=${TEST_TMPDIR:-${TMPDIR:-/tmp}}/poo-flow-runtime-symbols.$$
actual=$temporary.actual
expected=$temporary.expected
trap 'rm -f "$actual" "$expected"' EXIT HUP INT TERM

case "$(uname -s)" in
  Darwin) nm -gU "$library" ;;
  *) nm -g --defined-only "$library" ;;
esac \
  | awk '{print $NF}' \
  | sed 's/^_//' \
  | awk '/^poo_flow_runtime_v0_/ || /^poo_flow_proof_/' \
  | LC_ALL=C sort -u >"$actual"

LC_ALL=C sort -u "$allowlist" >"$expected"

if ! cmp -s "$expected" "$actual"; then
  echo "runtime C exported-symbol surface differs from the checked allowlist" >&2
  diff -u "$expected" "$actual" >&2 || true
  exit 1
fi

if grep -Eiq '(graph|compat|legacy)' "$actual"; then
  echo "retired graph/compatibility symbol escaped the public C boundary" >&2
  exit 1
fi
