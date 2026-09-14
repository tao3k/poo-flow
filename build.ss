#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 default-exclude-dirs))

(def +public-entry-modules+
  '("src/core/api.ss"
    "src/module-system/api.ss"
    "src/feature-system/interface.ss"
    "user-interface/init.ss"))

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
 (exclude-dirs
  (append '("lambda-episteme"
            "bindings"
            "packages"
            "target"
            "user-interface/cases"
            "user-interface/profiles"
            "user-interface/custom/my-module/cases"
            "user-interface/custom/my-module/profiles")
          default-exclude-dirs))
 (exclude-modules '("src/modules/nono-sandbox/_nono.ss"))
 (extra-spec
  '("user-interface/custom/my-module/profiles/all.ss"
    "user-interface/custom/my-module/cases/cicd-owner.ss"
    "user-interface/custom/my-module/cases/loop-engine-owner.ss"
    "user-interface/custom/my-module/cases/session-owner.ss"
    "user-interface/custom/my-module/cases/runtime-owner.ss"
    "user-interface/custom/my-module/cases/durable-owner.ss"))
 (native-prelude-spec
  `((gxc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,+nono-c-include-option+
          "-ld-options" ,+nono-c-link-option+))))

(defbuild-script (poo-flow-library-spec))
