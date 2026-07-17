#!/usr/bin/env bash
set -euo pipefail

: "${GERBIL_REF:?GERBIL_REF is required}"
: "${GERBIL_SRC:?GERBIL_SRC is required}"
: "${GERBIL_PREFIX:?GERBIL_PREFIX is required}"

architecture_profile="${GERBIL_ARCH_PROFILE:-native}"
case "$architecture_profile" in
  native)
    configure_architecture=(--enable-march=native)
    ;;
  portable)
    configure_architecture=(--enable-march=)
    ;;
  *)
    printf 'unsupported Gerbil architecture profile: %s\n' "$architecture_profile" >&2
    exit 64
    ;;
esac

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

require_ccache="${GERBIL_REQUIRE_CCACHE:-0}"
case "$require_ccache" in
  0 | false | no)
    require_ccache=false
    ;;
  1 | true | yes)
    require_ccache=true
    ;;
  *)
    printf 'invalid GERBIL_REQUIRE_CCACHE value: %s\n' "$require_ccache" >&2
    exit 64
    ;;
esac

compiler_request="${CC:-cc}"
compiler_command="$compiler_request"
ccache_executable="$(command -v ccache || true)"
ccache_enabled=false
ccache_activity=0
if [[ -n "$ccache_executable" ]]; then
  ccache_enabled=true
  if [[ -n "${CCACHE_DIR:-}" ]]; then
    mkdir -p "$CCACHE_DIR"
  fi
  if [[ -n "${CCACHE_MAXSIZE:-}" ]]; then
    "$ccache_executable" --set-config=max_size="$CCACHE_MAXSIZE"
  fi
  "$ccache_executable" --zero-stats
  if [[ "$compiler_request" != ccache\ * && "$compiler_request" != "$ccache_executable"\ * ]]; then
    compiler_command="$ccache_executable $compiler_request"
  fi
elif [[ "$require_ccache" == true ]]; then
  printf 'ccache is required but was not discovered on PATH\n' >&2
  exit 69
fi
export CC="$compiler_command"

started_at="$SECONDS"
mkdir -p "$(dirname "$GERBIL_SRC")" "$(dirname "$GERBIL_PREFIX")"
rm -rf "$GERBIL_SRC" "$GERBIL_PREFIX"
git init --quiet "$GERBIL_SRC"
git -C "$GERBIL_SRC" remote add origin https://git.cons.io/mighty-gerbils/gerbil
git -C "$GERBIL_SRC" fetch --depth=1 origin "$GERBIL_REF"
git -C "$GERBIL_SRC" checkout --quiet --detach FETCH_HEAD

cd "$GERBIL_SRC"
./configure --prefix="$GERBIL_PREFIX" "${configure_architecture[@]}"

export GERBIL_BUILD_CORES="$build_cores"
make -j"$build_cores"
make install

if [[ "$ccache_enabled" == true ]]; then
  ccache_stats="$("$ccache_executable" --print-stats 2>/dev/null || true)"
  ccache_activity="$({
    printf '%s\n' "$ccache_stats"
  } | awk '
    $1 == "cache_miss" ||
    $1 == "direct_cache_hit" ||
    $1 == "preprocessed_cache_hit" { total += $2 }
    END { print total + 0 }
  ')"
  "$ccache_executable" --show-stats
  if [[ "$require_ccache" == true && "$ccache_activity" -lt 1 ]]; then
    printf 'ccache was required but observed no compiler activity\n' >&2
    exit 70
  fi
fi

elapsed_seconds=$((SECONDS - started_at))
gerbil_version="$("$GERBIL_PREFIX/bin/gxi" --version)"
jq -n \
  --arg architecture_profile "$architecture_profile" \
  --arg compiler "$compiler_request" \
  --arg compiler_command "$compiler_command" \
  --arg ccache_dir "${CCACHE_DIR:-}" \
  --arg ccache_executable "$ccache_executable" \
  --arg gerbil_version "$gerbil_version" \
  --arg prefix "$GERBIL_PREFIX" \
  --arg source_ref "$GERBIL_REF" \
  --argjson build_cores "$build_cores" \
  --argjson ccache_activity "$ccache_activity" \
  --argjson ccache_enabled "$ccache_enabled" \
  --argjson ccache_required "$require_ccache" \
  --argjson elapsed_seconds "$elapsed_seconds" \
  '{
    schema: "poo-flow.gerbil-toolchain-bootstrap-receipt.v1",
    version: 1,
    outcome: "ready",
    architecture_profile: $architecture_profile,
    source_ref: $source_ref,
    gerbil_version: $gerbil_version,
    compiler: $compiler,
    compiler_command: $compiler_command,
    ccache: {
      required: $ccache_required,
      enabled: $ccache_enabled,
      executable: $ccache_executable,
      directory: $ccache_dir,
      compiler_activity: $ccache_activity
    },
    build_cores: $build_cores,
    elapsed_seconds: $elapsed_seconds,
    prefix: $prefix
  }' >"$GERBIL_PREFIX/bootstrap.receipt.json"
jq -c . "$GERBIL_PREFIX/bootstrap.receipt.json"
