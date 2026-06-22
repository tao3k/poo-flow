;;; -*- Gerbil -*-
;;; Boundary: tests verify user-interface presentation receipts.
;;; Invariant: presentations stay report-only and never realize descriptors.

(import (only-in :std/test
                 check
                 check-eq?
                 check-equal?
                 check-false
                 check-not-equal?
                 check-output
                 check-true
                 run-tests!
                 test-case
                 test-error
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/facade
        :poo-flow/src/module-system/profile-config
        :poo-flow/t/user-interface-fixtures)

(export user-interface-presentation-test)

;;; Trace stage order is the presentation contract for downstream tooling; the
;;; cases assert order without duplicating the projection implementation.
;; : [Symbol]
(def user-interface-presentation-trace-stages
  '(selected-modules
    feature-facts
    sandbox-profile-derivations
    cicd-intents
    workflow-cicd-pipelines
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

;;; Invalid loop-engine result contracts exercise the profile doctor path,
;;; not the shared valid fixtures used by broad presentation checks.
;; : [PooUserModuleSelection]
(def user-interface-invalid-loop-result-module
  (use-module loop-engine
    :config
    (.def (invalid-loop-result @ loop-engine-use-case name workflow)
      name: 'invalid-loop-result
      workflow: 'funflow-cicd)

    (.def (invalid-loop-result-human-audit @ loop-engine-human-audit
                                           actions)
      actions: '(+manual-gate))

    (.def (invalid-loop-result-contract @ loop-engine-result
                                        human-audit format required-fields)
      human-audit: 'bad-contract
      format: 'structured-alist
      required-fields: '())

    (.def (invalid-loop-result-runtime @ loop-engine-runtime capabilities)
      capabilities: '(+manifest-handoff))

    (.def (invalid-loop-result-profile @ loop-engine-profile
                                       use-case human-audit result runtime)
      use-case: invalid-loop-result
      human-audit: invalid-loop-result-human-audit
      result: invalid-loop-result-contract
      runtime: invalid-loop-result-runtime)))

;; : PooUserProfile
(def user-interface-invalid-loop-result-profile
  (pooFlowUserProfile
   'invalid-loop-result
   (list user-interface-invalid-loop-result-module)
   (pooFlowDefaultUserSettings 'invalid-loop-result)
   poo-flow-default-user-setting-keys))

;;; Invalid sandbox profile is resolvable but not handoff-ready: it declares a
;;; filesystem capability without a filesystem resource boundary.
;; : ResourcePolicy
(def user-interface-invalid-sandbox-resource-policy
  '((cpu . 2)
    (memory . "4Gi")
    (timeout-ms . 300000)))

;; : Metadata
(def user-interface-invalid-sandbox-metadata
  '((intent . invalid-sandbox-profile)
    (scope . test)))

;; : [PooUserModuleSelection]
(def user-interface-invalid-sandbox-profile-module
  (use-module nono-sandbox
    (.def (ci/build @ nono-sandbox-profile
                    network capabilities resources metadata)
      network: (deny-network)
      capabilities: '(filesystem-read process-run)
      resources: user-interface-invalid-sandbox-resource-policy
      metadata: => (lambda (super-metadata)
                     (append super-metadata
                             user-interface-invalid-sandbox-metadata)))))

;; : [PooUserModuleSelection]
(def user-interface-invalid-sandbox-loop-module
  (use-module loop-engine
    :config
    (.def (invalid-sandbox-loop @ loop-engine-use-case name workflow)
      name: 'invalid-sandbox-loop
      workflow: 'funflow-cicd)

    (.def (invalid-sandbox-loop-sandbox @ loop-engine-sandbox profile)
      profile: 'ci/build)

    (.def (invalid-sandbox-loop-runtime @ loop-engine-runtime capabilities)
      capabilities: '(+manifest-handoff))

    (.def (invalid-sandbox-loop-profile @ loop-engine-profile
                                        use-case sandbox runtime)
      use-case: invalid-sandbox-loop
      sandbox: invalid-sandbox-loop-sandbox
      runtime: invalid-sandbox-loop-runtime)))

;; : PooUserProfile
(def user-interface-invalid-sandbox-profile
  (pooFlowUserProfile
   'invalid-sandbox
   (list user-interface-invalid-sandbox-profile-module
         user-interface-invalid-sandbox-loop-module)
   (pooFlowDefaultUserSettings 'invalid-sandbox)
   poo-flow-default-user-setting-keys))

;;; Config presentation is the broadest receipt surface, covering module
;;; switches, CI/CD handoff rows, loop-engine rows, and ownership boundaries.
;; : (-> Unit TestSuite)
(def user-interface-config-presentation-test
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
        (check-equal? (.ref presentation 'module-count) 6)
        (check-equal? (.ref presentation 'module-keys)
                      '((flow . funflow)
                        (loop . governor)
                        (sandbox . nono-sandbox)
                        (sandbox . cubeSandbox)
                        (sandbox . docker-sandbox)
                        (flow . loop-engine)))
        (check-equal? (.ref presentation 'feature-count) 6)
        (check-equal? (.ref presentation 'sandbox-profile-derivation-count)
                      0)
        (check-equal? (.ref presentation 'sandbox-profile-derivations)
                      '())
        (check-equal? (alist-value 'declaration-index
                                   (car feature-facts))
                      0)
        (check-equal? (alist-value 'declaration-phase
                                   (car feature-facts))
                      'init-selection)
        (check-equal? (alist-value 'key (car feature-facts))
                      '(flow . funflow))
        (check-equal? (alist-value 'dependency-installation?
                                   (car feature-facts))
                      #f)
        (check-equal? (alist-value 'descriptor-realized?
                                   (car feature-facts))
                      #f)
        (check-equal? (.ref presentation 'setting-count) 7)
        (check-equal? (alist-value 'flags (car modules))
                      '(+functional +dag +typed-receipts
                        +runtime-manifest
                        (+cicd
                         (checks +parallel +typed-receipts)
                         (artifacts +export)
                         (release +manual-gate)
                         (webhook +server)
                         (runtime +manifest-handoff))))
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
                      '(#f #f #f #f #f #f #f #f #f #f #f #f #f #f #f #f))
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
(def user-interface-profile-presentation-case-test
  (test-case "presents profile without descriptor realization"
      (let* ((presentation
              (pooFlowUserProfilePresentation test-poo-flow-user-profile)))
        (check-equal? (.ref presentation 'kind)
                      poo-flow-user-profile-presentation-kind)
        (check-equal? (.ref presentation 'profile-name) 'developer)
        (check-equal? (.ref presentation 'module-bundle-count) 6)
        (check-equal? (.ref presentation 'module-count) 6)
        (check-equal? (.ref presentation 'config-presentation-kind)
                      poo-flow-user-config-presentation-kind)
        (check-equal? (.ref presentation 'config-module-count) 6)
        (check-equal? (.ref presentation 'feature-count) 6)
        (check-equal? (.ref presentation 'sandbox-profile-derivation-count)
                      0)
        (check-equal? (.ref presentation 'sandbox-profile-derivations)
                      '())
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
                      '(flow . funflow))
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
(def user-interface-profile-doctor-case-test
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
        (check-equal? (.ref presentation 'module-count) 6)
        (check-equal? (.ref presentation 'feature-count) 6)
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

;;; Loop-engine result-contract diagnostics must surface through profile doctor,
;;; otherwise invalid structured result expectations remain buried in manifests.
;; : (-> Unit TestSuite)
(def user-interface-invalid-loop-result-doctor-case-test
  (test-case "doctors invalid loop-engine result contracts"
      (let* ((doctor-report
              (pooFlowUserProfileDoctor
               user-interface-invalid-loop-result-profile))
             (presentation
              (pooFlowUserProfileDoctorPresentation
               user-interface-invalid-loop-result-profile))
             (diagnostics (.ref presentation 'profile-diagnostics))
             (result-contract
              (car (.ref presentation 'loop-engine-result-contracts))))
        (check-equal? (.ref doctor-report 'doctor-status) 'error)
        (check-equal? (.ref doctor-report 'doctor-ok) #f)
        (check-equal? (.ref doctor-report 'diagnostic-count) 1)
        (check-equal? (.ref presentation 'doctor-status) 'error)
        (check-equal? (.ref presentation 'diagnostic-count) 1)
        (check-equal? (diagnostic-code-member?
                       'invalid-loop-engine-result-contract
                       diagnostics)
                      #t)
        (check-equal? (alist-value 'valid? result-contract) #f)
        (check-equal? (alist-value 'diagnostic-count result-contract) 1)
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f))))

;;; Invalid sandbox profiles should be caught by profile doctor through the
;;; loop-engine sandbox handoff agreement, not by throwing during presentation.
;; : (-> Unit TestSuite)
(def user-interface-invalid-sandbox-profile-doctor-case-test
  (test-case "doctors invalid loop-engine sandbox profile agreements"
      (let* ((doctor-report
              (pooFlowUserProfileDoctor
               user-interface-invalid-sandbox-profile))
             (presentation
              (pooFlowUserProfileDoctorPresentation
               user-interface-invalid-sandbox-profile))
             (diagnostics (.ref presentation 'profile-diagnostics))
             (sandbox-agreement
              (car (.ref presentation
                         'loop-engine-sandbox-handoff-agreements))))
        (check-equal? (.ref doctor-report 'doctor-status) 'error)
        (check-equal? (.ref doctor-report 'doctor-ok) #f)
        (check-equal? (.ref doctor-report 'diagnostic-count) 1)
        (check-equal? (.ref presentation 'doctor-status) 'error)
        (check-equal? (.ref presentation 'diagnostic-count) 1)
        (check-equal? (diagnostic-code-member?
                       'invalid-loop-engine-sandbox-handoff
                       diagnostics)
                      #t)
        (check-equal? (alist-value 'valid? sandbox-agreement) #f)
        (check-equal? (alist-value 'invalid-runtime-summary-count
                                   sandbox-agreement)
                      1)
        (check-equal? (map (lambda (row) (alist-value 'code row))
                           (alist-value 'diagnostics sandbox-agreement))
                      '(invalid-sandbox-runtime-summaries))
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f))))

;;; Broken-profile doctor output is the regression guard for declaration
;;; mistakes remaining visible as data instead of failing during presentation.
;; : (-> Unit TestSuite)
(def user-interface-broken-profile-doctor-case-test
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
    user-interface-config-presentation-test
    user-interface-profile-presentation-case-test
    user-interface-profile-doctor-case-test
    user-interface-invalid-loop-result-doctor-case-test
    user-interface-invalid-sandbox-profile-doctor-case-test
    user-interface-broken-profile-doctor-case-test))

(run-tests! user-interface-presentation-test)
