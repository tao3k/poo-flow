;;; Module responsibility: declare POO Flow's package-building plan through the
;;; Harness Build API, while retaining gxc, FFI, and cache probes in domain
;;; executors.  The Framework itself remains owned by Project Harness.
(export poo-flow-package-build-stage-plan
        poo-flow-package-build-run!
        poo-flow-package-building-testing-bootstrap!
        poo-flow-package-building-testing-project!)

(import :gslph/src/build-api/framework
        (only-in "./package-build-support/options.ss"
                 poo-flow-cli-build-options?
                 poo-flow-entry-options
                 poo-flow-native-build-options?
                 poo-flow-tests-build-options?)
        (only-in "./package-build-support/specs.ss"
                 +poo-flow-cli-library-build-spec+
                 +poo-flow-ffi-build-spec+
                 +poo-flow-testing-bootstrap-build-spec+
                 +poo-flow-testing-project-build-spec+
                 poo-flow-cli-only-module-build-spec
                 poo-flow-entry-build-spec
                 poo-flow-runtime-bootstrap-build-spec
                 poo-flow-runtime-main-build-spec
                 poo-flow-test-build-spec)
        (only-in "./package-build-support/env.ss"
                 poo-flow-package-require-gxpkg-env!)
        (only-in "./package-build-support/stage-cache.ss"
                 poo-flow-stage-cache-valid?)
        (only-in "./package-build-support/engine.ss"
                 poo-flow-gxc-stage
                 poo-flow-gxc-stage/force-on-cache-miss!
                 poo-flow-make
                 poo-flow-make-bootstrap)
        (only-in "./package-build-support/launcher.ss"
                 poo-flow-write-cli-launcher!))

;;; Focused stages retain a named compiler boundary instead of passing an
;;; unstructured list through the Framework. The runner remains private to the
;;; package build adapter, while receipts stay on the Framework surface.
;; : (forall (label spec runner) (-> [label spec runner] [List]))
;; poo-flow-package-focused-stage
;;   : (-> String List List List)
(defstruct poo-flow-package-focused-stage (label spec runner))

;; : (forall (stage) (-> [stage] [BuildStageReceipt]))
;; poo-flow-package-build-focused-stage!
;;   : (-> List List [BuildStageReceipt])
(def (poo-flow-package-build-focused-stage! stage options)
  (let ((label (poo-flow-package-focused-stage-label stage))
        (spec (poo-flow-package-focused-stage-spec stage))
        (runner (poo-flow-package-focused-stage-runner stage))
        (dirty?
         (let (value #f)
           (case-lambda
            (() value)
            ((next)
             (set! value next)
             value)))))
    (poo-flow-package-require-gxpkg-env!)
    (build-plan-run!
     (list
      (make-build-stage
       label
       'poo-flow/package
       spec
       (lambda (_stage _context)
         (and (not (dirty?))
              (poo-flow-stage-cache-valid? spec options)))
       (lambda (_stage _context)
         (runner))
       (lambda (_stage _context _result)
         (dirty? #t))
       "POO Flow package compiler stage"))
     options)))

;;; Optimization boundary: only a compiled upstream stage invalidates its
;;; successors. This keeps Framework receipts truthful while preserving POO
;;; Flow's package-specific cache and native compiler invariants.
;; : (forall (options stage) (-> options [stage]))
;; poo-flow-package-build-stage-plan
;;   : (-> PooFlowBuildOptions [BuildStage])
(def (poo-flow-package-build-stage-plan options)
  (let (dirty?
        (let (value #f)
          (case-lambda
           (() value)
           ((next)
            (set! value next)
            value))))
    (let (make-stage
          (lambda (label stage runner)
            (make-build-stage
             label
             'poo-flow/package
             stage
             (lambda (_stage _context)
               (and (not (dirty?))
                    (poo-flow-stage-cache-valid? stage options)))
             (lambda (_stage _context)
               (runner (dirty?)))
             (lambda (_stage _context result)
               (when result
                 (dirty? #t)))
             "POO Flow package compiler stage")))
      (append
       (list
        (make-stage
         "runtime-bootstrap"
         (poo-flow-runtime-bootstrap-build-spec options)
         (lambda (_upstream-dirty?)
           (poo-flow-make-bootstrap
            "runtime-bootstrap"
            (poo-flow-runtime-bootstrap-build-spec options)
            options))))
       (if (poo-flow-native-build-options? options)
         (list
          (make-stage
           "ffi"
           +poo-flow-ffi-build-spec+
           (lambda (upstream-dirty?)
             (poo-flow-make "ffi"
                            +poo-flow-ffi-build-spec+
                            options
                            upstream-dirty?))))
         [])
       (list
        (make-stage
         "runtime"
         (poo-flow-runtime-main-build-spec options)
         (lambda (upstream-dirty?)
           (poo-flow-make "runtime"
                          (poo-flow-runtime-main-build-spec options)
                          options
                          upstream-dirty?)))
        (make-stage
         "testing-project"
         +poo-flow-testing-project-build-spec+
         (lambda (upstream-dirty?)
           (poo-flow-make "testing-project"
                          +poo-flow-testing-project-build-spec+
                          options
                          upstream-dirty?))))
       (if (poo-flow-tests-build-options? options)
         (list
          (make-stage
           "tests"
           (poo-flow-test-build-spec options)
           (lambda (upstream-dirty?)
             (poo-flow-make "tests"
                            (poo-flow-test-build-spec options)
                            options
                            upstream-dirty?))))
         [])
       (list
        (make-stage
         "cli-library"
         +poo-flow-cli-library-build-spec+
         (lambda (upstream-dirty?)
           (poo-flow-make "cli-library"
                          +poo-flow-cli-library-build-spec+
                          options
                          upstream-dirty?)))
        (make-stage
         "entry"
         (poo-flow-entry-build-spec options)
         (lambda (upstream-dirty?)
           (poo-flow-make "entry"
                          (poo-flow-entry-build-spec options)
                          options
                          upstream-dirty?))))))))

;; : (forall (options receipt) (-> options [receipt]))
;; poo-flow-package-build-run!
;;   : (-> PooFlowBuildOptions [BuildStageReceipt])
(def (poo-flow-package-build-run! options)
  (poo-flow-package-require-gxpkg-env!)
  (if (poo-flow-cli-build-options? options)
    (let (receipts
          (poo-flow-package-build-focused-stage!
           (make-poo-flow-package-focused-stage
            "cli-modules"
            (poo-flow-cli-only-module-build-spec options)
            (lambda ()
              (poo-flow-gxc-stage
               "cli-modules"
               (poo-flow-cli-only-module-build-spec options)
               options)))
           options))
      (poo-flow-write-cli-launcher!)
      receipts)
    (let (receipts
          (build-plan-run! (poo-flow-package-build-stage-plan options)
                           options))
      (poo-flow-write-cli-launcher!)
      receipts)))

;; : (forall (receipt) (-> [] [(List receipt)]))
;; poo-flow-package-building-testing-bootstrap!
;;   : (-> [] [(List BuildStageReceipt)])
(def (poo-flow-package-building-testing-bootstrap!)
  (let (options (poo-flow-entry-options #f #f #f #f #f #f #f))
    (poo-flow-package-build-focused-stage!
     (make-poo-flow-package-focused-stage
      "testing-bootstrap"
      +poo-flow-testing-bootstrap-build-spec+
      (lambda ()
        (poo-flow-gxc-stage/force-on-cache-miss!
         "testing-bootstrap"
         +poo-flow-testing-bootstrap-build-spec+
         options)))
     options)))

;; : (forall (receipt) (-> [] [(List receipt)]))
;; poo-flow-package-building-testing-project!
;;   : (-> [] [(List BuildStageReceipt)])
(def (poo-flow-package-building-testing-project!)
  (let (options (poo-flow-entry-options #f #f #f #f #f #f #f))
    (poo-flow-package-build-focused-stage!
     (make-poo-flow-package-focused-stage
      "testing-project"
      +poo-flow-testing-project-build-spec+
      (lambda ()
        (poo-flow-gxc-stage
         "testing-project"
         +poo-flow-testing-project-build-spec+
         options)))
     options)))
