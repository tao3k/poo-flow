;;; Module boundary: workflow-CI presentation code owns runtime handoff projection
;;; slots while the facade keeps only scenario selection.

(export poo-flow-user-config-workflow-cicd-focused-presentation
        poo-flow-user-config-workflow-cicd-focused-presentation/summary-fast)

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
        :poo-flow/src/module-system/workflow-cicd-pipeline-run-config
        :poo-flow/src/module-system/workflow-cicd-runtime-command-config
        :poo-flow/src/module-system/presentation-config-support)

;; Engineering note: workflow-CI focused presentation keeps runtime projection
;; memoized so command, handoff, and receipt rows share one projection pass.
;; : (-> UserConfig ModuleSelections UserSettings SettingKeys PresentationObject)
(def (poo-flow-user-config-workflow-cicd-focused-presentation
      config
      selected-modules
      setting-object
      public-setting-keys)
  ;; Engineering note: the cache keeps runtime projection, DAG, run, and result
  ;; rows shared across many lazy slots in the focused presentation object.
  (let (cache (vector '()))
    ;; : (-> MemoKey SlotThunk SlotValue)
    (def (memo key thunk)
      (poo-flow-user-config-presentation-memo cache key thunk))
    ;; : (-> Symbol SlotThunk SlotSpec)
    (def (computed key thunk)
      (poo-flow-user-config-presentation-computed-slot key thunk))
    ;; : (-> Void FeatureFacts)
    (def (feature-fact-rows)
      (memo 'feature-fact-rows
            (lambda () (poo-flow-user-config-feature-facts config))))
    ;; : (-> Void DerivationRows)
    (def (sandbox-profile-derivation-rows)
      (memo 'sandbox-profile-derivation-rows
            (lambda ()
              (poo-flow-user-config-sandbox-profile-derivations
               selected-modules))))
    ;; : (-> Void SandboxValidation)
    (def (sandbox-validation)
      (memo 'sandbox-validation
            (lambda ()
              (poo-flow-user-config-sandbox-backend-capability-registry-validation
               selected-modules))))
    ;; : (-> Void CicdIntents)
    (def (cicd-intent-rows)
      (memo 'cicd-intent-rows
            (lambda () (poo-flow-user-config-cicd-intents config))))
    ;; : (-> Void RuntimeProjection)
    (def (workflow-projection)
      (memo 'workflow-projection
            (lambda ()
              (poo-flow-user-config-workflow-cicd-runtime-projection
               config))))
    ;; : (-> Symbol FieldDefault FieldValue)
    (def (workflow-field key default-value)
      (poo-flow-user-alist-ref
       (workflow-projection)
       key
       default-value))
    ;; : (-> Void CicdCheckMaps)
    (def (workflow-check-maps)
      (workflow-field 'check-maps '()))
    ;; : (-> Void FunctionalDagRows)
    (def (workflow-functional-dag-rows)
      (memo 'workflow-functional-dag-rows
            (lambda ()
              (poo-flow-user-workflow-cicd-functional-dag-rows
               (workflow-check-maps)))))
    ;; : (-> Void PipelineRunRows)
    (def (workflow-pipeline-run-rows)
      (memo 'workflow-pipeline-run-rows
            (lambda ()
              (poo-flow-user-config-workflow-cicd-pipeline-runs config))))
    ;; : (-> Void PipelineResultRows)
    (def (workflow-pipeline-result-rows)
      (memo 'workflow-pipeline-result-rows
            (lambda ()
              (poo-flow-user-config-workflow-cicd-pipeline-results config))))
    ;; : (-> Void RuntimeReadinessRows)
    (def (workflow-readiness-rows)
      (workflow-field 'runtime-readiness '()))
    ;; : (-> Void RuntimeCommandRows)
    (def (workflow-runtime-command-manifest-rows)
      (workflow-field 'runtime-command-manifests '()))
    ;; : (-> Void RuntimeCommandSummaryRows)
    (def (workflow-runtime-command-manifest-summary-rows)
      (workflow-field 'runtime-command-manifest-summaries '()))
    ;; : (-> Void RuntimeAgreementReport)
    (def (workflow-runtime-command-manifest-agreement)
      (workflow-field 'runtime-command-manifest-agreement '()))
    ;; : (-> Void HandoffAbiRows)
    (def (workflow-marlin-runtime-handoff-abi-rows)
      (workflow-field 'marlin-runtime-handoff-abis '()))
    ;; : (-> Void HandoffSummaryRows)
    (def (workflow-marlin-runtime-handoff-summary-rows)
      (workflow-field 'marlin-runtime-handoff-summaries '()))
    ;; : (-> Void ReceiptRows)
    (def (workflow-receipt-rows)
      (workflow-field 'receipts '()))
    ;; : (-> Void HandoffBundle)
    (def (workflow-handoff-bundle)
      (workflow-field 'marlin-handoff-receipt-bundle '()))
    ;; : (-> Void PresentationTrace)
    (def (presentation-trace-rows)
      (memo 'presentation-trace-rows
            (lambda ()
              (poo-flow-user-config-presentation-trace
               selected-modules
               (feature-fact-rows)
               (sandbox-profile-derivation-rows)
               '()
               (cicd-intent-rows)
               (workflow-check-maps)
               (workflow-functional-dag-rows)
               (workflow-pipeline-run-rows)
               (workflow-pipeline-result-rows)
               (workflow-readiness-rows)
               (workflow-runtime-command-manifest-rows)
               (workflow-runtime-command-manifest-summary-rows)
               (workflow-runtime-command-manifest-agreement)
               (workflow-marlin-runtime-handoff-abi-rows)
               (workflow-receipt-rows)
               (workflow-handoff-bundle)
               '()
               public-setting-keys))))
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
      (computed 'sandbox-profile-derivation-count
                (lambda () (length (sandbox-profile-derivation-rows))))
      (computed 'sandbox-profile-derivations
                sandbox-profile-derivation-rows)
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
      (computed 'cicd-intent-count
                (lambda () (length (cicd-intent-rows))))
      (computed 'cicd-intents cicd-intent-rows)
      (computed 'workflow-cicd-pipeline-count
                (lambda () (workflow-field 'pipeline-count 0)))
      (computed 'workflow-cicd-pipelines
                (lambda () (workflow-field 'pipeline-names '())))
      (computed 'workflow-cicd-functional-dag-count
                (lambda () (length (workflow-functional-dag-rows))))
      (computed 'workflow-cicd-functional-dags
                workflow-functional-dag-rows)
      (computed 'workflow-cicd-pipeline-run-count
                (lambda () (length (workflow-pipeline-run-rows))))
      (computed 'workflow-cicd-pipeline-runs
                workflow-pipeline-run-rows)
      (computed 'workflow-cicd-pipeline-result-count
                (lambda () (length (workflow-pipeline-result-rows))))
      (computed 'workflow-cicd-pipeline-results
                workflow-pipeline-result-rows)
      (computed 'workflow-cicd-runtime-readiness-count
                (lambda () (length (workflow-readiness-rows))))
      (computed 'workflow-cicd-runtime-readiness
                workflow-readiness-rows)
      (computed 'workflow-cicd-runtime-command-manifest-map-count
                (lambda ()
                  (length (workflow-runtime-command-manifest-rows))))
      (computed 'workflow-cicd-runtime-command-manifests
                workflow-runtime-command-manifest-rows)
      (computed 'workflow-cicd-runtime-command-manifest-summary-count
                (lambda ()
                  (length
                   (workflow-runtime-command-manifest-summary-rows))))
      (computed 'workflow-cicd-runtime-command-manifest-summaries
                workflow-runtime-command-manifest-summary-rows)
      (computed 'workflow-cicd-runtime-command-manifest-agreement
                workflow-runtime-command-manifest-agreement)
      (computed 'workflow-cicd-runtime-command-manifest-agreement-valid?
                (lambda ()
                  (poo-flow-user-alist-ref
                   (workflow-runtime-command-manifest-agreement)
                   'valid?
                   #f)))
      (computed 'workflow-cicd-runtime-command-manifest-agreement-diagnostics
                (lambda ()
                  (poo-flow-user-alist-ref
                   (workflow-runtime-command-manifest-agreement)
                   'diagnostics
                   '())))
      (computed 'workflow-cicd-marlin-runtime-handoff-abi-count
                (lambda ()
                  (length (workflow-marlin-runtime-handoff-abi-rows))))
      (computed 'workflow-cicd-marlin-runtime-handoff-abis
                workflow-marlin-runtime-handoff-abi-rows)
      (computed 'workflow-cicd-marlin-runtime-handoff-summary-count
                (lambda ()
                  (length
                   (workflow-marlin-runtime-handoff-summary-rows))))
      (computed 'workflow-cicd-marlin-runtime-handoff-summaries
                workflow-marlin-runtime-handoff-summary-rows)
      (computed 'workflow-cicd-receipt-count
                (lambda () (length (workflow-receipt-rows))))
      (computed 'workflow-cicd-receipts workflow-receipt-rows)
      (computed 'workflow-cicd-sandbox-runtime-summaries
                (lambda ()
                  (workflow-field 'sandbox-runtime-summaries '())))
      (computed 'workflow-cicd-sandbox-handoff-summaries
                (lambda ()
                  (workflow-field 'sandbox-handoff-summaries '())))
      (computed 'workflow-cicd-sandbox-unresolved-profile-refs
                (lambda ()
                  (workflow-field 'sandbox-unresolved-profile-refs '())))
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-intent-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-intents
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-runtime-handoff-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-runtime-handoffs
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-workflow-agreements
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-workflow-functional-dag-counts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-workflow-functional-dags
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-receipt-contracts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-result-contracts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-agent-profiles
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-agent-harnesses
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-agent-sessions
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-session-agent-graphs
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-session-agent-topology-traces
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-workflow-runs
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-dispatch-receipts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-agent-operations
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-delegated-operations
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-lineage-receipts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-selector-receipts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-resource-dispatch-receipts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-capability-receipts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-memory-receipts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-compression-receipts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-session-selector-receipts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-session-materialization-receipts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-policy-extension-receipts
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-spec-evolution-reviews
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-spec-evolution-human-audit-review-items
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-spec-evolution-runtime-manifest-rows
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-runtime-command-manifests
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-runtime-command-manifest-summaries
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-sandbox-runtime-summaries
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-sandbox-handoff-summaries
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-sandbox-handoff-agreements
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-sandbox-unresolved-profile-refs
       '())
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-runtime-snapshot-count
       0)
      (poo-flow-user-config-presentation-constant-slot
       'loop-engine-runtime-snapshots
       '())
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

;; Engineering note: summary-fast mirrors the legacy focused path while avoiding
;; the full lazy-slot object when only pipeline and handoff counters are needed.
;; : (-> UserConfig ModuleSelections UserSettings SettingKeys PresentationObject)
(def (poo-flow-user-config-workflow-cicd-focused-presentation/summary-fast
      config
      selected-modules
      setting-object
      public-setting-keys)
  ;; Engineering note: summary-fast recomputes only the handoff-critical rows
  ;; needed by bundle gates instead of materializing every focused slot.
  (let* ((workflow-check-maps
          (poo-flow-user-config-workflow-cicd-check-maps config))
         (workflow-runtime-command-manifest-rows
          (poo-flow-user-config-workflow-cicd-runtime-command-manifests
           config))
         (workflow-runtime-command-manifest-summary-rows
          (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries
           workflow-runtime-command-manifest-rows))
         (workflow-runtime-command-manifest-agreement
          (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement
           workflow-runtime-command-manifest-rows
           workflow-runtime-command-manifest-summary-rows))
         (workflow-marlin-runtime-handoff-abi-rows
          (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis
           workflow-runtime-command-manifest-rows))
         (workflow-marlin-runtime-handoff-summary-rows
          (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summaries
           workflow-marlin-runtime-handoff-abi-rows))
         (workflow-handoff-bundle
          (poo-flow-user-workflow-cicd-marlin-handoff-receipt-bundle
           workflow-runtime-command-manifest-rows
           workflow-runtime-command-manifest-summary-rows
           workflow-runtime-command-manifest-agreement
           workflow-marlin-runtime-handoff-abi-rows
           workflow-marlin-runtime-handoff-summary-rows
           workflow-runtime-command-manifest-summary-rows)))
    (object<-alist
     (list
      (cons 'workflow-cicd-marlin-handoff-receipt-bundle
            workflow-handoff-bundle)
      (cons 'workflow-cicd-pipeline-count (length workflow-check-maps))
      (cons 'workflow-cicd-runtime-command-manifest-map-count
            (length workflow-runtime-command-manifest-rows))
      (cons 'workflow-cicd-runtime-command-manifest-summary-count
            (length workflow-runtime-command-manifest-summary-rows))
      (cons 'workflow-cicd-marlin-runtime-handoff-abi-count
            (length workflow-marlin-runtime-handoff-abi-rows))
      (cons 'runtime-executed #f)
      (cons 'kind poo-flow-user-config-presentation-kind)
      (cons 'module-count (length selected-modules))
      (cons 'module-keys (poo-flow-user-config-module-keys config))
      (cons 'feature-count (length selected-modules))
      (cons 'cicd-intent-count (length (poo-flow-user-config-cicd-intents
                                        config)))
      (cons 'workflow-cicd-pipelines
            (poo-flow-user-config-presentation-workflow-cicd-check-map-names
             workflow-check-maps))
      (cons 'workflow-cicd-runtime-command-manifests
            workflow-runtime-command-manifest-rows)
      (cons 'workflow-cicd-runtime-command-manifest-summaries
            workflow-runtime-command-manifest-summary-rows)
      (cons 'workflow-cicd-runtime-command-manifest-agreement
            workflow-runtime-command-manifest-agreement)
      (cons 'workflow-cicd-marlin-runtime-handoff-abis
            workflow-marlin-runtime-handoff-abi-rows)
      (cons 'workflow-cicd-marlin-runtime-handoff-summaries
            workflow-marlin-runtime-handoff-summary-rows)
      (cons 'workflow-cicd-receipt-count
            (length workflow-runtime-command-manifest-summary-rows))
      (cons 'workflow-cicd-receipts '())
      (cons 'loop-engine-intent-count 0)
      (cons 'loop-engine-runtime-handoff-count 0)
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
      (cons 'replayable #t)))))
