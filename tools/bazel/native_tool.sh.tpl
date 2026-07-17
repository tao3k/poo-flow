#!/usr/bin/env bash
set -euo pipefail

native_environment=(%{NativeEnvironment})

exec %{GXPkg} env env "${native_environment[@]}" %{Tool} "$@"
