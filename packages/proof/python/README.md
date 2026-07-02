# poo-flow-proof

Typed Lean artifact generator for poo-flow proof manifests.

This package emits Lean declarations that use constructors from
`PooFlowProof.Manifest`.

```sh
uv run poo-flow-proof emit-lean --output ../lean/PooFlowProof/Generated/LoopEngine.lean
```
