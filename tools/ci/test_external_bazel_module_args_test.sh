#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
subject="$repo_root/tools/ci/test_external_bazel_module.sh"
test_root="$(cd "$(mktemp -d)" && pwd -P)"
cleanup() {
  chmod -R u+rwX "$test_root" 2>/dev/null || true
  rm -rf "$test_root"
}
trap cleanup EXIT

mock_bazel="$test_root/mock-bazel"
args_log="$test_root/bazel-args.log"
cat >"$mock_bazel" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

first=1
for arg in "$@"; do
  if [[ "$first" == 0 ]]; then
    printf '\t' >>"$POO_FLOW_EXTERNAL_BAZEL_ARGS_LOG"
  fi
  printf '%s' "$arg" >>"$POO_FLOW_EXTERNAL_BAZEL_ARGS_LOG"
  first=0
done
printf '\n' >>"$POO_FLOW_EXTERNAL_BAZEL_ARGS_LOG"

case "$*" in
  *bazel-no-root-override*) exit 1 ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$mock_bazel"

export BAZEL="$mock_bazel"
export POO_FLOW_EXTERNAL_BAZEL_ARGS_LOG="$args_log"
export TMPDIR="$test_root/tmp"
mkdir -p "$TMPDIR"
unset POO_FLOW_EXTERNAL_BAZEL_OUTPUT_BASE
unset POO_FLOW_EXTERNAL_TEST_KEEP_ROOT

assert_count() {
  local expected="$1"
  local pattern="$2"
  local actual
  actual="$(grep -Ec "$pattern" "$args_log" || true)"
  if [[ "$actual" != "$expected" ]]; then
    printf 'expected %s invocation(s) matching %q, observed %s\n' \
      "$expected" "$pattern" "$actual" >&2
    sed -n '1,20p' "$args_log" >&2
    exit 1
  fi
}

relative_stdout="$test_root/relative.stdout"
relative_stderr="$test_root/relative.stderr"
: >"$args_log"
set +e
POO_FLOW_EXTERNAL_BAZEL_OUTPUT_BASE=relative/path \
  POO_FLOW_EXTERNAL_TEST_MODE=analysis \
  bash "$subject" >"$relative_stdout" 2>"$relative_stderr"
relative_status=$?
set -e
if [[ "$relative_status" != 2 ]]; then
  printf 'relative output base returned %s instead of 2\n' "$relative_status" >&2
  exit 1
fi
grep -Fx \
  'POO_FLOW_EXTERNAL_BAZEL_OUTPUT_BASE must be an absolute path: relative/path' \
  "$relative_stderr" >/dev/null
if [[ -s "$args_log" ]]; then
  printf 'relative output base unexpectedly invoked Bazel\n' >&2
  exit 1
fi

tab=$'\t'
: >"$args_log"
POO_FLOW_EXTERNAL_TEST_MODE=analysis bash "$subject" >/dev/null 2>&1
assert_count 1 "^--output_user_root=.*/bazel-no-root-override${tab}query${tab}"
assert_count 1 "^--output_user_root=.*/bazel${tab}query${tab}"
assert_count 1 "^--output_user_root=.*/bazel${tab}build${tab}"
assert_count 0 '^--output_base='

stable_output_base="$test_root/stable output base"
: >"$args_log"
POO_FLOW_EXTERNAL_BAZEL_OUTPUT_BASE="$stable_output_base" \
  POO_FLOW_EXTERNAL_TEST_MODE=full \
  bash "$subject" >/dev/null 2>&1
test -d "$stable_output_base"
assert_count 1 "^--output_user_root=.*/bazel-no-root-override${tab}query${tab}"
assert_count 1 "^--output_base=${stable_output_base}${tab}query${tab}"
assert_count 1 "^--output_base=${stable_output_base}${tab}build${tab}"
assert_count 1 "^--output_base=${stable_output_base}${tab}test${tab}"
assert_count 1 '^--output_user_root='

printf 'external Bazel startup argument tests passed\n'
