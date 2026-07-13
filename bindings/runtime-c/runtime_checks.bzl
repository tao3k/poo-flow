"""Runtime-C checks that need a small Bazel-native test launcher."""

def _runtime_leak_test_impl(ctx):
    executable = ctx.actions.declare_file(ctx.label.name + ".sh")
    binary_paths = [binary[DefaultInfo].files_to_run.executable.short_path for binary in ctx.attr.binaries]
    quoted_paths = " ".join(["\"$runfiles/%s\"" % path for path in binary_paths])
    ctx.actions.write(
        output = executable,
        content = """#!/bin/sh
set -eu
runfiles="${TEST_SRCDIR}/${TEST_WORKSPACE}"
case "$(uname -s)" in
  Darwin)
    for binary in %s; do
      leaks -atExit -- "$binary"
    done
    ;;
  *)
    if ! command -v valgrind >/dev/null 2>&1; then
      echo "no supported leak checker available" >&2
      exit 77
    fi
    for binary in %s; do
      valgrind --error-exitcode=1 --leak-check=full "$binary"
    done
    ;;
esac
""" % (quoted_paths, quoted_paths),
        is_executable = True,
    )

    runfiles = ctx.runfiles()
    for binary in ctx.attr.binaries:
        runfiles = runfiles.merge(binary[DefaultInfo].default_runfiles)
        runfiles = runfiles.merge(binary[DefaultInfo].data_runfiles)

    return [DefaultInfo(executable = executable, runfiles = runfiles)]

runtime_leak_test = rule(
    implementation = _runtime_leak_test_impl,
    test = True,
    attrs = {
        "binaries": attr.label_list(
            cfg = "target",
            mandatory = True,
        ),
    },
)

def _runtime_contract_parity_test_impl(ctx):
    executable = ctx.actions.declare_file(ctx.label.name + ".sh")
    pairs = [
        (ctx.file.generated_header, ctx.file.checked_header),
        (ctx.file.generated_vector, ctx.file.checked_vector),
        (ctx.file.generated_event_vector, ctx.file.checked_event_vector),
    ]
    commands = []
    for generated, checked in pairs:
        commands.append(
            "diff -u \"$runfiles/%s\" \"$runfiles/%s\"" % (
                checked.short_path,
                generated.short_path,
            ),
        )
    ctx.actions.write(
        output = executable,
        content = "#!/bin/sh\nset -eu\nrunfiles=\"${TEST_SRCDIR}/${TEST_WORKSPACE}\"\n%s\n" % "\n".join(commands),
        is_executable = True,
    )
    files = []
    for generated, checked in pairs:
        files.extend([generated, checked])
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = files),
    )]

runtime_contract_parity_test = rule(
    implementation = _runtime_contract_parity_test_impl,
    test = True,
    attrs = {
        "checked_event_vector": attr.label(allow_single_file = True, mandatory = True),
        "checked_header": attr.label(allow_single_file = True, mandatory = True),
        "checked_vector": attr.label(allow_single_file = True, mandatory = True),
        "generated_event_vector": attr.label(allow_single_file = True, mandatory = True),
        "generated_header": attr.label(allow_single_file = True, mandatory = True),
        "generated_vector": attr.label(allow_single_file = True, mandatory = True),
    },
)

def _runtime_gerbil_benchmark_test_impl(ctx):
    executable = ctx.actions.declare_file(ctx.label.name + ".sh")
    library = ctx.attr.library[DefaultInfo].files.to_list()[0]
    ctx.actions.write(
        output = executable,
        content = """#!/bin/sh
set -eu
runfiles="${TEST_SRCDIR}/${TEST_WORKSPACE}"
source="$runfiles/%s"
header="$runfiles/%s"
contract_header="$runfiles/%s"
library="$runfiles/%s"
gxc="$runfiles/%s"
gxi="$runfiles/%s"
gerbil_cc="$runfiles/%s"
output_root="$TEST_TMPDIR/gerbil"
mkdir -p "$output_root/lib"
compiler_dir="$TEST_TMPDIR/compiler-bin"
mkdir -p "$compiler_dir"
ln -s "$gerbil_cc" "$compiler_dir/gcc-16"
env -u CPATH -u SDKROOT -u C_INCLUDE_PATH -u LIBRARY_PATH \
  PATH="$compiler_dir:$PATH" \
  "$gxc" -O -d "$output_root/lib" \
  -cc-options "-I$(dirname "$(dirname "$header")") -I$(dirname "$(dirname "$contract_header")")" \
  -ld-options "-L$(dirname "$library") -lruntime_c_shared" \
  "$source"
env -u CPATH -u SDKROOT -u C_INCLUDE_PATH -u LIBRARY_PATH \
  DYLD_LIBRARY_PATH="$(dirname "$library")" \
  LD_LIBRARY_PATH="$(dirname "$library")" \
  GERBIL_PATH="$output_root" \
  "$gxi" -e '(begin (import :poo-flow/bindings/runtime-c/benchmarks/runtime-v0-gerbil-ffi-benchmark) (main))'
""" % (
            ctx.file.source.short_path,
            ctx.file.header.short_path,
            ctx.file.contract_header.short_path,
            library.short_path,
            ctx.file.gxc.short_path,
            ctx.file.gxi.short_path,
            ctx.file.gerbil_cc.short_path,
        ),
        is_executable = True,
    )
    runfiles = ctx.runfiles(files = [
        ctx.file.contract_header,
        ctx.file.gxc,
        ctx.file.gxi,
        ctx.file.gerbil_cc,
        ctx.file.header,
        ctx.file.package_file,
        ctx.file.source,
        library,
    ])
    return [DefaultInfo(executable = executable, runfiles = runfiles)]

runtime_gerbil_benchmark_test = rule(
    implementation = _runtime_gerbil_benchmark_test_impl,
    test = True,
    attrs = {
        "contract_header": attr.label(allow_single_file = True, mandatory = True),
        "gxc": attr.label(allow_single_file = True, cfg = "exec", mandatory = True),
        "gxi": attr.label(allow_single_file = True, cfg = "exec", mandatory = True),
        "gerbil_cc": attr.label(allow_single_file = True, cfg = "exec", mandatory = True),
        "header": attr.label(allow_single_file = True, mandatory = True),
        "library": attr.label(mandatory = True),
        "package_file": attr.label(allow_single_file = True, mandatory = True),
        "source": attr.label(allow_single_file = [".ss"], mandatory = True),
    },
)
