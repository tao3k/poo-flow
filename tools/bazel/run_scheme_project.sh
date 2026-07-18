#!/usr/bin/env bash
set -euo pipefail

if (( $# < 11 )); then
  printf 'usage: %s GXI GXC GXPKG CC AS LD DEPENDENCY_ROOT_MARKER BUILD_SS OUTPUT_ROOT RECEIPT LOG [COMPILE_ARGS...]\n' "$0" >&2
  exit 64
fi

absolute_path() {
  local path=$1
  local directory
  directory=$(dirname "$path")
  printf '%s/%s\n' "$(cd "$directory" && pwd)" "$(basename "$path")"
}

canonical_file() {
  local path=$1
  local directory target
  path=$(absolute_path "$path")
  while [[ -L "$path" ]]; do
    directory=$(cd "$(dirname "$path")" && pwd -P)
    target=$(readlink "$path")
    if [[ "$target" = /* ]]; then
      path=$target
    else
      path="$directory/$target"
    fi
  done
  directory=$(cd "$(dirname "$path")" && pwd -P)
  printf '%s/%s\n' "$directory" "$(basename "$path")"
}

gxi=$(absolute_path "$1")
gxc=$(absolute_path "$2")
gxpkg=$(absolute_path "$3")
gerbil_cc=$(absolute_path "$4")
gerbil_as=$(absolute_path "$5")
gerbil_ld=$(absolute_path "$6")
dependency_root_marker=$(absolute_path "$7")
build_script=$(canonical_file "$8")
output_root=$(absolute_path "$9")
receipt=$(absolute_path "${10}")
log=$(absolute_path "${11}")
shift 11

dependency_root=$(dirname "$dependency_root_marker")
project_root=$(dirname "$build_script")
tool_bin="$output_root/.tool-bin"
rm -rf "$tool_bin"
mkdir -p "$output_root/lib" "$tool_bin"

cleanup_tool_bin() {
  rm -rf "$tool_bin"
}
trap cleanup_tool_bin EXIT

ln -s "$gxi" "$tool_bin/gxi"
ln -s "$gxc" "$tool_bin/gxc"
ln -s "$gxpkg" "$tool_bin/gxpkg"
ln -s "$gerbil_cc" "$tool_bin/gcc-16"
ln -s "$gerbil_cc" "$tool_bin/cc"
ln -s "$gerbil_as" "$tool_bin/as"
ln -s "$gerbil_ld" "$tool_bin/ld"

export CC="$gerbil_cc"
export GERBIL_LOADPATH="$output_root/lib:$dependency_root"
export GERBIL_PATH="$output_root"
export PATH="$tool_bin:$PATH"

set +e
cd "$project_root"
"$gxi" "$build_script" compile "$@" >"$log" 2>&1
status=$?
set -e

if (( status != 0 )); then
  printf 'canonical build.ss compile failed with exit %d; final log follows\n' "$status" >&2
  tail -n 200 "$log" >&2
  exit "$status"
fi

receipt_prefix='POO_FLOW_PROJECT_BUILD_RECEIPT '
receipt_payload=
while IFS= read -r line || [[ -n "$line" ]]; do
  case "$line" in
    "$receipt_prefix"*) receipt_payload=${line#"$receipt_prefix"} ;;
  esac
done <"$log"

if [[ -z "$receipt_payload" ]]; then
  printf 'canonical build.ss compile completed without a project JSON receipt\n' >&2
  tail -n 200 "$log" >&2
  exit 65
fi

printf '%s\n' "$receipt_payload" >"$receipt"
