#!/usr/bin/env bash
set -euo pipefail

output_base=
max_idle_seconds=
lockfile_mode=
for argument in "$@"; do
  case "$argument" in
    --output_base=*)
      output_base=${argument#--output_base=}
      ;;
    --max_idle_secs=*)
      max_idle_seconds=${argument#--max_idle_secs=}
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

if [[ "$max_idle_seconds" != 30 ]]; then
  printf 'performance audit requires --max_idle_secs=30\n' >&2
  exit 2
fi

command=
startup_argument_count=0
for argument in "$@"; do
  case "$argument" in
    --*)
      startup_argument_count=$((startup_argument_count + 1))
      ;;
    *)
      command=$argument
      break
      ;;
  esac
done

if [[ -z "$command" ]]; then
  printf 'Bazel command is required\n' >&2
  exit 2
fi

shift $((startup_argument_count + 1))

case "$command" in
  clean)
    mkdir -p "$output_base"
    : >"$output_base/.compile-sample-cleaned"
    ;;
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
        if [[ ! -f "$output_base/.compile-sample-cleaned" ]]; then
          printf 'dependency seed requires a preceding Bazel clean\n' >&2
          exit 2
        fi
        rm "$output_base/.compile-sample-cleaned"
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
