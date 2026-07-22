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

cat >"$consumer/MODULE.bazel" <<EOF
module(name = "poo_flow_external_consumer", version = "0.0.0")

bazel_dep(name = "poo_flow", version = "0.1.0")
local_path_override(module_name = "poo_flow", path = "$exported_module")

git_override(
    module_name = "gerbil_bazel",
    commit = "faa83024b7fa6f681bf3bd0da57376e05fb9a2f7",
    remote = "https://github.com/tao3k/gerbil-bazel.git",
)
EOF

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
printf '{"schema":"poo-flow.external-bazel-module.v1","mode":"%s","ambientGerbil":false,"configured":true,"compiled":%s,"receiptValidated":%s}\n' \
  "$external_test_mode" "$compiled" "$receipt_validated"
