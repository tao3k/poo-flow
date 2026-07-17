load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

sh_binary(
    name = "native_scheme_env",
    srcs = ["native_scheme_env.sh"],
    visibility = ["//visibility:public"],
)

exports_files(
    [
        "gerbil_cc",
        "gxc",
        "gxi",
        "gxpkg",
        "toolchain.receipt.json",
    ],
    visibility = ["//visibility:public"],
)
