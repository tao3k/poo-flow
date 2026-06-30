;;; -*- Gerbil -*-
;;; Boundary: user-config presentation projection for module-system reports.
;;; Invariant: presentation is read-only and never realizes descriptors or runtimes.

(import (only-in :clan/poo/object .o object<-alist)
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

;;; Row accumulation preserves module selection order so profile derivation
;;; diagnostics line up with the order a user wrote in `use-module :config`.
;; : (-> PooUserModuleSelection [PooSandboxProfile] [Alist])
(def (poo-flow-user-module-selection-sandbox-profile-derivations/add
      selection
      profiles)
  (cond
   ((null? profiles) '())
   (else
    (let ((row (poo-flow-user-sandbox-profile-derivation-row
                selection
                (car profiles))))
      (if row
        (cons row
              (poo-flow-user-module-selection-sandbox-profile-derivations/add
               selection
               (cdr profiles)))
        (poo-flow-user-module-selection-sandbox-profile-derivations/add
         selection
         (cdr profiles)))))))

;;; Module-level derivation projection is a pure presentation helper: it turns
;;; resolved sandbox profiles into trace rows without realizing descriptors.
;; : (-> PooUserModuleSelection [Alist])
(def (poo-flow-user-module-selection-sandbox-profile-derivations selection)
  (poo-flow-user-module-selection-sandbox-profile-derivations/add
   selection
   (poo-flow-user-module-selection-sandbox-config-profiles selection)))

;;; Config-level derivations are flattened for the public presentation object so
;;; downstream agents can audit every sandbox lineage from a single slot.
;; : (-> [PooUserModuleSelection] [Alist])
(def (poo-flow-user-config-sandbox-profile-derivations selected-modules)
  (cond
   ((null? selected-modules) '())
   (else
    (append
     (poo-flow-user-module-selection-sandbox-profile-derivations
      (car selected-modules))
     (poo-flow-user-config-sandbox-profile-derivations
      (cdr selected-modules))))))

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
          (cons 'replayable #t))))))))
