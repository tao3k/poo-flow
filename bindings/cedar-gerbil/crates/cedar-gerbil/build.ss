#!/usr/bin/env gxi
;;; Canonical compiler owner for the downstream native conformance program.
(import (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 call-with-framework-native-build-memory-anomaly-guard)
        (only-in "./scheme/conformance-build-runtime"
                 cedar-conformance-build!))

;; This is a bounded native projection of the parent POO Flow package, not a
;; new package or source-catalog authority. Dependencies come from the parent
;; gerbil.pkg, including ASP's declarative build API.
(asp-gerbil-scheme-package-spec!
 (cedar-conformance-package @ asp-gerbil-scheme-library-package-prototype)
 (spec cedar-conformance-spec)
 (modules ["src/module-system/object-family/syntax.ss"
           "src/policy/cedar-authority.ss"
           "bindings/cedar-gerbil/crates/cedar-gerbil/scheme/conformance.ss"]))

;; : (-> Path Void)
(def (main output-dir)
  (call-with-framework-native-build-memory-anomaly-guard
   "poo-flow cedar conformance build"
   (lambda ()
     (cedar-conformance-build! (cedar-conformance-spec) output-dir))))
