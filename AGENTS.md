# POO Flow Project Rules

## Core Invariants

- Public extension and module APIs must be 100% POO-native. Expose Gerbil POO objects, prototype composition, slot operators, and object extension helpers as the normal path.
- Prefer functional programming style in the Scheme control plane. Flow composition should be expressed as pure values and functional combinators first; side effects belong behind explicit runtime or Marlin handoff boundaries.
- Funflow is here to anchor that functional route. The project core is POO + functional programming, and new features must preserve that direction.
- Do not make raw alist DSLs, record DSLs, ad hoc patch languages, or raw `(lambda (self super) ...)` compute hooks the ordinary user interface. Advanced escape hatches may exist only behind named POO-native or functional helpers.

## Build Flow

- Treat `.gerbil/` compilation output as package-manager-owned state. Do not manually delete `.gerbil/lib/...`, `.ssi`, `.scm`, or other generated artifacts to repair stale builds.
- Use the native `poo-flow` CLI for focused agent gates:
  - `poo-flow test <test-file>`
  - `poo-flow build compile --module <source-file>`
- Use the Gerbil package CLI as the source of truth for full package lifecycle commands:
  - `gxpkg clean`
  - `gxpkg build -R -O`
- Prefer RTK wrappers for noisy verification, for example:
  - `rtk --ultra-compact err gxpkg clean`
  - `rtk --ultra-compact err gxpkg build -R -O`
  - `rtk --ultra-compact err poo-flow test t/agent-sandbox-profile-candidate-test.ss`
- If `gxpkg clean` or `gxpkg build` fails because `build.ss` lacks a package-manager command, fix the package CLI integration in `build.ss` instead of cleaning generated files by hand.
- Do not use `gxi build.ss compile --module ...`, `gxpkg env gxtest ...`, or any separate build binary as focused agent gates; those paths reintroduce package-env startup cost or drift from the canonical CLI contract.
- Root `t/*.ss` test modules are part of the package build spec so aggregate imports such as `:poo-flow/t/user-interface-custom-loop-engine-test` do not read stale generated state. Keep `t/fixtures/` excluded from package compilation.
- After changing agent-sandbox profile or nono bindings, run the focused package-context tests:
  - `poo-flow test t/agent-sandbox-profile-candidate-test.ss`
  - `poo-flow test t/agent-sandbox-nono-profile-candidate-test.ss`
  - `poo-flow test t/nono-sandbox-c-binding-test.ss`
- `t/project-policy-test.ss` may emit warning diagnostics while still exiting 0. Treat new warnings as follow-up work, but do not bypass the package CLI flow.
- Follow the Gerbil POO programming rules in `docs/10-19-design/10.06-poo-module-system/29-gerbil-poo-programming-guidelines.org`. In particular, model extension surfaces as POO prototypes/mixins and avoid hot-path `.ref` reads of nested child POO objects.
