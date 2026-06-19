# POO Flow Build Flow

- Treat `.gerbil/` compilation output as package-manager-owned state. Do not manually delete `.gerbil/lib/...`, `.ssi`, `.scm`, or other generated artifacts to repair stale builds.
- Use the Gerbil package CLI as the source of truth for package lifecycle commands:
  - `gxpkg clean`
  - `gxpkg build`
  - `gxpkg env gxtest <test-file>`
- Prefer RTK wrappers for noisy verification, for example:
  - `rtk --ultra-compact err gxpkg clean`
  - `rtk --ultra-compact err gxpkg build`
  - `rtk --ultra-compact err gxpkg env gxtest t/agent-sandbox-profile-candidate-test.ss`
- If `gxpkg clean` or `gxpkg build` fails because `build.ss` lacks a package-manager command, fix the package CLI integration in `build.ss` instead of cleaning generated files by hand.
- After changing agent-sandbox profile or nono bindings, run the focused package-context tests:
  - `gxpkg env gxtest t/agent-sandbox-profile-candidate-test.ss`
  - `gxpkg env gxtest t/agent-sandbox-nono-profile-candidate-test.ss`
  - `gxpkg env gxtest t/nono-sandbox-c-binding-test.ss`
- `t/project-policy-test.ss` may emit warning diagnostics while still exiting 0. Treat new warnings as follow-up work, but do not bypass the package CLI flow.
