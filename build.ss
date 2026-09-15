#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; Unique native POO Flow package build entry.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/src/build-api/source-bootstrap
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype)
        (only-in :asp-gerbil-scheme/src/build-api/native-spec-support
                 default-exclude-dirs))

;;; These stable public interfaces are the only declared package roots.  ASP's
;;; native Import Model projects their complete production closure before the
;;; resulting BuildSpec is handed to std/make.
(def +poo-flow-public-entry-modules+
  '("src/core/api.ss"
    "src/module-system/api.ss"
    "src/feature-system/interface.ss"
    "src/user-interface/facade.ss"))

(def +poo-flow-build-exclude-dirs+
  (append '("lambda-episteme"
            "bindings"
            "packages"
            "target"
            "user-interface/cases"
            "user-interface/profiles"
            "user-interface/custom/my-module/cases"
            "user-interface/custom/my-module/profiles")
          default-exclude-dirs))

(def +nono-c-include-option+
  (string-append
   "-I"
   (path-expand "bindings/nono-c" (current-directory))))

(def +nono-c-link-option+
  (cond-expand
   (darwin "-Wl,-undefined,dynamic_lookup")
   (else "-ldl")))

(asp-gerbil-scheme-package-spec!
 (poo-flow-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
 (spec poo-flow-native-spec)
 (public-entry-modules +poo-flow-public-entry-modules+)
 (exclude-dirs +poo-flow-build-exclude-dirs+)
 (exclude-modules '("src/modules/nono-sandbox/_nono.ss"
                    "observe-contribute-import.ss"
                    "observe-contribute-test.ss"
                    "user-interface/custom/my-module/config.ss"))
 (native-prelude-spec
  `((gxc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,+nono-c-include-option+
          "-ld-options" ,+nono-c-link-option+))))

(defbuild-script (poo-flow-native-spec))
