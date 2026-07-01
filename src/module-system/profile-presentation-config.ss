;;; -*- Gerbil -*-
;;; Boundary: user profile and doctor presentation receipts.
;;; Invariant: presentation is shallow inspection data and does not activate modules.

(import (only-in :clan/poo/object .o .ref object<-alist)
        (only-in :poo-flow/src/modules/workflow/cicd
                 poo-flow-cicd-check-map-name)
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/sandbox-profile-catalog
        :poo-flow/src/module-system/session-core-config
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/workflow-cicd-pipeline-run-config
        :poo-flow/src/module-system/loop-engine-config
        :poo-flow/src/module-system/presentation
        :poo-flow/src/module-system/projection-syntax
        :poo-flow/src/module-system/profile-core
        :poo-flow/src/module-system/profile-doctor)

(export pooFlowUserProfilePresentation
        pooFlowUserProfileSetPresentation
        pooFlowUserProfileDoctorPresentation
        pooFlowUserProfileSetDoctorPresentation)

;;; Profile summaries avoid embedding POO profile objects in presentations.
;; : (-> PooUserProfile Alist)
(defpoo-module-final-projection
  poo-flow-user-profile-summary->alist (profile)
  (bindings ((modules (poo-flow-user-profile-modules profile))))
  (fields ((profile-name (poo-flow-user-profile-name profile))
           (module-count (length modules))
           (module-keys
            (map poo-flow-user-module-selection-key modules))
           (module-bundle-count
            (length (poo-flow-user-profile-module-bundles profile)))
           (setting-keys (poo-flow-user-profile-setting-keys profile))
           (descriptor-realized? #f)
           (runtime-executed #f))))

;;; Boundary: user profile presentation copy slots is the policy-visible edge
;;; for module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> POOObject [Symbol] Alist)
(def (poo-flow-user-profile-presentation-copy-slots source keys)
  (map (lambda (key) (cons key (.ref source key))) keys))

;;; Profile doctor needs a subset of loop-engine receipt fields. Gather them in
;;; one pass so doctor rows do not repeat the presentation hot-path scan.
;; : [Symbol]
(def +poo-flow-user-profile-doctor-loop-engine-fields+
  '(runtime-handoff-facts
    workflow-agreement
    workflow-functional-dag-count
    workflow-functional-dags
    result-contract
    agent-profiles
    agent-harnesses
    agent-sessions
    workflow-run
    dispatch-receipt
    agent-operation
    delegated-operation
    runtime-command-manifest
    runtime-command-manifest-summary
    sandbox-runtime-summaries
    sandbox-handoff-summaries
    sandbox-handoff-agreement
    sandbox-unresolved-profile-refs
    runtime-snapshot))

;; : (-> [Symbol] [Pair])
(def (poo-flow-user-profile-presentation-empty-field-values fields)
  (cond
   ((null? fields) '())
   (else
    (cons (cons (car fields) '())
          (poo-flow-user-profile-presentation-empty-field-values
           (cdr fields))))))

;; : (-> Alist [Pair] [Pair])
(def (poo-flow-user-profile-presentation-accumulate-loop-fields intent
                                                                field-values)
  (cond
   ((null? field-values) '())
   (else
    (let ((field (caar field-values))
          (values (cdar field-values)))
      (cons
       (cons field
             (cons (poo-flow-user-loop-engine-intent-ref intent field #f)
                   values))
       (poo-flow-user-profile-presentation-accumulate-loop-fields
        intent
        (cdr field-values)))))))

;; : (-> [Alist] [Pair] [Pair])
(def (poo-flow-user-profile-presentation-accumulate-loop-rows intents
                                                              field-values)
  (cond
   ((null? intents) field-values)
   (else
    (poo-flow-user-profile-presentation-accumulate-loop-rows
     (cdr intents)
     (poo-flow-user-profile-presentation-accumulate-loop-fields
      (car intents)
      field-values)))))

;; : (-> [Pair] [Pair])
(def (poo-flow-user-profile-presentation-reverse-field-values field-values)
  (cond
   ((null? field-values) '())
   (else
    (cons
     (cons (caar field-values) (reverse (cdar field-values)))
     (poo-flow-user-profile-presentation-reverse-field-values
      (cdr field-values))))))

;; : (-> [Alist] [Pair])
(def (poo-flow-user-profile-presentation-loop-engine-field-values intents)
  (poo-flow-user-profile-presentation-reverse-field-values
   (poo-flow-user-profile-presentation-accumulate-loop-rows
    intents
    (poo-flow-user-profile-presentation-empty-field-values
     +poo-flow-user-profile-doctor-loop-engine-fields+))))

;; : (-> [Pair] Symbol [Value])
(def (poo-flow-user-profile-presentation-field-values-ref field-values field)
  (poo-flow-user-profile-alist-ref field-values field '()))

;;; Profile presentation is the downstream view for the high-level user
;;; entrypoint. It keeps config fields shallow to avoid recursive POO printing.
;; : (-> PooUserProfile POOObject)
(def (pooFlowUserProfilePresentation profile)
  (let* ((config (pooFlowUserConfigFromProfile profile))
         (config-presentation
          (pooFlowUserConfigPresentation
           config
           (poo-flow-user-profile-setting-keys profile))))
    (object<-alist
     (append
      (list (cons 'kind poo-flow-user-profile-presentation-kind)
            (cons 'profile-name (poo-flow-user-profile-name profile))
            (cons 'module-bundle-count
                  (length (poo-flow-user-profile-module-bundles profile))))
      (poo-flow-user-profile-presentation-copy-slots
       config-presentation
       '(module-count
         module-keys
         modules
         feature-count
         feature-facts
         sandbox-profile-derivation-count
         sandbox-profile-derivations
         sandbox-backend-capability-registry-validation
         sandbox-backend-capability-registry-valid?
         sandbox-backend-capability-registry-diagnostic-count
         sandbox-backend-capability-registry-diagnostics
         session-core-intent-count
         session-core-intents
         cicd-intent-count
         cicd-intents
         workflow-cicd-pipeline-count
         workflow-cicd-pipelines
         workflow-cicd-functional-dag-count
         workflow-cicd-functional-dags
         workflow-cicd-pipeline-run-count
         workflow-cicd-pipeline-runs
         workflow-cicd-pipeline-result-count
         workflow-cicd-pipeline-results
         workflow-cicd-runtime-readiness-count
         workflow-cicd-runtime-readiness
         workflow-cicd-runtime-command-manifest-map-count
         workflow-cicd-runtime-command-manifests
         workflow-cicd-runtime-command-manifest-summary-count
         workflow-cicd-runtime-command-manifest-summaries
         workflow-cicd-runtime-command-manifest-agreement
         workflow-cicd-runtime-command-manifest-agreement-valid?
         workflow-cicd-runtime-command-manifest-agreement-diagnostics
         workflow-cicd-marlin-runtime-handoff-abi-count
         workflow-cicd-marlin-runtime-handoff-abis
         workflow-cicd-marlin-runtime-handoff-summary-count
         workflow-cicd-marlin-runtime-handoff-summaries
         workflow-cicd-marlin-handoff-receipt-bundle
         workflow-cicd-marlin-handoff-receipt-bundle-runtime-executed
         workflow-cicd-receipt-count
         workflow-cicd-receipts
         workflow-cicd-sandbox-runtime-summaries
         workflow-cicd-sandbox-handoff-summaries
         workflow-cicd-sandbox-unresolved-profile-refs
         loop-engine-intent-count
         loop-engine-intents
         loop-engine-runtime-handoff-count
         loop-engine-runtime-handoffs
         loop-engine-workflow-agreements
         loop-engine-workflow-functional-dag-counts
         loop-engine-workflow-functional-dags
         loop-engine-result-contracts
         loop-engine-agent-profiles
         loop-engine-agent-harnesses
         loop-engine-agent-sessions
         loop-engine-workflow-runs
         loop-engine-dispatch-receipts
         loop-engine-agent-operations
         loop-engine-delegated-operations
         loop-engine-runtime-command-manifests
         loop-engine-runtime-command-manifest-summaries
         loop-engine-sandbox-runtime-summaries
         loop-engine-sandbox-handoff-summaries
         loop-engine-sandbox-handoff-agreements
         loop-engine-sandbox-unresolved-profile-refs
         loop-engine-runtime-snapshot-count
         loop-engine-runtime-snapshots
         presentation-trace
         setting-count
         setting-keys
         settings))
      (list
       (cons 'config-presentation-kind (.ref config-presentation 'kind))
       (cons 'config-module-count (.ref config-presentation 'module-count))
       (cons 'user-entrypoints poo-flow-user-config-public-entrypoints)
       (cons 'api-entrypoints poo-flow-user-config-api-entrypoints)
       (cons 'boundary poo-flow-user-config-boundary)
       (cons 'brand-name poo-flow-brand-name)
       (cons 'brand-group poo-flow-brand-group)
       (cons 'scheme-owner poo-flow-scheme-owner)
       (cons 'module-system-owner poo-flow-module-system-owner)
       (cons 'runtime-owner "marlin-agent-core")
       (cons 'descriptor-realized? #f)
       (cons 'runtime-executed #f)
       (cons 'replayable #t))))))

;;; Profile set presentation is the inspectable registry view. It keeps the
;;; selected profile shallow and does not trigger descriptor realization.
;; : (-> PooUserProfileSet POOObject)
(def (pooFlowUserProfileSetPresentation profile-set)
  (let ((selected-profile
         (poo-flow-user-profile-set-default-profile profile-set)))
    (object<-alist
     (list
      (cons 'kind poo-flow-user-profile-set-presentation-kind)
      (cons 'profile-set-name
            (poo-flow-user-profile-set-name profile-set))
      (cons 'default-profile-name
            (poo-flow-user-profile-set-default-profile-name profile-set))
      (cons 'selected-profile-name
            (if selected-profile
              (poo-flow-user-profile-name selected-profile)
              #f))
      (cons 'selected-profile? (not (not selected-profile)))
      (cons 'profile-count
            (length (poo-flow-user-profile-set-profiles profile-set)))
      (cons 'profile-names
            (poo-flow-user-profile-set-profile-names profile-set))
      (cons 'profiles
            (map poo-flow-user-profile-summary->alist
                 (poo-flow-user-profile-set-profiles profile-set)))
      (cons 'user-entrypoints poo-flow-user-config-public-entrypoints)
      (cons 'api-entrypoints poo-flow-user-config-api-entrypoints)
      (cons 'boundary poo-flow-user-config-boundary)
      (cons 'brand-name poo-flow-brand-name)
      (cons 'brand-group poo-flow-brand-group)
      (cons 'scheme-owner poo-flow-scheme-owner)
      (cons 'module-system-owner poo-flow-module-system-owner)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'package-management? #f)
      (cons 'dependency-installation? #f)
      (cons 'descriptor-realized? #f)
      (cons 'runtime-executed #f)
      (cons 'replayable #t)))))

;;; Doctor presentation combines high-level profile facts with shallow
;;; diagnostics, keeping the report inspectable for downstream config tooling.
;;; It deliberately avoids full profile presentation so missing settings and
;;; disabled module bundles can still be reported instead of blocking doctor.
;; : (-> PooUserProfile POOObject)
(def (pooFlowUserProfileDoctorPresentation profile)
  (let* ((doctor-report (pooFlowUserProfileDoctor profile))
         (diagnostics (.ref doctor-report 'profile-diagnostics))
         (profile-modules (poo-flow-user-profile-modules profile))
         (profile-config (pooFlowUserConfigFromProfile profile))
         (feature-fact-rows
          (poo-flow-user-config-feature-facts profile-config))
         (sandbox-profile-derivation-rows
         (poo-flow-user-config-sandbox-profile-derivations
           profile-modules))
         (session-core-intent-rows
          (poo-flow-user-config-session-core-intents profile-config))
         (cicd-intent-rows
          (poo-flow-user-config-cicd-intents profile-config))
         (workflow-cicd-check-maps
         (poo-flow-user-config-workflow-cicd-check-maps profile-config))
         (workflow-cicd-functional-dag-rows
          (poo-flow-user-config-workflow-cicd-functional-dag-rows
           profile-config))
         (workflow-cicd-pipeline-run-rows
          (poo-flow-user-config-workflow-cicd-pipeline-runs
           profile-config))
         (workflow-cicd-pipeline-result-rows
          (poo-flow-user-config-workflow-cicd-pipeline-results
           profile-config))
         (workflow-cicd-readiness-rows
          (poo-flow-user-config-workflow-cicd-runtime-readiness
           profile-config))
         (workflow-cicd-runtime-command-manifest-rows
          (poo-flow-user-config-workflow-cicd-runtime-command-manifests
           profile-config))
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
          (poo-flow-user-config-workflow-cicd-receipts profile-config))
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
          (poo-flow-user-config-loop-engine-intents profile-config))
         (loop-engine-field-values
          (poo-flow-user-profile-presentation-loop-engine-field-values
           loop-engine-intent-rows))
         (public-setting-keys (poo-flow-user-profile-setting-keys profile))
         (presentation-trace-rows
          (poo-flow-user-config-presentation-trace
           profile-modules
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
    (object<-alist
     (list
      (cons 'kind poo-flow-user-profile-doctor-presentation-kind)
      (cons 'profile-name (.ref doctor-report 'profile-name))
      (cons 'doctor-status (.ref doctor-report 'doctor-status))
      (cons 'doctor-ok (.ref doctor-report 'doctor-ok))
      (cons 'diagnostic-count (.ref doctor-report 'diagnostic-count))
      (cons 'profile-diagnostics diagnostics)
      (cons 'profile-presentation-kind
            poo-flow-user-profile-presentation-kind)
      (cons 'module-bundle-count
            (length (poo-flow-user-profile-module-bundles profile)))
      (cons 'module-count (length profile-modules))
      (cons 'module-keys
            (map poo-flow-user-module-selection-key profile-modules))
      (cons 'feature-count (length profile-modules))
      (cons 'feature-facts feature-fact-rows)
      (cons 'sandbox-profile-derivation-count
            (length sandbox-profile-derivation-rows))
      (cons 'sandbox-profile-derivations sandbox-profile-derivation-rows)
      (cons 'session-core-intent-count (length session-core-intent-rows))
      (cons 'session-core-intents session-core-intent-rows)
      (cons 'cicd-intent-count (length cicd-intent-rows))
      (cons 'cicd-intents cicd-intent-rows)
      (cons 'workflow-cicd-pipeline-count
            (length workflow-cicd-check-maps))
      (cons 'workflow-cicd-pipelines
            (map poo-flow-cicd-check-map-name workflow-cicd-check-maps))
      (cons 'workflow-cicd-functional-dag-count
            (length workflow-cicd-functional-dag-rows))
      (cons 'workflow-cicd-functional-dags
            workflow-cicd-functional-dag-rows)
      (cons 'workflow-cicd-pipeline-run-count
            (length workflow-cicd-pipeline-run-rows))
      (cons 'workflow-cicd-pipeline-runs workflow-cicd-pipeline-run-rows)
      (cons 'workflow-cicd-pipeline-result-count
            (length workflow-cicd-pipeline-result-rows))
      (cons 'workflow-cicd-pipeline-results
            workflow-cicd-pipeline-result-rows)
      (cons 'workflow-cicd-runtime-readiness-count
            (length workflow-cicd-readiness-rows))
      (cons 'workflow-cicd-runtime-readiness workflow-cicd-readiness-rows)
      (cons 'workflow-cicd-runtime-command-manifest-map-count
            (length workflow-cicd-runtime-command-manifest-rows))
      (cons 'workflow-cicd-runtime-command-manifests
            workflow-cicd-runtime-command-manifest-rows)
      (cons 'workflow-cicd-runtime-command-manifest-summary-count
            (length workflow-cicd-runtime-command-manifest-summary-rows))
      (cons 'workflow-cicd-runtime-command-manifest-summaries
            workflow-cicd-runtime-command-manifest-summary-rows)
      (cons 'workflow-cicd-runtime-command-manifest-agreement
            workflow-cicd-runtime-command-manifest-agreement-report)
      (cons 'workflow-cicd-runtime-command-manifest-agreement-valid?
            (poo-flow-user-profile-alist-ref
             workflow-cicd-runtime-command-manifest-agreement-report
             'valid?
             #f))
      (cons 'workflow-cicd-runtime-command-manifest-agreement-diagnostics
            (poo-flow-user-profile-alist-ref
             workflow-cicd-runtime-command-manifest-agreement-report
             'diagnostics
             '()))
      (cons 'workflow-cicd-marlin-runtime-handoff-abi-count
            (length workflow-cicd-marlin-runtime-handoff-abi-rows))
      (cons 'workflow-cicd-marlin-runtime-handoff-abis
            workflow-cicd-marlin-runtime-handoff-abi-rows)
      (cons 'workflow-cicd-marlin-runtime-handoff-summary-count
            (length workflow-cicd-marlin-runtime-handoff-abi-summary-rows))
      (cons 'workflow-cicd-marlin-runtime-handoff-summaries
            workflow-cicd-marlin-runtime-handoff-abi-summary-rows)
      (cons 'workflow-cicd-marlin-handoff-receipt-bundle
            workflow-cicd-marlin-handoff-receipt-bundle-row)
      (cons 'workflow-cicd-marlin-handoff-receipt-bundle-runtime-executed
            (poo-flow-user-profile-alist-ref
             workflow-cicd-marlin-handoff-receipt-bundle-row
             'runtime-executed
             #f))
      (cons 'workflow-cicd-receipt-count (length workflow-cicd-receipt-rows))
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
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'runtime-handoff-facts))
      (cons 'loop-engine-workflow-agreements
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'workflow-agreement))
      (cons 'loop-engine-workflow-functional-dag-counts
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'workflow-functional-dag-count))
      (cons 'loop-engine-workflow-functional-dags
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'workflow-functional-dags))
      (cons 'loop-engine-result-contracts
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'result-contract))
      (cons 'loop-engine-agent-profiles
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'agent-profiles))
      (cons 'loop-engine-agent-harnesses
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'agent-harnesses))
      (cons 'loop-engine-agent-sessions
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'agent-sessions))
      (cons 'loop-engine-workflow-runs
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'workflow-run))
      (cons 'loop-engine-dispatch-receipts
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'dispatch-receipt))
      (cons 'loop-engine-agent-operations
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'agent-operation))
      (cons 'loop-engine-delegated-operations
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'delegated-operation))
      (cons 'loop-engine-runtime-command-manifests
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'runtime-command-manifest))
      (cons 'loop-engine-runtime-command-manifest-summaries
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'runtime-command-manifest-summary))
      (cons 'loop-engine-sandbox-runtime-summaries
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'sandbox-runtime-summaries))
      (cons 'loop-engine-sandbox-handoff-summaries
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'sandbox-handoff-summaries))
      (cons 'loop-engine-sandbox-handoff-agreements
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'sandbox-handoff-agreement))
      (cons 'loop-engine-sandbox-unresolved-profile-refs
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'sandbox-unresolved-profile-refs))
      (cons 'loop-engine-runtime-snapshot-count
            (length loop-engine-intent-rows))
      (cons 'loop-engine-runtime-snapshots
            (poo-flow-user-profile-presentation-field-values-ref
             loop-engine-field-values
             'runtime-snapshot))
      (cons 'presentation-trace presentation-trace-rows)
      (cons 'setting-count (length public-setting-keys))
      (cons 'setting-keys public-setting-keys)
      (cons 'user-entrypoints poo-flow-user-config-public-entrypoints)
      (cons 'api-entrypoints poo-flow-user-config-api-entrypoints)
      (cons 'boundary poo-flow-user-config-boundary)
      (cons 'brand-name poo-flow-brand-name)
      (cons 'brand-group poo-flow-brand-group)
      (cons 'scheme-owner poo-flow-scheme-owner)
      (cons 'module-system-owner poo-flow-module-system-owner)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'package-management? #f)
      (cons 'dependency-installation? #f)
      (cons 'descriptor-realized? #f)
      (cons 'runtime-executed #f)
      (cons 'replayable #t)))))

;;; Profile set doctor presentation exposes registry health and selected
;;; profile state in one shallow receipt.
;; : (-> PooUserProfileSet POOObject)
(def (pooFlowUserProfileSetDoctorPresentation profile-set)
  (let* ((doctor-report (pooFlowUserProfileSetDoctor profile-set))
         (selected-profile
          (poo-flow-user-profile-set-default-profile profile-set)))
    (object<-alist
     (list
      (cons 'kind poo-flow-user-profile-set-doctor-presentation-kind)
      (cons 'profile-set-name (.ref doctor-report 'profile-set-name))
      (cons 'default-profile-name (.ref doctor-report 'default-profile-name))
      (cons 'selected-profile-name
            (if selected-profile
              (poo-flow-user-profile-name selected-profile)
              #f))
      (cons 'selected-profile? (not (not selected-profile)))
      (cons 'doctor-status (.ref doctor-report 'doctor-status))
      (cons 'doctor-ok (.ref doctor-report 'doctor-ok))
      (cons 'diagnostic-count (.ref doctor-report 'diagnostic-count))
      (cons 'profile-diagnostics (.ref doctor-report 'profile-diagnostics))
      (cons 'profile-count
            (length (poo-flow-user-profile-set-profiles profile-set)))
      (cons 'profile-names (.ref doctor-report 'profile-names))
      (cons 'user-entrypoints poo-flow-user-config-public-entrypoints)
      (cons 'api-entrypoints poo-flow-user-config-api-entrypoints)
      (cons 'boundary poo-flow-user-config-boundary)
      (cons 'brand-name poo-flow-brand-name)
      (cons 'brand-group poo-flow-brand-group)
      (cons 'scheme-owner poo-flow-scheme-owner)
      (cons 'module-system-owner poo-flow-module-system-owner)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'package-management? #f)
      (cons 'dependency-installation? #f)
      (cons 'descriptor-realized? #f)
      (cons 'runtime-executed #f)
      (cons 'replayable #t)))))
