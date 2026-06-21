;;; -*- Gerbil -*-
;;; Boundary: user-config presentation projection for module-system reports.
;;; Invariant: presentation is read-only and never realizes descriptors or runtimes.

(import (only-in :clan/poo/object .o)
        (only-in :poo-flow/src/modules/workflow/cicd
                 poo-flow-cicd-check-map-name)
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/observability
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/loop-engine-config)

(export poo-flow-user-config-presentation-trace
        pooFlowUserConfigPresentation)

;;; The trace is deterministic and strict. It is the first slot tests should
;;; inspect when a presentation hangs, because it does not call back into POO.
;; : (-> [PooUserModuleSelection] [Alist] [Alist] [PooFlowCicdCheckMap] [Alist] [Alist] [Alist] Alist [Alist] [Alist] [Symbol] [Alist])
(def (poo-flow-user-config-presentation-trace
      selected-modules
      feature-fact-rows
      cicd-intent-rows
      workflow-cicd-check-maps
      workflow-cicd-readiness-rows
      workflow-cicd-runtime-command-manifest-rows
      workflow-cicd-runtime-command-manifest-summary-rows
      workflow-cicd-runtime-command-manifest-agreement-report
      workflow-cicd-marlin-runtime-handoff-abi-rows
      workflow-cicd-receipt-rows
      loop-engine-intent-rows
      public-setting-keys)
  (poo-flow-module-presentation-trace
   'user-config-presentation
   (list (cons 'selected-modules (length selected-modules))
         (cons 'feature-facts (length feature-fact-rows))
         (cons 'cicd-intents (length cicd-intent-rows))
         (cons 'workflow-cicd-pipelines
               (length workflow-cicd-check-maps))
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
           (cicd-intent-rows
            (poo-flow-user-config-cicd-intents config))
           (workflow-cicd-check-maps
            (poo-flow-user-config-workflow-cicd-check-maps config))
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
           (loop-engine-intent-rows
            (poo-flow-user-config-loop-engine-intents config)))
      (let (workflow-cicd-check-rows
            (poo-flow-user-workflow-cicd-readiness-checks
             workflow-cicd-readiness-rows))
        (.o kind: poo-flow-user-config-presentation-kind
            module-count: (length selected-modules)
            module-keys: (poo-flow-user-config-module-keys config)
            modules: (map poo-flow-user-module-selection->alist selected-modules)
            feature-count: (length selected-modules)
            feature-facts: feature-fact-rows
            cicd-intent-count: (length cicd-intent-rows)
            cicd-intents: cicd-intent-rows
            workflow-cicd-pipeline-count: (length workflow-cicd-check-maps)
            workflow-cicd-pipelines:
            (map poo-flow-cicd-check-map-name workflow-cicd-check-maps)
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
          loop-engine-intent-count: (length loop-engine-intent-rows)
          loop-engine-intents: loop-engine-intent-rows
          loop-engine-runtime-handoff-count: (length loop-engine-intent-rows)
          loop-engine-runtime-handoffs:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'runtime-handoff-facts)
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
          loop-engine-sandbox-unresolved-profile-refs:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'sandbox-unresolved-profile-refs)
          loop-engine-runtime-snapshot-count: (length loop-engine-intent-rows)
          loop-engine-runtime-snapshots:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'runtime-snapshot)
          presentation-trace:
          (poo-flow-user-config-presentation-trace
           selected-modules
           feature-fact-rows
           cicd-intent-rows
           workflow-cicd-check-maps
           workflow-cicd-readiness-rows
           workflow-cicd-runtime-command-manifest-rows
           workflow-cicd-runtime-command-manifest-summary-rows
           workflow-cicd-runtime-command-manifest-agreement-report
           workflow-cicd-marlin-runtime-handoff-abi-rows
           workflow-cicd-receipt-rows
           loop-engine-intent-rows
           public-setting-keys)
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
          replayable: #t)))))
