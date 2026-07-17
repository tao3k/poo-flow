"""Bazel orchestration rules for the canonical POO Flow Scheme project."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")
load(":gerbil_toolchain.bzl", "GerbilToolchainInfo")

GerbilProjectInfo = provider(
    doc = "Declared outputs from one canonical build.ss compile action.",
    fields = {
        "compiled_root": "Tree artifact containing the isolated GERBIL_PATH.",
        "log": "Complete Building Framework compile log.",
        "receipt": "Canonical Scheme-owned project build JSON receipt.",
    },
)

def _gerbil_project_compile_impl(ctx):
    toolchain = ctx.attr.gerbil_toolchain[GerbilToolchainInfo]
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
            "POO_FLOW_BUILD_SYSTEM_MEMORY_BYTES": toolchain.system_memory_bytes,
        },
        inputs = depset(
            direct = [
                ctx.file.build_script,
                toolchain.dependency_library_root,
                toolchain.gerbil_as,
                toolchain.gerbil_cc,
                toolchain.gerbil_ld,
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
        "gerbil_toolchain": attr.label(
            default = Label("@local_gerbil//:toolchain"),
            providers = [GerbilToolchainInfo],
        ),
        "srcs": attr.label(mandatory = True),
        "_runner": attr.label(
            cfg = "exec",
            default = Label("//tools/bazel:run_scheme_project"),
            executable = True,
        ),
    },
)

def gerbil_project_test(name, test_root, size = "medium"):
    """Declares one gxtest root against the isolated compiled project tree."""
    sh_test(
        name = name,
        srcs = ["//tools/bazel:run_scheme_tests.sh"],
        args = [
            "$(rootpath @local_gerbil//:gxtest)",
            "$(rootpath @local_gerbil//:gxi)",
            "$(rootpath @local_gerbil//:gxc)",
            "$(rootpath @local_gerbil//:gxpkg)",
            "$(rootpath @local_gerbil//:gerbil_cc)",
            "$(rootpath @local_gerbil//:gerbil_as)",
            "$(rootpath @local_gerbil//:gerbil_ld)",
            "$(rootpath @local_gerbil//:dependency_library_root)",
            "$(rootpath :compiled_root)",
            "$(rootpath //:%s)" % test_root,
        ],
        data = [
            "//:scheme_test_sources",
            "//:%s" % test_root,
            ":compiled_root",
            "@local_gerbil//:dependency_library_root",
            "@local_gerbil//:gerbil_as",
            "@local_gerbil//:gerbil_cc",
            "@local_gerbil//:gerbil_ld",
            "@local_gerbil//:gxc",
            "@local_gerbil//:gxi",
            "@local_gerbil//:gxpkg",
            "@local_gerbil//:gxtest",
            "@local_gerbil//:toolchain",
        ],
        size = size,
        tags = ["exclusive"],
    )
