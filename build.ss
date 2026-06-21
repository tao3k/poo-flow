#!/usr/bin/env gxi

;;; -*- Gerbil -*-
;;; Build file for the POO Flow Gerbil runtime package.
;;; The runtime package root is the repository root, matching imports such as
;;; :poo-flow/src/core/roles.

(import (only-in :gerbil/gambit
                 path-expand
                 string-append)
        (only-in :std/build-script
                 defbuild-script)
        (only-in :clan/building
                 all-gerbil-modules
                 default-exclude))

;;; clan/building owns package source discovery. Non-module practice fragments
;;; stay out of package build and are loaded through user-interface macros.
;;; Native C binding note:
;;; nono's C ABI is package-managed through a Gambit FFI shim, following the
;;; gerbil-mysql `gsc:`/`ssi:` pattern. The shim uses dlopen/dlsym, so package
;;; compilation checks the header contract without requiring libnono_ffi to be
;;; present until native live tests opt in at runtime.
;; : (-> String)
(def (nono-c-binding-include-option)
  (string-append "-I" (path-expand "bindings/nono-c")))

;;; Build spec stays declarative. Runtime modules are discovered first, then
;;; the macro entry and root user-interface are compiled after their owners.
;; : BuildSpec
(def +poo-flow-build-spec+
  (append
   `((gsc: "src/modules/nono-sandbox/_nono"
            "-cc-options" ,(nono-c-binding-include-option))
     (ssi: "src/modules/nono-sandbox/_nono"))
   (all-gerbil-modules
    exclude: (append default-exclude
                     '("src/cli"
                       "src/cli.ss"
                       "src/module-system/init-syntax.ss"
                       "version.ss"
                       "t/fixtures/object-load-valid/parts/object1.ss"
                       "t/fixtures/negative/object-load-invalid/parts/object1.ss"))
    exclude-dirs: '("run"
                    ".git"
                    "_darcs"
                    ".gerbil"
                    ".data"
                    "docs"
                    "t"
                    "t/fixtures/negative"
                    "user-interface"))
   '("src/module-system/init-syntax"
     "user-interface/init"
     "user-interface/custom/my-module/config"
     (exe: "src/cli" bin: "poo-flow"))))

(defbuild-script +poo-flow-build-spec+
  parallelize: 1
  optimize: #f
  debug: #f)
