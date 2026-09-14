#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 all-gerbil-modules
                 default-exclude-dirs))

;;; PackageSpec owns the complete maintained source closure.  These bootstrap
;;; roots stay explicit because build.ss must load after `gerbil clean`, before
;;; any :poo-flow library module exists.  Runtime module discovery still uses
;;; the public collection loader; the build script does not duplicate it.
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

(def +maintained-module-entry-modules+
  '("src/modules/agent-sandbox/interface.ss"
    "src/modules/cubeSandbox/interface.ss"
    "src/modules/custom-task/interface.ss"
    "src/modules/docker-sandbox/interface.ss"
    "src/modules/docker/interface.ss"
    "src/modules/funflow/interface.ss"
    "src/modules/governor/interface.ss"
    "src/modules/loop-engine/interface.ss"
    "src/modules/memory-core/interface.ss"
    "src/modules/model-core/interface.ss"
    "src/modules/nono-sandbox/interface.ss"
    "src/modules/sandbox-core/interface.ss"
    "src/modules/session-core/interface.ss"
    "src/modules/session/interface.ss"
    "src/modules/text/interface.ss"
    "src/modules/tool-core/interface.ss"
    "src/modules/workflow/interface.ss"))

(def +public-entry-modules+
  (append
   +maintained-public-entry-modules+
   +maintained-module-entry-modules+))

;;; Public entries define the supported import surface; the native catalog is
;;; intentionally broader because tests and runtime contracts dynamically load
;;; maintained leaf modules.  Catalog acquisition is the ASP projection of
;;; clan/filesystem find-files and std/make remains the sole build executor.
(def +native-exclude-dirs+
  (append '("lambda-episteme"
            "bindings"
            "packages"
            "target"
            "user-interface/cases"
            "user-interface/profiles"
            "user-interface/custom/my-module/cases"
            "user-interface/custom/my-module/profiles")
          default-exclude-dirs))

(def (poo-flow-native-modules)
  (all-gerbil-modules exclude-dirs: +native-exclude-dirs+))

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
 (modules poo-flow-native-modules)
 (public-entry-modules +public-entry-modules+)
 (exclude-dirs +native-exclude-dirs+)
 (exclude-modules '("src/modules/nono-sandbox/_nono.ss"))
 (native-prelude-spec
  `((gxc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,+nono-c-include-option+
          "-ld-options" ,+nono-c-link-option+))))

(defbuild-script (poo-flow-library-spec))
