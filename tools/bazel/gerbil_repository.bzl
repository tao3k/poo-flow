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

    repository_ctx.symlink(gerbil_cc, "gerbil_cc")
    repository_ctx.symlink(gxc, "gxc")
    repository_ctx.symlink(gxi, "gxi")
    repository_ctx.file(
        "BUILD.bazel",
        """exports_files(
    ["gerbil_cc", "gxc", "gxi"],
    visibility = ["//visibility:public"],
)
""",
    )

local_gerbil_repository = repository_rule(
    implementation = _local_gerbil_repository_impl,
    environ = ["PATH"],
    local = True,
)
