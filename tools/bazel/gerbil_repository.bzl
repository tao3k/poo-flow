"""Local repository rule that makes the selected Gerbil toolchain explicit."""

def _shell_quote(value):
    return "'" + value.replace("'", "'\"'\"'") + "'"

def _checked_output(repository_ctx, argv, description):
    result = repository_ctx.execute(argv)
    if result.return_code != 0:
        fail("%s failed: %s" % (description, result.stderr))
    value = result.stdout.strip()
    if not value:
        fail("%s returned an empty path" % description)
    return value

def _usable_non_nix_directory(repository_ctx, value):
    return bool(value) and not value.startswith("/nix/store/") and repository_ctx.path(value).exists

def _native_environment(repository_ctx):
    host_os = repository_ctx.os.name.lower()
    if not host_os.startswith("mac"):
        return struct(
            policy = "preserve-host-environment",
            developer_dir = "",
            sdkroot = "",
        )

    xcode_select = repository_ctx.path("/usr/bin/xcode-select")
    xcrun = repository_ctx.path("/usr/bin/xcrun")
    env = repository_ctx.path("/usr/bin/env")
    if not xcode_select.exists or not xcrun.exists or not env.exists:
        fail("Darwin Gerbil builds require /usr/bin/xcode-select, /usr/bin/xcrun, and /usr/bin/env")

    inherited_developer_dir = repository_ctx.os.environ.get("DEVELOPER_DIR", "")
    inherited_sdkroot = repository_ctx.os.environ.get("SDKROOT", "")
    developer_dir = inherited_developer_dir
    inherited_developer_dir_usable = _usable_non_nix_directory(repository_ctx, developer_dir)
    if not inherited_developer_dir_usable:
        developer_dir = _checked_output(
            repository_ctx,
            [
                env,
                "-u",
                "DEVELOPER_DIR",
                "-u",
                "SDKROOT",
                xcode_select,
                "--print-path",
            ],
            "xcode-select --print-path",
        )

    sdkroot = inherited_sdkroot
    if not inherited_developer_dir_usable or not _usable_non_nix_directory(repository_ctx, sdkroot):
        sdkroot = _checked_output(
            repository_ctx,
            [
                env,
                "-u",
                "SDKROOT",
                "DEVELOPER_DIR=%s" % developer_dir,
                xcrun,
                "--sdk",
                "macosx",
                "--show-sdk-path",
            ],
            "xcrun --sdk macosx --show-sdk-path",
        )

    return struct(
        policy = "darwin-active-xcode",
        developer_dir = developer_dir,
        sdkroot = sdkroot,
    )

def _native_scheme_env_script(gxpkg, native_environment):
    lines = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
    ]
    if native_environment.policy == "darwin-active-xcode":
        lines.extend([
            "exec %s env env \\" % _shell_quote(str(gxpkg)),
            "  %s \\" % _shell_quote("DEVELOPER_DIR=%s" % native_environment.developer_dir),
            "  %s \\" % _shell_quote("SDKROOT=%s" % native_environment.sdkroot),
            "  \"$@\"",
        ])
    else:
        lines.append("exec %s env env \"$@\"" % _shell_quote(str(gxpkg)))
    return "\n".join(lines) + "\n"

def _local_gerbil_repository_impl(repository_ctx):
    gxi = repository_ctx.which("gxi")
    if gxi == None:
        fail("gxi was not found on PATH while configuring the Gerbil tool repository")
    gxc = repository_ctx.which("gxc")
    if gxc == None:
        fail("gxc was not found on PATH while configuring the Gerbil tool repository")
    gxpkg = repository_ctx.which("gxpkg")
    if gxpkg == None:
        fail("gxpkg was not found on PATH while configuring the Gerbil tool repository")
    gerbil_cc = repository_ctx.which("gcc-16")
    if gerbil_cc == None:
        gerbil_cc = repository_ctx.which("cc")
    if gerbil_cc == None:
        fail("neither gcc-16 nor cc was found for the Gerbil compiler")

    gxi_version = repository_ctx.execute([gxi, "--version"])
    if gxi_version.return_code != 0:
        fail("gxi --version failed: %s" % gxi_version.stderr)
    gxc_version = repository_ctx.execute([gxc, "--version"])
    if gxc_version.return_code != 0:
        fail("gxc --version failed: %s" % gxc_version.stderr)
    expected = repository_ctx.attr.expected_version_prefix
    if not gxi_version.stdout.startswith(expected):
        fail("gxi version mismatch: expected prefix %r, got %r" % (expected, gxi_version.stdout.strip()))
    if not gxc_version.stdout.startswith(expected):
        fail("gxc version mismatch: expected prefix %r, got %r" % (expected, gxc_version.stdout.strip()))

    native_environment = _native_environment(repository_ctx)

    repository_ctx.symlink(gerbil_cc, "gerbil_cc")
    repository_ctx.symlink(gxc, "gxc")
    repository_ctx.symlink(gxi, "gxi")
    repository_ctx.file(
        "native_scheme_env.sh",
        _native_scheme_env_script(gxpkg, native_environment),
        executable = True,
    )
    repository_ctx.file(
        "native_scheme_env.bzl",
        """def _native_scheme_env_impl(ctx):
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = executable,
        target_file = ctx.file.src,
        is_executable = True,
    )
    return [DefaultInfo(
        executable = executable,
        files = depset([executable]),
        runfiles = ctx.runfiles(files = [ctx.file.src]),
    )]

native_scheme_env = rule(
    implementation = _native_scheme_env_impl,
    attrs = {"src": attr.label(allow_single_file = True, mandatory = True)},
    executable = True,
)
""",
    )
    repository_ctx.file(
        "toolchain.receipt",
        "host_os=%s\ngxi=%s\ngxc=%s\ngxpkg=%s\nversion=%s\nnative_env_policy=%s\ndeveloper_dir=%s\nsdkroot=%s\n" % (
            repository_ctx.os.name,
            gxi,
            gxc,
            gxpkg,
            gxi_version.stdout.strip(),
            native_environment.policy,
            native_environment.developer_dir,
            native_environment.sdkroot,
        ),
    )
    repository_ctx.file(
        "BUILD.bazel",
        """load(":native_scheme_env.bzl", "native_scheme_env")

native_scheme_env(
    name = "native_scheme_env",
    src = "native_scheme_env.sh",
    visibility = ["//visibility:public"],
)

exports_files(
    ["gerbil_cc", "gxc", "gxi", "toolchain.receipt"],
    visibility = ["//visibility:public"],
)
""",
    )

local_gerbil_repository = repository_rule(
    attrs = {
        "expected_version_prefix": attr.string(mandatory = True),
    },
    implementation = _local_gerbil_repository_impl,
    environ = ["PATH", "DEVELOPER_DIR", "SDKROOT"],
    local = True,
)
