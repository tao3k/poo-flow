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

case "$(uname -s)" in
  Darwin) nm -gU "$library" ;;
  *) nm -g --defined-only "$library" ;;
esac \
  | awk '{print $NF}' \
  | sed 's/^_//' \
  | awk '/^poo_flow_runtime_v0_/ || /^poo_flow_proof_/' \
  | LC_ALL=C sort -u >"$actual"

exec "$gxi" "$validator" "$manifest" "$actual"
