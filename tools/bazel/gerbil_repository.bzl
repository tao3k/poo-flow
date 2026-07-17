"""Declare the host Gerbil toolchain used by Bazel outer orchestration."""

load(
    ":host_system.bzl",
    "resolve_host_environment",
    "resolve_native_abi_fingerprint",
)

_TOOL_CANDIDATES = {
    "gerbil_as": ["as"],
    "gerbil_cc": ["gcc-16", "cc"],
    "gerbil_ld": ["ld"],
    "gxc": ["gxc"],
    "gxi": ["gxi"],
    "gxpkg": ["gxpkg"],
    "gxtest": ["gxtest"],
}

_VERSIONED_TOOLS = ["gxi", "gxc"]

_EXEC_CONSTRAINT_BY_SYSTEM = {
    "darwin": "@platforms//os:macos",
    "linux": "@platforms//os:linux",
}

def _shell_quote(value):
    return "'" + value.replace("'", "'\"'\"'") + "'"

def _resolve_tools(repository_ctx, tool_overrides):
    tools = {}
    for name, candidates in _TOOL_CANDIDATES.items():
        override = tool_overrides.get(name)
        if override != None:
            path = repository_ctx.path(override)
            if not path.exists:
                fail("%s tool override does not exist: %s" % (name, override))
            tools[name] = path
            continue
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
    native_environment = resolve_host_environment(repository_ctx)
    tools = _resolve_tools(repository_ctx, native_environment.tool_overrides)
    native_abi_fingerprint = resolve_native_abi_fingerprint(
        repository_ctx,
        str(tools["gerbil_cc"]),
        str(repository_ctx.path(repository_ctx.attr.native_abi_probe)),
        native_environment.environment,
    )
    versions = _read_versions(
        repository_ctx,
        tools,
        repository_ctx.attr.expected_version_prefix,
    )
    repository_ctx.symlink(tools["gerbil_as"], "gerbil_as")
    repository_ctx.symlink(tools["gerbil_cc"], "gerbil_cc")
    repository_ctx.symlink(tools["gerbil_ld"], "gerbil_ld")
    for name in ["gxc", "gxi", "gxpkg", "gxtest"]:
        repository_ctx.symlink(tools[name], name + "_raw")
        repository_ctx.template(
            name + ".sh",
            repository_ctx.attr.native_tool_template,
            substitutions = {
                "%{GXPkg}": _shell_quote(str(tools["gxpkg"])),
                "%{NativeEnvironment}": _environment_arguments(native_environment.environment),
                "%{Tool}": _shell_quote(str(tools[name])),
            },
            executable = True,
        )

    package_root = repository_ctx.path(repository_ctx.attr.project_package_file).dirname
    project_library_root = repository_ctx.path(str(package_root) + "/.gerbil/lib")
    repository_ctx.file("lib/.root", "local Gerbil dependency library root\n")
    repository_ctx.file("native_abi.txt", native_abi_fingerprint + "\n")
    if repository_ctx.attr.include_project_dependencies:
        for name in ["clan", "gslph"]:
            dependency_library = repository_ctx.path(str(project_library_root) + "/" + name)
            if not dependency_library.exists:
                fail(
                    "compiled Gerbil dependency %s is missing under %s; run `bazel run //scheme:deps` first" %
                    (name, project_library_root),
                )
            repository_ctx.symlink(dependency_library, "lib/" + name)

    repository_ctx.template(
        "native_scheme_env.sh",
        repository_ctx.attr.native_runner_template,
        substitutions = {
            "%{GXPkg}": _shell_quote(str(tools["gxpkg"])),
            "%{NativeEnvironment}": _environment_arguments(native_environment.environment),
        },
        executable = True,
    )
    repository_ctx.template(
        "install_gerbil_dependencies.sh",
        repository_ctx.attr.dependency_installer_template,
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
            "dependency_policy": "project-library-view" if repository_ctx.attr.include_project_dependencies else "bootstrap-host-only",
            "native_abi_fingerprint": native_abi_fingerprint,
            "system_memory_bytes": native_environment.system_memory_bytes,
            "tools": _tool_paths(tools),
            "versions": versions,
        }, indent = "  ") + "\n",
    )
    repository_ctx.template(
        "BUILD.bazel",
        repository_ctx.attr.build_file_template,
        substitutions = {
            "%{ExecCompatibleWith}": _EXEC_CONSTRAINT_BY_SYSTEM[native_environment.system],
            "%{NativeAbiFingerprint}": native_abi_fingerprint,
            "%{SystemMemoryBytes}": str(native_environment.system_memory_bytes),
        },
    )

local_gerbil_repository = repository_rule(
    attrs = {
        "build_file_template": attr.label(
            allow_single_file = True,
            default = Label("//tools/bazel:local_gerbil.BUILD.bazel.tpl"),
        ),
        "dependency_installer_template": attr.label(
            allow_single_file = True,
            default = Label("//tools/bazel:install_gerbil_dependencies.sh.tpl"),
        ),
        "expected_version_prefix": attr.string(mandatory = True),
        "include_project_dependencies": attr.bool(default = True),
        "native_runner_template": attr.label(
            allow_single_file = True,
            default = Label("//tools/bazel:native_scheme_env.sh.tpl"),
        ),
        "native_abi_probe": attr.label(
            allow_single_file = True,
            default = Label("//tools/bazel:native_abi_fingerprint.sh"),
        ),
        "native_tool_template": attr.label(
            allow_single_file = True,
            default = Label("//tools/bazel:native_tool.sh.tpl"),
        ),
        "project_package_file": attr.label(
            allow_single_file = True,
            default = Label("//:gerbil.pkg"),
        ),
    },
    implementation = _local_gerbil_repository_impl,
    environ = [
        "PATH",
        "CPATH",
        "DEVELOPER_DIR",
        "LDFLAGS",
        "LIBRARY_PATH",
        "GERBIL_NATIVE_ABI",
        "PKG_CONFIG_PATH",
        "SDKROOT",
    ],
    local = True,
)
