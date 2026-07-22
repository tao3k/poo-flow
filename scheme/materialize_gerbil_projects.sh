#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${BUILD_WORKSPACE_DIRECTORY:-}" ]]; then
  echo "POO-FLOW-BUILD-E020 BUILD_WORKSPACE_DIRECTORY is required" >&2
  exit 20
fi

runfiles_lib="bazel_tools/tools/bash/runfiles/runfiles.bash"
if [[ -n "${RUNFILES_DIR:-}" && -f "$RUNFILES_DIR/$runfiles_lib" ]]; then
  # shellcheck source=/dev/null
  source "$RUNFILES_DIR/$runfiles_lib"
elif [[ -f "$0.runfiles/$runfiles_lib" ]]; then
  # shellcheck source=/dev/null
  source "$0.runfiles/$runfiles_lib"
elif [[ -n "${RUNFILES_MANIFEST_FILE:-}" ]]; then
  runfiles_path="$(awk -v key="$runfiles_lib" '$1 == key { print $2; exit }' "$RUNFILES_MANIFEST_FILE")"
  if [[ -z "$runfiles_path" || ! -f "$runfiles_path" ]]; then
    echo "POO-FLOW-BUILD-E021 Bazel runfiles library is unavailable" >&2
    exit 21
  fi
  # shellcheck source=/dev/null
  source "$runfiles_path"
elif [[ -f "$0.runfiles_manifest" ]]; then
  runfiles_path="$(awk -v key="$runfiles_lib" '$1 == key { print $2; exit }' "$0.runfiles_manifest")"
  if [[ -z "$runfiles_path" || ! -f "$runfiles_path" ]]; then
    echo "POO-FLOW-BUILD-E021 Bazel runfiles library is unavailable" >&2
    exit 21
  fi
  # shellcheck source=/dev/null
  source "$runfiles_path"
else
  echo "POO-FLOW-BUILD-E021 Bazel runfiles are unavailable" >&2
  exit 21
fi

destination="${GERBIL_MATERIALIZE_DESTINATION:-$BUILD_WORKSPACE_DIRECTORY/.gerbil}"
mkdir -p "$destination"

for project in "$@"; do
  [[ "$project" == *.project ]] || continue
  project_root="$(rlocation "_main/$project")"
  if [[ -z "$project_root" || ! -d "$project_root/.gerbil" ]]; then
    echo "POO-FLOW-BUILD-E022 missing Gerbil project artifact: $project" >&2
    exit 22
  fi
  chmod -R u+w "$destination"
  cp -R "$project_root/.gerbil/." "$destination/"
done

chmod -R u+w "$destination"

printf '%s\n' 'POO_FLOW_RUNTIME_WASM_MATERIALIZE_RECEIPT {"status":"ok","closure":"clan->clan/poo->poo-flow"}'
