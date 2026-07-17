#!/usr/bin/env bash
set -euo pipefail

: "${GERBIL_REF:?GERBIL_REF is required}"
: "${GERBIL_SRC:?GERBIL_SRC is required}"
: "${GERBIL_PREFIX:?GERBIL_PREFIX is required}"

build_cores="${GERBIL_BUILD_CORES:-}"
if [[ -z "$build_cores" ]]; then
  build_cores="$(getconf _NPROCESSORS_ONLN)"
fi
case "$build_cores" in
  ''|*[!0-9]*)
    printf 'invalid available build parallelism: %s\n' "$build_cores" >&2
    exit 64
    ;;
esac
if ((build_cores < 1)); then
  printf 'available build parallelism must be positive: %s\n' "$build_cores" >&2
  exit 64
fi

started_at="$SECONDS"
mkdir -p "$(dirname "$GERBIL_SRC")" "$(dirname "$GERBIL_PREFIX")"
rm -rf "$GERBIL_SRC" "$GERBIL_PREFIX"
git init --quiet "$GERBIL_SRC"
git -C "$GERBIL_SRC" remote add origin https://git.cons.io/mighty-gerbils/gerbil
git -C "$GERBIL_SRC" fetch --depth=1 origin "$GERBIL_REF"
git -C "$GERBIL_SRC" checkout --quiet --detach FETCH_HEAD

cd "$GERBIL_SRC"
./configure --prefix="$GERBIL_PREFIX"

export GERBIL_BUILD_CORES="$build_cores"
make -j"$build_cores"
make install

elapsed_seconds=$((SECONDS - started_at))
gerbil_version="$("$GERBIL_PREFIX/bin/gxi" --version)"
jq -n \
  --arg compiler "${CC:-cc}" \
  --arg gerbil_version "$gerbil_version" \
  --arg prefix "$GERBIL_PREFIX" \
  --arg source_ref "$GERBIL_REF" \
  --argjson build_cores "$build_cores" \
  --argjson elapsed_seconds "$elapsed_seconds" \
  '{
    schema: "poo-flow.gerbil-toolchain-bootstrap-receipt.v1",
    version: 1,
    outcome: "ready",
    source_ref: $source_ref,
    gerbil_version: $gerbil_version,
    compiler: $compiler,
    build_cores: $build_cores,
    elapsed_seconds: $elapsed_seconds,
    prefix: $prefix
  }' >"$GERBIL_PREFIX/bootstrap.receipt.json"
jq -c . "$GERBIL_PREFIX/bootstrap.receipt.json"
