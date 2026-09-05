#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import :std/make
        (only-in :clan/building init-build-environment!)
        (only-in :std/misc/path path-expand)
        (only-in :std/srfi/1 fold)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :asp-gerbil-scheme/src/package-build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-development-builder-profile
                 asp-gerbil-scheme-package-modules
                 asp-gerbil-scheme-package-profiled-build-spec))

(def +interface-only-modules+
  '("src/module-system/object-family-syntax.ss"
    "src/module-system/init-syntax.ss"))

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
 (role 'library)
 (profile asp-gerbil-scheme-development-builder-profile)
 (spec-projector asp-gerbil-scheme-package-profiled-build-spec)
 (native-spec-projector poo-flow-native-spec))

(init-build-environment!
 name: "poo-flow"
 deps: '("clan" "clan/poo" "asp-gerbil-scheme")
 spec: spec)
