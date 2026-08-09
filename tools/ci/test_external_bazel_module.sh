#!/usr/bin/env bash
set -euo pipefail

bazel_bin="${BAZEL:-bazelisk}"
external_test_mode="${POO_FLOW_EXTERNAL_TEST_MODE:-full}"
case "$external_test_mode" in
  analysis | full) ;;
  *)
    printf 'unsupported external-module test mode: %s\n' "$external_test_mode" >&2
    exit 2
    ;;
esac
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test_root="$(cd "$(mktemp -d)" && pwd -P)"
cleanup() {
  if [[ "${POO_FLOW_EXTERNAL_TEST_KEEP_ROOT:-0}" == 1 ]]; then
    printf 'preserved external-module test root: %s\n' "$test_root" >&2
  else
    chmod -R u+rwX "$test_root" 2>/dev/null || true
    rm -rf "$test_root"
  fi
}
trap cleanup EXIT

exported_module="$test_root/poo-flow"
consumer="$test_root/consumer"
bazel_tmp="$test_root/tmp"
mkdir -p "$exported_module" "$consumer" "$bazel_tmp"
(
  cd "$repo_root"
  git ls-files -z | tar --null -T - -cf -
) | tar -xf - -C "$exported_module"

if [[ -e "$exported_module/.gerbil" ]]; then
  printf 'external POO Flow export unexpectedly contains .gerbil\n' >&2
  exit 1
fi

write_consumer_module() {
  local include_gerbil_bazel_override="$1"
  cat >"$consumer/MODULE.bazel" <<EOF
module(name = "poo_flow_external_consumer", version = "0.0.0")

bazel_dep(name = "poo_flow", version = "0.1.0")
local_path_override(module_name = "poo_flow", path = "$exported_module")
EOF

  if [[ "$include_gerbil_bazel_override" == 1 ]]; then
    cat >>"$consumer/MODULE.bazel" <<EOF
git_override(
    module_name = "gerbil_bazel",
    commit = "0d5ef5362674d788e0fc9e146b8e9e1daf78f137",
    remote = "https://github.com/tao3k/gerbil-bazel.git",
)
EOF
  fi
}

expect_missing_root_override_failure() {
  local log="$test_root/no-root-gerbil-bazel-override.log"
  write_consumer_module 0
  set +e
  (
    cd "$consumer"
    export TMPDIR="$bazel_tmp"
    "$bazel_bin" --output_user_root="$test_root/bazel-no-root-override" query \
      --lockfile_mode=off @poo_flow//scheme:compile
  ) >"$log" 2>&1
  local status=$?
  set -e
  if [[ "$status" == 0 ]]; then
    printf 'external POO Flow consumer unexpectedly succeeded without a root gerbil_bazel override\n' >&2
    exit 1
  fi
  printf 'external module requires root gerbil_bazel override until the source-package API is released\n' >&2
}

expect_missing_root_override_failure
write_consumer_module 1

cat >"$consumer/BUILD.bazel" <<'EOF'
alias(
    name = "poo_flow_compile",
    actual = "@poo_flow//scheme:compile",
)

EOF

(
  cd "$consumer"
  export TMPDIR="$bazel_tmp"
  "$bazel_bin" --output_user_root="$test_root/bazel" query \
    --lockfile_mode=off @poo_flow//scheme:compile
  if [[ "$external_test_mode" == analysis ]]; then
    "$bazel_bin" --output_user_root="$test_root/bazel" build \
      --nobuild --lockfile_mode=off //:poo_flow_compile
  else
    "$bazel_bin" --output_user_root="$test_root/bazel" build \
      --lockfile_mode=off //:poo_flow_compile
    "$bazel_bin" --output_user_root="$test_root/bazel" test \
      --lockfile_mode=off --test_output=errors \
      @poo_flow//scheme:compile_receipt_v1_test
  fi
)

if [[ "$external_test_mode" == full ]]; then
  compiled=true
  receipt_validated=true
else
  compiled=false
  receipt_validated=false
fi
printf '{"schema":"poo-flow.external-bazel-module.v1","mode":"%s","ambientGerbil":false,"configured":true,"requiresRootGerbilBazelOverride":true,"compiled":%s,"receiptValidated":%s}\n' \
  "$external_test_mode" "$compiled" "$receipt_validated"
