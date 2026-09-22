;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: tests verify user-interface presentation receipts.
;;; Invariant: presentations stay report-only and never realize descriptors.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/module-system/interface
                 poo-flow-brand-group
                 poo-flow-brand-name)
        (only-in :poo-flow/src/module-system/declaration/interface
                 poo-flow-user-config-presentation-kind)
        (only-in :poo-flow/src/user-interface/presentation-config
                 pooFlowUserConfigPresentation)
        (only-in :poo-flow/src/user-interface/profile-core
                 poo-flow-user-profile-doctor-presentation-kind
                 poo-flow-user-profile-doctor-report-kind
                 poo-flow-user-profile-presentation-kind)
        (only-in :poo-flow/src/user-interface/profile-doctor
                 poo-flow-user-profile-doctor-ok?
                 pooFlowUserProfileDoctor)
        (only-in :poo-flow/src/user-interface/profile-presentation-config
                 pooFlowUserProfileDoctorPresentation
                 pooFlowUserProfilePresentation)
        "user-interface-fixtures.ss")

(export user-interface-presentation-test)

;;; Trace stage order is the presentation contract for downstream tooling; the
;;; cases assert order without duplicating the projection implementation.
;; : [Symbol]
(def user-interface-presentation-trace-stages
  '(selected-modules
    feature-facts
    sandbox-profile-derivations
    session-core-intents
    cicd-intents
    workflow-cicd-pipelines
    workflow-cicd-functional-dags
    workflow-cicd-pipeline-runs
    workflow-cicd-pipeline-results
    workflow-cicd-runtime-readiness
    workflow-cicd-runtime-command-manifest-maps
    workflow-cicd-runtime-command-manifest-summaries
    workflow-cicd-runtime-command-manifest-agreement
    workflow-cicd-marlin-runtime-handoff-abis
    workflow-cicd-receipts
    workflow-cicd-marlin-handoff-receipt-bundle
    loop-engine-intents
    settings))

;;; Trace lookup keeps assertions focused on stage names instead of relying on
;;; positional indexes that would hide missing or reordered projection steps.
;; : (-> [Alist] Symbol MaybeAlist)
(def (user-interface-presentation-trace-stage trace stage)
  (cond
   ((null? trace) #f)
   ((equal? (alist-value 'stage (car trace)) stage) (car trace))
   (else
    (user-interface-presentation-trace-stage (cdr trace) stage))))

;;; Config presentation is the broadest receipt surface, covering module
;;; switches, CI/CD handoff rows, loop-engine rows, and ownership boundaries.
;; : (-> Unit TestSuite)
(def (user-interface-config-presentation-test)
  (test-case "presents downstream config without descriptor realization"
      (let* ((presentation
              (pooFlowUserConfigPresentation
               test-poo-flow-user-config
               '(surface
                 profile
                 flow-mode
                 loop-strategy
                 sandbox-policy
                 sandbox-backends
                 mode-lock)))
             (modules (.ref presentation 'modules))
             (feature-facts (.ref presentation 'feature-facts))
             (cicd-intent (car (.ref presentation 'cicd-intents)))
             (loop-engine-intent
              (car (.ref presentation 'loop-engine-intents)))
             (loop-engine-result-contract
              (car (.ref presentation 'loop-engine-result-contracts)))
             (trace (.ref presentation 'presentation-trace))
             (settings (.ref presentation 'settings)))
        (check-equal? (.ref presentation 'kind)
                      poo-flow-user-config-presentation-kind)
        (check-equal? (.ref presentation 'module-count) 8)
        (check-equal? (.ref presentation 'module-keys)
                      '((core . poo-clos)
                        (flow . funflow)
                        (session . session-core)
                        (loop . governor)
                        (sandbox . nono-sandbox)
                        (sandbox . cubeSandbox)
                        (sandbox . docker-sandbox)
                        (flow . loop-engine)))
        (check-equal? (.ref presentation 'feature-count) 8)
        (check-equal? (.ref presentation 'sandbox-profile-derivation-count)
                      0)
        (check-equal? (.ref presentation 'sandbox-profile-derivations)
                      '())
        (check-equal? (.ref presentation 'session-core-intent-count) 1)
        (check-equal? (alist-value 'key
                                   (car (.ref presentation
                                             'session-core-intents)))
                      '(session . session-core))
        (check-equal? (alist-value 'flags
                                   (car (.ref presentation
                                             'session-core-intents)))
                      '(+lineage +placement +handoff +graph +transform +doctor))
        (check-equal? (alist-value 'transform-enabled?
                                   (car (.ref presentation
                                             'session-core-intents)))
                      #t)
        (check-equal? (alist-value 'runtime-executed
                                   (car (.ref presentation
                                             'session-core-intents)))
                      #f)
        (check-equal? (alist-value 'declaration-index
                                   (car feature-facts))
                      0)
        (check-equal? (alist-value 'declaration-phase
                                   (car feature-facts))
                      'init-selection)
        (check-equal? (alist-value 'key (car feature-facts))
                      '(core . poo-clos))
        (check-equal? (alist-value 'dependency-installation?
                                   (car feature-facts))
                      #f)
        (check-equal? (alist-value 'descriptor-realized?
                                   (car feature-facts))
                      #f)
        (check-equal? (.ref presentation 'setting-count) 7)
        (check-equal? (alist-value 'flags (car modules))
                      '(+native))
        (check-equal? (.ref presentation 'cicd-intent-count) 1)
        (check-equal? (alist-value 'checks cicd-intent)
                      '(+parallel +typed-receipts))
        (check-equal? (alist-value 'runtime-handoff cicd-intent)
                      'runtime-command-manifest)
        (check-equal? (alist-value 'runtime-executed cicd-intent) #f)
        (check-equal? (.ref presentation 'workflow-cicd-pipeline-run-count)
                      0)
        (check-equal? (.ref presentation 'workflow-cicd-pipeline-runs)
                      '())
        (check-equal? (.ref presentation 'workflow-cicd-pipeline-result-count)
                      0)
        (check-equal? (.ref presentation 'workflow-cicd-pipeline-results)
                      '())
        (check-equal? (.ref presentation
                            'workflow-cicd-runtime-command-manifest-agreement-valid?)
                      #t)
        (check-equal? (.ref presentation
                            'workflow-cicd-runtime-command-manifest-agreement-diagnostics)
                      '())
        (check-equal? (.ref presentation
                            'workflow-cicd-marlin-runtime-handoff-abi-count)
                      0)
        (check-equal? (.ref presentation
                            'workflow-cicd-marlin-runtime-handoff-summary-count)
                      0)
        (check-equal? (.ref presentation
                            'workflow-cicd-marlin-runtime-handoff-summaries)
                      '())
        (let ((bundle
               (.ref presentation
                     'workflow-cicd-marlin-handoff-receipt-bundle)))
          (check-equal? (alist-value 'kind bundle)
                        'workflow-cicd-marlin-handoff-receipt-bundle)
          (check-equal? (alist-value 'marlin-runtime-handoff-abi-count bundle)
                        0)
          (check-equal? (alist-value 'runtime-executed bundle) #f))
        (check-equal? (.ref presentation 'loop-engine-intent-count) 1)
        (check-equal? (alist-value 'key loop-engine-intent)
                      '(flow . loop-engine))
        (check-equal? (alist-value 'workflow-owned? loop-engine-intent) #t)
        (check-equal? (alist-value 'governor-derived? loop-engine-intent) #t)
        (check-equal? (alist-value 'governor loop-engine-intent)
                      '(+strategy +policy))
        (check-equal? (alist-value 'agent-judges loop-engine-intent)
                      '((auditor repo-audit-agent)
                        (verifier repo-verifier-agent)
                        (governor repo-governor)))
        (check-equal? (alist-value 'human-audit loop-engine-intent)
                      '(+approval +changes-requested))
        (check-equal? (alist-value 'runtime-handoff loop-engine-intent)
                      'loop-governor-marlin-runtime-manifest)
        (check-equal? (alist-value 'contract loop-engine-result-contract)
                      'poo-flow.loop-governor.result-contract.v1)
        (check-equal? (alist-value 'valid? loop-engine-result-contract) #t)
        (check-equal? (alist-value 'human-audit loop-engine-result-contract)
                      'poo-flow.loop-governor.node-result.v1)
        (check-equal? (alist-value 'required-fields
                                   loop-engine-result-contract)
                      '(decision summary evidence))
        (check-equal? (car (.ref presentation 'loop-engine-agent-profiles))
                      (alist-value 'agent-profiles loop-engine-intent))
        (check-equal? (car (.ref presentation
                                  'loop-engine-delegated-operations))
                      (alist-value 'delegated-operation loop-engine-intent))
        (check-equal? (alist-value 'runtime-executed loop-engine-intent) #f)
        (check-equal? (map (lambda (step) (alist-value 'stage step))
                           trace)
                      user-interface-presentation-trace-stages)
        (check-equal? (map (lambda (step) (alist-value 'runtime-executed step))
                           trace)
                      '(#f #f #f #f #f #f #f #f #f #f #f #f #f #f #f #f #f #f))
        (check-equal? (alist-value 'profile settings)
                      "developer")
        (check-equal? (.ref presentation 'brand-name) poo-flow-brand-name)
        (check-equal? (.ref presentation 'brand-group) poo-flow-brand-group)
        (check-equal? (not
                       (not
                        (member "poo-flow!"
                                (.ref presentation 'user-entrypoints))))
                      #t)
        (check-equal? (not
                       (not
                        (member "use-module"
                                (.ref presentation 'user-entrypoints))))
                      #t)
        (check-equal? (not
                       (not
                        (member "pooFlowUserConfigPresentation"
                                (.ref presentation 'api-entrypoints))))
                      #t)
        (check-equal? (not
                       (not
                        (member "poo-flow-user-config-feature?"
                                (.ref presentation 'api-entrypoints))))
                      #t)
        (check-equal? (not
                       (not
                        (member "pooFlowSandboxProfilesPresentation"
                                (.ref presentation 'api-entrypoints))))
                      #t)
        (check-equal? (alist-value 'runtime-owner
                                   (.ref presentation 'boundary))
                      "marlin-agent-core")
        (check-equal? (alist-value 'package-management
                                   (.ref presentation 'boundary))
                      #f)
        (check-equal? (alist-value 'dependency-installation
                                   (.ref presentation 'boundary))
                      #f)
        (check-equal? (.ref presentation 'runtime-owner)
                      "marlin-agent-core")
        (check-equal? (.ref presentation 'package-management?) #f)
        (check-equal? (.ref presentation 'dependency-installation?) #f)
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f))))

;;; Profile presentation wraps the config projection while preserving the
;;; higher-level Doom-style profile fields users inspect.
;; : (-> Unit TestSuite)
(def (user-interface-profile-presentation-case-test)
  (test-case "presents profile without descriptor realization"
      (let* ((presentation
              (pooFlowUserProfilePresentation test-poo-flow-user-profile)))
        (check-equal? (.ref presentation 'kind)
                      poo-flow-user-profile-presentation-kind)
        (check-equal? (.ref presentation 'profile-name) 'developer)
        (check-equal? (.ref presentation 'module-bundle-count) 8)
        (check-equal? (.ref presentation 'module-count) 8)
        (check-equal? (.ref presentation 'config-presentation-kind)
                      poo-flow-user-config-presentation-kind)
        (check-equal? (.ref presentation 'config-module-count) 8)
        (check-equal? (.ref presentation 'feature-count) 8)
        (check-equal? (.ref presentation 'sandbox-profile-derivation-count)
                      0)
        (check-equal? (.ref presentation 'sandbox-profile-derivations)
                      '())
        (check-equal? (.ref presentation 'session-core-intent-count) 1)
        (check-equal? (alist-value 'key
                                   (car (.ref presentation
                                             'session-core-intents)))
                      '(session . session-core))
        (check-equal? (.ref presentation 'cicd-intent-count) 1)
        (check-equal? (.ref presentation
                            'workflow-cicd-runtime-command-manifest-agreement-valid?)
                      #t)
        (check-equal? (.ref presentation
                            'workflow-cicd-marlin-runtime-handoff-abi-count)
                      0)
        (check-equal? (.ref presentation 'workflow-cicd-pipeline-run-count)
                      0)
        (check-equal? (.ref presentation 'workflow-cicd-pipeline-result-count)
                      0)
        (check-equal? (alist-value
                       'runtime-executed
                       (.ref presentation
                             'workflow-cicd-marlin-handoff-receipt-bundle))
                      #f)
        (check-equal? (.ref presentation 'loop-engine-intent-count) 1)
        (check-equal? (alist-value
                       'valid?
                       (car (.ref presentation 'loop-engine-result-contracts)))
                      #t)
        (check-equal? (car (.ref presentation 'loop-engine-agent-profiles))
                      (alist-value
                       'agent-profiles
                       (car (.ref presentation 'loop-engine-intents))))
        (check-equal? (car (.ref presentation
                                  'loop-engine-delegated-operations))
                      (alist-value
                       'delegated-operation
                       (car (.ref presentation 'loop-engine-intents))))
        (check-equal? (alist-value
                       'runtime-handoff
                       (car (.ref presentation 'cicd-intents)))
                      'runtime-command-manifest)
        (check-equal? (map (lambda (step) (alist-value 'stage step))
                           (.ref presentation 'presentation-trace))
                      user-interface-presentation-trace-stages)
        (check-equal? (alist-value 'declaration-index
                                   (car (.ref presentation 'feature-facts)))
                      0)
        (check-equal? (alist-value 'key
                                   (car (.ref presentation 'feature-facts)))
                      '(core . poo-clos))
        (check-equal? (not
                       (not
                        (member "poo-flow-profile"
                                (.ref presentation 'user-entrypoints))))
                      #t)
        (check-equal? (.ref presentation 'brand-name) poo-flow-brand-name)
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f))))

;;; Doctor presentation verifies that valid profiles expose diagnostics and
;;; projection rows without descriptor realization.
;; : (-> Unit TestSuite)
(def (user-interface-profile-doctor-case-test)
  (test-case "doctors valid profile before realization"
      (let* ((doctor-report
              (pooFlowUserProfileDoctor test-poo-flow-user-profile))
             (presentation
              (pooFlowUserProfileDoctorPresentation test-poo-flow-user-profile)))
        (check-equal? (.ref doctor-report 'kind)
                      poo-flow-user-profile-doctor-report-kind)
        (check-equal? (poo-flow-user-profile-doctor-ok? doctor-report) #t)
        (check-equal? (.ref doctor-report 'profile-diagnostics) '())
        (check-equal? (.ref presentation 'kind)
                      poo-flow-user-profile-doctor-presentation-kind)
        (check-equal? (.ref presentation 'doctor-status) 'ok)
        (check-equal? (.ref presentation 'diagnostic-count) 0)
        (check-equal? (.ref presentation 'module-count) 8)
        (check-equal? (.ref presentation 'feature-count) 8)
        (check-equal? (.ref presentation 'session-core-intent-count) 1)
        (check-equal? (.ref presentation 'cicd-intent-count) 1)
        (check-equal? (.ref presentation
                            'workflow-cicd-runtime-command-manifest-agreement-valid?)
                      #t)
        (check-equal? (.ref presentation
                            'workflow-cicd-marlin-runtime-handoff-abi-count)
                      0)
        (check-equal? (.ref presentation 'workflow-cicd-pipeline-run-count)
                      0)
        (check-equal? (.ref presentation 'workflow-cicd-pipeline-result-count)
                      0)
        (check-equal? (.ref presentation 'loop-engine-intent-count) 1)
        (check-equal? (alist-value
                       'valid?
                       (car (.ref presentation 'loop-engine-result-contracts)))
                      #t)
        (check-equal? (car (.ref presentation 'loop-engine-agent-harnesses))
                      (alist-value
                       'agent-harnesses
                       (car (.ref presentation 'loop-engine-intents))))
        (check-equal? (car (.ref presentation
                                  'loop-engine-delegated-operations))
                      (alist-value
                       'delegated-operation
                       (car (.ref presentation 'loop-engine-intents))))
        (check-equal? (alist-value
                       'runtime-owner
                       (car (.ref presentation 'cicd-intents)))
                      "marlin-agent-core")
        (check-equal? (alist-value
                       'stage
                       (user-interface-presentation-trace-stage
                        (.ref presentation 'presentation-trace)
                        'cicd-intents))
                      'cicd-intents)
        (check-equal? (alist-value
                       'stage
                       (user-interface-presentation-trace-stage
                        (.ref presentation 'presentation-trace)
                        'loop-engine-intents))
                      'loop-engine-intents)
        (check-equal? (alist-value 'declaration-index
                                   (car (.ref presentation 'feature-facts)))
                      0)
        (check-equal? (.ref presentation 'package-management?) #f)
        (check-equal? (not
                       (not
                        (member "pooFlowUserProfileDoctorPresentation"
                                (.ref presentation 'api-entrypoints))))
                      #t)
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f))))

;;; Broken-profile doctor output is the regression guard for declaration
;;; mistakes remaining visible as data instead of failing during presentation.
;; : (-> Unit TestSuite)
(def (user-interface-broken-profile-doctor-case-test)
  (test-case "reports profile declaration mistakes like doctor output"
      (let* ((presentation
              (pooFlowUserProfileDoctorPresentation test-poo-flow-user-broken-profile))
             (diagnostics (.ref presentation 'profile-diagnostics)))
        (check-equal? (.ref presentation 'doctor-status) 'error)
        (check-equal? (.ref presentation 'doctor-ok) #f)
        (check-equal? (.ref presentation 'diagnostic-count) 3)
        (check-equal? (diagnostic-code-member?
                       'duplicate-module-selection
                       diagnostics)
                      #t)
        (check-equal? (diagnostic-code-member?
                       'inactive-module-bundle
                       diagnostics)
                      #t)
        (check-equal? (diagnostic-code-member?
                       'missing-setting-key
                       diagnostics)
                      #t)
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f))))

;; : (-> Unit TestSuite)
;;; This suite keeps presentation output aligned with the declarative user
;;; interface contract while each case remains a separately inspectable owner.
(def user-interface-presentation-test
  (test-suite "poo-flow user interface presentation"
    (user-interface-config-presentation-test)
    (user-interface-profile-presentation-case-test)
    (user-interface-profile-doctor-case-test)
    (user-interface-broken-profile-doctor-case-test)))
