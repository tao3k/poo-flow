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

For the production caller-owned path, reuse an output buffer. ABI layout and
fingerprint negotiation happens once per runtime instance; thread-local CFFI
scratch objects are reused after their first call:

```python
output = bytearray(424)
layout = runtime.validate_and_write(native_vector, output)
```

The differential gate requires Python and C to agree on validation status,
schema fingerprint, ABI layout, and the exact round-trip bytes. Rust,
TypeScript, and other language runtimes remain downstream adapters over the
same C ABI.

The installed-consumer gate builds a non-editable wheel, installs it into an
isolated virtual environment, removes `PYTHONPATH`, and verifies the canonical
vector through the public shared library:

```sh
uv run pytest -q tests/test_installed_wheel.py
```
