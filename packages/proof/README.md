# poo-flow proof packages

This workspace is the typed proof bridge for user-interface configuration.

- `lean/` defines the proof-critical data as Lean inductive types and structures.
- `python/` is a `uv` generator package that emits Lean typed declarations.

The proof source is the Lean value built from typed constructors. Gerbil/POO
should eventually generate that Lean value directly from typed Scheme projection
helpers through the C ABI.
