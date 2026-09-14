#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype)
        (only-in :poo-flow/src/module-system/loader/collection
                 poo-flow-load-modules
                 poo-flow-maintained-module-source)
        (only-in :poo-flow/src/module-system/loader/source
                 poo-flow-module-source-ref-value))

;;; PackageSpec owns the complete maintained source closure.  Module collection
;;; entrypoints are discovered by the same public loader used at runtime, while
;;; public roots outside src/modules remain explicit because they do not belong
;;; to that collection.  Downstream examples under user-interface/custom are
;;; intentionally excluded from the library package.
(def +maintained-public-entry-modules+
  '("src/core/api.ss"
    "src/module-system/api.ss"
    "src/feature-system/interface.ss"
    "src/loops/agent.ss"
    "src/profiles/kernel/interface.ss"
    "src/module-system/loader/fragment-syntax.ss"
    "src/module-system/observability/module-presentation.ss"
    "src/module-system/observability/testing-extension.ss"
    "src/user-interface/facade.ss"
    "src/user-interface/init-syntax.ss"
    "src/user-interface/init-declaration-syntax.ss"
    "src/user-interface/config-discovery-syntax.ss"
    "src/user-interface/declaration-case.ss"))

(def +public-entry-modules+
  (append
   +maintained-public-entry-modules+
   (map poo-flow-module-source-ref-value
        (poo-flow-load-modules poo-flow-maintained-module-source))))

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
