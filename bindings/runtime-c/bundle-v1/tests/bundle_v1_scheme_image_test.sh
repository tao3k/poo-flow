#!/bin/sh
set -eu

gxi=$1
fixture=$2
harness=$3
clan_package=$4
utils_package=$5

if [ -z "${GERBIL_LOADPATH:-}" ]; then
  GERBIL_LOADPATH=$PWD:$(dirname "$clan_package"):$(dirname "$utils_package")
  export GERBIL_LOADPATH
fi

temporary=${TEST_TMPDIR:-${TMPDIR:-/tmp}}/poo-flow-bundle-v1.$$
descriptor=$temporary.descriptor.bin
arena=$temporary.arena.bin
trap 'rm -f "$descriptor" "$arena"' EXIT HUP INT TERM

POO_FLOW_BUNDLE_V1_DESCRIPTOR_OUT=$descriptor
POO_FLOW_BUNDLE_V1_ARENA_OUT=$arena
export POO_FLOW_BUNDLE_V1_DESCRIPTOR_OUT POO_FLOW_BUNDLE_V1_ARENA_OUT

"$gxi" "$fixture"
"$harness" "$descriptor" "$arena"
