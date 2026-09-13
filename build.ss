#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(def +public-entry-modules+
  '("src/core/api.ss"
    "src/module-system/interface.ss"
    "src/feature-system/interface.ss"))

(asp-gerbil-scheme-package-spec!
 (poo-flow-library-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
 (spec poo-flow-library-spec)
 (public-entry-modules +public-entry-modules+))

(defbuild-script (poo-flow-library-spec))
