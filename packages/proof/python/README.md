# poo-flow-proof

Typed Lean artifact generator for poo-flow proof manifests.

This package emits Lean declarations that use constructors from
`PooFlowProof.Manifest`.

```sh
uv run poo-flow-proof emit-lean --output ../lean/PooFlowProof/Generated/LoopEngine.lean
```

## Native proof runtime

`NativeProofCaseRuntime` is the production-capable Python adapter for the
stable `poo_flow_proof_case_v1` C ABI. It consumes the generated native Scheme
type projection directly; JSON is not part of this boundary.

```python
from poo_flow_proof.proof_case_runtime import (
    NativeProofCaseRuntime,
    assert_native_differential,
)

runtime = NativeProofCaseRuntime("/path/to/libpoo_flow_runtime.dylib")
layout = assert_native_differential(runtime, native_vector)
```

The differential gate requires Python and C to agree on validation status,
schema fingerprint, ABI layout, and the exact round-trip bytes. Rust,
TypeScript, and other language runtimes remain downstream adapters over the
same C ABI.
