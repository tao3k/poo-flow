#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

set -euo pipefail

release_root="${1:?usage: install-gerbil-v19-release.sh RELEASE_ROOT}"
revision=2591dcd9b7c6d2c4e9dd8611a17c5b1a5d82bbdb

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)
    release_os=linux
    release_arch=x86_64
    tag=gerbil-v0.19-2591dcd9b7c6d2c4e9dd8611a17c5b1a5d82bbdb-linux-x86_64-portable-full-single-host-unlimited-patchf5cedd8168cb
    sha256=9844ba362fdf6f1c5e8a4411e462a466d52dee0d541f8e84f61091cec0e5e740
    ;;
  Darwin-arm64)
    release_os=darwin
    release_arch=aarch64
    tag=gerbil-v0.19-2591dcd9b7c6d2c4e9dd8611a17c5b1a5d82bbdb-darwin-aarch64-gcc16-arm64-aot-tools-single-host-unlimited-patchf5cedd8168cb
    sha256=8d9c88434aed6301eaebb719bf52472f05c2368eafc630e8a9f1d67cc9895a21
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
