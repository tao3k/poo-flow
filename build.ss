#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; Unique native POO Flow package build entry.

(import (only-in :std/build-script defbuild-script)
        (only-in :clan/poo/object .get)
        (only-in :asp-gerbil-scheme/src/build-api/source-bootstrap
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype)
        (only-in :asp-gerbil-scheme/src/build-api/native-spec-support
                 default-exclude-dirs)
        (only-in "./src/module-system/observability/build-projection.ss"
                 poo-flow-make-observed-package-spec-projector)
        (only-in "./src/module-system/observability/config.ss"
                 poo-flow-default-build-observability-policy))

;;; ASP's PackageSpec default owns the native package source catalog. Omitting
;;; modules and public-entry-modules is intentional: this entry constructs no
;;; second discovery function or eager Import Model closure.
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
 (spec-projector
  (poo-flow-make-observed-package-spec-projector
   (.get asp-gerbil-scheme-library-package-prototype spec-projector)
   poo-flow-default-build-observability-policy))
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
