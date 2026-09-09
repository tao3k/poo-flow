#!/usr/bin/env gxi
;;; Canonical compiler owner for the downstream native conformance program.
(import :std/make
        (only-in :asp-gerbil-scheme/src/package-build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-development-builder-profile)
        :gerbil-scheme-rust/scheme/program-build)

(def +build-directory+ (path-directory (this-source-file)))

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

(def (main output-dir)
  (let* ((root (path-normalize (path-expand "../../../../" +build-directory+)))
         (stage (path-expand "gerbil" output-dir))
         (library (path-expand "lib" stage)))
    ;; Keep the caller's dependency load path, but publish this graph's own
    ;; signatures/AOT units in the build output, not the shared package cache.
    (setenv "GERBIL_PATH" stage)
    (add-load-path! library)
    (make (cedar-conformance-spec)
          srcdir: root libdir: library
          build-deps: (path-expand "build-deps" output-dir)
          optimize: #t parallelize: #f)
    (gerbil-rs-stage-program (path-expand "scheme/conformance.ss" +build-directory+) output-dir)))
