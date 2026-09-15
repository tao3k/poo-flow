#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/src/build-api/source-bootstrap
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(def +roots+
  '("src/core/api.ss"
    "src/module-system/api.ss"
    "src/feature-system/interface.ss"
    "src/user-interface/facade.ss"))

(asp-gerbil-scheme-package-spec!
 (root-mode-modules @ asp-gerbil-scheme-library-package-prototype)
 (spec root-mode-modules-spec)
 (modules +roots+))

(defbuild-script (root-mode-modules-spec))
