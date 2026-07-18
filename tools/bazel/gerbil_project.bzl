"""Bazel orchestration rules for the canonical POO Flow Scheme project."""

load(
    ":gerbil_toolchain.bzl",
    "GERBIL_TOOLCHAIN_TYPE",
    "resolved_gerbil_toolchain",
)

GerbilProjectInfo = provider(
    doc = "Declared outputs from one canonical build.ss compile action.",
    fields = {
        "compiled_root": "Tree artifact containing the isolated GERBIL_PATH.",
        "log": "Complete Building Framework compile log.",
        "receipt": "Canonical Scheme-owned project build JSON receipt.",
    },
)

GerbilProjectionInfo = provider(
    doc = "One projection artifact derived from a canonical Gerbil project.",
    fields = {
        "artifact": "Packaged no-Gerbil projection artifact.",
        "project": "Canonical Gerbil project provider used by the action.",
    },
)

def _shell_quote(value):
    return "'" + value.replace("'", "'\"'\"'") + "'"

def _gerbil_project_compile_impl(ctx):
    toolchain = resolved_gerbil_toolchain(ctx)
    compiled_root = ctx.actions.declare_directory(ctx.label.name + ".gerbil")
    receipt = ctx.actions.declare_file(ctx.label.name + ".receipt.json")
    log = ctx.actions.declare_file(ctx.label.name + ".log")

    arguments = ctx.actions.args()
    arguments.add(toolchain.gxi.executable.path)
    arguments.add(toolchain.gxc.executable.path)
    arguments.add(toolchain.gxpkg.executable.path)
    arguments.add(toolchain.gerbil_cc.path)
    arguments.add(toolchain.gerbil_as.path)
    arguments.add(toolchain.gerbil_ld.path)
    arguments.add(toolchain.dependency_library_root.path)
    arguments.add(ctx.file.build_script.path)
    arguments.add(compiled_root.path)
    arguments.add(receipt.path)
    arguments.add(log.path)
    arguments.add_all(ctx.attr.compile_args)

    ctx.actions.run(
        arguments = [arguments],
        executable = ctx.executable._runner,
        env = {
            "POO_FLOW_GERBIL_NATIVE_ABI": toolchain.native_abi_fingerprint,
        },
        inputs = depset(
            direct = [
                ctx.file.build_script,
                toolchain.dependency_library_root,
                toolchain.gerbil_as,
                toolchain.gerbil_cc,
                toolchain.gerbil_ld,
                toolchain.native_abi_fingerprint_file,
            ],
            transitive = [
                ctx.attr.srcs[DefaultInfo].files,
                toolchain.dependency_libraries,
            ],
        ),
        mnemonic = "GerbilProjectCompile",
        outputs = [compiled_root, receipt, log],
        progress_message = "Compiling canonical Gerbil project %{label}",
        tools = [
            toolchain.gxi,
            toolchain.gxc,
            toolchain.gxpkg,
        ],
    )

    return [
        DefaultInfo(files = depset([compiled_root, receipt, log])),
        GerbilProjectInfo(
            compiled_root = compiled_root,
            log = log,
            receipt = receipt,
        ),
        OutputGroupInfo(
            compiled_root = depset([compiled_root]),
            log = depset([log]),
            receipt = depset([receipt]),
        ),
    ]

gerbil_project_compile = rule(
    implementation = _gerbil_project_compile_impl,
    attrs = {
        "build_script": attr.label(
            allow_single_file = [".ss"],
            mandatory = True,
        ),
        "compile_args": attr.string_list(),
        "srcs": attr.label(mandatory = True),
        "_runner": attr.label(
            cfg = "exec",
            default = Label("//tools/bazel:run_scheme_project"),
            executable = True,
        ),
    },
    toolchains = [GERBIL_TOOLCHAIN_TYPE],
)

def _gerbil_project_dev_runfile(file):
    return '"$runfiles_workspace/%s"' % file.short_path

def _gerbil_project_dev_command(command, arguments, execute):
    prefix = "exec " if execute else ""
    if not arguments:
        return [prefix + command]

    lines = [prefix + command + " \\"]
    for index, argument in enumerate(arguments):
        continuation = " \\" if index < len(arguments) - 1 else ""
        lines.append("  %s%s" % (argument, continuation))
    return lines

def _gerbil_project_dev_impl(ctx):
    toolchain = resolved_gerbil_toolchain(ctx)
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    output_root = ctx.attr.output_root
    if (not output_root or
        output_root.startswith("/") or
        output_root == ".." or
        output_root.startswith("../") or
        "/../" in output_root or
        output_root.endswith("/..")):
        fail("output_root must be a workspace-relative path without parent traversal")

    compile_arguments = [
        _gerbil_project_dev_runfile(toolchain.gxi.executable),
        _gerbil_project_dev_runfile(toolchain.gxc.executable),
        _gerbil_project_dev_runfile(toolchain.gxpkg.executable),
        _gerbil_project_dev_runfile(toolchain.gerbil_cc),
        _gerbil_project_dev_runfile(toolchain.gerbil_as),
        _gerbil_project_dev_runfile(toolchain.gerbil_ld),
        _gerbil_project_dev_runfile(toolchain.dependency_library_root),
        _gerbil_project_dev_runfile(ctx.file.build_script),
        '"$output_root"',
        '"$receipt"',
        '"$log"',
    ] + [_shell_quote(argument) for argument in ctx.attr.compile_args]

    lines = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        'runfiles_root="${RUNFILES_DIR:-${BASH_SOURCE[0]}.runfiles}"',
        'runfiles_workspace="$runfiles_root/%s"' % ctx.workspace_name,
        'workspace="${BUILD_WORKSPACE_DIRECTORY:?bazel run must provide BUILD_WORKSPACE_DIRECTORY}"',
        'output_root="${POO_FLOW_BAZEL_DEV_ROOT:-$workspace/%s}"' % output_root,
        'receipt="$output_root/compile.receipt.json"',
        'log="$output_root/compile.log"',
        'mkdir -p "$output_root"',
        'cd "$workspace"',
        "export POO_FLOW_GERBIL_NATIVE_ABI=%s" % _shell_quote(toolchain.native_abi_fingerprint),
    ]

    test_root = ctx.file.test_root
    lines.extend(_gerbil_project_dev_command(
        _gerbil_project_dev_runfile(ctx.executable._runner),
        compile_arguments,
        not test_root,
    ))
    if test_root:
        lines.extend([
            'export TEST_SRCDIR="$runfiles_root"',
            "export TEST_WORKSPACE=%s" % _shell_quote(ctx.workspace_name),
            'export TEST_TMPDIR="${TEST_TMPDIR:-$output_root/.test-tmp}"',
            'mkdir -p "$TEST_TMPDIR"',
        ])
        lines.extend(_gerbil_project_dev_command(
            _gerbil_project_dev_runfile(ctx.file._test_runner),
            [
                _gerbil_project_dev_runfile(toolchain.gxtest.executable),
                _gerbil_project_dev_runfile(toolchain.gxi.executable),
                _gerbil_project_dev_runfile(toolchain.gxc.executable),
                _gerbil_project_dev_runfile(toolchain.gxpkg.executable),
                _gerbil_project_dev_runfile(toolchain.gerbil_cc),
                _gerbil_project_dev_runfile(toolchain.gerbil_as),
                _gerbil_project_dev_runfile(toolchain.gerbil_ld),
                _gerbil_project_dev_runfile(toolchain.dependency_library_root),
                '"$output_root"',
                _gerbil_project_dev_runfile(test_root),
            ],
            True,
        ))

    ctx.actions.write(
        content = "\n".join(lines) + "\n",
        is_executable = True,
        output = launcher,
    )

    runfiles_files = [
        ctx.file.build_script,
        ctx.executable._runner,
        ctx.file._test_runner,
        toolchain.dependency_library_root,
        toolchain.gerbil_as,
        toolchain.gerbil_cc,
        toolchain.gerbil_ld,
        toolchain.native_abi_fingerprint_file,
    ]
    if test_root:
        runfiles_files.append(test_root)

    runfiles = ctx.runfiles(
        files = runfiles_files,
        transitive_files = depset(transitive = [
            ctx.attr.srcs[DefaultInfo].files,
            toolchain.dependency_libraries,
        ]),
    ).merge(toolchain.runfiles)
    return [DefaultInfo(executable = launcher, runfiles = runfiles)]

gerbil_project_dev = rule(
    implementation = _gerbil_project_dev_impl,
    attrs = {
        "build_script": attr.label(
            allow_single_file = [".ss"],
            mandatory = True,
        ),
        "compile_args": attr.string_list(),
        "output_root": attr.string(default = ".gerbil"),
        "srcs": attr.label(mandatory = True),
        "test_root": attr.label(allow_single_file = [".ss"]),
        "_runner": attr.label(
            cfg = "exec",
            default = Label("//tools/bazel:run_scheme_project"),
            executable = True,
        ),
        "_test_runner": attr.label(
            allow_single_file = True,
            default = Label("//tools/bazel:run_scheme_tests.sh"),
        ),
    },
    executable = True,
    toolchains = [GERBIL_TOOLCHAIN_TYPE],
)

def _gerbil_project_projection_impl(ctx):
    toolchain = resolved_gerbil_toolchain(ctx)
    project = ctx.attr.project[GerbilProjectInfo]
    artifact = ctx.actions.declare_file(ctx.attr.output_name)

    arguments = ctx.actions.args()
    arguments.add("--gxi")
    arguments.add(toolchain.gxi.executable.path)
    arguments.add("--compiled-root")
    arguments.add(project.compiled_root.path)
    arguments.add("--dependency-root-marker")
    arguments.add(toolchain.dependency_library_root.path)
    arguments.add("--projection-source")
    arguments.add(ctx.file.projection_source.path)
    arguments.add("--source")
    arguments.add(ctx.file.source.path)
    arguments.add("--output")
    arguments.add(artifact.path)

    ctx.actions.run(
        arguments = [arguments],
        executable = ctx.attr._exporter[DefaultInfo].files_to_run,
        env = {
            "POO_FLOW_GERBIL_NATIVE_ABI": toolchain.native_abi_fingerprint,
        },
        inputs = depset(
            direct = [
                ctx.file.projection_source,
                ctx.file.source,
                project.compiled_root,
                toolchain.dependency_library_root,
                toolchain.native_abi_fingerprint_file,
            ],
            transitive = [toolchain.dependency_libraries],
        ),
        mnemonic = "GerbilProjectProjection",
        outputs = [artifact],
        progress_message = "Projecting canonical Gerbil module %{label}",
        tools = [toolchain.gxi],
    )

    return [
        DefaultInfo(files = depset([artifact])),
        GerbilProjectionInfo(
            artifact = artifact,
            project = project,
        ),
    ]

gerbil_project_projection = rule(
    implementation = _gerbil_project_projection_impl,
    attrs = {
        "output_name": attr.string(mandatory = True),
        "project": attr.label(
            mandatory = True,
            providers = [GerbilProjectInfo],
        ),
        "projection_source": attr.label(
            allow_single_file = [".ss"],
            mandatory = True,
        ),
        "source": attr.label(
            allow_single_file = [".ss"],
            mandatory = True,
        ),
        "_exporter": attr.label(
            cfg = "exec",
            default = Label("//tools/bazel:scheme_projection_artifact_tool"),
            executable = True,
        ),
    },
    toolchains = [GERBIL_TOOLCHAIN_TYPE],
)

def _gerbil_project_test_impl(ctx):
    toolchain = resolved_gerbil_toolchain(ctx)
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    test_arguments = [
        toolchain.gxtest.executable.short_path,
        toolchain.gxi.executable.short_path,
        toolchain.gxc.executable.short_path,
        toolchain.gxpkg.executable.short_path,
        toolchain.gerbil_cc.short_path,
        toolchain.gerbil_as.short_path,
        toolchain.gerbil_ld.short_path,
        toolchain.dependency_library_root.short_path,
        ctx.file.compiled_root.short_path,
        ctx.file.test_root.short_path,
    ]
    launcher_lines = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "runfiles_workspace=${TEST_SRCDIR:?}/${TEST_WORKSPACE:?}",
        "runner=%s" % _shell_quote(ctx.file._test_runner.short_path),
        "exec \"$runfiles_workspace/$runner\" \\",
    ]
    for index, argument in enumerate(test_arguments):
        continuation = " \\" if index < len(test_arguments) - 1 else ""
        launcher_lines.append("  %s%s" % (_shell_quote(argument), continuation))
    ctx.actions.write(
        content = "\n".join(launcher_lines) + "\n",
        is_executable = True,
        output = launcher,
    )

    runfiles = ctx.runfiles(
        files = [
            ctx.file._test_runner,
            ctx.file.compiled_root,
            ctx.file.test_root,
        ],
        transitive_files = depset(transitive = [
            ctx.attr.srcs[DefaultInfo].files,
            toolchain.dependency_libraries,
        ]),
    ).merge(toolchain.runfiles)
    return [
        DefaultInfo(
            executable = launcher,
            runfiles = runfiles,
        ),
    ]

_gerbil_project_test = rule(
    implementation = _gerbil_project_test_impl,
    attrs = {
        "compiled_root": attr.label(allow_single_file = True, mandatory = True),
        "srcs": attr.label(mandatory = True),
        "test_root": attr.label(allow_single_file = [".ss"], mandatory = True),
        "_test_runner": attr.label(
            allow_single_file = True,
            default = Label("//tools/bazel:run_scheme_tests.sh"),
        ),
    },
    test = True,
    toolchains = [GERBIL_TOOLCHAIN_TYPE],
)

def gerbil_project_test(
        name,
        test_root,
        compiled_root = ":compiled_root",
        srcs = "//:scheme_test_sources",
        tags = None,
        **kwargs):
    """Declare one exclusive gxtest root through the registered toolchain."""
    declared_tags = [] if tags == None else tags
    _gerbil_project_test(
        name = name,
        compiled_root = compiled_root,
        srcs = srcs,
        tags = ["exclusive"] + declared_tags,
        test_root = test_root,
        **kwargs
    )
