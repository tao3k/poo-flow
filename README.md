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
