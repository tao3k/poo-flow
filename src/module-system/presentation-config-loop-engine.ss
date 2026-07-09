;;; Module boundary: loop-engine presentation code is isolated from the facade so
;;; the loop-only fast path can be optimized without widening the public API.

(export poo-flow-user-config-loop-engine-only-presentation
        poo-flow-user-config-loop-engine-only-presentation/summary)

(import (only-in :clan/poo/object
                 make-object
                 object<-alist)
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/sandbox-backend-capability-catalog
        (only-in :poo-flow/src/modules/sandbox-core/profile-support/policy-backend-validation
                 poo-flow-sandbox-backend-capability-registry-validation-valid?
                 poo-flow-sandbox-backend-capability-registry-validation-diagnostic-count
                 poo-flow-sandbox-backend-capability-registry-validation-diagnostics)
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/workflow-cicd-runtime-command-config
        :poo-flow/src/module-system/loop-engine-config
        :poo-flow/src/module-system/presentation-config-support)

;; Engineering note: loop-engine-only presentation uses lazy slots so heavy
;; receipt projections are computed only when a downstream caller asks for them.
;; : (-> UserConfig ModuleSelections UserSettings SettingKeys PresentationObject)
(def (poo-flow-user-config-loop-engine-only-presentation
      config
      selected-modules
      setting-object
      public-setting-keys)
  ;; Engineering note: the mutable cell is intentionally local to the returned
  ;; POO object factory; it memoizes expensive projections without escaping.
  (let (cache (vector '()))
    ;; : (-> MemoKey SlotThunk SlotValue)
    (def (memo key thunk)
      (poo-flow-user-config-presentation-memo cache key thunk))
    ;; : (-> Void FeatureFacts)
    (def (feature-fact-rows)
      (memo 'feature-fact-rows
            (lambda () (poo-flow-user-config-feature-facts config))))
    ;; : (-> Void SandboxValidation)
    (def (sandbox-validation)
      (memo 'sandbox-validation
            (lambda ()
              (poo-flow-user-config-sandbox-backend-capability-registry-validation
               selected-modules))))
    ;; : (-> Void LoopIntentRows)
    (def (loop-engine-intent-rows)
      (memo 'loop-engine-intent-rows
            (lambda () (poo-flow-user-config-loop-engine-intents config))))
    ;; : (-> Void LoopFieldValues)
    (def (loop-engine-field-values)
      (memo 'loop-engine-field-values
            (lambda ()
              (poo-flow-user-config-presentation-field-values
               (loop-engine-intent-rows)
               +poo-flow-user-config-presentation-loop-engine-fields+
               poo-flow-user-loop-engine-intent-ref))))
    ;; : (-> Symbol FieldValues)
    (def (loop-engine-field field)
      (poo-flow-user-config-presentation-field-values-ref
       (loop-engine-field-values)
       field))
    ;; : (-> Void RuntimeManifestAgreement)
    (def (workflow-command-manifest-agreement)
      (memo 'workflow-command-manifest-agreement
            (lambda ()
              (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement
               '()
               '()))))
    ;; : (-> Void HandoffBundle)
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
    ;; : (-> Void PresentationTrace)
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
    ;; : (-> Symbol SlotThunk SlotSpec)
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
      (computed 'loop-engine-session-agent-topology-traces
                (lambda ()
                  (loop-engine-field 'session-agent-topology-trace)))
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
      (computed 'loop-engine-spec-evolution-reviews
                (lambda () (loop-engine-field 'spec-evolution-reviews)))
      (computed 'loop-engine-spec-evolution-human-audit-review-items
                (lambda ()
                  (loop-engine-field
                   'spec-evolution-human-audit-review-items)))
      (computed 'loop-engine-spec-evolution-runtime-manifest-rows
                (lambda ()
                  (loop-engine-field
                   'spec-evolution-runtime-manifest-rows)))
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

;; Engineering note: summary path is the hot path used by the facade for
;; loop-only configs and avoids constructing every lazy slot closure.
;; : (-> UserConfig ModuleSelections UserSettings SettingKeys PresentationObject)
(def (poo-flow-user-config-loop-engine-only-presentation/summary
      config
      selected-modules
      setting-object
      public-setting-keys)
  ;; Engineering note: this summary is eager because loop-only scenarios are
  ;; used as compile-time receipts and should avoid lazy slot allocation.
  (let* ((loop-engine-intent-rows
          (poo-flow-user-config-loop-engine-intents config))
         (loop-engine-field-values
          (poo-flow-user-config-presentation-field-values
           loop-engine-intent-rows
           +poo-flow-user-config-presentation-loop-engine-fields+
           poo-flow-user-loop-engine-intent-ref))
         (workflow-command-manifest-agreement
          (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement
           '()
           '()))
         (workflow-handoff-bundle
          (poo-flow-user-workflow-cicd-marlin-handoff-receipt-bundle
           '()
           '()
           workflow-command-manifest-agreement
           '()
           '()
           '()))
         (presentation-trace-rows
          (poo-flow-user-config-presentation-trace
           selected-modules
           (poo-flow-user-config-feature-facts config)
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
           workflow-command-manifest-agreement
           '()
           '()
           workflow-handoff-bundle
           loop-engine-intent-rows
           public-setting-keys)))
    (object<-alist
     (append
      (poo-flow-user-config-presentation-loop-engine-slots
       loop-engine-field-values
       loop-engine-intent-rows)
      (list
       (cons 'module-count (length selected-modules))
       (cons 'presentation-trace presentation-trace-rows)
       (cons 'runtime-executed #f)
       (cons 'kind poo-flow-user-config-presentation-kind)
       (cons 'module-keys (poo-flow-user-config-module-keys config))
       (cons 'feature-count (length selected-modules))
       (cons 'feature-facts (poo-flow-user-config-feature-facts config))
       (cons 'workflow-cicd-pipeline-count 0)
       (cons 'workflow-cicd-runtime-command-manifest-map-count 0)
       (cons 'workflow-cicd-marlin-runtime-handoff-abi-count 0)
       (cons 'setting-count (length public-setting-keys))
       (cons 'setting-keys public-setting-keys)
       (cons 'settings
             (poo-flow-user-settings->alist
              setting-object
              public-setting-keys))
       (cons 'runtime-owner "marlin-agent-core")
       (cons 'runtime-parses-scheme-source #f)
       (cons 'scheme-manufactures-runtime-handlers #f)
       (cons 'descriptor-realized? #f)
       (cons 'replayable #t))))))
