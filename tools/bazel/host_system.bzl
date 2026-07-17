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

_DARWIN_HOMEBREW_DEPENDENCIES = [
    "openssl@3",
    "sqlite",
    "zlib",
]

_DARWIN_HOMEBREW_REQUIRED_LIBRARIES = {
    "openssl@3": ["libssl.dylib", "libcrypto.dylib"],
    "sqlite": ["libsqlite3.dylib"],
    "zlib": ["libz.dylib"],
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

def _prepend_path_entries(entries, inherited):
    return ":".join(entries + ([inherited] if inherited else []))

def _prepend_flag_entries(entries, inherited):
    return " ".join(entries + ([inherited] if inherited else []))

def _required_inherited_path(repository_ctx):
    path = repository_ctx.os.environ.get("PATH", "")
    if not path:
        fail("Gerbil toolchain discovery requires a non-empty host PATH")
    return path

def _resolve_darwin_native_dependency_environment(repository_ctx):
    brew = repository_ctx.which("brew")
    if brew == None:
        fail("Darwin Gerbil builds require Homebrew on PATH")

    prefixes = []
    for formula in _DARWIN_HOMEBREW_DEPENDENCIES:
        prefix = _checked_output(
            repository_ctx,
            [brew, "--prefix", formula],
            "brew --prefix %s" % formula,
        )
        for library in _DARWIN_HOMEBREW_REQUIRED_LIBRARIES[formula]:
            library_path = repository_ctx.path("%s/lib/%s" % (prefix, library))
            if not library_path.exists:
                fail("Homebrew capability %s is missing %s" % (formula, library_path))
        prefixes.append(prefix)

    include_paths = ["%s/include" % prefix for prefix in prefixes]
    library_paths = ["%s/lib" % prefix for prefix in prefixes]
    pkg_config_paths = ["%s/lib/pkgconfig" % prefix for prefix in prefixes]
    return {
        "CPATH": _prepend_path_entries(
            include_paths,
            repository_ctx.os.environ.get("CPATH", ""),
        ),
        "LDFLAGS": _prepend_flag_entries(
            ["-L%s" % path for path in library_paths],
            repository_ctx.os.environ.get("LDFLAGS", ""),
        ),
        "LIBRARY_PATH": _prepend_path_entries(
            library_paths,
            repository_ctx.os.environ.get("LIBRARY_PATH", ""),
        ),
        "PKG_CONFIG_PATH": _prepend_path_entries(
            pkg_config_paths,
            repository_ctx.os.environ.get("PKG_CONFIG_PATH", ""),
        ),
    }

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

    environment = {
        "DEVELOPER_DIR": developer_dir,
        "PATH": _required_inherited_path(repository_ctx),
        "SDKROOT": sdkroot,
    }
    environment.update(_resolve_darwin_native_dependency_environment(repository_ctx))

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
        environment = environment,
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
        environment = {
            "PATH": _required_inherited_path(repository_ctx),
        },
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
