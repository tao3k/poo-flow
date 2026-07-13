;;; -*- Gerbil -*-
;;; POO Flow package declaration for the upstream Building Framework.

(import (only-in :gerbil/gambit current-directory)
        (only-in :gerbil/compiler/base __available-cores)
        (only-in :clan/building all-gerbil-modules)
        (only-in :std/srfi/1 filter filter-map)
        (only-in :std/misc/path path-expand path-normalize)
        :gslph/src/building/facade)

(export poo-flow-project-build-options
        poo-flow-project-build-spec
        poo-flow-project-clean!
        poo-flow-project-compile!
        poo-flow-project-configure-build-root!
        poo-flow-project-build-requests)

(def poo-flow-project-root #f)

(def +poo-flow-project-interface-only-modules+
  '("module-system/object-family-syntax.ss"
    "module-system/init-syntax.ss"))


;;; Declarative UI roots are package modules; individual case files remain
;;; composition inputs loaded by these owners rather than standalone libraries.
;; : [ModulePath]
(def +poo-flow-project-user-interface-modules+
  '("init.ss"
    "custom/my-module/profiles/all.ss"
    "custom/my-module/cases/cicd-owner.ss"
    "custom/my-module/cases/loop-engine-owner.ss"
    "custom/my-module/cases/session-owner.ss"
    "custom/my-module/cases/runtime-owner.ss"
    "custom/my-module/cases/durable-owner.ss"
    "custom/my-module/config.ss"))

;; : (-> Path Void)
(def (poo-flow-project-configure-build-root! root)
  (set! poo-flow-project-root (path-normalize root)))

;; : (-> Path)
(def (poo-flow-project-require-build-root)
  (or poo-flow-project-root
      (error "POO Flow build root is not configured")))

;; : (-> Boolean Boolean Boolean Boolean [BuildOption])
(def (poo-flow-project-build-options release optimized debug verbose)
  (apply append
         (filter-map
          (lambda (entry)
            (and (car entry) (cdr entry)))
          `((,release . [build-release: #t])
            (,optimized . [build-optimized: #t])
            (,debug . [debug: #t])
            (,verbose . [verbose: 9])))))

;; : (-> Path [ModulePath])
(def (poo-flow-project-source-modules source-root)
  (let (previous-directory (current-directory))
    (dynamic-wind
      (lambda () (current-directory source-root))
      (lambda () (reverse (all-gerbil-modules)))
      (lambda () (current-directory previous-directory)))))

;; : (-> ModulePath Boolean)
(def (poo-flow-project-runtime-module? module)
  (not (equal? module "modules/nono-sandbox/_nono.ss")))

;; : (-> ModulePath BuildSpec)
(def (poo-flow-project-runtime-spec module)
  (let (path (string-append "src/" module))
    (if (member module +poo-flow-project-interface-only-modules+)
      [ssi: path]
      path)))

;; : (-> String [ModulePath] [BuildSpec])
(def (poo-flow-project-prefix-modules prefix modules)
  (map (lambda (module)
         (string-append prefix module))
       modules))

;; : (-> [PackageSourceStage])
(def (poo-flow-project-build-positive-integer-from-env name)
  (let* ((raw (getenv name #f))
         (configured (and raw (string->number raw))))
    (and configured
         (integer? configured)
         (> configured 0)
         configured)))

(def (poo-flow-project-build-worker-count)
  (or (poo-flow-project-build-positive-integer-from-env "GERBIL_BUILD_CORES")
      (poo-flow-project-build-positive-integer-from-env "CARGO_BUILD_JOBS")
      (poo-flow-project-build-positive-integer-from-env "NUM_JOBS")
      (max 1 (##cpu-count))))

(def (poo-flow-project-sync-build-worker-count!)
  (let (worker-count (poo-flow-project-build-worker-count))
    (set! __available-cores worker-count)
    (setenv "GERBIL_BUILD_CORES" (number->string worker-count))
    worker-count))

(def (poo-flow-project-source-stages)
  (let* ((root (poo-flow-project-require-build-root))
         (runtime-root (path-expand "src" root))
         (interface-root (path-expand "user-interface" root)))
    (list
     (make-package-source-stage
      "runtime"
      root
      "poo-flow"
      (map poo-flow-project-runtime-spec
           (filter poo-flow-project-runtime-module?
                   (poo-flow-project-source-modules runtime-root)))
      'topology)
     (make-package-source-stage
      "user-interface"
      root
      "poo-flow"
      (poo-flow-project-prefix-modules
       "user-interface/"
       +poo-flow-project-user-interface-modules+)
      'topology))))

;; : (-> [BuildOption] [BuildRequest])
(def (poo-flow-project-build-requests options)
  (package-source-stages->requests
   (poo-flow-project-source-stages)
   options))

;; : (-> [BuildOption] [[ModulePath]])
(def (poo-flow-project-build-spec options)
  (package-source-stages-spec
   (poo-flow-project-source-stages)))

;; : (-> [BuildOption] [BuildStageReceipt])
(def (poo-flow-project-compile! options)
  (build-plan-receipts-summary
   (package-source-stages-run!
    (poo-flow-project-source-stages)
    (append options
            [parallelize: (poo-flow-project-sync-build-worker-count!)]))))

;; : (-> Void)
(def (poo-flow-project-clean!)
  (package-source-stages-clean!
   (poo-flow-project-source-stages))
  #!void)
