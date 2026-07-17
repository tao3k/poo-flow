#!/usr/bin/env bash
set -euo pipefail

workspace=${BUILD_WORKSPACE_DIRECTORY:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}
gerbil_prefix=${GERBIL_PREFIX:?GERBIL_PREFIX is required}
overlay=${GERBIL_GXPKG_OVERLAY:?GERBIL_GXPKG_OVERLAY is required}
source_ref=${GERBIL_GXPKG_REF:?GERBIL_GXPKG_REF is required}
native_abi=${GERBIL_NATIVE_ABI:?GERBIL_NATIVE_ABI is required}
source_repository=${GERBIL_GXPKG_REPOSITORY:-https://git.cons.io/mighty-gerbils/gerbil.git}
build_spec="$workspace/tools/bazel/gxpkg_overlay_build.ss"

case "$overlay" in
  ""|/)
    echo "Refusing unsafe gxpkg overlay path: $overlay" >&2
    exit 64
    ;;
esac

artifact_dir="$overlay/artifact/lib/gerbil/tools"
receipt="$overlay/receipt.json"
source_dir="$overlay/source"
stage_dir="$overlay/stage"
target_dir="$gerbil_prefix/lib/gerbil/tools"

overlay_ready() {
  [ -f "$receipt" ] &&
    grep -Fq "\"source_ref\": \"$source_ref\"" "$receipt" &&
    grep -Fq "\"native_abi\": \"$native_abi\"" "$receipt" &&
    [ -f "$artifact_dir/gxpkg.o1" ] &&
    [ -f "$artifact_dir/gxpkg~0.o1" ] &&
    [ -f "$artifact_dir/gxpkg.ssi" ]
}

build_overlay() {
  rm -rf "$source_dir" "$stage_dir" "$overlay/artifact" "$receipt"
  mkdir -p "$source_dir" "$stage_dir/bin"

  git -C "$source_dir" init -q
  git -C "$source_dir" remote add origin "$source_repository"
  git -C "$source_dir" fetch -q --depth 1 origin "$source_ref"
  resolved_ref=$(git -C "$source_dir" rev-parse FETCH_HEAD)
  if [ "$resolved_ref" != "$source_ref" ]; then
    echo "gxpkg source ref mismatch: expected $source_ref, got $resolved_ref" >&2
    exit 65
  fi
  git -C "$source_dir" checkout -q --detach "$resolved_ref"
  cp "$build_spec" "$source_dir/src/tools/poo-flow-gxpkg-build.ss"

  GERBIL_BUILD_PREFIX="$stage_dir" \
    "$gerbil_prefix/bin/gxi" \
    "$source_dir/src/tools/poo-flow-gxpkg-build.ss" \
    compile --optimized

  shopt -s nullglob
  built_artifacts=("$stage_dir/lib/gerbil/tools"/gxpkg*)
  if [ "${#built_artifacts[@]}" -eq 0 ]; then
    echo "The gxpkg overlay build produced no artifacts" >&2
    exit 66
  fi
  mkdir -p "$artifact_dir"
  cp -p "${built_artifacts[@]}" "$artifact_dir/"

  receipt_tmp="$receipt.tmp.$$"
  printf '{\n  "schema": "poo-flow.gerbil-gxpkg-overlay-receipt.v1",\n  "source_ref": "%s",\n  "native_abi": "%s",\n  "artifact_count": %s,\n  "status": "ready"\n}\n' \
    "$source_ref" "$native_abi" "${#built_artifacts[@]}" > "$receipt_tmp"
  mv "$receipt_tmp" "$receipt"
  rm -rf "$source_dir" "$stage_dir"
}

if overlay_ready; then
  echo "Using cached Gerbil gxpkg provider overlay"
else
  echo "Building Gerbil gxpkg provider overlay at $source_ref"
  build_overlay
fi

if [ ! -d "$target_dir" ]; then
  echo "Gerbil tool library directory is absent: $target_dir" >&2
  exit 67
fi
shopt -s nullglob
overlay_artifacts=("$artifact_dir"/gxpkg*)
if [ "${#overlay_artifacts[@]}" -eq 0 ]; then
  echo "Cached gxpkg overlay contains no artifacts" >&2
  exit 68
fi
cp -p "${overlay_artifacts[@]}" "$target_dir/"
"$gerbil_prefix/bin/gxpkg" version
