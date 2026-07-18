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
