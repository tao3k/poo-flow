#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import (only-in :std/build-script defbuild-script)
        (only-in :std/misc/path path-expand)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(def +interface-only-modules+
  '("src/module-system/object-family/syntax.ss"
    "src/user-interface/init-syntax.ss"))

(def +excluded-runtime-modules+
  '("src/contract/dependency-source-identity.ss"
    "src/modules/nono-sandbox/_nono.ss"))

(def +user-interface-modules+
  '("user-interface/init.ss"
    "user-interface/custom/my-module/profiles/all.ss"
    "user-interface/custom/my-module/cases/cicd-owner.ss"
    "user-interface/custom/my-module/cases/loop-engine-owner.ss"
    "user-interface/custom/my-module/cases/session-owner.ss"
    "user-interface/custom/my-module/cases/runtime-owner.ss"
    "user-interface/custom/my-module/cases/durable-owner.ss"
    "user-interface/custom/my-module/config.ss"))

;; Test modules remain owned by gxtest.  These are library modules imported by
;; those tests, matching gerbil-poo's native pattern of adding only reusable
;; test support to the std/make graph.
(def +test-support-modules+
  '("t/domain-case-test-support.ss"
    "t/fixtures/bundle-v1-domain-case-projection.ss"
    "t/fixtures/object-load-valid/objects.ss"
    "t/support/compile-performance-budget.ss"
    "t/support/performance.ss"
    "t/support/poo-performance-fixtures.ss"
    "t/support/poo-performance-object-scenarios.ss"
    "t/support/poo-performance.ss"
    "t/support/type-contract-performance.ss"
    "t/support/funflow-config-pipeline-performance.ss"
    "t/support/json-schema-contract-performance.ss"
    "t/support/loop-engine-runtime-manifest-receipts.ss"
    "t/support/custom-loop-engine/fixtures.ss"
    "t/support/custom-loop-engine/declaration.ss"
    "t/support/custom-loop-engine/agent.ss"
    "t/support/custom-loop-engine/operation.ss"
    "t/support/custom-loop-engine/presentation.ss"
    "t/support/custom-loop-engine/case.ss"
    "t/module-system-poo-performance-test-support/composition-gates.ss"
    "t/module-system-poo-performance-test-support/composition-large-library.ss"
    "t/module-system-poo-performance-test-support/composition-scenarios.ss"
    "t/scenarios/performance/composition-macro-expansion/benchmark.ss"
    "t/user-interface-fixtures.ss"))

(def +nono-ffi-spec+
  `((gxc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,(string-append "-I" (path-expand "bindings/nono-c"))
          ,@(cond-expand
              (darwin '("-ld-options" "-Wl,-undefined,dynamic_lookup"))
              (else '("-ld-options" "-ldl"))))))

(asp-gerbil-scheme-package-spec!
 (poo-flow-library-package-spec
 @ asp-gerbil-scheme-library-package-prototype)
 (spec spec)
 (exclude-modules
  (append '("version.ss")
          +excluded-runtime-modules+
          +interface-only-modules+))
 (extra-spec
  (append +nono-ffi-spec+
          '((ssi: "src/user-interface/init-syntax.ss")
            (ssi: "src/module-system/object-family/syntax.ss"))
          +user-interface-modules+
          +test-support-modules+)))

;; This macro must remain at top level: it installs the package script's
;; multicall main for spec/compile/clean and passes the heterogeneous native
;; targets to the single upstream std/make scheduler.
(defbuild-script (spec))
