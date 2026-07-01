;;; -*- Gerbil -*-
;;; Boundary: user-config presentation projection for module-system reports.
;;; Invariant: presentation is read-only and never realizes descriptors or runtimes.

(import (only-in :clan/poo/object
                 .o
                 object<-alist
                 make-object
                 $constant-slot-spec
                 $computed-slot-spec)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-sandbox-profile?
                 poo-flow-sandbox-profile-name
                 poo-flow-sandbox-profile-backend-kind
                 poo-flow-sandbox-profile-backend-ref
                 poo-flow-sandbox-profile-metadata)
        (only-in :poo-flow/src/modules/sandbox-core/profile-support/policy
                 poo-flow-sandbox-backend-capability-registry-validation-valid?
                 poo-flow-sandbox-backend-capability-registry-validation-diagnostics
                 poo-flow-sandbox-backend-capability-registry-validation-diagnostic-count)
        (only-in :poo-flow/src/modules/workflow/cicd
                 poo-flow-cicd-check-map-name)
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/observability
        :poo-flow/src/module-system/sandbox-backend-capability-catalog
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/workflow-cicd-pipeline-run-config
        :poo-flow/src/module-system/session-core-config
        :poo-flow/src/module-system/loop-engine-config)

(export poo-flow-user-config-sandbox-profile-derivations
        poo-flow-user-config-presentation-trace
        pooFlowUserConfigPresentation)

;;; Sandbox profile derivation presentation is intentionally separate from
;;; visible `:config`: users see their authored DSL in module flags, while this
;;; section exposes resolved POO lineage for agent/session/branch handoff.
;; : (-> [Alist] MaybeAlist)
(def (poo-flow-user-sandbox-profile-derivation-last-step derivation-path)
  (cond
   ((null? derivation-path) #f)
   ((null? (cdr derivation-path)) (car derivation-path))
   (else
    (poo-flow-user-sandbox-profile-derivation-last-step
     (cdr derivation-path)))))

;;; Derivation path reads only package-side profile metadata. It deliberately
;;; ignores runtime descriptor state because sandbox materialization belongs to
;;; Marlin and should not leak into user presentation.
;; : (-> PooSandboxProfile [Alist])
(def (poo-flow-user-sandbox-profile-derivation-path profile)
  (let ((derivation-path
         (poo-flow-user-alist-ref
          (poo-flow-sandbox-profile-metadata profile)
          'derivation-path
          '())))
    (if (list? derivation-path) derivation-path '())))

;;; A derivation row is the user-facing trace from a selected module to the
;;; profile lineage that produced its sandbox handoff candidate.
;; : (-> PooUserModuleSelection PooSandboxProfile MaybeAlist)
(def (poo-flow-user-sandbox-profile-derivation-row selection profile)
  (let* ((module-key (poo-flow-user-module-selection-key selection))
         (derivation-path
          (poo-flow-user-sandbox-profile-derivation-path profile))
         (last-step
          (poo-flow-user-sandbox-profile-derivation-last-step
           derivation-path)))
    (if last-step
      (list
       (cons 'key module-key)
       (cons 'group (car module-key))
       (cons 'module (cdr module-key))
       (cons 'profile-name (poo-flow-sandbox-profile-name profile))
       (cons 'backend-kind (poo-flow-sandbox-profile-backend-kind profile))
       (cons 'backend-ref (poo-flow-sandbox-profile-backend-ref profile))
       (cons 'parent-profile
             (poo-flow-user-alist-ref last-step 'parent-profile #f))
       (cons 'scope (poo-flow-user-alist-ref last-step 'scope #f))
       (cons 'scope-ref (poo-flow-user-alist-ref last-step 'scope-ref #f))
       (cons 'derivation-depth (length derivation-path))
       (cons 'derivation-path derivation-path)
       (cons 'runtime-owner "marlin-agent-core")
       (cons 'descriptor-realized? #f)
       (cons 'runtime-executed #f))
      #f)))

;;; Only authored sandbox profiles inside `:config` are eligible for lineage
;;; presentation; auxiliary module flags must not synthesize sandbox rows.
;; : (-> PooUserModuleSelection [PooSandboxProfile])
(def (poo-flow-user-module-selection-sandbox-config-profiles selection)
  (let ((entry (poo-flow-user-module-selection-flag-entry selection ':config)))
    (if (and entry (pair? entry))
      (filter poo-flow-sandbox-profile? (cdr entry))
      '())))

;;; Row accumulation builds the public order in reverse so config-level
;;; flattening can avoid one append per selected module.
;; : (-> PooUserModuleSelection [PooSandboxProfile] [Alist] [Alist])
(def (poo-flow-user-module-selection-sandbox-profile-derivations/rev
      selection
      profiles
      results)
  (cond
   ((null? profiles) results)
   (else
    (let ((row (poo-flow-user-sandbox-profile-derivation-row
                selection
                (car profiles))))
      (if row
        (poo-flow-user-module-selection-sandbox-profile-derivations/rev
         selection
         (cdr profiles)
         (cons row results))
        (poo-flow-user-module-selection-sandbox-profile-derivations/rev
         selection
         (cdr profiles)
         results))))))

;;; Module-level derivation projection is a pure presentation helper: it turns
;;; resolved sandbox profiles into trace rows without realizing descriptors.
;; : (-> PooUserModuleSelection [Alist])
(def (poo-flow-user-module-selection-sandbox-profile-derivations selection)
  (reverse
   (poo-flow-user-module-selection-sandbox-profile-derivations/rev
    selection
    (poo-flow-user-module-selection-sandbox-config-profiles selection)
    '())))

;;; Config-level derivations are flattened for the public presentation object so
;;; downstream agents can audit every sandbox lineage from a single slot.
;; : (-> [PooUserModuleSelection] [Alist] [Alist])
(def (poo-flow-user-config-sandbox-profile-derivations/rev selected-modules
                                                           results)
  (cond
   ((null? selected-modules) results)
   (else
    (poo-flow-user-config-sandbox-profile-derivations/rev
     (cdr selected-modules)
     (poo-flow-user-module-selection-sandbox-profile-derivations/rev
      (car selected-modules)
      (poo-flow-user-module-selection-sandbox-config-profiles
       (car selected-modules))
      results)))))

;; : (-> [PooUserModuleSelection] [Alist])
(def (poo-flow-user-config-sandbox-profile-derivations selected-modules)
  (reverse
   (poo-flow-user-config-sandbox-profile-derivations/rev
    selected-modules
    '())))

;;; The trace is deterministic and strict. It is the first slot tests should
;;; inspect when a presentation hangs, because it does not call back into POO.
;; : (-> [PooUserModuleSelection] [Alist] [Alist] [Alist] [PooFlowCicdCheckMap] [Alist] [Alist] [Alist] [Alist] [Alist] Alist [Alist] [Alist] [Symbol] [Alist])
(def (poo-flow-user-config-presentation-trace
      selected-modules
      feature-fact-rows
      sandbox-profile-derivation-rows
      session-core-intent-rows
      cicd-intent-rows
      workflow-cicd-check-maps
      workflow-cicd-functional-dag-rows
      workflow-cicd-pipeline-run-rows
      workflow-cicd-pipeline-result-rows
      workflow-cicd-readiness-rows
      workflow-cicd-runtime-command-manifest-rows
      workflow-cicd-runtime-command-manifest-summary-rows
      workflow-cicd-runtime-command-manifest-agreement-report
      workflow-cicd-marlin-runtime-handoff-abi-rows
      workflow-cicd-receipt-rows
      workflow-cicd-marlin-handoff-receipt-bundle
      loop-engine-intent-rows
      public-setting-keys)
  (poo-flow-module-presentation-trace
   'user-config-presentation
   (list (cons 'selected-modules (length selected-modules))
         (cons 'feature-facts (length feature-fact-rows))
         (cons 'sandbox-profile-derivations
               (length sandbox-profile-derivation-rows))
         (cons 'session-core-intents (length session-core-intent-rows))
         (cons 'cicd-intents (length cicd-intent-rows))
         (cons 'workflow-cicd-pipelines
               (length workflow-cicd-check-maps))
         (cons 'workflow-cicd-functional-dags
               (length workflow-cicd-functional-dag-rows))
         (cons 'workflow-cicd-pipeline-runs
               (length workflow-cicd-pipeline-run-rows))
         (cons 'workflow-cicd-pipeline-results
               (length workflow-cicd-pipeline-result-rows))
         (cons 'workflow-cicd-runtime-readiness
               (length workflow-cicd-readiness-rows))
         (cons 'workflow-cicd-runtime-command-manifest-maps
               (length workflow-cicd-runtime-command-manifest-rows))
         (cons 'workflow-cicd-runtime-command-manifest-summaries
               (length workflow-cicd-runtime-command-manifest-summary-rows))
         (cons 'workflow-cicd-runtime-command-manifest-agreement
               (if (poo-flow-user-alist-ref
                    workflow-cicd-runtime-command-manifest-agreement-report
                    'valid?
                    #f)
                 1
                 0))
         (cons 'workflow-cicd-marlin-runtime-handoff-abis
               (length workflow-cicd-marlin-runtime-handoff-abi-rows))
         (cons 'workflow-cicd-receipts
               (length workflow-cicd-receipt-rows))
         (cons 'workflow-cicd-marlin-handoff-receipt-bundle
               (if (poo-flow-user-alist-ref
                    workflow-cicd-marlin-handoff-receipt-bundle
                    'runtime-executed
                    #t)
                 0
                 1))
         (cons 'loop-engine-intents (length loop-engine-intent-rows))
         (cons 'settings (length public-setting-keys)))))

;;; Batch projection avoids repeatedly walking the same intent/check rows for
;;; every presentation slot. The row accessor remains caller-owned so alist ABI
;;; rows and POO-native receipt rows can share the same traversal shape.
;; : (-> [Symbol] [Pair])
(def (poo-flow-user-config-presentation-empty-field-values fields)
  (cond
   ((null? fields) '())
   (else
    (cons (cons (car fields) '())
          (poo-flow-user-config-presentation-empty-field-values
           (cdr fields))))))

;; : (-> Value [Pair] (-> Value Symbol Value Value) [Pair])
(def (poo-flow-user-config-presentation-accumulate-field-values
      row
      field-values
      row-ref)
  (cond
   ((null? field-values) '())
   (else
    (let ((field (caar field-values))
          (values (cdar field-values)))
      (cons
       (cons field (cons (row-ref row field #f) values))
       (poo-flow-user-config-presentation-accumulate-field-values
        row
        (cdr field-values)
        row-ref))))))

;; : (-> [Value] [Pair] (-> Value Symbol Value Value) [Pair])
(def (poo-flow-user-config-presentation-accumulate-rows
      rows
      field-values
      row-ref)
  (cond
   ((null? rows) field-values)
   (else
    (poo-flow-user-config-presentation-accumulate-rows
     (cdr rows)
     (poo-flow-user-config-presentation-accumulate-field-values
      (car rows)
      field-values
      row-ref)
     row-ref))))

;; : (-> [Pair] [Pair])
(def (poo-flow-user-config-presentation-reverse-field-values field-values)
  (cond
   ((null? field-values) '())
   (else
    (cons
     (cons (caar field-values) (reverse (cdar field-values)))
     (poo-flow-user-config-presentation-reverse-field-values
      (cdr field-values))))))

;; : (-> [Value] [Symbol] (-> Value Symbol Value Value) [Pair])
(def (poo-flow-user-config-presentation-field-values rows fields row-ref)
  (poo-flow-user-config-presentation-reverse-field-values
   (poo-flow-user-config-presentation-accumulate-rows
    rows
    (poo-flow-user-config-presentation-empty-field-values fields)
    row-ref)))

;; : (-> [Pair] Symbol [Value])
(def (poo-flow-user-config-presentation-field-values-ref field-values field)
  (poo-flow-user-alist-ref field-values field '()))

;; : [Symbol]
(def +poo-flow-user-config-presentation-loop-engine-fields+
  '(runtime-handoff-facts
    workflow-agreement
    workflow-functional-dag-count
    workflow-functional-dags
    receipt-contracts
    result-contract
    agent-profiles
    agent-harnesses
    agent-sessions
    session-agent-graph
    workflow-run
    dispatch-receipt
    agent-operation
    delegated-operation
    lineage-receipt
    selector-receipt
    resource-dispatch-receipt
    capability-receipt
    memory-receipt
    compression-receipt
    session-selector-receipts
    session-materialization-receipts
    policy-extension-receipts
    runtime-command-manifest
    runtime-command-manifest-summary
    sandbox-runtime-summaries
    sandbox-handoff-summaries
    sandbox-handoff-agreement
    sandbox-unresolved-profile-refs
    runtime-snapshot))

;; : (-> Symbol Value PooSlotSpec)
(def (poo-flow-user-config-presentation-constant-slot key value)
  (cons key ($constant-slot-spec value)))

;; : (-> Symbol (-> Unit Value) PooSlotSpec)
(def (poo-flow-user-config-presentation-computed-slot key thunk)
  (cons key
        ($computed-slot-spec
         (lambda (_self _superfun)
           (thunk)))))

;; : (-> Vector Symbol (-> Unit Value) Value)
(def (poo-flow-user-config-presentation-memo cache key thunk)
  (let (entry (assq key (vector-ref cache 0)))
    (if entry
      (cdr entry)
      (let (value (thunk))
        (vector-set! cache 0 (cons (cons key value) (vector-ref cache 0)))
        value))))

;; : (-> [PooUserModuleSelection] Boolean)
(def (poo-flow-user-config-loop-engine-only? selected-modules)
  (cond
   ((null? selected-modules) #f)
   (else
    (let loop ((modules selected-modules))
      (cond
       ((null? modules) #t)
       ((equal? (poo-flow-user-module-selection-key (car modules))
                '(flow . loop-engine))
        (loop (cdr modules)))
       (else #f))))))

;; : (-> PooUserConfig [PooUserModuleSelection] POOSettings [Symbol] POOObject)
(def (poo-flow-user-config-loop-engine-only-presentation
      config
      selected-modules
      setting-object
      public-setting-keys)
  (let (cache (vector '()))
    (def (memo key thunk)
      (poo-flow-user-config-presentation-memo cache key thunk))
    (def (feature-fact-rows)
      (memo 'feature-fact-rows
            (lambda () (poo-flow-user-config-feature-facts config))))
    (def (sandbox-validation)
      (memo 'sandbox-validation
            (lambda ()
              (poo-flow-user-config-sandbox-backend-capability-registry-validation
               selected-modules))))
    (def (loop-engine-intent-rows)
      (memo 'loop-engine-intent-rows
            (lambda () (poo-flow-user-config-loop-engine-intents config))))
    (def (loop-engine-field-values)
      (memo 'loop-engine-field-values
            (lambda ()
              (poo-flow-user-config-presentation-field-values
               (loop-engine-intent-rows)
               +poo-flow-user-config-presentation-loop-engine-fields+
               poo-flow-user-loop-engine-intent-ref))))
    (def (loop-engine-field field)
      (poo-flow-user-config-presentation-field-values-ref
       (loop-engine-field-values)
       field))
    (def (workflow-command-manifest-agreement)
      (memo 'workflow-command-manifest-agreement
            (lambda ()
              (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement
               '()
               '()))))
    (def (workflow-handoff-bundle)
      (memo 'workflow-handoff-bundle
            (lambda ()
              (poo-flow-user-workflow-cicd-marlin-handoff-receipt-bundle
               '()
               '()
               (workflow-command-manifest-agreement)
               '()
               '()
               '()))))
    (def (presentation-trace-rows)
      (memo 'presentation-trace-rows
            (lambda ()
              (poo-flow-user-config-presentation-trace
               selected-modules
               (feature-fact-rows)
               '()
               '()
               '()
               '()
               '()
               '()
               '()
               '()
               '()
               '()
               (workflow-command-manifest-agreement)
               '()
               '()
               (workflow-handoff-bundle)
               (loop-engine-intent-rows)
               public-setting-keys))))
    (def (computed key thunk)
      (poo-flow-user-config-presentation-computed-slot key thunk))
    (make-object
     supers: '()
     defaults: '()
     slots:
     (list
      (poo-flow-user-config-presentation-constant-slot
       'kind
       poo-flow-user-config-presentation-kind)
      (poo-flow-user-config-presentation-constant-slot
       'module-count
       (length selected-modules))
      (computed 'module-keys
                (lambda () (poo-flow-user-config-module-keys config)))
      (computed 'modules
                (lambda ()
                  (map poo-flow-user-module-selection->alist
                       selected-modules)))
      (poo-flow-user-config-presentation-constant-slot
       'feature-count
       (length selected-modules))
      (computed 'feature-facts feature-fact-rows)
      (poo-flow-user-config-presentation-constant-slot
       'sandbox-profile-derivation-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'sandbox-profile-derivations
       '())
      (computed 'sandbox-backend-capability-registry-validation
                sandbox-validation)
      (computed 'sandbox-backend-capability-registry-valid?
                (lambda ()
                  (poo-flow-sandbox-backend-capability-registry-validation-valid?
                   (sandbox-validation))))
      (computed 'sandbox-backend-capability-registry-diagnostic-count
                (lambda ()
                  (poo-flow-sandbox-backend-capability-registry-validation-diagnostic-count
                   (sandbox-validation))))
      (computed 'sandbox-backend-capability-registry-diagnostics
                (lambda ()
                  (poo-flow-sandbox-backend-capability-registry-validation-diagnostics
                   (sandbox-validation))))
      (poo-flow-user-config-presentation-constant-slot
       'session-core-intent-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'session-core-intents
       '())
      (poo-flow-user-config-presentation-constant-slot 'cicd-intent-count 0)
      (poo-flow-user-config-presentation-constant-slot 'cicd-intents '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-pipeline-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-pipelines
       '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-functional-dag-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-functional-dags
       '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-pipeline-run-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-pipeline-runs
       '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-pipeline-result-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-pipeline-results
       '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-runtime-readiness-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-runtime-readiness
       '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-runtime-command-manifest-map-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-runtime-command-manifests
       '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-runtime-command-manifest-summary-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-runtime-command-manifest-summaries
       '())
      (computed 'workflow-cicd-runtime-command-manifest-agreement
                workflow-command-manifest-agreement)
      (computed 'workflow-cicd-runtime-command-manifest-agreement-valid?
                (lambda ()
                  (poo-flow-user-alist-ref
                   (workflow-command-manifest-agreement)
                   'valid?
                   #f)))
      (computed 'workflow-cicd-runtime-command-manifest-agreement-diagnostics
                (lambda ()
                  (poo-flow-user-alist-ref
                   (workflow-command-manifest-agreement)
                   'diagnostics
                   '())))
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-marlin-runtime-handoff-abi-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-marlin-runtime-handoff-abis
       '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-marlin-runtime-handoff-summary-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-marlin-runtime-handoff-summaries
       '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-receipt-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-receipts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-sandbox-runtime-summaries
       '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-sandbox-handoff-summaries
       '())
      (poo-flow-user-config-presentation-constant-slot
       'workflow-cicd-sandbox-unresolved-profile-refs
       '())
      (computed 'loop-engine-intent-count
                (lambda () (length (loop-engine-intent-rows))))
      (computed 'loop-engine-intents loop-engine-intent-rows)
      (computed 'loop-engine-runtime-handoff-count
                (lambda () (length (loop-engine-intent-rows))))
      (computed 'loop-engine-runtime-handoffs
                (lambda () (loop-engine-field 'runtime-handoff-facts)))
      (computed 'loop-engine-workflow-agreements
                (lambda () (loop-engine-field 'workflow-agreement)))
      (computed 'loop-engine-workflow-functional-dag-counts
                (lambda () (loop-engine-field 'workflow-functional-dag-count)))
      (computed 'loop-engine-workflow-functional-dags
                (lambda () (loop-engine-field 'workflow-functional-dags)))
      (computed 'loop-engine-receipt-contracts
                (lambda () (loop-engine-field 'receipt-contracts)))
      (computed 'loop-engine-result-contracts
                (lambda () (loop-engine-field 'result-contract)))
      (computed 'loop-engine-agent-profiles
                (lambda () (loop-engine-field 'agent-profiles)))
      (computed 'loop-engine-agent-harnesses
                (lambda () (loop-engine-field 'agent-harnesses)))
      (computed 'loop-engine-agent-sessions
                (lambda () (loop-engine-field 'agent-sessions)))
      (computed 'loop-engine-session-agent-graphs
                (lambda () (loop-engine-field 'session-agent-graph)))
      (computed 'loop-engine-workflow-runs
                (lambda () (loop-engine-field 'workflow-run)))
      (computed 'loop-engine-dispatch-receipts
                (lambda () (loop-engine-field 'dispatch-receipt)))
      (computed 'loop-engine-agent-operations
                (lambda () (loop-engine-field 'agent-operation)))
      (computed 'loop-engine-delegated-operations
                (lambda () (loop-engine-field 'delegated-operation)))
      (computed 'loop-engine-lineage-receipts
                (lambda () (loop-engine-field 'lineage-receipt)))
      (computed 'loop-engine-selector-receipts
                (lambda () (loop-engine-field 'selector-receipt)))
      (computed 'loop-engine-resource-dispatch-receipts
                (lambda () (loop-engine-field 'resource-dispatch-receipt)))
      (computed 'loop-engine-capability-receipts
                (lambda () (loop-engine-field 'capability-receipt)))
      (computed 'loop-engine-memory-receipts
                (lambda () (loop-engine-field 'memory-receipt)))
      (computed 'loop-engine-compression-receipts
                (lambda () (loop-engine-field 'compression-receipt)))
      (computed 'loop-engine-session-selector-receipts
                (lambda () (loop-engine-field 'session-selector-receipts)))
      (computed 'loop-engine-session-materialization-receipts
                (lambda ()
                  (loop-engine-field 'session-materialization-receipts)))
      (computed 'loop-engine-policy-extension-receipts
                (lambda () (loop-engine-field 'policy-extension-receipts)))
      (computed 'loop-engine-runtime-command-manifests
                (lambda () (loop-engine-field 'runtime-command-manifest)))
      (computed 'loop-engine-runtime-command-manifest-summaries
                (lambda ()
                  (loop-engine-field 'runtime-command-manifest-summary)))
      (computed 'loop-engine-sandbox-runtime-summaries
                (lambda () (loop-engine-field 'sandbox-runtime-summaries)))
      (computed 'loop-engine-sandbox-handoff-summaries
                (lambda () (loop-engine-field 'sandbox-handoff-summaries)))
      (computed 'loop-engine-sandbox-handoff-agreements
                (lambda () (loop-engine-field 'sandbox-handoff-agreement)))
      (computed 'loop-engine-sandbox-unresolved-profile-refs
                (lambda () (loop-engine-field 'sandbox-unresolved-profile-refs)))
      (computed 'loop-engine-runtime-snapshot-count
                (lambda () (length (loop-engine-intent-rows))))
      (computed 'loop-engine-runtime-snapshots
                (lambda () (loop-engine-field 'runtime-snapshot)))
      (computed 'presentation-trace presentation-trace-rows)
      (poo-flow-user-config-presentation-constant-slot
       'setting-count
       (length public-setting-keys))
      (poo-flow-user-config-presentation-constant-slot
       'setting-keys
       public-setting-keys)
      (computed 'settings
                (lambda ()
                  (poo-flow-user-settings->alist
                   setting-object
                   public-setting-keys)))
      (poo-flow-user-config-presentation-constant-slot
       'user-entrypoints
       poo-flow-user-config-public-entrypoints)
      (poo-flow-user-config-presentation-constant-slot
       'api-entrypoints
       poo-flow-user-config-api-entrypoints)
      (poo-flow-user-config-presentation-constant-slot
       'boundary
       poo-flow-user-config-boundary)
      (poo-flow-user-config-presentation-constant-slot
       'brand-name
       poo-flow-brand-name)
      (poo-flow-user-config-presentation-constant-slot
       'brand-group
       poo-flow-brand-group)
      (poo-flow-user-config-presentation-constant-slot
       'scheme-owner
       poo-flow-scheme-owner)
      (poo-flow-user-config-presentation-constant-slot
       'module-system-owner
       poo-flow-module-system-owner)
      (poo-flow-user-config-presentation-constant-slot
       'runtime-owner
       "marlin-agent-core")
      (poo-flow-user-config-presentation-constant-slot
       'runtime-parses-scheme-source
       #f)
      (poo-flow-user-config-presentation-constant-slot
       'scheme-manufactures-runtime-handlers
       #f)
      (poo-flow-user-config-presentation-constant-slot
       'package-management?
       #f)
      (poo-flow-user-config-presentation-constant-slot
       'dependency-installation?
       #f)
      (poo-flow-user-config-presentation-constant-slot
       'descriptor-realized?
       #f)
      (poo-flow-user-config-presentation-constant-slot
       'runtime-executed
       #f)
      (computed 'workflow-cicd-marlin-handoff-receipt-bundle
                workflow-handoff-bundle)
      (computed 'workflow-cicd-marlin-handoff-receipt-bundle-runtime-executed
                (lambda ()
                  (poo-flow-user-alist-ref
                   (workflow-handoff-bundle)
                   'runtime-executed
                   #f)))
      (poo-flow-user-config-presentation-constant-slot
       'replayable
       #t)))))

;;; User config presentation is the downstream-facing doctor view. It exposes
;;; choices and settings but never realizes modules or executes runtime hooks.
;;; Presentation is a read-only contract projection over config objects. It
;;; gathers module, CI/CD, sandbox, and loop-engine facts without loading or
;;; executing any downstream runtime provider.
;; : (-> PooUserConfig [Symbol]... POOObject)
(def (pooFlowUserConfigPresentation config . maybe-setting-keys)
  (let ((selected-modules
         (poo-flow-user-config-modules config))
        (setting-object
         (poo-flow-user-config-settings config))
        (public-setting-keys
         (if (null? maybe-setting-keys) '() (car maybe-setting-keys))))
    (if (poo-flow-user-config-loop-engine-only? selected-modules)
      (poo-flow-user-config-loop-engine-only-presentation
       config
       selected-modules
       setting-object
       public-setting-keys)
      (let* ((feature-fact-rows
            (poo-flow-user-config-feature-facts config))
           (sandbox-profile-derivation-rows
            (poo-flow-user-config-sandbox-profile-derivations
             selected-modules))
           (sandbox-backend-capability-registry-validation
            (poo-flow-user-config-sandbox-backend-capability-registry-validation
             selected-modules))
           (session-core-intent-rows
            (poo-flow-user-config-session-core-intents config))
           (cicd-intent-rows
            (poo-flow-user-config-cicd-intents config))
           (workflow-cicd-check-maps
            (poo-flow-user-config-workflow-cicd-check-maps config))
           (workflow-cicd-functional-dag-rows
            (poo-flow-user-config-workflow-cicd-functional-dag-rows
             config))
           (workflow-cicd-pipeline-run-rows
            (poo-flow-user-config-workflow-cicd-pipeline-runs config))
           (workflow-cicd-pipeline-result-rows
            (poo-flow-user-config-workflow-cicd-pipeline-results config))
           (workflow-cicd-readiness-rows
            (poo-flow-user-config-workflow-cicd-runtime-readiness config))
           (workflow-cicd-runtime-command-manifest-rows
            (poo-flow-user-config-workflow-cicd-runtime-command-manifests
             config))
           (workflow-cicd-runtime-command-manifest-summary-rows
            (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries
             workflow-cicd-runtime-command-manifest-rows))
           (workflow-cicd-runtime-command-manifest-agreement-report
            (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement
             workflow-cicd-runtime-command-manifest-rows
             workflow-cicd-runtime-command-manifest-summary-rows))
           (workflow-cicd-marlin-runtime-handoff-abi-rows
            (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis
             workflow-cicd-runtime-command-manifest-rows))
           (workflow-cicd-marlin-runtime-handoff-abi-summary-rows
            (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summaries
             workflow-cicd-marlin-runtime-handoff-abi-rows))
           (workflow-cicd-receipt-rows
            (poo-flow-user-config-workflow-cicd-receipts config))
           (workflow-cicd-marlin-handoff-receipt-bundle-row
            (poo-flow-user-workflow-cicd-marlin-handoff-receipt-bundle
             workflow-cicd-runtime-command-manifest-rows
             workflow-cicd-runtime-command-manifest-summary-rows
             workflow-cicd-runtime-command-manifest-agreement-report
             workflow-cicd-marlin-runtime-handoff-abi-rows
             workflow-cicd-marlin-runtime-handoff-abi-summary-rows
             workflow-cicd-receipt-rows))
           (loop-engine-intent-rows
            (poo-flow-user-config-loop-engine-intents config))
           (presentation-trace-rows
            (poo-flow-user-config-presentation-trace
             selected-modules
             feature-fact-rows
             sandbox-profile-derivation-rows
             session-core-intent-rows
             cicd-intent-rows
             workflow-cicd-check-maps
             workflow-cicd-functional-dag-rows
             workflow-cicd-pipeline-run-rows
             workflow-cicd-pipeline-result-rows
             workflow-cicd-readiness-rows
             workflow-cicd-runtime-command-manifest-rows
             workflow-cicd-runtime-command-manifest-summary-rows
             workflow-cicd-runtime-command-manifest-agreement-report
             workflow-cicd-marlin-runtime-handoff-abi-rows
             workflow-cicd-receipt-rows
             workflow-cicd-marlin-handoff-receipt-bundle-row
             loop-engine-intent-rows
             public-setting-keys)))
      (let ((workflow-cicd-check-rows
             (poo-flow-user-workflow-cicd-readiness-checks
              workflow-cicd-readiness-rows)))
        (let ((loop-engine-field-values
                (poo-flow-user-config-presentation-field-values
                 loop-engine-intent-rows
                 +poo-flow-user-config-presentation-loop-engine-fields+
                 poo-flow-user-loop-engine-intent-ref)))
        (object<-alist
         (list
          (cons 'kind poo-flow-user-config-presentation-kind)
          (cons 'module-count (length selected-modules))
          (cons 'module-keys (poo-flow-user-config-module-keys config))
          (cons 'modules
                (map poo-flow-user-module-selection->alist selected-modules))
          (cons 'feature-count (length selected-modules))
          (cons 'feature-facts feature-fact-rows)
          (cons 'sandbox-profile-derivation-count
                (length sandbox-profile-derivation-rows))
          (cons 'sandbox-profile-derivations sandbox-profile-derivation-rows)
          (cons 'sandbox-backend-capability-registry-validation
                sandbox-backend-capability-registry-validation)
          (cons 'sandbox-backend-capability-registry-valid?
                (poo-flow-sandbox-backend-capability-registry-validation-valid?
                 sandbox-backend-capability-registry-validation))
          (cons 'sandbox-backend-capability-registry-diagnostic-count
                (poo-flow-sandbox-backend-capability-registry-validation-diagnostic-count
                 sandbox-backend-capability-registry-validation))
          (cons 'sandbox-backend-capability-registry-diagnostics
                (poo-flow-sandbox-backend-capability-registry-validation-diagnostics
                 sandbox-backend-capability-registry-validation))
          (cons 'session-core-intent-count
                (length session-core-intent-rows))
          (cons 'session-core-intents session-core-intent-rows)
          (cons 'cicd-intent-count (length cicd-intent-rows))
          (cons 'cicd-intents cicd-intent-rows)
          (cons 'workflow-cicd-pipeline-count
                (length workflow-cicd-check-maps))
          (cons 'workflow-cicd-pipelines
                (map poo-flow-cicd-check-map-name
                     workflow-cicd-check-maps))
          (cons 'workflow-cicd-functional-dag-count
                (length workflow-cicd-functional-dag-rows))
          (cons 'workflow-cicd-functional-dags
                workflow-cicd-functional-dag-rows)
          (cons 'workflow-cicd-pipeline-run-count
                (length workflow-cicd-pipeline-run-rows))
          (cons 'workflow-cicd-pipeline-runs
                workflow-cicd-pipeline-run-rows)
          (cons 'workflow-cicd-pipeline-result-count
                (length workflow-cicd-pipeline-result-rows))
          (cons 'workflow-cicd-pipeline-results
                workflow-cicd-pipeline-result-rows)
          (cons 'workflow-cicd-runtime-readiness-count
                (length workflow-cicd-readiness-rows))
          (cons 'workflow-cicd-runtime-readiness
                workflow-cicd-readiness-rows)
          (cons 'workflow-cicd-runtime-command-manifest-map-count
                (length workflow-cicd-runtime-command-manifest-rows))
          (cons 'workflow-cicd-runtime-command-manifests
                workflow-cicd-runtime-command-manifest-rows)
          (cons 'workflow-cicd-runtime-command-manifest-summary-count
                (length
                 workflow-cicd-runtime-command-manifest-summary-rows))
          (cons 'workflow-cicd-runtime-command-manifest-summaries
                workflow-cicd-runtime-command-manifest-summary-rows)
          (cons 'workflow-cicd-runtime-command-manifest-agreement
                workflow-cicd-runtime-command-manifest-agreement-report)
          (cons 'workflow-cicd-runtime-command-manifest-agreement-valid?
                (poo-flow-user-alist-ref
                 workflow-cicd-runtime-command-manifest-agreement-report
                 'valid?
                 #f))
          (cons 'workflow-cicd-runtime-command-manifest-agreement-diagnostics
                (poo-flow-user-alist-ref
                 workflow-cicd-runtime-command-manifest-agreement-report
                 'diagnostics
                 '()))
          (cons 'workflow-cicd-marlin-runtime-handoff-abi-count
                (length workflow-cicd-marlin-runtime-handoff-abi-rows))
          (cons 'workflow-cicd-marlin-runtime-handoff-abis
                workflow-cicd-marlin-runtime-handoff-abi-rows)
          (cons 'workflow-cicd-marlin-runtime-handoff-summary-count
                (length
                 workflow-cicd-marlin-runtime-handoff-abi-summary-rows))
          (cons 'workflow-cicd-marlin-runtime-handoff-summaries
                workflow-cicd-marlin-runtime-handoff-abi-summary-rows)
          (cons 'workflow-cicd-receipt-count
                (length workflow-cicd-receipt-rows))
          (cons 'workflow-cicd-receipts workflow-cicd-receipt-rows)
          (cons 'workflow-cicd-sandbox-runtime-summaries
                (poo-flow-user-workflow-cicd-checks-field-values
                 workflow-cicd-check-rows
                 'sandbox-runtime-summaries))
          (cons 'workflow-cicd-sandbox-handoff-summaries
                (poo-flow-user-workflow-cicd-checks-field-values
                 workflow-cicd-check-rows
                 'sandbox-handoff-summaries))
          (cons 'workflow-cicd-sandbox-unresolved-profile-refs
                (poo-flow-user-workflow-cicd-checks-field-values
                 workflow-cicd-check-rows
                 'sandbox-unresolved-profile-refs))
          (cons 'loop-engine-intent-count (length loop-engine-intent-rows))
          (cons 'loop-engine-intents loop-engine-intent-rows)
          (cons 'loop-engine-runtime-handoff-count
                (length loop-engine-intent-rows))
          (cons 'loop-engine-runtime-handoffs
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'runtime-handoff-facts))
          (cons 'loop-engine-workflow-agreements
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'workflow-agreement))
          (cons 'loop-engine-workflow-functional-dag-counts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'workflow-functional-dag-count))
          (cons 'loop-engine-workflow-functional-dags
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'workflow-functional-dags))
          (cons 'loop-engine-receipt-contracts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'receipt-contracts))
          (cons 'loop-engine-result-contracts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'result-contract))
          (cons 'loop-engine-agent-profiles
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'agent-profiles))
          (cons 'loop-engine-agent-harnesses
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'agent-harnesses))
          (cons 'loop-engine-agent-sessions
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'agent-sessions))
          (cons 'loop-engine-session-agent-graphs
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'session-agent-graph))
          (cons 'loop-engine-workflow-runs
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'workflow-run))
          (cons 'loop-engine-dispatch-receipts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'dispatch-receipt))
          (cons 'loop-engine-agent-operations
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'agent-operation))
          (cons 'loop-engine-delegated-operations
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'delegated-operation))
          (cons 'loop-engine-lineage-receipts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'lineage-receipt))
          (cons 'loop-engine-selector-receipts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'selector-receipt))
          (cons 'loop-engine-resource-dispatch-receipts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'resource-dispatch-receipt))
          (cons 'loop-engine-capability-receipts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'capability-receipt))
          (cons 'loop-engine-memory-receipts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'memory-receipt))
          (cons 'loop-engine-compression-receipts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'compression-receipt))
          (cons 'loop-engine-session-selector-receipts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'session-selector-receipts))
          (cons 'loop-engine-session-materialization-receipts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'session-materialization-receipts))
          (cons 'loop-engine-policy-extension-receipts
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'policy-extension-receipts))
          (cons 'loop-engine-runtime-command-manifests
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'runtime-command-manifest))
          (cons 'loop-engine-runtime-command-manifest-summaries
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'runtime-command-manifest-summary))
          (cons 'loop-engine-sandbox-runtime-summaries
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'sandbox-runtime-summaries))
          (cons 'loop-engine-sandbox-handoff-summaries
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'sandbox-handoff-summaries))
          (cons 'loop-engine-sandbox-handoff-agreements
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'sandbox-handoff-agreement))
          (cons 'loop-engine-sandbox-unresolved-profile-refs
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'sandbox-unresolved-profile-refs))
          (cons 'loop-engine-runtime-snapshot-count
                (length loop-engine-intent-rows))
          (cons 'loop-engine-runtime-snapshots
                (poo-flow-user-config-presentation-field-values-ref
                 loop-engine-field-values
                 'runtime-snapshot))
          (cons 'presentation-trace presentation-trace-rows)
          (cons 'setting-count (length public-setting-keys))
          (cons 'setting-keys public-setting-keys)
          (cons 'settings
                (poo-flow-user-settings->alist
                 setting-object
                 public-setting-keys))
          (cons 'user-entrypoints poo-flow-user-config-public-entrypoints)
          (cons 'api-entrypoints poo-flow-user-config-api-entrypoints)
          (cons 'boundary poo-flow-user-config-boundary)
          (cons 'brand-name poo-flow-brand-name)
          (cons 'brand-group poo-flow-brand-group)
          (cons 'scheme-owner poo-flow-scheme-owner)
          (cons 'module-system-owner poo-flow-module-system-owner)
          (cons 'runtime-owner "marlin-agent-core")
          (cons 'runtime-parses-scheme-source #f)
          (cons 'scheme-manufactures-runtime-handlers #f)
          (cons 'package-management? #f)
          (cons 'dependency-installation? #f)
          (cons 'descriptor-realized? #f)
          (cons 'runtime-executed #f)
          (cons 'workflow-cicd-marlin-handoff-receipt-bundle
                workflow-cicd-marlin-handoff-receipt-bundle-row)
          (cons 'workflow-cicd-marlin-handoff-receipt-bundle-runtime-executed
                (poo-flow-user-alist-ref
                 workflow-cicd-marlin-handoff-receipt-bundle-row
                 'runtime-executed
                 #f))
          (cons 'replayable #t)))))))))
