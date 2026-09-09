#!/usr/bin/env gxi
;;; Canonical compiler owner for the downstream native conformance program.
(import (only-in :asp-gerbil-scheme/src/package-build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-development-builder-profile)
        (only-in "./scheme/conformance-build-runtime"
                 cedar-conformance-build!))

;; This is a bounded native projection of the parent POO Flow package, not a
;; new package or source-catalog authority. Dependencies come from the parent
;; gerbil.pkg, including ASP's declarative build API.
(asp-gerbil-scheme-package-spec!
 (cedar-conformance-package @ asp-gerbil-scheme-library-package-prototype)
 (spec cedar-conformance-spec)
 (profile asp-gerbil-scheme-development-builder-profile)
 (source-catalog-authority #f)
 (modules ["src/module-system/object-family/syntax.ss"
           "src/policy/cedar-authority.ss"
           "bindings/cedar-gerbil/crates/cedar-gerbil/scheme/conformance.ss"]))

;; : (-> Path Void)
(def (main output-dir)
  (cedar-conformance-build! (cedar-conformance-spec) output-dir))
