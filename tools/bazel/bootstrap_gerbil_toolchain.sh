#!/usr/bin/env bash
set -euo pipefail

: "${GERBIL_REF:?GERBIL_REF is required}"
: "${GERBIL_SRC:?GERBIL_SRC is required}"
: "${GERBIL_PREFIX:?GERBIL_PREFIX is required}"

gerbil_source_url="${GERBIL_SOURCE_URL:-https://github.com/mighty-gerbils/gerbil.git}"
bootstrap_cache_mode="${GERBIL_BOOTSTRAP_CACHE_MODE:-normal}"
case "$bootstrap_cache_mode" in
  normal | install-miss | cold)
    ;;
  *)
    printf 'unsupported Gerbil bootstrap cache mode: %s\n' "$bootstrap_cache_mode" >&2
    exit 64
    ;;
esac

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
cd "$GERBIL_SRC"
bootstrap_state_path="$GERBIL_SRC/.poo-flow-bootstrap-state.json"
bootstrap_started_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
bootstrap_started_epoch="$(date '+%s')"
bootstrap_phase="prepare"
bootstrap_phase_started_at="$bootstrap_started_at"
bootstrap_phase_started_epoch="$bootstrap_started_epoch"
bootstrap_phase_open=false
bootstrap_phases='[]'

write_bootstrap_state() {
  local status="$1"
  local exit_code="${2:-0}"
  local updated_at updated_epoch elapsed_ms phase_elapsed_ms temporary_path
  updated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  updated_epoch="$(date '+%s')"
  elapsed_ms="$(( (updated_epoch - bootstrap_started_epoch) * 1000 ))"
  if [[ "$bootstrap_phase_open" == true ]]; then
    phase_elapsed_ms="$(( (updated_epoch - bootstrap_phase_started_epoch) * 1000 ))"
  else
    phase_elapsed_ms=0
  fi
  temporary_path="${bootstrap_state_path}.tmp"

  jq -n \
    --arg schema "poo-flow.gerbil-bootstrap-state.v1" \
    --arg status "$status" \
    --arg phase "$bootstrap_phase" \
    --arg ref "$GERBIL_REF" \
    --arg sourceUrl "$gerbil_source_url" \
    --arg source "$GERBIL_SRC" \
    --arg prefix "$GERBIL_PREFIX" \
    --arg compiler "$compiler_command" \
    --arg architecture "$architecture_profile" \
    --arg cacheMode "$bootstrap_cache_mode" \
    --arg startedAt "$bootstrap_started_at" \
    --arg phaseStartedAt "$bootstrap_phase_started_at" \
    --arg updatedAt "$updated_at" \
    --argjson buildCores "$build_cores" \
    --argjson elapsedMs "$elapsed_ms" \
    --argjson phaseElapsedMs "$phase_elapsed_ms" \
    --argjson exitCode "$exit_code" \
    --argjson phases "$bootstrap_phases" \
    '{
      schema: $schema,
      status: $status,
      phase: $phase,
      phaseStartedAt: $phaseStartedAt,
      phaseElapsedMs: $phaseElapsedMs,
      phases: $phases,
      ref: $ref,
      sourceUrl: $sourceUrl,
      source: $source,
      prefix: $prefix,
      compiler: $compiler,
      architecture: $architecture,
      cacheMode: $cacheMode,
      buildCores: $buildCores,
      startedAt: $startedAt,
      updatedAt: $updatedAt,
      elapsedMs: $elapsedMs,
      exitCode: $exitCode
    }' >"$temporary_path"
  mv "$temporary_path" "$bootstrap_state_path"
}

close_bootstrap_phase() {
  local status="$1"
  local exit_code="${2:-0}"
  local completed_at completed_epoch phase_elapsed_ms
  if [[ "$bootstrap_phase_open" != true ]]; then
    return
  fi

  completed_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  completed_epoch="$(date '+%s')"
  phase_elapsed_ms="$(( (completed_epoch - bootstrap_phase_started_epoch) * 1000 ))"
  bootstrap_phases="$(
    jq -cn \
      --argjson phases "$bootstrap_phases" \
      --arg phase "$bootstrap_phase" \
      --arg status "$status" \
      --arg startedAt "$bootstrap_phase_started_at" \
      --arg completedAt "$completed_at" \
      --argjson elapsedMs "$phase_elapsed_ms" \
      --argjson exitCode "$exit_code" \
      '$phases + [{
        phase: $phase,
        status: $status,
        startedAt: $startedAt,
        completedAt: $completedAt,
        elapsedMs: $elapsedMs,
        exitCode: $exitCode
      }]'
  )"
  bootstrap_phase_open=false
}

begin_bootstrap_phase() {
  if [[ "$bootstrap_phase_open" == true ]]; then
    close_bootstrap_phase "success" 0
  fi
  bootstrap_phase="$1"
  bootstrap_phase_started_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  bootstrap_phase_started_epoch="$(date '+%s')"
  bootstrap_phase_open=true
  write_bootstrap_state "running" 0
}

finish_bootstrap_state() {
  local exit_code="$?"
  trap - EXIT
  if (( exit_code == 0 )); then
    close_bootstrap_phase "success" 0
    bootstrap_phase="complete"
    write_bootstrap_state "success" 0 || true
  else
    close_bootstrap_phase "interrupted" "$exit_code" || true
    write_bootstrap_state "interrupted" "$exit_code" || true
  fi
  exit "$exit_code"
}

trap 'exit 130' INT
trap 'exit 143' TERM
trap finish_bootstrap_state EXIT

begin_bootstrap_phase "fetch"
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$gerbil_source_url"
else
  git remote add origin "$gerbil_source_url"
fi
git fetch --depth=1 origin "$GERBIL_REF"
git checkout --quiet --detach FETCH_HEAD

begin_bootstrap_phase "configure"

# A GitHub-hosted runner starts with an empty workspace, so an existing
# config.status here can only come from the capability-keyed bootstrap-tree
# cache.  Adopt it once when migrating older cached trees that predate the
# explicit signature stamp.
./configure --prefix="$GERBIL_PREFIX" "${configure_architecture[@]}"

export GERBIL_BUILD_CORES="$build_cores"
begin_bootstrap_phase "build"
make -j"$build_cores"
begin_bootstrap_phase "install"
make install

begin_bootstrap_phase "verify"
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
begin_bootstrap_phase "receipt"
jq -n \
  --arg architecture_profile "$architecture_profile" \
  --arg bootstrap_cache_mode "$bootstrap_cache_mode" \
  --arg compiler "$compiler_request" \
  --arg compiler_command "$compiler_command" \
  --arg ccache_dir "${CCACHE_DIR:-}" \
  --arg ccache_executable "$ccache_executable" \
  --arg gerbil_version "$gerbil_version" \
  --arg prefix "$GERBIL_PREFIX" \
  --arg source_url "$gerbil_source_url" \
  --arg source_ref "$GERBIL_REF" \
  --arg state_receipt "$bootstrap_state_path" \
  --argjson build_cores "$build_cores" \
  --argjson ccache_activity "$ccache_activity" \
  --argjson ccache_enabled "$ccache_enabled" \
  --argjson ccache_required "$require_ccache" \
  --argjson elapsed_seconds "$elapsed_seconds" \
  --argjson phases "$bootstrap_phases" \
  '{
    schema: "poo-flow.gerbil-toolchain-bootstrap-receipt.v1",
    version: 1,
    outcome: "ready",
    architecture_profile: $architecture_profile,
    bootstrap_cache_mode: $bootstrap_cache_mode,
    source_ref: $source_ref,
    source_url: $source_url,
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
    phases: $phases,
    state_receipt: $state_receipt,
    prefix: $prefix
  }' >"$GERBIL_PREFIX/bootstrap.receipt.json"
close_bootstrap_phase "success" 0
bootstrap_phase="complete"
write_bootstrap_state "success" 0
trap - EXIT
jq -c . "$GERBIL_PREFIX/bootstrap.receipt.json"
