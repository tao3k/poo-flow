#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import (only-in :clan/building default-exclude-dirs)
        (only-in :std/build-script defbuild-script)
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

(def +nono-ffi-spec+
  `((gsc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,(string-append "-I" (path-expand "bindings/nono-c"))
          ,@(cond-expand
              (darwin '("-ld-options" "-Wl,-undefined,dynamic_lookup"))
              (else '("-ld-options" "-ldl"))))
    (ssi: "src/modules/nono-sandbox/_nono")))

(asp-gerbil-scheme-package-spec!
 (poo-flow-library-package-spec
 @ asp-gerbil-scheme-library-package-prototype)
 (spec spec)
 (exclude-dirs (cons "testing" default-exclude-dirs))
 (exclude-modules
  (append '("version.ss")
          +excluded-runtime-modules+
          +interface-only-modules+))
 (extra-spec
  (append +nono-ffi-spec+
          '((ssi: "src/user-interface/init-syntax.ss")
            (ssi: "src/module-system/object-family/syntax.ss"))
          +user-interface-modules+)))

;; This macro must remain at top level: it installs the package script's
;; multicall main for spec/compile/clean and passes the heterogeneous native
;; targets to the single upstream std/make scheduler.
(defbuild-script (spec))
