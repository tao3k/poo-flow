;;; -*- Gerbil -*-
;;; Boundary: user profile and doctor presentation receipts.
;;; Invariant: presentation is shallow inspection data and does not activate modules.

(import (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/src/modules/workflow/cicd
                 poo-flow-cicd-check-map-name)
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/sandbox-profile-catalog
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/workflow-cicd-pipeline-run-config
        :poo-flow/src/module-system/loop-engine-config
        :poo-flow/src/module-system/presentation
        :poo-flow/src/module-system/profile-core
        :poo-flow/src/module-system/profile-doctor)

(export pooFlowUserProfilePresentation
        pooFlowUserProfileSetPresentation
        pooFlowUserProfileDoctorPresentation
        pooFlowUserProfileSetDoctorPresentation)

;;; Profile summaries avoid embedding POO profile objects in presentations.
;; : (-> PooUserProfile Alist)
(def (poo-flow-user-profile-summary->alist profile)
  (list
   (cons 'profile-name (poo-flow-user-profile-name profile))
   (cons 'module-count (length (poo-flow-user-profile-modules profile)))
   (cons 'module-keys
         (map poo-flow-user-module-selection-key
              (poo-flow-user-profile-modules profile)))
   (cons 'module-bundle-count
         (length (poo-flow-user-profile-module-bundles profile)))
   (cons 'setting-keys (poo-flow-user-profile-setting-keys profile))
   (cons 'descriptor-realized? #f)
   (cons 'runtime-executed #f)))

;;; Profile presentation is the downstream view for the high-level user
;;; entrypoint. It keeps config fields shallow to avoid recursive POO printing.
;; : (-> PooUserProfile POOObject)
(def (pooFlowUserProfilePresentation profile)
  (let* ((config (pooFlowUserConfigFromProfile profile))
         (config-presentation
          (pooFlowUserConfigPresentation
           config
           (poo-flow-user-profile-setting-keys profile))))
    (.o kind: poo-flow-user-profile-presentation-kind
        profile-name: (poo-flow-user-profile-name profile)
        module-bundle-count: (length (poo-flow-user-profile-module-bundles profile))
        module-count: (.ref config-presentation 'module-count)
        module-keys: (.ref config-presentation 'module-keys)
        modules: (.ref config-presentation 'modules)
        feature-count: (.ref config-presentation 'feature-count)
        feature-facts: (.ref config-presentation 'feature-facts)
        sandbox-profile-derivation-count:
        (.ref config-presentation 'sandbox-profile-derivation-count)
        sandbox-profile-derivations:
        (.ref config-presentation 'sandbox-profile-derivations)
        cicd-intent-count: (.ref config-presentation 'cicd-intent-count)
        cicd-intents: (.ref config-presentation 'cicd-intents)
        workflow-cicd-pipeline-count:
        (.ref config-presentation 'workflow-cicd-pipeline-count)
        workflow-cicd-pipelines:
        (.ref config-presentation 'workflow-cicd-pipelines)
        workflow-cicd-pipeline-run-count:
        (.ref config-presentation 'workflow-cicd-pipeline-run-count)
        workflow-cicd-pipeline-runs:
        (.ref config-presentation 'workflow-cicd-pipeline-runs)
        workflow-cicd-pipeline-result-count:
        (.ref config-presentation 'workflow-cicd-pipeline-result-count)
        workflow-cicd-pipeline-results:
        (.ref config-presentation 'workflow-cicd-pipeline-results)
        workflow-cicd-runtime-readiness-count:
        (.ref config-presentation 'workflow-cicd-runtime-readiness-count)
        workflow-cicd-runtime-readiness:
        (.ref config-presentation 'workflow-cicd-runtime-readiness)
        workflow-cicd-runtime-command-manifest-map-count:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-map-count)
        workflow-cicd-runtime-command-manifests:
        (.ref config-presentation 'workflow-cicd-runtime-command-manifests)
        workflow-cicd-runtime-command-manifest-summary-count:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-summary-count)
        workflow-cicd-runtime-command-manifest-summaries:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-summaries)
        workflow-cicd-runtime-command-manifest-agreement:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-agreement)
        workflow-cicd-runtime-command-manifest-agreement-valid?:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-agreement-valid?)
        workflow-cicd-runtime-command-manifest-agreement-diagnostics:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-agreement-diagnostics)
        workflow-cicd-marlin-runtime-handoff-abi-count:
        (.ref config-presentation
              'workflow-cicd-marlin-runtime-handoff-abi-count)
        workflow-cicd-marlin-runtime-handoff-abis:
        (.ref config-presentation
              'workflow-cicd-marlin-runtime-handoff-abis)
        workflow-cicd-marlin-runtime-handoff-summary-count:
        (.ref config-presentation
              'workflow-cicd-marlin-runtime-handoff-summary-count)
        workflow-cicd-marlin-runtime-handoff-summaries:
        (.ref config-presentation
              'workflow-cicd-marlin-runtime-handoff-summaries)
        workflow-cicd-marlin-handoff-receipt-bundle:
        (.ref config-presentation
              'workflow-cicd-marlin-handoff-receipt-bundle)
        workflow-cicd-marlin-handoff-receipt-bundle-runtime-executed:
        (.ref config-presentation
              'workflow-cicd-marlin-handoff-receipt-bundle-runtime-executed)
        workflow-cicd-receipt-count:
        (.ref config-presentation 'workflow-cicd-receipt-count)
        workflow-cicd-receipts:
        (.ref config-presentation 'workflow-cicd-receipts)
        workflow-cicd-sandbox-runtime-summaries:
        (.ref config-presentation 'workflow-cicd-sandbox-runtime-summaries)
        workflow-cicd-sandbox-handoff-summaries:
        (.ref config-presentation 'workflow-cicd-sandbox-handoff-summaries)
        workflow-cicd-sandbox-unresolved-profile-refs:
        (.ref config-presentation
              'workflow-cicd-sandbox-unresolved-profile-refs)
        loop-engine-intent-count:
        (.ref config-presentation 'loop-engine-intent-count)
        loop-engine-intents: (.ref config-presentation 'loop-engine-intents)
        loop-engine-runtime-handoff-count:
        (.ref config-presentation 'loop-engine-runtime-handoff-count)
        loop-engine-runtime-handoffs:
        (.ref config-presentation 'loop-engine-runtime-handoffs)
        loop-engine-workflow-agreements:
        (.ref config-presentation 'loop-engine-workflow-agreements)
        loop-engine-result-contracts:
        (.ref config-presentation 'loop-engine-result-contracts)
        loop-engine-agent-profiles:
        (.ref config-presentation 'loop-engine-agent-profiles)
        loop-engine-agent-harnesses:
        (.ref config-presentation 'loop-engine-agent-harnesses)
        loop-engine-agent-sessions:
        (.ref config-presentation 'loop-engine-agent-sessions)
        loop-engine-workflow-runs:
        (.ref config-presentation 'loop-engine-workflow-runs)
        loop-engine-dispatch-receipts:
        (.ref config-presentation 'loop-engine-dispatch-receipts)
        loop-engine-agent-operations:
        (.ref config-presentation 'loop-engine-agent-operations)
        loop-engine-delegated-operations:
        (.ref config-presentation 'loop-engine-delegated-operations)
        loop-engine-runtime-command-manifests:
        (.ref config-presentation 'loop-engine-runtime-command-manifests)
        loop-engine-runtime-command-manifest-summaries:
        (.ref config-presentation
              'loop-engine-runtime-command-manifest-summaries)
        loop-engine-sandbox-runtime-summaries:
        (.ref config-presentation 'loop-engine-sandbox-runtime-summaries)
        loop-engine-sandbox-handoff-summaries:
        (.ref config-presentation 'loop-engine-sandbox-handoff-summaries)
        loop-engine-sandbox-handoff-agreements:
        (.ref config-presentation 'loop-engine-sandbox-handoff-agreements)
        loop-engine-sandbox-unresolved-profile-refs:
        (.ref config-presentation 'loop-engine-sandbox-unresolved-profile-refs)
        loop-engine-runtime-snapshot-count:
        (.ref config-presentation 'loop-engine-runtime-snapshot-count)
        loop-engine-runtime-snapshots:
        (.ref config-presentation 'loop-engine-runtime-snapshots)
        presentation-trace: (.ref config-presentation 'presentation-trace)
        setting-count: (.ref config-presentation 'setting-count)
        setting-keys: (.ref config-presentation 'setting-keys)
        settings: (.ref config-presentation 'settings)
        config-presentation-kind: (.ref config-presentation 'kind)
        config-module-count: (.ref config-presentation 'module-count)
        user-entrypoints: poo-flow-user-config-public-entrypoints
        api-entrypoints: poo-flow-user-config-api-entrypoints
        boundary: poo-flow-user-config-boundary
        brand-name: poo-flow-brand-name
        brand-group: poo-flow-brand-group
        scheme-owner: poo-flow-scheme-owner
        module-system-owner: poo-flow-module-system-owner
        runtime-owner: "marlin-agent-core"
        descriptor-realized?: #f
        runtime-executed: #f
        replayable: #t)))

;;; Profile set presentation is the inspectable registry view. It keeps the
;;; selected profile shallow and does not trigger descriptor realization.
;; : (-> PooUserProfileSet POOObject)
(def (pooFlowUserProfileSetPresentation profile-set)
  (let ((selected-profile
         (poo-flow-user-profile-set-default-profile profile-set)))
    (.o kind: poo-flow-user-profile-set-presentation-kind
        profile-set-name: (poo-flow-user-profile-set-name profile-set)
        default-profile-name:
        (poo-flow-user-profile-set-default-profile-name profile-set)
        selected-profile-name:
        (if selected-profile
          (poo-flow-user-profile-name selected-profile)
          #f)
        selected-profile?:
        (not (not selected-profile))
        profile-count:
        (length (poo-flow-user-profile-set-profiles profile-set))
        profile-names: (poo-flow-user-profile-set-profile-names profile-set)
        profiles:
        (map poo-flow-user-profile-summary->alist
             (poo-flow-user-profile-set-profiles profile-set))
        user-entrypoints: poo-flow-user-config-public-entrypoints
        api-entrypoints: poo-flow-user-config-api-entrypoints
        boundary: poo-flow-user-config-boundary
        brand-name: poo-flow-brand-name
        brand-group: poo-flow-brand-group
        scheme-owner: poo-flow-scheme-owner
        module-system-owner: poo-flow-module-system-owner
        runtime-owner: "marlin-agent-core"
        package-management?: #f
        dependency-installation?: #f
        descriptor-realized?: #f
        runtime-executed: #f
        replayable: #t)))

;;; Doctor presentation combines high-level profile facts with shallow
;;; diagnostics, keeping the report inspectable for downstream config tooling.
;;; It deliberately avoids full profile presentation so missing settings and
;;; disabled module bundles can still be reported instead of blocking doctor.
;; : (-> PooUserProfile POOObject)
(def (pooFlowUserProfileDoctorPresentation profile)
  (let* ((doctor-report (pooFlowUserProfileDoctor profile))
         (diagnostics (.ref doctor-report 'profile-diagnostics))
         (profile-modules (poo-flow-user-profile-modules profile))
         (feature-fact-rows
          (poo-flow-user-config-feature-facts
           (pooFlowUserConfigFromProfile profile)))
         (sandbox-profile-derivation-rows
          (poo-flow-user-config-sandbox-profile-derivations
           profile-modules))
         (cicd-intent-rows
          (poo-flow-user-config-cicd-intents
           (pooFlowUserConfigFromProfile profile)))
         (workflow-cicd-check-maps
         (poo-flow-user-config-workflow-cicd-check-maps
           (pooFlowUserConfigFromProfile profile)))
         (workflow-cicd-pipeline-run-rows
          (poo-flow-user-config-workflow-cicd-pipeline-runs
           (pooFlowUserConfigFromProfile profile)))
         (workflow-cicd-pipeline-result-rows
          (poo-flow-user-config-workflow-cicd-pipeline-results
           (pooFlowUserConfigFromProfile profile)))
         (workflow-cicd-readiness-rows
          (poo-flow-user-config-workflow-cicd-runtime-readiness
           (pooFlowUserConfigFromProfile profile)))
         (workflow-cicd-runtime-command-manifest-rows
          (poo-flow-user-config-workflow-cicd-runtime-command-manifests
           (pooFlowUserConfigFromProfile profile)))
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
          (poo-flow-user-config-workflow-cicd-receipts
           (pooFlowUserConfigFromProfile profile)))
         (workflow-cicd-marlin-handoff-receipt-bundle-row
          (poo-flow-user-workflow-cicd-marlin-handoff-receipt-bundle
           workflow-cicd-runtime-command-manifest-rows
           workflow-cicd-runtime-command-manifest-summary-rows
           workflow-cicd-runtime-command-manifest-agreement-report
           workflow-cicd-marlin-runtime-handoff-abi-rows
           workflow-cicd-marlin-runtime-handoff-abi-summary-rows
           workflow-cicd-receipt-rows))
         (workflow-cicd-check-rows
          (poo-flow-user-workflow-cicd-readiness-checks
           workflow-cicd-readiness-rows))
         (loop-engine-intent-rows
          (poo-flow-user-config-loop-engine-intents
           (pooFlowUserConfigFromProfile profile)))
         (public-setting-keys (poo-flow-user-profile-setting-keys profile))
         (presentation-trace-rows
          (poo-flow-user-config-presentation-trace
           profile-modules
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
    (.o kind: poo-flow-user-profile-doctor-presentation-kind
        profile-name: (.ref doctor-report 'profile-name)
        doctor-status: (.ref doctor-report 'doctor-status)
        doctor-ok: (.ref doctor-report 'doctor-ok)
        diagnostic-count: (.ref doctor-report 'diagnostic-count)
        profile-diagnostics: diagnostics
        profile-presentation-kind: poo-flow-user-profile-presentation-kind
        module-bundle-count: (length (poo-flow-user-profile-module-bundles profile))
        module-count: (length profile-modules)
        module-keys: (map poo-flow-user-module-selection-key profile-modules)
        feature-count: (length profile-modules)
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
        (poo-flow-user-profile-alist-ref
         workflow-cicd-runtime-command-manifest-agreement-report
         'valid?
         #f)
        workflow-cicd-runtime-command-manifest-agreement-diagnostics:
        (poo-flow-user-profile-alist-ref
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
        workflow-cicd-marlin-handoff-receipt-bundle:
        workflow-cicd-marlin-handoff-receipt-bundle-row
        workflow-cicd-marlin-handoff-receipt-bundle-runtime-executed:
        (poo-flow-user-profile-alist-ref
         workflow-cicd-marlin-handoff-receipt-bundle-row
         'runtime-executed
         #f)
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
        loop-engine-workflow-agreements:
        (poo-flow-user-loop-engine-intents-field-values
         loop-engine-intent-rows
         'workflow-agreement)
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
        user-entrypoints: poo-flow-user-config-public-entrypoints
        api-entrypoints: poo-flow-user-config-api-entrypoints
        boundary: poo-flow-user-config-boundary
        brand-name: poo-flow-brand-name
        brand-group: poo-flow-brand-group
        scheme-owner: poo-flow-scheme-owner
        module-system-owner: poo-flow-module-system-owner
        runtime-owner: "marlin-agent-core"
        package-management?: #f
        dependency-installation?: #f
        descriptor-realized?: #f
        runtime-executed: #f
        replayable: #t)))

;;; Profile set doctor presentation exposes registry health and selected
;;; profile state in one shallow receipt.
;; : (-> PooUserProfileSet POOObject)
(def (pooFlowUserProfileSetDoctorPresentation profile-set)
  (let* ((doctor-report (pooFlowUserProfileSetDoctor profile-set))
         (selected-profile
          (poo-flow-user-profile-set-default-profile profile-set)))
    (.o kind: poo-flow-user-profile-set-doctor-presentation-kind
        profile-set-name: (.ref doctor-report 'profile-set-name)
        default-profile-name: (.ref doctor-report 'default-profile-name)
        selected-profile-name:
        (if selected-profile
          (poo-flow-user-profile-name selected-profile)
          #f)
        selected-profile?:
        (not (not selected-profile))
        doctor-status: (.ref doctor-report 'doctor-status)
        doctor-ok: (.ref doctor-report 'doctor-ok)
        diagnostic-count: (.ref doctor-report 'diagnostic-count)
        profile-diagnostics: (.ref doctor-report 'profile-diagnostics)
        profile-count:
        (length (poo-flow-user-profile-set-profiles profile-set))
        profile-names: (.ref doctor-report 'profile-names)
        user-entrypoints: poo-flow-user-config-public-entrypoints
        api-entrypoints: poo-flow-user-config-api-entrypoints
        boundary: poo-flow-user-config-boundary
        brand-name: poo-flow-brand-name
        brand-group: poo-flow-brand-group
        scheme-owner: poo-flow-scheme-owner
        module-system-owner: poo-flow-module-system-owner
        runtime-owner: "marlin-agent-core"
        package-management?: #f
        dependency-installation?: #f
        descriptor-realized?: #f
        runtime-executed: #f
        replayable: #t)))
