# `@poo-flow/runtime-wasm`

Browser WebAssembly runtime and generated workflow plans for POO Flow.

The package exposes a compact workflow cursor together with typed projections generated from the canonical Scheme compositions. Consumers can render a workflow before starting execution, then open the WASM cursor only when an interactive run begins.

## Exports

- `@poo-flow/runtime-wasm`: runtime loader, cursor API, and workflow registry
- `@poo-flow/runtime-wasm/wasm`: URL for the packaged WebAssembly module
- generated workflow subpaths declared by the package export map

The package payload is built and tested from the POO Flow source repository. Generated `dist/` and package archives are published from the independent `npm-package` branch and are not committed to `main`.
