#!/usr/bin/env bash
set -euo pipefail

workspace=${BUILD_WORKSPACE_DIRECTORY:?bazel run must provide BUILD_WORKSPACE_DIRECTORY}
native_environment=(%{NativeEnvironment})
export "${native_environment[@]}"

cd "$workspace"
gerbil_root=${GERBIL_PATH:-$workspace/.gerbil}
export GERBIL_PATH="$gerbil_root"
mkdir -p "${gerbil_root%/}/pkg"

%{GXPkg} env env "${native_environment[@]}" \
  %{GXPkg} deps --install
%{GXPkg} env env "${native_environment[@]}" \
  %{GXPkg} list
