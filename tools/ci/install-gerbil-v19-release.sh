#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

set -euo pipefail

release_root="${1:?usage: install-gerbil-v19-release.sh RELEASE_ROOT}"
revision=d801e7a1c7f77df421f638e62aaebe370f193c97

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)
    release_os=linux
    release_arch=x86_64
    tag=gerbil-v0.19-d801e7a1c7f77df421f638e62aaebe370f193c97-linux-x86_64-portable-full-single-host-unlimited-patch8bbb52add2b9
    sha256=44da3780cf450a6b747bf327b837696e0f99d5177a5a8046f9f65cd54e126745
    ;;
  Darwin-arm64)
    release_os=darwin
    release_arch=aarch64
    tag=gerbil-v0.19-d801e7a1c7f77df421f638e62aaebe370f193c97-darwin-aarch64-gcc16-arm64-aot-tools-single-host-unlimited-patch16675e99f856
    sha256=c6a4bc783311670ea56d0c384ebdffae491112ba9bdd253cd763a260a5793d6b
    ;;
  *)
    printf 'unsupported Gerbil release host: %s-%s\n' "$(uname -s)" "$(uname -m)" >&2
    exit 64
    ;;
esac

archive="$tag.tar.gz"
download="${RUNNER_TEMP:?}/$archive"
mkdir -p "$release_root"
curl --fail --location --retry 3 --output "$download" \
  "https://github.com/tao3k/gerbil-bazel/releases/download/$tag/$archive"
echo "$sha256  $download" | shasum -a 256 --check
tar -xzf "$download" -C "$release_root" --strip-components=1

jq -e --arg revision "$revision" --arg os "$release_os" --arg arch "$release_arch" \
  '.schema == "gerbil-bazel.toolchain-release.v1" and
   .upstreamRevision == $revision and
   .platform.os == $os and .platform.arch == $arch' \
  "$release_root/gerbil-toolchain-release.json" >/dev/null

source "$release_root/activate"
echo "$GERBIL_PREFIX/bin" >> "${GITHUB_PATH:?}"
{
  echo "GERBIL_PREFIX=$GERBIL_PREFIX"
  echo "GERBIL_HOME=$GERBIL_HOME"
  echo "GAMBOPT=$GAMBOPT"
} >> "${GITHUB_ENV:?}"

"$GERBIL_PREFIX/bin/gerbil" --version
"$GERBIL_PREFIX/bin/gerbil" interactive -e '(displayln "gerbil-ready")'
