"""Resolve the explicit Darwin or Linux host policy for Gerbil tools."""

_SYSTEM_BY_BAZEL_OS = {
    "darwin": "darwin",
    "linux": "linux",
    "mac os x": "darwin",
}

_DARWIN_TOOLS = {
    "env": "/usr/bin/env",
    "sysctl": "/usr/sbin/sysctl",
    "xcode-select": "/usr/bin/xcode-select",
    "xcrun": "/usr/bin/xcrun",
}

def _checked_output(repository_ctx, argv, description):
    result = repository_ctx.execute(argv)
    if result.return_code != 0:
        fail("%s failed: %s" % (description, result.stderr))
    value = result.stdout.strip()
    if not value:
        fail("%s returned an empty path" % description)
    return value

def _existing_non_nix_directory(repository_ctx, value):
    return bool(value) and not value.startswith("/nix/store/") and repository_ctx.path(value).exists

def _checked_positive_integer_output(repository_ctx, argv, description):
    value = _checked_output(repository_ctx, argv, description)
    parsed = int(value)
    if parsed <= 0:
        fail("%s returned a non-positive value: %s" % (description, value))
    return parsed

def _resolve_darwin_environment(repository_ctx):
    for name, path in _DARWIN_TOOLS.items():
        if not repository_ctx.path(path).exists:
            fail("Darwin Gerbil builds require %s at %s" % (name, path))

    inherited_developer_dir = repository_ctx.os.environ.get("DEVELOPER_DIR", "")
    inherited_sdkroot = repository_ctx.os.environ.get("SDKROOT", "")
    developer_dir_is_valid = _existing_non_nix_directory(repository_ctx, inherited_developer_dir)

    developer_dir = inherited_developer_dir
    if not developer_dir_is_valid:
        developer_dir = _checked_output(
            repository_ctx,
            [
                _DARWIN_TOOLS["env"],
                "-u",
                "DEVELOPER_DIR",
                "-u",
                "SDKROOT",
                _DARWIN_TOOLS["xcode-select"],
                "--print-path",
            ],
            "xcode-select --print-path",
        )

    sdkroot = inherited_sdkroot
    if not developer_dir_is_valid or not _existing_non_nix_directory(repository_ctx, sdkroot):
        sdkroot = _checked_output(
            repository_ctx,
            [
                _DARWIN_TOOLS["env"],
                "-u",
                "SDKROOT",
                "DEVELOPER_DIR=%s" % developer_dir,
                _DARWIN_TOOLS["xcrun"],
                "--sdk",
                "macosx",
                "--show-sdk-path",
            ],
            "xcrun --sdk macosx --show-sdk-path",
        )

    linker = _checked_output(
        repository_ctx,
        [
            _DARWIN_TOOLS["env"],
            "-u",
            "SDKROOT",
            "DEVELOPER_DIR=%s" % developer_dir,
            _DARWIN_TOOLS["xcrun"],
            "--sdk",
            "macosx",
            "--find",
            "ld",
        ],
        "xcrun --sdk macosx --find ld",
    )

    return struct(
        system = "darwin",
        policy = "active-xcode",
        system_memory_bytes = _checked_positive_integer_output(
            repository_ctx,
            [_DARWIN_TOOLS["sysctl"], "-n", "hw.memsize"],
            "sysctl -n hw.memsize",
        ),
        tool_overrides = {
            "gerbil_as": "/usr/bin/as",
            "gerbil_ld": linker,
        },
        environment = {
            "DEVELOPER_DIR": developer_dir,
            "SDKROOT": sdkroot,
        },
    )

def _resolve_linux_environment(repository_ctx):
    getconf = repository_ctx.which("getconf")
    if getconf == None:
        fail("Linux Gerbil builds require getconf on PATH")
    page_count = _checked_positive_integer_output(
        repository_ctx,
        [getconf, "_PHYS_PAGES"],
        "getconf _PHYS_PAGES",
    )
    page_size = _checked_positive_integer_output(
        repository_ctx,
        [getconf, "PAGE_SIZE"],
        "getconf PAGE_SIZE",
    )
    return struct(
        system = "linux",
        policy = "preserve-host-environment",
        system_memory_bytes = page_count * page_size,
        tool_overrides = {},
        environment = {},
    )

_ENVIRONMENT_RESOLVERS = {
    "darwin": _resolve_darwin_environment,
    "linux": _resolve_linux_environment,
}

def resolve_host_environment(repository_ctx):
    """Return the declared environment policy for the Bazel host system."""
    bazel_os = repository_ctx.os.name.lower()
    system = _SYSTEM_BY_BAZEL_OS.get(bazel_os)
    if system == None:
        fail(
            "unsupported Gerbil host OS %r; supported systems are darwin and linux" %
            repository_ctx.os.name,
        )
    return _ENVIRONMENT_RESOLVERS[system](repository_ctx)
