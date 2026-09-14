#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(def +core-public-entry-modules+
  '("src/core/api.ss"
    "src/module-system/api.ss"
    "src/feature-system/interface.ss"
    "src/loops/agent.ss"
    "src/profiles/kernel/interface.ss"
    "src/module-system/loader/fragment-syntax.ss"
    "src/module-system/observability/module-presentation.ss"
    "src/module-system/observability/testing-extension.ss"
    "src/user-interface/init-declaration-syntax.ss"
    "src/user-interface/config-discovery-syntax.ss"
    "user-interface/custom/my-module/cases/durable-artifact.ss"
    "user-interface/custom/my-module/cases/durable-recovery.ss"
    "user-interface/custom/my-module/cases/durable-runtime-store-handoff.ss"
    "user-interface/custom/my-module/cases/durable-runtime-store-operations.ss"
    "user-interface/custom/my-module/cases/durable-operation-bridge.ss"
    "user-interface/custom/my-module/cases/durable-owner.ss"))

(def +public-entry-modules+
  +core-public-entry-modules+)

(def +nono-c-include-option+
  (string-append
   "-I"
   (path-expand "bindings/nono-c" (current-directory))))

(def +nono-c-link-option+
  (cond-expand
   (darwin "-Wl,-undefined,dynamic_lookup")
   (else "-ldl")))

(asp-gerbil-scheme-package-spec!
 (poo-flow-library-package-spec
 @ asp-gerbil-scheme-library-package-prototype)
 (spec poo-flow-library-spec)
 (public-entry-modules +public-entry-modules+)
 (native-prelude-spec
  `((gxc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,+nono-c-include-option+
          "-ld-options" ,+nono-c-link-option+))))

(defbuild-script (poo-flow-library-spec))
