#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${TEST_SRCDIR:-}" && -n "${TEST_WORKSPACE:-}" ]]; then
  subject="$TEST_SRCDIR/$TEST_WORKSPACE/tools/bazel/bootstrap_gerbil_toolchain.sh"
else
  subject="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bootstrap_gerbil_toolchain.sh"
fi

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
fake_bin="$test_root/bin"
mkdir -p "$fake_bin"

cat >"$fake_bin/getconf" <<'EOF'
#!/usr/bin/env bash
printf '4\n'
EOF

cat >"$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  init)
    target="${!#}"
    mkdir -p "$target/.git"
    ;;
  remote)
    if [[ "${2:-}" == "get-url" ]]; then
      exit 1
    fi
    ;;
  fetch)
    ;;
  checkout)
    printf '#!/usr/bin/env bash\nexit 0\n' > configure
    chmod +x configure
    ;;
  *)
    printf 'unexpected fake git command: %s\n' "$*" >&2
    exit 64
    ;;
esac
EOF

cat >"$fake_bin/make" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ " $* " == *" install "* ]]; then
  mkdir -p "$GERBIL_PREFIX/bin"
  printf '#!/usr/bin/env bash\nprintf "Gerbil v0.18.2 test\\n"\n' \
    >"$GERBIL_PREFIX/bin/gxi"
  chmod +x "$GERBIL_PREFIX/bin/gxi"
fi
EOF

cat >"$fake_bin/ccache" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --print-stats)
    printf 'cache_miss 1\ndirect_cache_hit 0\npreprocessed_cache_hit 0\n'
    ;;
  --show-stats)
    printf 'Cacheable calls: 1 / 1\n'
    ;;
  --set-config=* | --zero-stats)
    ;;
  *)
    printf 'unexpected fake ccache command: %s\n' "$*" >&2
    exit 64
    ;;
esac
EOF

chmod +x "$fake_bin/getconf" "$fake_bin/git" "$fake_bin/make" "$fake_bin/ccache"

source_root="$test_root/source"
prefix_root="$test_root/prefix"
PATH="$fake_bin:$PATH" \
GERBIL_REF=test-ref \
GERBIL_SRC="$source_root" \
GERBIL_PREFIX="$prefix_root" \
GERBIL_SOURCE_URL=https://example.invalid/gerbil.git \
GERBIL_ARCH_PROFILE=portable \
GERBIL_REQUIRE_CCACHE=1 \
GERBIL_BOOTSTRAP_CACHE_MODE=cold \
CCACHE_DIR="$test_root/ccache" \
CCACHE_MAXSIZE=64M \
bash "$subject" >"$test_root/stdout"

state_receipt="$source_root/.poo-flow-bootstrap-state.json"
final_receipt="$prefix_root/bootstrap.receipt.json"
test -f "$state_receipt"
test -f "$final_receipt"

jq -e '
  .schema == "poo-flow.gerbil-bootstrap-state.v1" and
  .status == "success" and
  .phase == "complete" and
  .cacheMode == "cold" and
  .buildCores == 4 and
  ([.phases[].phase] == ["fetch", "configure", "build", "install", "verify", "receipt"]) and
  (all(.phases[]; .status == "success" and .exitCode == 0 and .elapsedMs >= 0))
' "$state_receipt" >/dev/null

jq -e '
  .schema == "poo-flow.gerbil-toolchain-bootstrap-receipt.v1" and
  .outcome == "ready" and
  .bootstrap_cache_mode == "cold" and
  .build_cores == 4 and
  .ccache.compiler_activity == 1 and
  ([.phases[].phase] == ["fetch", "configure", "build", "install", "verify"]) and
  (all(.phases[]; .status == "success" and .exitCode == 0 and .elapsedMs >= 0))
' "$final_receipt" >/dev/null

set +e
GERBIL_REF=test-ref \
GERBIL_SRC="$test_root/invalid-source" \
GERBIL_PREFIX="$test_root/invalid-prefix" \
GERBIL_BOOTSTRAP_CACHE_MODE=invalid \
bash "$subject" >"$test_root/invalid.stdout" 2>"$test_root/invalid.stderr"
invalid_status="$?"
set -e
test "$invalid_status" -eq 64
grep -F 'unsupported Gerbil bootstrap cache mode: invalid' "$test_root/invalid.stderr" >/dev/null

printf 'bootstrap Gerbil toolchain receipt tests: PASS\n'
