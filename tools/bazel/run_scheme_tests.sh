#!/usr/bin/env bash
set -euo pipefail

if (( $# != 10 )); then
  printf 'usage: %s GXTEST GXI GXC GXPKG CC AS LD DEPENDENCY_ROOT_MARKER COMPILED_ROOT TEST_ROOT\n' "$0" >&2
  exit 64
fi

runfiles_workspace=${TEST_SRCDIR:?}/${TEST_WORKSPACE:?}
cd "$runfiles_workspace"

absolute_runfile() {
  local path=$1
  local directory
  directory=$(dirname "$path")
  printf '%s/%s\n' "$(cd "$directory" && pwd)" "$(basename "$path")"
}

gxtest=$(absolute_runfile "$1")
gxi=$(absolute_runfile "$2")
gxc=$(absolute_runfile "$3")
gxpkg=$(absolute_runfile "$4")
gerbil_cc=$(absolute_runfile "$5")
gerbil_as=$(absolute_runfile "$6")
gerbil_ld=$(absolute_runfile "$7")
dependency_root_marker=$(absolute_runfile "$8")
compiled_root=$(absolute_runfile "$9")
test_root=$(absolute_runfile "${10}")

dependency_root=$(dirname "$dependency_root_marker")
tool_bin=${TEST_TMPDIR:?}/gerbil-toolchain-bin
mkdir -p "$tool_bin"

ln -s "$gxtest" "$tool_bin/gxtest"
ln -s "$gxi" "$tool_bin/gxi"
ln -s "$gxc" "$tool_bin/gxc"
ln -s "$gxpkg" "$tool_bin/gxpkg"
ln -s "$gerbil_cc" "$tool_bin/gcc-16"
ln -s "$gerbil_cc" "$tool_bin/cc"
ln -s "$gerbil_as" "$tool_bin/as"
ln -s "$gerbil_ld" "$tool_bin/ld"

export CC="$gerbil_cc"
export GERBIL_LOADPATH="$compiled_root/lib:$runfiles_workspace:$dependency_root"
export GERBIL_PATH="$compiled_root"
export PATH="$tool_bin:$PATH"

exec "$gxtest" "$test_root"
