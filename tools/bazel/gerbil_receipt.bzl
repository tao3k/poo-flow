"""Bazel-native validation gates for stable Gerbil project receipts."""

load(
    "@gerbil_bazel//gerbil:defs.bzl",
    "GERBIL_TOOLCHAIN_TYPE",
    "resolved_gerbil_toolchain",
)

def _single_file(target, attribute_name):
    files = target[DefaultInfo].files.to_list()
    if len(files) != 1:
        fail(
            "%s must provide exactly one file, got %d from %s" %
            (attribute_name, len(files), target.label),
        )
    return files[0]

def _gerbil_project_receipt_v1_test_impl(ctx):
    toolchain = resolved_gerbil_toolchain(ctx)
    receipt = _single_file(ctx.attr.receipt, "receipt")
    schema = ctx.file._schema
    validator = ctx.file._validator
    consumer_validator = ctx.file.consumer_validator
    executable = ctx.actions.declare_file(ctx.label.name + ".sh")

    commands = [
        "\"$gxi\" \"$runfiles/%s\" \"$runfiles/%s\" \"$runfiles/%s\"" % (
            validator.short_path,
            schema.short_path,
            receipt.short_path,
        ),
    ]
    if consumer_validator:
        commands.append(
            "\"$gxi\" \"$runfiles/%s\" \"$runfiles/%s\"" % (
                consumer_validator.short_path,
                receipt.short_path,
            ),
        )

    ctx.actions.write(
        output = executable,
        content = """#!/bin/sh
set -eu
runfiles="${TEST_SRCDIR}/${TEST_WORKSPACE}"
gxi="$runfiles/%s"
%s
""" % (
            toolchain.gxi.executable.short_path,
            "\n".join(commands),
        ),
        is_executable = True,
    )

    files = [receipt, schema, validator]
    if consumer_validator:
        files.append(consumer_validator)
    runfiles = ctx.runfiles(
        files = files,
        transitive_files = toolchain.runfiles,
    )
    for target in [ctx.attr.receipt, ctx.attr._schema, ctx.attr._validator]:
        runfiles = runfiles.merge(target[DefaultInfo].default_runfiles)
        runfiles = runfiles.merge(target[DefaultInfo].data_runfiles)
    if ctx.attr.consumer_validator:
        runfiles = runfiles.merge(
            ctx.attr.consumer_validator[DefaultInfo].default_runfiles,
        )
        runfiles = runfiles.merge(
            ctx.attr.consumer_validator[DefaultInfo].data_runfiles,
        )

    return [DefaultInfo(executable = executable, runfiles = runfiles)]

gerbil_project_receipt_v1_test = rule(
    implementation = _gerbil_project_receipt_v1_test_impl,
    test = True,
    attrs = {
        "consumer_validator": attr.label(allow_single_file = [".ss"]),
        "receipt": attr.label(allow_single_file = True, mandatory = True),
        "_schema": attr.label(
            allow_single_file = [".json"],
            default = Label("@gerbil_bazel//schemas:gerbil-bazel.project-receipt.v1.schema.json"),
        ),
        "_validator": attr.label(
            allow_single_file = [".ss"],
            default = Label("@gerbil_bazel//gerbil:validate_project_receipt_v1.ss"),
        ),
    },
    toolchains = [GERBIL_TOOLCHAIN_TYPE],
)
