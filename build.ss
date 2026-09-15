#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

;;; This is the package bootstrap closure. build.ss cannot import a :poo-flow
;;; module before the package exists in a clean Bazel/gxpkg image. Concrete
;;; module discovery and selection begin after these stable interfaces exist;
;;; catalog size therefore does not widen this bootstrap BuildSpec. Advanced
;;; init syntax, configuration discovery and declaration cases are registered
;;; lazy framework sources; the ordinary init.ss path does not compile them.
(def +framework-public-entry-modules+
  '("src/core/api.ss"
    "src/module-system/api.ss"
    "src/feature-system/interface.ss"
    "src/loops/agent.ss"
    "src/profiles/kernel/interface.ss"
    "src/module-system/observability/testing-extension.ss"
    "src/user-interface/facade.ss"))

(def +public-entry-modules+
  +framework-public-entry-modules+)

(def +nono-c-include-option+
  (string-append
   "-I"
   (path-expand "bindings/nono-c" (current-directory))))

(def +nono-c-link-option+
  (cond-expand
   (darwin "-Wl,-undefined,dynamic_lookup")
   (else "-ldl")))

(def (poo-flow-public-entry-modules)
  (displayln "[poo-flow] phase=spec-projected target-count="
             (length +public-entry-modules+)
             " framework-target-count="
             (length +framework-public-entry-modules+)
             " catalog-target-count=0"
             " executor=asp-build-api/std-make")
  (force-output)
  +public-entry-modules+)

(asp-gerbil-scheme-package-spec!
 (poo-flow-library-package-spec
 @ asp-gerbil-scheme-library-package-prototype)
 (spec poo-flow-library-spec)
 (modules poo-flow-public-entry-modules)
 (public-entry-modules +public-entry-modules+)
 (exclude-modules '("src/modules/nono-sandbox/_nono.ss"))
 (native-prelude-spec
  `((gxc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,+nono-c-include-option+
          "-ld-options" ,+nono-c-link-option+))))

(defbuild-script (poo-flow-library-spec))
