"""Rules for generating the runtime-v0 C contract with the Scheme owner."""

RuntimeContractInfo = provider(
    doc = "Generated runtime-v0 contract artifacts.",
    fields = {
        "header": "Generated C contract header.",
        "vector": "Generated contract vector.",
        "event_vector": "Generated native event vector.",
    },
)

def _runtime_contract_impl(ctx):
    header = ctx.actions.declare_file(
        "generated/include/poo_flow/runtime_v0_contract.h",
    )
    vector = ctx.actions.declare_file(
        "generated/tests/vectors/runtime_v0_contract.txt",
    )
    event_vector = ctx.actions.declare_file(
        "generated/tests/vectors/runtime_v0_event_1.txt",
    )

    ctx.actions.run_shell(
        inputs = depset(
            direct = [ctx.file.generator, ctx.file.gerbil_root],
            transitive = [
                ctx.attr.gerbil_path[DefaultInfo].files,
                ctx.attr.scheme_sources[DefaultInfo].files,
            ],
        ),
        outputs = [header, vector, event_vector],
        tools = [ctx.file.gxi],
        arguments = [
            ctx.file.gxi.path,
            ctx.file.generator.path,
            header.path,
            vector.path,
            event_vector.path,
            ctx.file.gerbil_root.path,
        ],
        command = """
set -eu
gxi="$1"
generator="$2"
header="$3"
vector="$4"
event_vector="$5"
gerbil_root="$(dirname "$6")/gerbil_path"
loadpath="$(mktemp -d "${TMPDIR:-/tmp}/poo-flow-gerbil-loadpath.XXXXXX")"
trap 'rm -rf "$loadpath"' EXIT
ln -s "$PWD" "$loadpath/poo-flow"
mkdir -p "$(dirname "$header")" "$(dirname "$vector")" "$(dirname "$event_vector")"
env -u CPATH -u SDKROOT -u C_INCLUDE_PATH -u LIBRARY_PATH \
  GERBIL_LOADPATH="$loadpath" \
  GERBIL_PATH="$gerbil_root" \
  "$gxi" "$generator" \
  --header-output "$header" \
  --vector-output "$vector" \
  --event-vector-output "$event_vector"
""",
        mnemonic = "RuntimeV0Contract",
        progress_message = "Generating runtime-v0 C contract with Scheme",
    )

    return [
        DefaultInfo(files = depset([header, vector, event_vector])),
        OutputGroupInfo(
            event_vector = depset([event_vector]),
            header = depset([header]),
            vector = depset([vector]),
        ),
        RuntimeContractInfo(
            header = header,
            vector = vector,
            event_vector = event_vector,
        ),
    ]

runtime_contract = rule(
    implementation = _runtime_contract_impl,
    attrs = {
        "generator": attr.label(
            allow_single_file = [".ss"],
            mandatory = True,
        ),
        "gerbil_path": attr.label(mandatory = True),
        "gerbil_root": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "gxi": attr.label(
            allow_single_file = True,
            cfg = "exec",
            mandatory = True,
        ),
        "scheme_sources": attr.label(mandatory = True),
    },
)
