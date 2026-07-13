"""Local repository rule that makes the selected Gerbil interpreter explicit."""

def _local_gerbil_repository_impl(repository_ctx):
    gxi = repository_ctx.which("gxi")
    if gxi == None:
        fail("gxi was not found on PATH while configuring the Gerbil tool repository")
    gxc = repository_ctx.which("gxc")
    if gxc == None:
        fail("gxc was not found on PATH while configuring the Gerbil tool repository")
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

    repository_ctx.symlink(gerbil_cc, "gerbil_cc")
    repository_ctx.symlink(gxc, "gxc")
    repository_ctx.symlink(gxi, "gxi")
    repository_ctx.file(
        "toolchain.receipt",
        "gxi=%s\\ngxc=%s\\nversion=%s\\n" % (
            gxi,
            gxc,
            gxi_version.stdout.strip(),
        ),
    )
    repository_ctx.file(
        "BUILD.bazel",
        """exports_files(
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
    environ = ["PATH"],
    local = True,
)
