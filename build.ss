#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Native POO Flow package build declaration.

(import :std/make
        :clan/building
        (only-in :std/misc/path path-expand)
        (only-in :std/srfi/1 fold)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :asp-gerbil-scheme/src/build-api/package-spec
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-package-build-profile
                 asp-gerbil-scheme-package-native-spec)
        (only-in :asp-gerbil-scheme/src/building/build-script
                 defbuild-script
                 framework-build-bindir))

(def +interface-only-modules+
  '("src/module-system/object-family-syntax.ss"
    "src/module-system/init-syntax.ss"))

(def +excluded-runtime-modules+
  '("src/contract/dependency-source-identity.ss"
    "src/modules/nono-sandbox/_nono.ss"))

(def +user-interface-modules+
  '("user-interface/init.ss"
    "user-interface/custom/my-module/profiles/all.ss"
    "user-interface/custom/my-module/cases/cicd-owner.ss"
    "user-interface/custom/my-module/cases/loop-engine-owner.ss"
    "user-interface/custom/my-module/cases/session-owner.ss"
    "user-interface/custom/my-module/cases/runtime-owner.ss"
    "user-interface/custom/my-module/cases/durable-owner.ss"
    "user-interface/custom/my-module/config.ss"))

(def +project-discovery-exclude-directories+
  '("run" ".git" "_darcs" ".gerbil" ".data" ".devenv" ".direnv"
    "bazel-bin" "bazel-out" "bazel-testlogs"
    "benchmarks" "bindings" "docs" "packages" "proofs" "tools"))

(def (project-source-module? module)
  (or (string-prefix? "src/" module)
      (string-prefix? "t/" module)
      (string-prefix? "user-interface/" module)))

(def (runtime-module? module)
  (and (string-prefix? "src/" module)
       (not (string-prefix? "src/build-api/" module))
       (not (string-prefix? "src/cli-support/" module))
       (not (string-prefix? "src/testing/" module))))

(def +project-modules+
  (filter project-source-module?
          (all-gerbil-modules
           exclude-dirs: +project-discovery-exclude-directories+)))

(def (remove-build-files specs modules)
  (fold (lambda (module current)
          (remove-build-file current module))
        specs
        modules))

(def (interface-only-specs specs)
  (fold (lambda (module current)
          (cons [ssi: module]
                (remove-build-file current module)))
        specs
        +interface-only-modules+))

(def (runtime-spec)
  (interface-only-specs
   (remove-build-files
    (filter runtime-module? +project-modules+)
    +excluded-runtime-modules+)))

(def (nono-ffi-spec)
  `((gsc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,(string-append "-I" (path-expand "bindings/nono-c"))
          ,@(cond-expand
              (darwin '("-ld-options" "-Wl,-undefined,dynamic_lookup"))
              (else '("-ld-options" "-ldl"))))
    (ssi: "src/modules/nono-sandbox/_nono")))

(asp-gerbil-scheme-package-spec!
 (poo-flow-library-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
 (modules +project-modules+)
 (source-catalog-authority 'project)
 (role 'library)
 (profile 'development)
 (roots ["src" "t" "user-interface"])
 (runtime-roots ["src"])
 (exclude-directories +project-discovery-exclude-directories+)
 (native-spec
  (append (nono-ffi-spec)
          (runtime-spec)
          +user-interface-modules+)))

(defbuild-script
 (asp-gerbil-scheme-package-native-spec
  poo-flow-library-package-spec)
 profile: (asp-gerbil-scheme-package-build-profile
           poo-flow-library-package-spec)
 bindir: (framework-build-bindir))
