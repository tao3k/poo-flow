#!/usr/bin/env bash
set -euo pipefail

native_environment=(%{NativeEnvironment})
export "${native_environment[@]}"

exec %{GXPkg} env env "${native_environment[@]}" "$@"
