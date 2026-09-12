#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import (only-in :clan/building
                 all-gerbil-modules
                 remove-build-file)
        (only-in :std/build-script defbuild-script)
        (only-in :std/misc/path path-expand)
        (only-in :std/srfi/1 fold)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-package-modules))

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

(def (runtime-module? module)
  (and (string-prefix? "src/" module)
       (not (string-prefix? "src/build-api/" module))
       (not (string-prefix? "src/cli-support/" module))
       (not (string-prefix? "src/testing/" module))))

(def (remove-build-files specs modules)
  (fold (lambda (module current)
          (remove-build-file current module))
        specs
        modules))

(def (interface-only-specs specs)
  (fold (lambda (module current)
          (cons [ssi: module]
                (remove-build-file current module)))
        specs
        +interface-only-modules+))

(def (runtime-spec modules)
  (interface-only-specs
   (remove-build-files
    (filter runtime-module? modules)
    +excluded-runtime-modules+)))

(def (nono-ffi-spec)
  `((gsc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,(string-append "-I" (path-expand "bindings/nono-c"))
          ,@(cond-expand
              (darwin '("-ld-options" "-Wl,-undefined,dynamic_lookup"))
              (else '("-ld-options" "-ldl"))))
    (ssi: "src/modules/nono-sandbox/_nono")))

;; POO Flow owns only this project-specific native projection.  The Build API
;; owns the single project scan and passes the resolved package catalog here.
(def (poo-flow-native-spec package-spec)
  (append (nono-ffi-spec)
          (runtime-spec
           (asp-gerbil-scheme-package-modules package-spec))
          +user-interface-modules+))

(asp-gerbil-scheme-package-spec!
 (poo-flow-library-package-spec
 @ asp-gerbil-scheme-library-package-prototype)
 (spec spec)
 (modules (all-gerbil-modules))
 (native-spec-projector poo-flow-native-spec))

;; This macro must remain at top level: it installs the package script's
;; multicall main for spec/compile/clean and passes the heterogeneous native
;; projection to the single upstream std/make scheduler.
(defbuild-script (spec))
