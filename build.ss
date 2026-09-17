#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; Unique native POO Flow package build entry.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/building-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 default-exclude-dirs))

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

;;; Gambit emits a loadable bundle for begin-ffi modules on Darwin.  The
;;; process/AOT consumer supplies libc and runtime symbols at final link time.
(def +runtime-v0-native-ffi-spec+
  (cond-expand
   (darwin
    '(gxc: "src/ffi/runtime-v0-native"
           "-ld-options" "-Wl,-undefined,dynamic_lookup"))
   (else
    '(gxc: "src/ffi/runtime-v0-native"))))

(asp-gerbil-scheme-package-spec!
 (poo-flow-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
 (spec poo-flow-native-spec)
 (exclude-dirs +poo-flow-build-exclude-dirs+)
 (exclude-modules '("src/modules/nono-sandbox/_nono.ss"
                    "src/ffi/runtime-v0-native.ss"
                    "observe-contribute-import.ss"
                    "performance-tests.ss"
                    "run-contribute-test.ss"
                    "user-interface/custom/my-module/config.ss"))
 (native-prelude-spec
  `((gxc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,+nono-c-include-option+
          "-ld-options" ,+nono-c-link-option+)))
 (extra-spec `(,+runtime-v0-native-ffi-spec+)))

(defbuild-script (poo-flow-native-spec))
