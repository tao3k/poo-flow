#!/usr/bin/env gxi

(import (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype)
        (only-in :std/build-script defbuild-script))

(asp-gerbil-scheme-package-spec!
 (compile-budget-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
 (spec spec)
 (modules ["t/support/compile-performance-budget.ss"]))

(defbuild-script (spec))
