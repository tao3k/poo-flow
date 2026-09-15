#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import (only-in :std/build-script defbuild-script)
        (only-in :std/sort sort)
        (only-in :asp-gerbil-scheme/src/build-api/source-bootstrap
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype)
        (only-in :asp-gerbil-scheme/src/build-api/native-spec-support
                 default-exclude-dirs))

;;; The default library profile is the stable public framework surface.  Module
;;; catalogs, tools, bindings, and tests are explicit release consumers; adding
;;; a maintained module therefore does not widen the ordinary warm build.
(def +library-public-entry-modules+
  '("src/core/api.ss"
    "src/module-system/interface.ss"
    "src/feature-system/interface.ss"))

(def (poo-flow-maintained-module-public-entry-modules)
  (sort
   (filter-map
    (lambda (name)
      (let (entry
            (path-expand "interface.ss"
                         (path-expand name "src/modules")))
        (and (file-exists? entry) entry)))
    (directory-files "src/modules"))
   string<?))

(def +release-product-entry-modules+
  '("src/module-system/contribution/interface.ss"
    "src/module-system/contribution/model.ss"
    "src/module-system/contribution/verification.ss"
    "src/feature-system/bundle-v1-composition-writer.ss"
    "src/modules/funflow/runtime-load-projection.ss"
    "src/modules/nono-sandbox/c-binding.ss"))

(def +release-public-entry-modules+
  (append +library-public-entry-modules+
          (poo-flow-maintained-module-public-entry-modules)
          +release-product-entry-modules+))

(def +test-exclude-dirs+
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
 (poo-flow-library-package-spec
 @ asp-gerbil-scheme-library-package-prototype)
 (spec poo-flow-library-spec)
 (public-entry-modules +library-public-entry-modules+)
 (exclude-modules '("src/modules/nono-sandbox/_nono.ss"))
 (native-prelude-spec
  `((gxc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,+nono-c-include-option+
          "-ld-options" ,+nono-c-link-option+))))

(asp-gerbil-scheme-package-spec!
 (poo-flow-release-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
 (spec poo-flow-release-spec)
 (public-entry-modules +release-public-entry-modules+)
 (exclude-modules '("src/modules/nono-sandbox/_nono.ss"))
 (native-prelude-spec
  `((gxc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,+nono-c-include-option+
          "-ld-options" ,+nono-c-link-option+))))

;;; Unit tests deliberately use a separate complete source image.  Omitting
;;; modules and public-entry-modules selects ASP's native package catalog; the
;;; default library and release projections stay independent of test imports.
(asp-gerbil-scheme-package-spec!
 (poo-flow-test-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
 (spec poo-flow-test-spec)
 (exclude-dirs +test-exclude-dirs+)
 (exclude-modules '("src/modules/nono-sandbox/_nono.ss"))
 (native-prelude-spec
  `((gxc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,+nono-c-include-option+
          "-ld-options" ,+nono-c-link-option+))))

(def (poo-flow-build-observability-enabled?)
  (alet (value (getenv "GERBIL_BUILD_VERBOSE" #f))
    (alet (level (string->number value))
      (and (real? level) (> level 0)))))

(def (poo-flow-observed-library-spec)
  (let* ((started (current-jiffy))
         (profile-name (getenv "POO_FLOW_BUILD_PROFILE" "library"))
         (projector
          (cond
           ((equal? profile-name "library") poo-flow-library-spec)
           ((equal? profile-name "release") poo-flow-release-spec)
           ((equal? profile-name "test") poo-flow-test-spec)
           (else
            (error "unsupported POO Flow build profile" profile-name)))))
    (when (poo-flow-build-observability-enabled?)
      (displayln "[poo-flow] phase=spec-start profile=" profile-name
                 " executor=asp-build-api/std-make")
      (force-output))
    (let (spec (projector))
      (when (poo-flow-build-observability-enabled?)
        (displayln "[poo-flow] phase=spec-projected profile=" profile-name
                   " target-count="
                   (length spec)
                   " elapsedNs="
                   (quotient (* (- (current-jiffy) started) 1000000000)
                             (jiffies-per-second))
                   " executor=asp-build-api/std-make")
        (force-output))
      spec)))

(defbuild-script (poo-flow-observed-library-spec))
