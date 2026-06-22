;;; -*- Gerbil -*-
;;; Boundary: user-config presentation projection for module-system reports.
;;; Invariant: presentation is read-only and never realizes descriptors or runtimes.

(import (only-in :clan/poo/object .o)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-sandbox-profile?
                 poo-flow-sandbox-profile-name
                 poo-flow-sandbox-profile-backend-kind
                 poo-flow-sandbox-profile-backend-ref
                 poo-flow-sandbox-profile-metadata)
        (only-in :poo-flow/src/modules/workflow/cicd
                 poo-flow-cicd-check-map-name)
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/observability
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/workflow-cicd-pipeline-run-config
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
      cicd-intent-rows
      workflow-cicd-check-maps
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
         (cons 'cicd-intents (length cicd-intent-rows))
         (cons 'workflow-cicd-pipelines
               (length workflow-cicd-check-maps))
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
;;; User config presentation is the downstream-facing doctor view. It exposes
;;; choices and settings but never realizes modules or executes runtime hooks.
;;; Presentation is a read-only contract projection over config objects. It
;;; gathers module, CI/CD, sandbox, and loop-engine facts without loading or
;;; executing any downstream runtime provider.
;; : (-> PooUserConfig [Symbol]... POOObject)
(def (pooFlowUserConfigPresentation config . maybe-setting-keys)
  (let ((selected-modules (poo-flow-user-config-modules config))
        (setting-object (poo-flow-user-config-settings config))
        (public-setting-keys
         (if (null? maybe-setting-keys) '() (car maybe-setting-keys))))
    (let* ((feature-fact-rows
            (poo-flow-user-config-feature-facts config))
           (sandbox-profile-derivation-rows
            (poo-flow-user-config-sandbox-profile-derivations
             selected-modules))
           (cicd-intent-rows
            (poo-flow-user-config-cicd-intents config))
           (workflow-cicd-check-maps
            (poo-flow-user-config-workflow-cicd-check-maps config))
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
             cicd-intent-rows
             workflow-cicd-check-maps
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
        (.o kind: poo-flow-user-config-presentation-kind
            module-count: (length selected-modules)
            module-keys: (poo-flow-user-config-module-keys config)
            modules: (map poo-flow-user-module-selection->alist selected-modules)
            feature-count: (length selected-modules)
            feature-facts: feature-fact-rows
            sandbox-profile-derivation-count:
            (length sandbox-profile-derivation-rows)
            sandbox-profile-derivations: sandbox-profile-derivation-rows
            cicd-intent-count: (length cicd-intent-rows)
            cicd-intents: cicd-intent-rows
            workflow-cicd-pipeline-count: (length workflow-cicd-check-maps)
            workflow-cicd-pipelines:
            (map poo-flow-cicd-check-map-name workflow-cicd-check-maps)
            workflow-cicd-pipeline-run-count:
            (length workflow-cicd-pipeline-run-rows)
            workflow-cicd-pipeline-runs: workflow-cicd-pipeline-run-rows
            workflow-cicd-pipeline-result-count:
            (length workflow-cicd-pipeline-result-rows)
            workflow-cicd-pipeline-results: workflow-cicd-pipeline-result-rows
            workflow-cicd-runtime-readiness-count:
            (length workflow-cicd-readiness-rows)
            workflow-cicd-runtime-readiness: workflow-cicd-readiness-rows
            workflow-cicd-runtime-command-manifest-map-count:
            (length workflow-cicd-runtime-command-manifest-rows)
            workflow-cicd-runtime-command-manifests:
            workflow-cicd-runtime-command-manifest-rows
            workflow-cicd-runtime-command-manifest-summary-count:
            (length workflow-cicd-runtime-command-manifest-summary-rows)
            workflow-cicd-runtime-command-manifest-summaries:
            workflow-cicd-runtime-command-manifest-summary-rows
            workflow-cicd-runtime-command-manifest-agreement:
            workflow-cicd-runtime-command-manifest-agreement-report
            workflow-cicd-runtime-command-manifest-agreement-valid?:
            (poo-flow-user-alist-ref
             workflow-cicd-runtime-command-manifest-agreement-report
             'valid?
             #f)
            workflow-cicd-runtime-command-manifest-agreement-diagnostics:
            (poo-flow-user-alist-ref
             workflow-cicd-runtime-command-manifest-agreement-report
             'diagnostics
             '())
            workflow-cicd-marlin-runtime-handoff-abi-count:
            (length workflow-cicd-marlin-runtime-handoff-abi-rows)
            workflow-cicd-marlin-runtime-handoff-abis:
            workflow-cicd-marlin-runtime-handoff-abi-rows
            workflow-cicd-marlin-runtime-handoff-summary-count:
            (length workflow-cicd-marlin-runtime-handoff-abi-summary-rows)
            workflow-cicd-marlin-runtime-handoff-summaries:
            workflow-cicd-marlin-runtime-handoff-abi-summary-rows
            workflow-cicd-receipt-count: (length workflow-cicd-receipt-rows)
            workflow-cicd-receipts: workflow-cicd-receipt-rows
            workflow-cicd-sandbox-runtime-summaries:
            (poo-flow-user-workflow-cicd-checks-field-values
             workflow-cicd-check-rows
             'sandbox-runtime-summaries)
            workflow-cicd-sandbox-handoff-summaries:
            (poo-flow-user-workflow-cicd-checks-field-values
             workflow-cicd-check-rows
             'sandbox-handoff-summaries)
            workflow-cicd-sandbox-unresolved-profile-refs:
            (poo-flow-user-workflow-cicd-checks-field-values
             workflow-cicd-check-rows
             'sandbox-unresolved-profile-refs)
          ;; Loop-engine presentation fields intentionally mirror the runtime
          ;; handoff payload. They give users and agents one doctor surface for
          ;; audit/report data while preserving the no-execution Scheme boundary.
          loop-engine-intent-count: (length loop-engine-intent-rows)
          loop-engine-intents: loop-engine-intent-rows
          loop-engine-runtime-handoff-count: (length loop-engine-intent-rows)
          loop-engine-runtime-handoffs:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'runtime-handoff-facts)
          loop-engine-workflow-agreements:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'workflow-agreement)
          loop-engine-receipt-contracts:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'receipt-contracts)
          loop-engine-result-contracts:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'result-contract)
          loop-engine-agent-profiles:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'agent-profiles)
          loop-engine-agent-harnesses:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'agent-harnesses)
          loop-engine-agent-sessions:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'agent-sessions)
          loop-engine-workflow-runs:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'workflow-run)
          loop-engine-dispatch-receipts:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'dispatch-receipt)
          loop-engine-agent-operations:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'agent-operation)
          loop-engine-delegated-operations:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'delegated-operation)
          loop-engine-lineage-receipts:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'lineage-receipt)
          loop-engine-selector-receipts:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'selector-receipt)
          loop-engine-resource-dispatch-receipts:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'resource-dispatch-receipt)
          loop-engine-capability-receipts:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'capability-receipt)
          loop-engine-memory-receipts:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'memory-receipt)
          loop-engine-compression-receipts:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'compression-receipt)
          loop-engine-policy-extension-receipts:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'policy-extension-receipts)
          loop-engine-runtime-command-manifests:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'runtime-command-manifest)
          loop-engine-runtime-command-manifest-summaries:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'runtime-command-manifest-summary)
          loop-engine-sandbox-runtime-summaries:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'sandbox-runtime-summaries)
          loop-engine-sandbox-handoff-summaries:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'sandbox-handoff-summaries)
          loop-engine-sandbox-handoff-agreements:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'sandbox-handoff-agreement)
          loop-engine-sandbox-unresolved-profile-refs:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'sandbox-unresolved-profile-refs)
          loop-engine-runtime-snapshot-count: (length loop-engine-intent-rows)
          loop-engine-runtime-snapshots:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'runtime-snapshot)
          presentation-trace: presentation-trace-rows
          setting-count: (length public-setting-keys)
          setting-keys: public-setting-keys
          settings: (poo-flow-user-settings->alist setting-object public-setting-keys)
          user-entrypoints: poo-flow-user-config-public-entrypoints
          api-entrypoints: poo-flow-user-config-api-entrypoints
          boundary: poo-flow-user-config-boundary
          brand-name: poo-flow-brand-name
          brand-group: poo-flow-brand-group
          scheme-owner: poo-flow-scheme-owner
          module-system-owner: poo-flow-module-system-owner
          runtime-owner: "marlin-agent-core"
          runtime-parses-scheme-source: #f
          scheme-manufactures-runtime-handlers: #f
          package-management?: #f
          dependency-installation?: #f
          descriptor-realized?: #f
          runtime-executed: #f
          workflow-cicd-marlin-handoff-receipt-bundle:
          workflow-cicd-marlin-handoff-receipt-bundle-row
          workflow-cicd-marlin-handoff-receipt-bundle-runtime-executed:
          (poo-flow-user-alist-ref
           workflow-cicd-marlin-handoff-receipt-bundle-row
           'runtime-executed
           #f)
          replayable: #t)))))
