#!/usr/bin/env bash
set -euo pipefail

state_path="${GERBIL_BOOTSTRAP_STATE:?GERBIL_BOOTSTRAP_STATE is required}"
step_outcome="${GERBIL_BOOTSTRAP_STEP_OUTCOME:?GERBIL_BOOTSTRAP_STEP_OUTCOME is required}"
timeout_minutes="${GERBIL_BOOTSTRAP_TIMEOUT_MINUTES:?GERBIL_BOOTSTRAP_TIMEOUT_MINUTES is required}"
finalized_at="${GERBIL_BOOTSTRAP_FINALIZED_AT:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

case "$step_outcome" in
  success | failure | cancelled | skipped) ;;
  *)
    echo "unsupported Gerbil bootstrap step outcome: $step_outcome" >&2
    exit 64
    ;;
esac

case "$timeout_minutes" in
  '' | *[!0-9]*)
    echo "GERBIL_BOOTSTRAP_TIMEOUT_MINUTES must be a positive integer" >&2
    exit 64
    ;;
esac
if (( timeout_minutes <= 0 )); then
  echo "GERBIL_BOOTSTRAP_TIMEOUT_MINUTES must be a positive integer" >&2
  exit 64
fi

if [[ ! -f "$state_path" ]]; then
  echo "Gerbil bootstrap state is missing: $state_path" >&2
  exit 66
fi
jq -e 'type == "object" and .schema == "poo-flow.gerbil-bootstrap-state.v1"' \
  "$state_path" >/dev/null

current_status="$(jq -r '.status // empty' "$state_path")"
if [[ "$current_status" != "running" ]]; then
  printf 'gerbil-bootstrap-finalizer status=%s action=preserve\n' "$current_status"
  exit 0
fi

iso_epoch_seconds() {
  local value="$1"
  if date -u -d "$value" +%s >/dev/null 2>&1; then
    date -u -d "$value" +%s
  else
    date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$value" +%s
  fi
}

started_at="$(jq -r '.startedAt // empty' "$state_path")"
phase_started_at="$(jq -r '.phaseStartedAt // .startedAt // empty' "$state_path")"
if [[ -z "$started_at" || -z "$phase_started_at" ]]; then
  echo "Gerbil bootstrap state lacks phase timing anchors" >&2
  exit 65
fi

finalized_epoch_seconds="${GERBIL_BOOTSTRAP_FINALIZED_EPOCH_SECONDS:-$(iso_epoch_seconds "$finalized_at")}"
started_epoch_seconds="$(iso_epoch_seconds "$started_at")"
phase_started_epoch_seconds="$(iso_epoch_seconds "$phase_started_at")"
elapsed_seconds=$((finalized_epoch_seconds - started_epoch_seconds))
phase_elapsed_seconds=$((finalized_epoch_seconds - phase_started_epoch_seconds))
if (( elapsed_seconds < 0 || phase_elapsed_seconds < 0 )); then
  echo "Gerbil bootstrap finalization timestamp precedes the state timestamp" >&2
  exit 65
fi

timeout_seconds=$((timeout_minutes * 60))
final_status=terminated
final_exit_code=1
finalizer_exit_code=0
case "$step_outcome" in
  failure)
    if (( elapsed_seconds >= timeout_seconds )); then
      final_status=timed-out
      final_exit_code=124
    fi
    ;;
  cancelled)
    final_status=cancelled
    final_exit_code=130
    ;;
  skipped)
    final_status=skipped
    final_exit_code=0
    ;;
  success)
    final_status=incomplete
    final_exit_code=70
    finalizer_exit_code=70
    ;;
esac

elapsed_ms=$((elapsed_seconds * 1000))
phase_elapsed_ms=$((phase_elapsed_seconds * 1000))
tmp_state="$(mktemp "${state_path}.tmp.XXXXXX")"
trap 'rm -f "$tmp_state"' EXIT
jq \
  --arg status "$final_status" \
  --arg stepOutcome "$step_outcome" \
  --arg completedAt "$finalized_at" \
  --argjson elapsedMs "$elapsed_ms" \
  --argjson phaseElapsedMs "$phase_elapsed_ms" \
  --argjson exitCode "$final_exit_code" \
  '
    (.phase // "unknown") as $currentPhase
    | (.phaseStartedAt // .startedAt) as $currentPhaseStartedAt
    | .status = $status
    | .stepOutcome = $stepOutcome
    | .updatedAt = $completedAt
    | .elapsedMs = $elapsedMs
    | .phaseElapsedMs = $phaseElapsedMs
    | .exitCode = $exitCode
    | .phases = ((.phases // []) + [{
        phase: $currentPhase,
        status: $status,
        startedAt: $currentPhaseStartedAt,
        completedAt: $completedAt,
        elapsedMs: $phaseElapsedMs,
        exitCode: $exitCode
      }])
  ' "$state_path" > "$tmp_state"
mv "$tmp_state" "$state_path"
trap - EXIT

printf 'gerbil-bootstrap-finalizer status=%s outcome=%s elapsed_ms=%s phase_elapsed_ms=%s\n' \
  "$final_status" "$step_outcome" "$elapsed_ms" "$phase_elapsed_ms"
exit "$finalizer_exit_code"
