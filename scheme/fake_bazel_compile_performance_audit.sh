#!/usr/bin/env bash
set -euo pipefail

output_base=
lockfile_mode=
for argument in "$@"; do
  case "$argument" in
    --output_base=*)
      output_base=${argument#--output_base=}
      ;;
    --lockfile_mode=*)
      lockfile_mode=${argument#--lockfile_mode=}
      ;;
  esac
done

if [[ -z "$output_base" ]]; then
  printf 'fake Bazel requires --output_base\n' >&2
  exit 2
fi

if [[ "$lockfile_mode" != off ]]; then
  printf 'performance audit requires --lockfile_mode=off\n' >&2
  exit 2
fi

command=${2:?Bazel command is required}
shift 2

case "$command" in
  build)
    symlink_prefix=
    bep_path=
    target=
    for argument in "$@"; do
      case "$argument" in
        --symlink_prefix=*)
          symlink_prefix=${argument#--symlink_prefix=}
          ;;
        --build_event_json_file=*)
          bep_path=${argument#--build_event_json_file=}
          ;;
        //scheme:*|@local_gerbil//*)
          target=$argument
          ;;
      esac
    done

    case "$target" in
      @local_gerbil//:native_abi.txt)
        mkdir -p "$output_base/execroot/external/fake"
        printf 'fixture-native-abi\n' \
          >"$output_base/execroot/external/fake/native_abi.txt"
        ;;
      //scheme:compile_receipt)
        if [[ -n "$bep_path" ]]; then
          : >"$bep_path"
        else
          mkdir -p "${symlink_prefix}bin/scheme"
          cp "$PWD/compile.receipt.json" \
            "${symlink_prefix}bin/scheme/compile.receipt.json"
        fi
        ;;
      //scheme:dependency_packages)
        ;;
      *)
        printf 'unexpected fake Bazel build target: %s\n' "$target" >&2
        exit 2
        ;;
    esac
    ;;
  cquery)
    printf 'external/fake/native_abi.txt\n'
    ;;
  info)
    info_key=
    for argument in "$@"; do
      case "$argument" in
        --*)
          ;;
        *)
          info_key=$argument
          break
          ;;
      esac
    done
    if [[ "$info_key" != "execution_root" ]]; then
      printf 'unexpected fake Bazel info key: %s\n' "$info_key" >&2
      exit 2
    fi
    printf '%s\n' "$output_base/execroot"
    ;;
  *)
    printf 'unexpected fake Bazel command: %s\n' "$command" >&2
    exit 2
    ;;
esac
