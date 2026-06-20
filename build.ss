#!/usr/bin/env gxi

;;; -*- Gerbil -*-
;;; Build file for the POO Flow Gerbil runtime package.
;;; The runtime package root is the repository root, matching imports such as :poo-flow/src/core/roles.

(import (only-in :gerbil/gambit
                 path-expand
                 string-append)
        (only-in :clan/building
                 all-gerbil-modules
                 default-exclude
                 init-build-environment!))

;;; clan/building owns package build-environment initialization and compilation.
;;; Non-module practice fragments stay out of the package build and are loaded
;;; through the user-interface macros that own them.
;;; Native C binding note:
;;; nono's C ABI is package-managed through a Gambit FFI shim, following the
;;; gerbil-mysql `gsc:`/`ssi:` pattern. The shim uses dlopen/dlsym, so package
;;; compilation checks the header contract without requiring libnono_ffi to be
;;; present until native live tests opt in at runtime.
;; : (-> String)
(def (nono-c-binding-include-option)
  (string-append "-I" (path-expand ".data/nono/bindings/c/include")))

;;; Build spec stays declarative: clan/building owns module discovery while the
;;; one native shim entry records the C header check needed by package compile.
;; : (-> List)
(def (spec)
  (append
   `((gsc: "src/modules/nono-sandbox/_nono"
            "-cc-options" ,(nono-c-binding-include-option)))
   (all-gerbil-modules
    exclude: (append default-exclude
                     '("src/cli.ss"
                       "version.ss"
                       "t/fixtures/object-load-valid/parts/object1.ss"
                       "t/fixtures/negative/object-load-invalid/parts/object1.ss"))
    exclude-dirs: '("run"
                    ".git"
                    "_darcs"
                    ".gerbil"
                    ".data"
                    "docs"
                    "harness-policy"
                    "t/fixtures/negative"
                    "user-interface"))
   '("user-interface/init"
     "user-interface/custom/my-module/config"
     (exe: "src/cli" bin: "poo-flow"))))

(init-build-environment!
 deps: '("gerbil-poo"
         "gslph")
 spec: spec)
