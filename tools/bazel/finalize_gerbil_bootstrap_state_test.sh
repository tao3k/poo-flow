#!/usr/bin/env bash
set -euo pipefail

runfiles_root="${TEST_SRCDIR:-$(pwd)}"
workspace="${TEST_WORKSPACE:-_main}"
finalizer="$runfiles_root/$workspace/tools/bazel/finalize_gerbil_bootstrap_state.sh"
tmpdir="$(mktemp -d "${TEST_TMPDIR:-/tmp}/gerbil-bootstrap-finalizer.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

write_running_state() {
  local path="$1"
  jq -n '{
    schema: "poo-flow.gerbil-bootstrap-state.v1",
    status: "running",
    phase: "build",
    phaseStartedAt: "2025-01-01T00:00:17Z",
    phaseElapsedMs: 0,
    phases: [
      {phase: "fetch", status: "success", elapsedMs: 8000, exitCode: 0},
      {phase: "configure", status: "success", elapsedMs: 9000, exitCode: 0}
    ],
    startedAt: "2025-01-01T00:00:00Z",
    updatedAt: "2025-01-01T00:00:17Z",
    elapsedMs: 17000,
    exitCode: 0
  }' > "$path"
}

timed_out_state="$tmpdir/timed-out.json"
write_running_state "$timed_out_state"
GERBIL_BOOTSTRAP_STATE="$timed_out_state" \
GERBIL_BOOTSTRAP_STEP_OUTCOME=failure \
GERBIL_BOOTSTRAP_TIMEOUT_MINUTES=12 \
GERBIL_BOOTSTRAP_FINALIZED_AT=2025-01-01T00:12:13Z \
  "$finalizer"
jq -e '
  .status == "timed-out"
  and .stepOutcome == "failure"
  and .elapsedMs == 733000
  and .phaseElapsedMs == 716000
  and .exitCode == 124
  and (.phases | length) == 3
  and .phases[2].phase == "build"
  and .phases[2].status == "timed-out"
  and .phases[2].elapsedMs == 716000
' "$timed_out_state" >/dev/null
cp "$timed_out_state" "$tmpdir/timed-out.before.json"
GERBIL_BOOTSTRAP_STATE="$timed_out_state" \
GERBIL_BOOTSTRAP_STEP_OUTCOME=failure \
GERBIL_BOOTSTRAP_TIMEOUT_MINUTES=12 \
GERBIL_BOOTSTRAP_FINALIZED_AT=2025-01-01T00:20:00Z \
  "$finalizer"
cmp "$tmpdir/timed-out.before.json" "$timed_out_state"

terminated_state="$tmpdir/terminated.json"
write_running_state "$terminated_state"
GERBIL_BOOTSTRAP_STATE="$terminated_state" \
GERBIL_BOOTSTRAP_STEP_OUTCOME=failure \
GERBIL_BOOTSTRAP_TIMEOUT_MINUTES=12 \
GERBIL_BOOTSTRAP_FINALIZED_AT=2025-01-01T00:05:00Z \
  "$finalizer"
jq -e '.status == "terminated" and .elapsedMs == 300000 and .exitCode == 1' \
  "$terminated_state" >/dev/null

incomplete_state="$tmpdir/incomplete.json"
write_running_state "$incomplete_state"
set +e
GERBIL_BOOTSTRAP_STATE="$incomplete_state" \
GERBIL_BOOTSTRAP_STEP_OUTCOME=success \
GERBIL_BOOTSTRAP_TIMEOUT_MINUTES=12 \
GERBIL_BOOTSTRAP_FINALIZED_AT=2025-01-01T00:01:00Z \
  "$finalizer"
incomplete_status=$?
set -e
[[ "$incomplete_status" -eq 70 ]]
jq -e '.status == "incomplete" and .stepOutcome == "success" and .exitCode == 70' \
  "$incomplete_state" >/dev/null

set +e
GERBIL_BOOTSTRAP_STATE="$tmpdir/missing.json" \
GERBIL_BOOTSTRAP_STEP_OUTCOME=failure \
GERBIL_BOOTSTRAP_TIMEOUT_MINUTES=12 \
  "$finalizer" >/dev/null 2>&1
missing_status=$?
set -e
[[ "$missing_status" -eq 66 ]]

printf 'gerbil-bootstrap-finalizer-test status=PASS\n'
