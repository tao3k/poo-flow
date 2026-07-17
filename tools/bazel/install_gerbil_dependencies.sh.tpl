#!/usr/bin/env bash
set -euo pipefail

workspace=${BUILD_WORKSPACE_DIRECTORY:?bazel run must provide BUILD_WORKSPACE_DIRECTORY}
native_environment=(%{NativeEnvironment})

cd "$workspace"
mkdir -p "${HOME:?}/.gerbil/pkg"

%{GXPkg} env env "${native_environment[@]}" \
  %{GXPkg} dir --add git.cons.io/mighty-gerbils/gerbil-directory
%{GXPkg} env env "${native_environment[@]}" \
  %{GXPkg} deps --install
%{GXPkg} env env "${native_environment[@]}" \
  %{GXPkg} list
