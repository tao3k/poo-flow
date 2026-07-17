"""Provider and resolution helpers for registered Gerbil toolchains."""

GERBIL_TOOLCHAIN_TYPE = "//tools/bazel:gerbil_toolchain_type"

GerbilToolchainInfo = provider(
    doc = "Host Gerbil tools with system-normalized execution wrappers.",
    fields = {
        "gerbil_cc": "Native compiler file selected for Gerbil.",
        "gerbil_as": "Native assembler file selected for Gerbil.",
        "gerbil_ld": "Native linker file selected for Gerbil.",
        "gxc": "FilesToRunProvider for the normalized gxc wrapper.",
        "gxc_runfiles": "Runfiles for the normalized gxc wrapper.",
        "gxi": "FilesToRunProvider for the normalized gxi wrapper.",
        "gxi_runfiles": "Runfiles for the normalized gxi wrapper.",
        "gxpkg": "FilesToRunProvider for the normalized gxpkg wrapper.",
        "gxpkg_runfiles": "Runfiles for the normalized gxpkg wrapper.",
        "gxtest": "FilesToRunProvider for the normalized gxtest wrapper.",
        "gxtest_runfiles": "Runfiles for the normalized gxtest wrapper.",
        "native_scheme_env": "FilesToRunProvider for arbitrary normalized commands.",
        "native_scheme_env_runfiles": "Runfiles for the normalized command wrapper.",
        "dependency_libraries": "Compiled external Gerbil dependency files.",
        "dependency_library_root": "Marker whose parent is the dependency library root.",
        "receipt": "Canonical JSON host-toolchain receipt.",
        "runfiles": "Complete runfiles closure for the normalized tools.",
        "system_memory_bytes": "Positive host physical-memory byte count.",
    },
)

def resolved_gerbil_toolchain(ctx):
    """Return the Gerbil capability selected for the current execution platform."""
    return ctx.toolchains[GERBIL_TOOLCHAIN_TYPE].gerbil

def _gerbil_toolchain_impl(ctx):
    executable_targets = [
        ctx.attr.gxc,
        ctx.attr.gxi,
        ctx.attr.gxpkg,
        ctx.attr.gxtest,
        ctx.attr.native_scheme_env,
    ]
    runfiles = ctx.runfiles(
        files = [
            ctx.file.dependency_library_root,
            ctx.file.gerbil_as,
            ctx.file.gerbil_cc,
            ctx.file.gerbil_ld,
            ctx.file.receipt,
        ],
        transitive_files = ctx.attr.dependency_libraries[DefaultInfo].files,
    )
    for target in executable_targets:
        runfiles = runfiles.merge(target[DefaultInfo].default_runfiles)

    files_to_run = [target[DefaultInfo].files_to_run for target in executable_targets]
    toolchain_info = GerbilToolchainInfo(
        dependency_libraries = ctx.attr.dependency_libraries[DefaultInfo].files,
        dependency_library_root = ctx.file.dependency_library_root,
        gerbil_as = ctx.file.gerbil_as,
        gerbil_cc = ctx.file.gerbil_cc,
        gerbil_ld = ctx.file.gerbil_ld,
        gxc = ctx.attr.gxc[DefaultInfo].files_to_run,
        gxc_runfiles = ctx.attr.gxc[DefaultInfo].default_runfiles,
        gxi = ctx.attr.gxi[DefaultInfo].files_to_run,
        gxi_runfiles = ctx.attr.gxi[DefaultInfo].default_runfiles,
        gxpkg = ctx.attr.gxpkg[DefaultInfo].files_to_run,
        gxpkg_runfiles = ctx.attr.gxpkg[DefaultInfo].default_runfiles,
        gxtest = ctx.attr.gxtest[DefaultInfo].files_to_run,
        gxtest_runfiles = ctx.attr.gxtest[DefaultInfo].default_runfiles,
        native_scheme_env = ctx.attr.native_scheme_env[DefaultInfo].files_to_run,
        native_scheme_env_runfiles = ctx.attr.native_scheme_env[DefaultInfo].default_runfiles,
        receipt = ctx.file.receipt,
        runfiles = runfiles,
        system_memory_bytes = ctx.attr.system_memory_bytes,
    )
    default_info = DefaultInfo(
        files = depset(
            direct = [
                ctx.file.gerbil_cc,
                ctx.file.gerbil_as,
                ctx.file.gerbil_ld,
                ctx.file.receipt,
            ] + [tool.executable for tool in files_to_run],
            transitive = [ctx.attr.dependency_libraries[DefaultInfo].files],
        ),
        runfiles = runfiles,
    )
    return [
        default_info,
        toolchain_info,
        platform_common.ToolchainInfo(gerbil = toolchain_info),
    ]

gerbil_toolchain = rule(
    implementation = _gerbil_toolchain_impl,
    attrs = {
        "dependency_libraries": attr.label(mandatory = True),
        "dependency_library_root": attr.label(allow_single_file = True, mandatory = True),
        "gerbil_as": attr.label(allow_single_file = True, mandatory = True),
        "gerbil_cc": attr.label(allow_single_file = True, mandatory = True),
        "gerbil_ld": attr.label(allow_single_file = True, mandatory = True),
        "gxc": attr.label(cfg = "exec", executable = True, mandatory = True),
        "gxi": attr.label(cfg = "exec", executable = True, mandatory = True),
        "gxpkg": attr.label(cfg = "exec", executable = True, mandatory = True),
        "gxtest": attr.label(cfg = "exec", executable = True, mandatory = True),
        "native_scheme_env": attr.label(cfg = "exec", executable = True, mandatory = True),
        "receipt": attr.label(allow_single_file = [".json"], mandatory = True),
        "system_memory_bytes": attr.string(mandatory = True),
    },
)
