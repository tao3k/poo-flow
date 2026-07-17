"""Generated targets for one system-adaptive local Gerbil toolchain."""

load("@//tools/bazel:gerbil_toolchain.bzl", "gerbil_toolchain")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

sh_binary(
    name = "native_scheme_env",
    srcs = ["native_scheme_env.sh"],
    data = ["gxpkg_raw", "native_abi.txt"],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "install_dependencies",
    srcs = ["install_gerbil_dependencies.sh"],
    data = ["gxpkg_raw", "native_abi.txt"],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "gxc",
    srcs = ["gxc.sh"],
    data = ["gxc_raw", "native_abi.txt"],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "gxi",
    srcs = ["gxi.sh"],
    data = ["gxi_raw", "native_abi.txt"],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "gxpkg",
    srcs = ["gxpkg.sh"],
    data = ["gxpkg_raw", "native_abi.txt"],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "gxtest",
    srcs = ["gxtest.sh"],
    data = ["gxtest_raw", "native_abi.txt"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "dependency_libraries",
    srcs = glob([
        "lib/clan/**",
        "lib/gslph/**",
    ], allow_empty = True),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "dependency_library_root",
    srcs = ["lib/.root"],
    visibility = ["//visibility:public"],
)

gerbil_toolchain(
    name = "toolchain_impl",
    dependency_libraries = ":dependency_libraries",
    dependency_library_root = "lib/.root",
    gerbil_as = "gerbil_as",
    gerbil_cc = "gerbil_cc",
    gerbil_ld = "gerbil_ld",
    gxc = ":gxc",
    gxi = ":gxi",
    gxpkg = ":gxpkg",
    gxtest = ":gxtest",
    native_scheme_env = ":native_scheme_env",
    native_abi_fingerprint = "%{NativeAbiFingerprint}",
    native_abi_fingerprint_file = "native_abi.txt",
    receipt = "toolchain.receipt.json",
    system_memory_bytes = "%{SystemMemoryBytes}",
)

toolchain(
    name = "registered_toolchain",
    exec_compatible_with = ["%{ExecCompatibleWith}"],
    toolchain = ":toolchain_impl",
    toolchain_type = "@//tools/bazel:gerbil_toolchain_type",
    visibility = ["//visibility:public"],
)

exports_files(
    [
        "gerbil_cc",
        "gerbil_as",
        "gerbil_ld",
        "gxc_raw",
        "gxi_raw",
        "gxpkg_raw",
        "gxtest_raw",
        "install_gerbil_dependencies.sh",
        "lib/.root",
        "native_abi.txt",
        "toolchain.receipt.json",
    ],
    visibility = ["//visibility:public"],
)
