;;; -*- Gerbil -*-
;;; Boundary: configured entrypoints assemble strategies and runtime adapters.
;;; Invariant: config data selects components but never executes workflow tasks.

(import :core/failure
        :core/strategy
        :core/runtime-adapter
        :core/task
        :core/flow
        :core/runner)

(export make-config-requirement
        config-requirement?
        config-requirement-source
        config-requirement-key
        config-requirement-secret
        config-requirement-secret?
        config-requirement->alist
        make-config-preflight
        config-preflight?
        config-preflight-requirements
        config-preflight-missing
        config-preflight-status
        config-preflight-ok?
        config-preflight->alist
        make-config-argument
        config-argument?
        config-argument-kind
        config-argument-value
        config-argument-secret
        config-argument-secret?
        config-argument->requirement
        config-arguments->requirements
        render-config-argument
        render-config-arguments
        make-run-config
        run-config?
        run-config-name
        run-config-strategy
        run-config-adapter
        run-config-options
        run-config-task-registry
        run-config-flow-registry
        run-config-config-requirements
        run-config-config-source
        run-config-preflight
        run-config-validate-preflight
        make-request-only-run-config
        make-rust-run-config
        run-config->runner
        run-config-runtime-owner
        run-flow-with-config)

;;; Config requirements describe what a runtime needs without loading or
;;; persisting the secret values themselves.
;; ConfigRequirement <- Symbol Symbol Boolean
(defstruct config-requirement
  (source
   key
   secret)
  transparent: #t)

;; Boolean <- ConfigRequirement
(def (config-requirement-secret? requirement)
  (config-requirement-secret requirement))

;; Alist <- ConfigRequirement
(def (config-requirement->alist requirement)
  (list (cons 'source (config-requirement-source requirement))
        (cons 'key (config-requirement-key requirement))
        (cons 'secret (config-requirement-secret requirement))))

;;; Preflight reports only requirement identity and missing keys; raw values
;;; remain in the runtime adapter or caller-owned config source.
;; ConfigPreflight <- [ConfigRequirement] [ConfigRequirement]
(defstruct config-preflight
  (requirements
   missing)
  transparent: #t)

;; Symbol <- ConfigPreflight
(def (config-preflight-status preflight)
  (if (null? (config-preflight-missing preflight))
    'ok
    'missing))

;; Boolean <- ConfigPreflight
(def (config-preflight-ok? preflight)
  (eq? (config-preflight-status preflight) 'ok))

;; Alist <- ConfigPreflight
(def (config-preflight->alist preflight)
  (list (cons 'status (config-preflight-status preflight))
        (cons 'requirements
              (config-requirements->alist
               (config-preflight-requirements preflight)))
        (cons 'missing
              (config-requirements->alist
               (config-preflight-missing preflight)))))

;;; Config arguments mirror Funflow's configurable arguments while keeping
;;; source loading and secret materialization outside the Scheme control plane.
;; ConfigArgument <- Symbol Value Boolean
(defstruct config-argument
  (kind
   value
   secret)
  transparent: #t)

;; Boolean <- ConfigArgument
(def (config-argument-secret? argument)
  (config-argument-secret argument))

;;; Only env/file arguments produce key requirements; literal and placeholder
;;; arguments are already representable without config source lookup.
;; MaybeConfigRequirement <- ConfigArgument
(def (config-argument->requirement argument)
  (let ((kind (config-argument-kind argument))
        (value (config-argument-value argument)))
    (cond
     ((or (eq? kind 'env) (eq? kind 'file))
      (make-config-requirement kind value (config-argument-secret? argument)))
     (else #f))))

;;; Requirement derivation is a filter-map over declaration arguments.
;;; The lambda branch keeps env/file ordering stable while dropping literals
;;; and placeholders that do not require caller-supplied config source keys.
;; [ConfigRequirement] <- [ConfigArgument]
(def (config-arguments->requirements arguments)
  (cond
   ((null? arguments) '())
   ((config-argument->requirement (car arguments))
    => (lambda (requirement)
         (cons requirement
               (config-arguments->requirements (cdr arguments)))))
   (else
    (config-arguments->requirements (cdr arguments)))))

;;; Rendering keeps placeholder arguments as symbolic runtime references.
;;; Secret source-backed arguments render as redacted references so receipts and
;;; request envelopes do not persist raw secret values.
;; Value <- Alist ConfigArgument
(def (render-config-argument source argument)
  (let ((kind (config-argument-kind argument))
        (value (config-argument-value argument)))
    (cond
     ((eq? kind 'literal) value)
     ((eq? kind 'placeholder) (list (cons 'placeholder value)))
     ((or (eq? kind 'env) (eq? kind 'file))
      (if (config-argument-secret? argument)
        (list (cons 'source kind)
              (cons 'key value)
              (cons 'secret #t))
        (config-source-ref source kind value)))
     (else
      (raise-control-plane-failure
       'config
       'unsupported-config-argument
       "unsupported config argument kind"
       (list (cons 'kind kind)
             (cons 'value value)))))))

;; [Value] <- Alist [ConfigArgument]
(def (render-config-arguments source arguments)
  (if (null? arguments)
    '()
    (cons (render-config-argument source (car arguments))
          (render-config-arguments source (cdr arguments)))))

;;; A run config is the inspectable data form of a Funflow-style configured
;;; execution entrypoint.
;; RunConfigState <- Symbol Strategy RuntimeAdapter Alist TaskFamilyRegistry FlowDeclarationRegistry
(defstruct run-config-state
  (name
   strategy
   adapter
   options
   task-registry
   flow-registry)
  transparent: #t)

;;; Public config construction keeps existing callers on default POO registries
;;; while allowing extensions to install descriptor bundles at the run boundary.
;; RunConfig <- Symbol Strategy RuntimeAdapter Alist [TaskFamilyRegistry] [FlowDeclarationRegistry]
(def (make-run-config name strategy adapter options . registries)
  (make-run-config-state name
                         strategy
                         adapter
                         options
                         (if (null? registries)
                           default-task-family-registry
                           (car registries))
                         (if (or (null? registries) (null? (cdr registries)))
                           default-flow-declaration-registry
                           (cadr registries))))

;; Boolean <- RunConfigCandidate
(def (run-config? config)
  (run-config-state? config))

;; Symbol <- RunConfig
(def (run-config-name config)
  (run-config-state-name config))

;; Strategy <- RunConfig
(def (run-config-strategy config)
  (run-config-state-strategy config))

;; RuntimeAdapter <- RunConfig
(def (run-config-adapter config)
  (run-config-state-adapter config))

;; Alist <- RunConfig
(def (run-config-options config)
  (run-config-state-options config))

;; TaskFamilyRegistry <- RunConfig
(def (run-config-task-registry config)
  (run-config-state-task-registry config))

;; FlowDeclarationRegistry <- RunConfig
(def (run-config-flow-registry config)
  (run-config-state-flow-registry config))

;; Value <- Alist Symbol Value
(def (run-config-option options key default)
  (let (entry (assoc key options))
    (if entry
      (cdr entry)
      default)))

;; [ConfigRequirement] <- RunConfig
(def (run-config-config-requirements config)
  (run-config-option (run-config-options config) 'config-requirements '()))

;; Alist <- RunConfig
(def (run-config-config-source config)
  (run-config-option (run-config-options config) 'config-source '()))

;;; Preflight keeps the Funflow-style missing-input check before execution.
;;; It checks caller-supplied source keys but does not read files or env vars.
;; ConfigPreflight <- RunConfig
(def (run-config-preflight config)
  (let ((requirements (run-config-config-requirements config))
        (source (run-config-config-source config)))
    (make-config-preflight
     requirements
     (missing-config-requirements requirements source))))

;; Boolean <- RunConfig
(def (run-config-validate-preflight config)
  (let (preflight (run-config-preflight config))
    (if (config-preflight-ok? preflight)
      #t
      (raise-control-plane-failure
       'config
       'missing-config-keys
       "missing config keys"
       (config-preflight->alist preflight)
       #t))))

;;; The request-only config records adapter envelopes for tests without claiming
;;; to run store or external work.
;; RunConfig <- Unit
(def (make-request-only-run-config)
  (make-run-config 'request-only
                   (make-local-eager-strategy)
                   (make-request-only-adapter)
                   '((runtime . request-only))))

;;; The Rust config selects the handoff adapter while Scheme keeps ownership of
;;; declaration, planning, and audit evidence.
;; RunConfig <- [Alist]
(def (make-rust-run-config . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (command (run-config-option options 'runtime-command #f)))
    (make-run-config 'rust
                     (make-local-eager-strategy)
                     (make-rust-adapter command)
                     (append '((runtime . rust)) options))))

;;; Lowering config through the existing runner keeps validation behavior
;;; identical for configured and direct execution.
;; Runner <- RunConfig
(def (run-config->runner config)
  (make-runner (run-config-strategy config)
               (run-config-adapter config)
               (run-config-task-registry config)
               (run-config-flow-registry config)))

;;; Runtime ownership is derived from the selected adapter instead of copied
;;; into config options.
;; Symbol <- RunConfig
(def (run-config-runtime-owner config)
  (runtime-adapter-name (run-config-adapter config)))

;;; The configured entrypoint mirrors Funflow's run-with-config shape while
;;; reusing the normal runner interpreter and receipt schema.
;; RunResult <- RunConfig Flow Input
(def (run-flow-with-config config flow input)
  (run-config-validate-preflight config)
  (runner-run (run-config->runner config) flow input))

;; [Alist] <- [ConfigRequirement]
(def (config-requirements->alist requirements)
  (if (null? requirements)
    '()
    (cons (config-requirement->alist (car requirements))
          (config-requirements->alist (cdr requirements)))))

;; [ConfigRequirement] <- [ConfigRequirement] Alist
(def (missing-config-requirements requirements source)
  (cond
   ((null? requirements) '())
   ((config-source-satisfies? source (car requirements))
    (missing-config-requirements (cdr requirements) source))
   (else
    (cons (car requirements)
          (missing-config-requirements (cdr requirements) source)))))

;;; Literal requirements are already satisfied; file/env requirements are
;;; satisfied only by key presence in their source bucket.
;; Boolean <- Alist ConfigRequirement
(def (config-source-satisfies? source requirement)
  (let ((source-kind (config-requirement-source requirement))
        (key (config-requirement-key requirement)))
    (if (eq? source-kind 'literal)
      #t
      (let (bucket (assoc source-kind source))
        (and bucket
             (assoc key (cdr bucket))
             #t)))))

;; Value <- Alist Symbol Symbol
(def (config-source-ref source source-kind key)
  (let (bucket (assoc source-kind source))
    (if bucket
      (let (entry (assoc key (cdr bucket)))
        (if entry
          (cdr entry)
          (raise-missing-config-value source-kind key)))
      (raise-missing-config-value source-kind key))))

;; Never <- Symbol Symbol
(def (raise-missing-config-value source-kind key)
  (raise-control-plane-failure
   'config
   'missing-config-keys
   "missing config key"
   (list (cons 'status 'missing)
         (cons 'missing
               (list (config-requirement->alist
                      (make-config-requirement source-kind key #f)))))
   #t))
