# Bazel Runtime C Build Design

## Status

Accepted design for replacing `bindings/runtime-c/Makefile` with an optional Bazel/Starlark build surface while preserving `build.ss` as the authoritative Scheme build system.

## Goal

Introduce Bazel as an external, optional build choice for the Scheme-to-C-to-Python runtime boundary. Bazel replaces the runtime C Makefile completely, but it does not replace or reimplement the native Scheme build semantics owned by `build.ss`.

The completed path must build the runtime contract, C library, C tests, benchmarks, and Python runtime integration without invoking Make.

## Architectural Boundary

`build.ss` remains the sole owner of Gerbil/Scheme build semantics, including module stages, build specifications, compilation, cleaning, worker configuration, and Scheme-side receipts. Bazel must not interpret or duplicate the Scheme module topology.

The existing Scheme contract generator remains the sole owner of generated contract content. Bazel invokes that generator as a declared tool and consumes its declared outputs. Both the contract generator and `build.ss` remain usable independently of Bazel.

Bazel owns the external action graph that replaces `bindings/runtime-c/Makefile`:

1. Read the authoritative runtime schema.
2. Invoke the Scheme contract generator.
3. Compile and link the runtime C library.
4. Build and run the C tests.
5. Build and smoke-test the C benchmarks.
6. Provide the runtime artifacts and metadata required by Python runtime tests.

There is no Make fallback after migration. Once the Bazel path meets the acceptance gates, the Makefile and its public command references are removed.

## Target Graph

The initial Bazel graph has these conceptual targets. Exact Bazel labels may follow repository naming conventions during implementation, but their ownership and dependencies must remain distinct.

### Target: runtime_v0_schema

A source-only target containing the authoritative Org/schema inputs. It performs no generation and exposes no files that are derived from a previous local build.

### Target: generate_runtime_v0_contract

A Starlark rule or macro-backed action that invokes the existing Scheme contract generator. Its inputs include the generator, schema, required Scheme modules, declared parameters, and the hermetic Gerbil execution environment. It declares every generated file and writes only to the Bazel output tree.

The action fails when the generator exits unsuccessfully, omits a declared file, produces an undeclared required file, or reports a contract-version mismatch.

### Target: runtime_v0_generated_sources

A provider boundary aggregating generated C sources, headers, contract metadata, and version information. Consumers depend on the provider rather than on a private output-directory layout.

The provider must be narrow: it describes generated runtime-contract artifacts and must not become a second model of Scheme build stages.

### Target: runtime_c_library

A native Bazel C/C++ library target consuming `runtime_v0_generated_sources`. It explicitly declares sources, public headers, include paths, compile definitions, and link dependencies.

Static and shared outputs may be exposed as separate targets when both are required. Compilation must use Bazel C/C++ toolchains rather than custom shell actions that reproduce Makefile compiler commands.

### Target: runtime_c_tests

Native `cc_test` targets covering the C ABI, generated contract, and runtime behavior. Fixtures and runtime files are declared through Bazel dependencies and `data`; tests must not discover artifacts through working-directory assumptions.

### Target: runtime_c_benchmarks

Explicit benchmark binaries and smoke-test targets. Benchmarks are fully migrated from the Makefile, but performance runs are not part of the default unit-test gate. The acceptance gate requires successful builds and a bounded smoke run, not stable performance numbers across machines.

### Target: python_runtime_ffi_tests

Python runtime integration tests that explicitly depend on the required runtime library, contract metadata, and dynamic-library runfiles. They validate the Scheme projection/contract boundary and must not locate products through Makefile paths or undeclared local installations.

## Starlark Responsibilities

Starlark should define the contract-generation action, its provider, and small macros that remove repeated target declarations. It must not implement Scheme compilation semantics or replace native Bazel rules where standard rules suffice.

The preferred split is:

- a contract-generation rule and provider;
- native `cc_library`, `cc_test`, and binary targets for C;
- native Python rules for package and integration tests;
- platform-specific selection through Bazel toolchains and `select()` only where the standard toolchain interface is insufficient.

## Hermeticity and Reproducibility

Every generator input, executable, environment setting, and output is declared. The generator writes only inside the Bazel sandbox/output tree.

The build must not depend on:

- an ambient user Gerbil package cache;
- an implicit `PATH` lookup for the generator or compiler;
- previously generated files in the source tree;
- a previously installed runtime library;
- Makefile-created directories or environment variables.

The rule constructs the required Gerbil load path from declared inputs. C compilation and platform behavior are delegated to Bazel toolchains. Linux and macOS differences are represented through toolchain constraints or bounded `select()` expressions rather than scattered shell conditionals.

Changing the schema, generator, generation parameters, C sources, or relevant toolchain inputs must invalidate the corresponding Bazel actions and their downstream dependents.

## Diagnostics and Failure Semantics

Generator failure is a hard Bazel action failure, with the Scheme generator's diagnostic output preserved. Missing or unexpected required artifacts and contract-version mismatches are also hard failures.

Python integration failures must report the selected contract metadata, runtime library/runfile, and relevant ABI or version mismatch. No rule may silently fall back to Make, a source-tree artifact, or a locally installed library.

Cleaning is not reimplemented as an application-specific target. Bazel owns its output tree and standard clean behavior, while `build.ss` retains its independent Scheme-side cleaning semantics.

## Migration Sequence

1. Establish Bazel workspace/module metadata and the minimum supported Bazel version.
2. Declare the runtime schema and Scheme generator tool inputs.
3. Implement the contract-generation rule and provider.
4. Add native C library targets.
5. Migrate C contract/runtime tests.
6. Migrate benchmark build and smoke-test targets.
7. Connect Python runtime integration tests to declared Bazel artifacts.
8. Add clean-checkout and invalidation validation.
9. Replace CI and documentation references to Make commands.
10. Delete `bindings/runtime-c/Makefile` and verify all acceptance gates again.

At no point does this sequence redirect Scheme module compilation away from `build.ss`.

## Acceptance Gates

The Makefile may be deleted only after all of these conditions hold:

1. A clean checkout can generate the runtime-v0 contract through Bazel.
2. Required static and shared runtime libraries build through native Bazel toolchains.
3. C contract and runtime tests pass.
4. C benchmarks build and complete a bounded smoke run.
5. Python runtime FFI/projection integration tests pass against Bazel-declared artifacts.
6. A schema change invalidates and rebuilds generation, the C library, and affected Python tests.
7. Generated contract and ABI behavior are equivalent to the former Makefile path.
8. Repository CI, documentation, tests, and scripts no longer reference public Makefile commands.
9. Deleting `bindings/runtime-c/Makefile` leaves the full Bazel acceptance path green.
10. The independent `build.ss` Scheme compile/test path remains green and has no Bazel dependency.

## Non-Goals

- Replacing `build.ss` or the Gerbil package build system.
- Expressing Scheme module topology in Starlark.
- Making Bazel mandatory for Scheme-only development.
- Preserving Make as a compatibility wrapper after acceptance.
- Treating benchmark performance numbers as portable pass/fail thresholds in the first migration.
