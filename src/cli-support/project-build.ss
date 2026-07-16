;;; -*- Gerbil -*-
;;; POO Flow package declaration for the upstream Building Framework.

(import (only-in :gerbil/gambit
                 current-directory
                 delete-directory
                 delete-file
                 directory-files
                 file-exists?
                 file-info
                 file-info-type)
        (only-in :gerbil/compiler/base __available-cores)
        (only-in :clan/building all-gerbil-modules)
        (only-in :std/srfi/1 filter)
        (only-in :std/misc/path path-expand path-normalize)
        (only-in :gslph/src/building/facade
                 build-plan-receipts-summary
                 make-package-source-stage
                 package-source-stages->requests
                 package-source-stages-clean!
                 package-source-stages-run!
                 package-source-stages-spec))

(export poo-flow-project-build-options
        poo-flow-project-build-stage-labels
        poo-flow-project-build-spec
        poo-flow-project-clean-package-outputs!
        poo-flow-project-clean!
        poo-flow-project-compile!
        poo-flow-project-configure-build-root!
        poo-flow-project-build-requests)

(def poo-flow-project-root #f)

(def +poo-flow-project-ffi-stage-label+ "nono-c-ffi")
(def +poo-flow-project-runtime-stage-label+ "runtime")
(def +poo-flow-project-user-interface-stage-label+ "user-interface")

;; : (-> [String])
(def (poo-flow-project-build-stage-labels)
  (list +poo-flow-project-ffi-stage-label+
        +poo-flow-project-runtime-stage-label+
        +poo-flow-project-user-interface-stage-label+))

(def (poo-flow-project-nono-c-binding-include-option)
  (string-append "-I" (path-expand "bindings/nono-c")))

(def (poo-flow-project-nono-c-binding-link-options)
  (cond-expand
    (darwin '("-ld-options" "-Wl,-undefined,dynamic_lookup"))
    (else '("-ld-options" "-ldl"))))

(def (poo-flow-project-ffi-build-spec)
  `((gsc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,(poo-flow-project-nono-c-binding-include-option)
          ,@(poo-flow-project-nono-c-binding-link-options))
    (ssi: "src/modules/nono-sandbox/_nono")))

(def (poo-flow-project-delete-output-tree! path)
  (when (file-exists? path)
    (if (eq? (file-info-type (file-info path)) 'directory)
      (begin
        (for-each
         (lambda (name)
           (unless (member name '("." ".."))
             (poo-flow-project-delete-output-tree!
              (path-expand name path))))
         (directory-files path))
        (delete-directory path))
      (delete-file path))))

;; : (-> Path Void)
(def (poo-flow-project-clean-package-outputs! gerbil-path)
  (poo-flow-project-delete-output-tree!
   (path-expand "lib/poo-flow" gerbil-path))
  #!void)

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
  (set! poo-flow-project-root (path-normalize root))
  (unless (getenv "GERBIL_PATH" #f)
    (setenv "GERBIL_PATH"
            (path-expand ".gerbil" poo-flow-project-root))))

;; : (-> Path)
(def (poo-flow-project-require-build-root)
  (or poo-flow-project-root
      (error "POO Flow build root is not configured")))

;; : (-> Boolean Boolean Boolean Boolean [BuildOption])
(def (poo-flow-project-build-options release optimized debug verbose)
  (append (if release [build-release: #t] [])
          (if optimized [build-optimized: #t] [])
          (if debug [debug: #t] [])
          (if verbose [verbose: 1] [])))

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

(def (poo-flow-project-source-stages include-ffi?)
  (let* ((root (poo-flow-project-require-build-root))
         (runtime-root (path-expand "src" root))
         (interface-root (path-expand "user-interface" root)))
    (append
     (if include-ffi?
       (list
         (make-package-source-stage
          +poo-flow-project-ffi-stage-label+
         root
         "poo-flow"
         (poo-flow-project-ffi-build-spec)
         #t))
       '())
     (list
       (make-package-source-stage
        +poo-flow-project-runtime-stage-label+
       root
       "poo-flow"
       (map poo-flow-project-runtime-spec
            (filter poo-flow-project-runtime-module?
                    (poo-flow-project-source-modules runtime-root)))
       'topology)
       (make-package-source-stage
        +poo-flow-project-user-interface-stage-label+
       root
       "poo-flow"
       (poo-flow-project-prefix-modules
        "user-interface/"
        +poo-flow-project-user-interface-modules+)
       'topology)))))

;; : (-> [BuildOption] [BuildRequest])
(def (poo-flow-project-build-requests options)
  (package-source-stages->requests
   (poo-flow-project-source-stages #t)
   options))

;; : (-> [BuildOption] [[ModulePath]])
(def (poo-flow-project-build-spec options)
  (package-source-stages-spec
   (poo-flow-project-source-stages #t)))

;; : (-> [BuildOption] [BuildStageReceipt])
(def (poo-flow-project-compile! options)
  (build-plan-receipts-summary
   (package-source-stages-run!
    (poo-flow-project-source-stages #t)
    (append options
            [parallelize: (poo-flow-project-sync-build-worker-count!)]))))

;; : (-> Void)
(def (poo-flow-project-clean!)
  (package-source-stages-clean!
   (poo-flow-project-source-stages #f))
  (poo-flow-project-clean-package-outputs!
   (or (getenv "GERBIL_PATH" #f) ".gerbil"))
  #!void)
