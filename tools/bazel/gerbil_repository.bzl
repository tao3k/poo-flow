"""Declare the host Gerbil toolchain used by Bazel outer orchestration."""

load(":host_system.bzl", "resolve_host_environment")

_TOOL_CANDIDATES = {
    "gerbil_cc": ["gcc-16", "cc"],
    "gxc": ["gxc"],
    "gxi": ["gxi"],
    "gxpkg": ["gxpkg"],
}

_VERSIONED_TOOLS = ["gxi", "gxc"]

def _shell_quote(value):
    return "'" + value.replace("'", "'\"'\"'") + "'"

def _resolve_tools(repository_ctx):
    tools = {}
    for name, candidates in _TOOL_CANDIDATES.items():
        for candidate in candidates:
            path = repository_ctx.which(candidate)
            if path != None:
                tools[name] = path
                break
        if name not in tools:
            fail("%s was not found on PATH; tried %s" % (name, ", ".join(candidates)))
    return tools

def _read_versions(repository_ctx, tools, expected_prefix):
    versions = {}
    for name in _VERSIONED_TOOLS:
        result = repository_ctx.execute([tools[name], "--version"])
        if result.return_code != 0:
            fail("%s --version failed: %s" % (name, result.stderr))
        version = result.stdout.strip()
        if not version.startswith(expected_prefix):
            fail("%s version mismatch: expected prefix %r, got %r" % (name, expected_prefix, version))
        versions[name] = version
    return versions

def _environment_arguments(environment):
    return " ".join([
        _shell_quote("%s=%s" % (name, environment[name]))
        for name in sorted(environment.keys())
    ])

def _tool_paths(tools):
    return {name: str(path) for name, path in tools.items()}

def _local_gerbil_repository_impl(repository_ctx):
    tools = _resolve_tools(repository_ctx)
    versions = _read_versions(
        repository_ctx,
        tools,
        repository_ctx.attr.expected_version_prefix,
    )
    native_environment = resolve_host_environment(repository_ctx)

    for name, path in tools.items():
        repository_ctx.symlink(path, name)

    repository_ctx.template(
        "native_scheme_env.sh",
        repository_ctx.attr.native_runner_template,
        substitutions = {
            "%{GXPkg}": _shell_quote(str(tools["gxpkg"])),
            "%{NativeEnvironment}": _environment_arguments(native_environment.environment),
        },
        executable = True,
    )
    repository_ctx.file(
        "toolchain.receipt.json",
        json.encode_indent({
            "schema": "poo-flow.bazel.local-gerbil-toolchain-receipt.v1",
            "host_os": repository_ctx.os.name,
            "system": native_environment.system,
            "environment_policy": native_environment.policy,
            "environment": native_environment.environment,
            "tools": _tool_paths(tools),
            "versions": versions,
        }, indent = "  ") + "\n",
    )
    repository_ctx.template(
        "BUILD.bazel",
        repository_ctx.attr.build_file_template,
    )

local_gerbil_repository = repository_rule(
    attrs = {
        "build_file_template": attr.label(
            allow_single_file = True,
            default = Label("//tools/bazel:local_gerbil.BUILD.bazel.tpl"),
        ),
        "expected_version_prefix": attr.string(mandatory = True),
        "native_runner_template": attr.label(
            allow_single_file = True,
            default = Label("//tools/bazel:native_scheme_env.sh.tpl"),
        ),
    },
    implementation = _local_gerbil_repository_impl,
    environ = ["PATH", "DEVELOPER_DIR", "SDKROOT"],
    local = True,
)
