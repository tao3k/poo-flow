#!/bin/sh
set -eu

gxi=$1
validator=$2
library=$3
manifest=$4
clan_package=${5:-}
utils_package=${6:-}
if [ -z "${GERBIL_LOADPATH:-}" ] && [ -d "${PWD}/src" ]; then
  GERBIL_LOADPATH=$PWD
  if [ -n "$clan_package" ]; then
    GERBIL_LOADPATH=$GERBIL_LOADPATH:$(dirname "$clan_package")
  fi
  if [ -n "$utils_package" ]; then
    GERBIL_LOADPATH=$GERBIL_LOADPATH:$(dirname "$utils_package")
  fi
  export GERBIL_LOADPATH
fi
temporary=${TEST_TMPDIR:-${TMPDIR:-/tmp}}/poo-flow-runtime-symbols.$$
actual=$temporary.actual
trap 'rm -f "$actual"' EXIT HUP INT TERM

if [ -n "${NM_BIN:-}" ]; then
  nm_bin=$NM_BIN
elif command -v nm >/dev/null 2>&1; then
  nm_bin=$(command -v nm)
elif command -v llvm-nm >/dev/null 2>&1; then
  nm_bin=$(command -v llvm-nm)
elif [ -x /usr/bin/nm ]; then
  nm_bin=/usr/bin/nm
else
  echo "runtime_v0_symbol_surface_test: nm or llvm-nm not found" >&2
  exit 127
fi

case "$(uname -s)" in
  Darwin) "$nm_bin" -gU "$library" ;;
  *) "$nm_bin" -g --defined-only "$library" ;;
esac \
  | awk '{print $NF}' \
  | sed 's/^_//' \
  | awk '/^poo_flow_runtime_v0_/ || /^poo_flow_proof_/' \
  | LC_ALL=C sort -u >"$actual"

exec "$gxi" "$validator" "$manifest" "$actual"
