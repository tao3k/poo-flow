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
        :poo-flow/src/modules/module-system
        :poo-flow/t/user-interface-fixtures)

(export user-interface-presentation-test)

;; : (-> Unit TestSuite)
;;; This suite keeps presentation output aligned with the declarative user
;;; interface contract.
(def user-interface-presentation-test
  (test-suite "poo-flow user interface presentation"
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
        (check-equal? (alist-value 'runtime-executed loop-engine-intent) #f)
        (check-equal? (map (lambda (step) (alist-value 'stage step))
                           trace)
                      '(selected-modules feature-facts cicd-intents
                        loop-engine-intents settings))
        (check-equal? (map (lambda (step) (alist-value 'runtime-executed step))
                           trace)
                      '(#f #f #f #f #f))
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
        (check-equal? (.ref presentation 'runtime-executed) #f)))
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
        (check-equal? (.ref presentation 'cicd-intent-count) 1)
        (check-equal? (.ref presentation 'loop-engine-intent-count) 1)
        (check-equal? (alist-value
                       'runtime-handoff
                       (car (.ref presentation 'cicd-intents)))
                      'runtime-command-manifest)
        (check-equal? (map (lambda (step) (alist-value 'stage step))
                           (.ref presentation 'presentation-trace))
                      '(selected-modules feature-facts cicd-intents
                        loop-engine-intents settings))
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
        (check-equal? (.ref presentation 'runtime-executed) #f)))
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
        (check-equal? (.ref presentation 'loop-engine-intent-count) 1)
        (check-equal? (alist-value
                       'runtime-owner
                       (car (.ref presentation 'cicd-intents)))
                      "marlin-agent-core")
        (check-equal? (alist-value
                       'stage
                       (caddr (.ref presentation 'presentation-trace)))
                      'cicd-intents)
        (check-equal? (alist-value
                       'stage
                       (cadddr (.ref presentation 'presentation-trace)))
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
        (check-equal? (.ref presentation 'runtime-executed) #f)))
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
        (check-equal? (.ref presentation 'runtime-executed) #f)))))

(run-tests! user-interface-presentation-test)
