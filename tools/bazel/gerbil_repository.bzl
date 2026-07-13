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

    workspace_root = repository_ctx.path(Label("//:gerbil.pkg")).dirname
    gerbil_path = workspace_root.get_child(".gerbil")
    if not gerbil_path.exists:
        fail("workspace-local .gerbil is required; run gxpkg deps --install first")

    repository_ctx.symlink(gerbil_cc, "gerbil_cc")
    repository_ctx.symlink(gxc, "gxc")
    repository_ctx.symlink(gxi, "gxi")
    repository_ctx.symlink(gerbil_path.get_child("lib"), "gerbil_path/lib")
    repository_ctx.file("gerbil_root.marker", "workspace-local Gerbil dependencies\n")
    repository_ctx.file(
        "BUILD.bazel",
        """exports_files(
    ["gerbil_cc", "gerbil_root.marker", "gxc", "gxi"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "gerbil_path",
    srcs = glob([
        "gerbil_path/lib/clan/**",
        "gerbil_path/lib/static/clan__*",
    ]),
    visibility = ["//visibility:public"],
)
""",
    )

local_gerbil_repository = repository_rule(
    implementation = _local_gerbil_repository_impl,
    environ = ["PATH"],
    local = True,
)
