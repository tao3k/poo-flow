# `@poo-flow/runtime-wasm`

Browser WebAssembly runtime for canonical POO Flow Bundle v1 topologies.

Scheme compositions lower to the language-neutral execution plan and Bundle v1
tables. The package ships the resulting immutable descriptor and arena bytes;
the WASM runtime validates and owns topology queries and cursor state. JavaScript
and TypeScript provide binding APIs only and do not regenerate workflow meaning.

## Exports

- `@poo-flow/runtime-wasm`: runtime loader, topology queries, and cursor API
- `@poo-flow/runtime-wasm/wasm`: packaged WebAssembly module
- `@poo-flow/runtime-wasm/workflows/human-capability/descriptor`: Bundle v1 descriptor
- `@poo-flow/runtime-wasm/workflows/human-capability/arena`: immutable Bundle v1 arena

The package payload is built and tested from the POO Flow source repository.
Generated `dist/`, Bundle assets, and package archives are published from the
independent `npm-package` branch and are not committed to `main`.

## Downstream Scheme compositions

Downstream projects own their composition source as Scheme. The public Bazel
rule keeps lowering in the host build and emits immutable files for this browser
runtime:

```starlark
load("@poo_flow//tools/bazel:bundle_v1.bzl", "poo_flow_bundle_v1")

poo_flow_bundle_v1(
    name = "principles_bundle",
    src = "human-capability.ss",
    arena_out = "human-capability.arena.bin",
    bundle_id = "human-capability",
    descriptor_out = "human-capability.descriptor.bin",
)
```

The Scheme entrypoint calls
`poo-flow-write-composition-bundle-v1/from-environment!` with its composed POO
value. Bazel supplies the bundle identity and declared output paths. No Scheme
compiler or lowering implementation is added to the browser WASM surface.
