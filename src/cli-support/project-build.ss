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
        (only-in :clan/poo/object .o .ref)
        (only-in :std/crypto
                 digest-final!
                 digest-update!
                 digest::sha256
                 make-digest)
        (only-in :std/srfi/1 filter)
        (only-in :std/srfi/13 string-suffix?)
        (only-in :std/srfi/19 current-time time-nanosecond time-second)
        (only-in :std/misc/path path-expand path-normalize)
        (only-in :std/misc/ports read-file-u8vector)
        (only-in :std/text/hex hex-encode)
        (only-in :gslph/src/building/facade
                 build-plan-receipts-summary
                 make-package-source-stage
                 package-source-stage-label
                 package-source-stage-source
                 package-source-stage-specs
                 package-source-stages->requests
                 package-source-stages-clean!
                 package-source-stages-run!
                 package-source-stages-spec)
        (only-in :gslph/src/building/std-builder
                 execution-window-controller?)
        "../build-api/adaptive-execution-window.ss")

(export poo-flow-project-build-options
        poo-flow-project-build-execution-policy
        poo-flow-project-build-source-identity
        poo-flow-project-build-stage-labels
        poo-flow-project-build-spec
        poo-flow-project-clean-package-outputs!
        poo-flow-project-clean!
        poo-flow-project-compile!
        poo-flow-project-compile-with-source-identity!
        poo-flow-project-configure-build-root!
        poo-flow-project-build-requests
        poo-flow-project-adaptive-cold-gate-available?)

(def poo-flow-project-root #f)
(def +poo-flow-project-build-root-environment-name+
  "POO_FLOW_PROJECT_BUILD_ROOT")
(def +poo-flow-project-build-execution-policy-environment-name+
  "POO_FLOW_BUILD_EXECUTION_POLICY")
(def +poo-flow-project-build-source-identity-schema+
  'poo-flow.project-build-source-identity.v1)

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
  (let (normalized-root (path-normalize root))
    (set! poo-flow-project-root normalized-root)
    ;; Build entrypoints can load the source and compiled forms of this module
    ;; in distinct Gerbil instantiations.  Keep the configured source root in a
    ;; process-wide slot so every Building Framework boundary resolves the same
    ;; explicit value without assuming module-instance identity.
    (setenv +poo-flow-project-build-root-environment-name+ normalized-root))
  (unless (getenv "GERBIL_PATH" #f)
    (setenv "GERBIL_PATH"
            (path-expand ".gerbil" poo-flow-project-root))))

;; : (-> Path)
(def (poo-flow-project-require-build-root)
  (or poo-flow-project-root
      (and (getenv +poo-flow-project-build-root-environment-name+ #f)
           (path-normalize
            (getenv +poo-flow-project-build-root-environment-name+)))
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

(def (poo-flow-project-build-nonnegative-integer-from-env name fallback)
  (let* ((raw (getenv name #f))
         (configured (and raw (string->number raw))))
    (cond
     ((not raw) fallback)
     ((and (integer? configured) (>= configured 0)) configured)
     (else
      (error "build environment value must be a nonnegative integer"
             name raw)))))

(def (poo-flow-project-build-execution-policy)
  (let (raw
        (getenv
         +poo-flow-project-build-execution-policy-environment-name+
         #f))
    (cond
     ((or (not raw) (equal? raw "") (equal? raw "topology"))
      'topology)
     ((equal? raw "adaptive-window")
      'adaptive-window)
     (else
      (error "unknown POO Flow build execution policy" raw)))))

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

(def (poo-flow-project-adaptive-controller-from-env)
  (case (poo-flow-project-build-execution-policy)
    ((topology) #f)
    ((adaptive-window)
     (let (hard-max-rss-bytes
           (poo-flow-project-build-positive-integer-from-env
            "POO_FLOW_BUILD_MAX_RSS_BYTES"))
       (unless hard-max-rss-bytes
         (error
          "adaptive-window policy requires POO_FLOW_BUILD_MAX_RSS_BYTES"))
       (let (headroom-bytes
             (poo-flow-project-build-nonnegative-integer-from-env
              "POO_FLOW_BUILD_RSS_HEADROOM_BYTES" 0))
         (make-poo-flow-adaptive-execution-window-controller
          (poo-flow-project-build-worker-count)
          hard-max-rss-bytes
          headroom-bytes))))))

(def (poo-flow-project-resolve-adaptive-controller controller)
  (cond
   ((execution-window-controller? controller) controller)
   (controller
    (error "invalid POO Flow adaptive execution-window controller"
           controller))
   (else (poo-flow-project-adaptive-controller-from-env))))

(def (poo-flow-project-adaptive-cold-gate-available? (controller #f))
  (and (poo-flow-project-resolve-adaptive-controller controller) #t))

(def (poo-flow-project-source-stages include-ffi? (controller #f))
  (unless (or (not controller) (execution-window-controller? controller))
    (error "invalid explicit execution-window controller" controller))
  (let* ((runtime-batching (or controller 'topology))
         (root (poo-flow-project-require-build-root))
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
        runtime-batching)
       (make-package-source-stage
       +poo-flow-project-user-interface-stage-label+
        root
        "poo-flow"
        (poo-flow-project-prefix-modules
         "user-interface/"
         +poo-flow-project-user-interface-modules+)
         runtime-batching)))))

(def (poo-flow-project-build-spec-kind spec)
  (if (string? spec)
    'module
    (car spec)))

(def (poo-flow-project-build-spec-module spec)
  (if (string? spec)
    spec
    (cadr spec)))

(def (poo-flow-project-build-spec-source-path stage spec)
  (let* ((module (poo-flow-project-build-spec-module spec))
         (kind
          (object->string (poo-flow-project-build-spec-kind spec)))
         (source
          (cond
           ((string-suffix? ".ss" module) module)
           ((equal? kind "gsc:") (string-append module ".scm"))
           ((equal? kind "ssi:") (string-append module ".ssi"))
           (else (string-append module ".ss")))))
    (path-expand
     source
     (package-source-stage-source stage))))

(def (poo-flow-project-build-source-identity-update-token! digest token)
  (let (token-bytes (string->utf8 token))
    ;; Materialize the canonical token boundary as bytes.  Besides avoiding
    ;; port-based digest updates in the inner source loop, byte length keeps
    ;; the identity unambiguous for non-ASCII paths.
    (digest-update!
     digest
     (string->utf8 (number->string (u8vector-length token-bytes))))
    (digest-update! digest (string->utf8 ":"))
    (digest-update! digest token-bytes)))

(def (poo-flow-project-build-source-identity-update-spec!
      digest stage spec)
  (let* ((source-path
          (poo-flow-project-build-spec-source-path stage spec))
         (source-content (read-file-u8vector source-path)))
    (for-each
     (lambda (token)
       (poo-flow-project-build-source-identity-update-token! digest token))
     (list
      (package-source-stage-label stage)
      (object->string (poo-flow-project-build-spec-kind spec))
      (poo-flow-project-build-spec-module spec)
      (number->string (u8vector-length source-content))))
    (digest-update! digest source-content)))

(def (poo-flow-project-build-source-identity (stages #f))
  (let* ((stage-graph
          (or stages (poo-flow-project-source-stages #t)))
         (source-digest-state (make-digest digest::sha256)))
    (poo-flow-project-build-source-identity-update-token!
     source-digest-state
     (symbol->string +poo-flow-project-build-source-identity-schema+))
    (for-each
     (lambda (stage)
       (for-each
        (lambda (spec)
          (poo-flow-project-build-source-identity-update-spec!
           source-digest-state stage spec))
        (package-source-stage-specs stage)))
     stage-graph)
    (.o
     (schema +poo-flow-project-build-source-identity-schema+)
     (algorithm 'sha256)
     (digest (hex-encode (digest-final! source-digest-state)))
     (stage-count (length stage-graph))
     (spec-count
      (apply +
             (map (lambda (stage)
                    (length (package-source-stage-specs stage)))
                  stage-graph)))
     (stages
      (map
       (lambda (stage)
         (.o
          (label (package-source-stage-label stage))
          (spec-count (length (package-source-stage-specs stage)))))
       stage-graph)))))

;; : (-> [BuildOption] [BuildRequest])
(def (poo-flow-project-build-requests options (controller #f))
  (let (adaptive-controller
        (poo-flow-project-resolve-adaptive-controller controller))
    (package-source-stages->requests
     (poo-flow-project-source-stages #t adaptive-controller)
     options)))

;; : (-> [BuildOption] [[ModulePath]])
(def (poo-flow-project-build-spec options (controller #f))
  (let (adaptive-controller
        (poo-flow-project-resolve-adaptive-controller controller))
    (package-source-stages-spec
     (poo-flow-project-source-stages #t adaptive-controller))))

(def (poo-flow-project-build-current-milliseconds)
  (let (now (current-time))
    (+ (* (time-second now) 1000)
       (quotient (time-nanosecond now) 1000000))))

;; : (-> [BuildOption] [BuildStageReceipt])
(def (poo-flow-project-compile-with-source-identity!
      options (controller #f))
  (let (adaptive-controller
        (poo-flow-project-resolve-adaptive-controller controller))
    (let* ((stages
            (poo-flow-project-source-stages #t adaptive-controller))
           (identity-materialization-start-ms
            (poo-flow-project-build-current-milliseconds))
           (identity-value
            (poo-flow-project-build-source-identity stages))
           (identity-materialization-duration-ms
            (- (poo-flow-project-build-current-milliseconds)
               identity-materialization-start-ms))
           (build-summary-value
            (build-plan-receipts-summary
             (package-source-stages-run!
              stages
              (append
               options
               [parallelize:
                (poo-flow-project-sync-build-worker-count!)])))))
      (.o
       (schema 'poo-flow.project-compile-result.v1)
       (source-identity identity-value)
       (source-identity-materialization-elapsed-ms
        identity-materialization-duration-ms)
       (build build-summary-value)))))

(def (poo-flow-project-compile! options (controller #f))
  (.ref
   (poo-flow-project-compile-with-source-identity!
    options controller)
   'build))

;; : (-> Void)
(def (poo-flow-project-clean!)
  (package-source-stages-clean!
   (poo-flow-project-source-stages #f))
  (poo-flow-project-clean-package-outputs!
   (or (getenv "GERBIL_PATH" #f) ".gerbil"))
  #!void)
(export poo-flow-project-source-stages)
