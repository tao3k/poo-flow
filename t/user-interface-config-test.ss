;;; -*- Gerbil -*-
;;; Boundary: tests verify user-interface config through stable module APIs.
;;; Invariant: root practice files stay top-level and outside test load paths.

(import :std/test
        (only-in :clan/poo/object .ref)
        "user-interface-fixtures.ss"
        (only-in :poo-flow/user-interface/init
                 poo-flow-user-module-bundles)
        :modules/module-system)

(export user-interface-config-test)

;; : (-> Unit PooUserProfile)
(def root-poo-flow-user-profile
  (pooFlowUserInterfaceProfile poo-flow-user-module-bundles))

;; : (-> Unit PooUserConfig)
(def root-poo-flow-user-config
  (pooFlowUserConfigFromProfile root-poo-flow-user-profile))

;; : (-> Unit TestSuite)
(def user-interface-config-test
  (test-suite "poo-flow user interface config"
    (test-case "keeps user practice config thin and inspectable"
      (check-equal? (poo-flow-user-profile? test-poo-flow-user-profile) #t)
      (check-equal? (poo-flow-user-profile-name test-poo-flow-user-profile)
                    'developer)
      (check-equal? (length (poo-flow-user-profile-module-bundles
                             test-poo-flow-user-profile))
                    4)
      (check-equal? (poo-flow-user-config? test-poo-flow-user-config) #t)
      (check-equal? (poo-flow-user-config-module-keys test-poo-flow-user-config)
                    '((flow . funflow)
                      (loop . governor)
                      (sandbox . nono-sandbox)
                      (sandbox . cubeSandbox))))
    (test-case "builds profile module bundles and conditional gates"
      (check-equal? (length test-poo-flow-user-modules) 4)
      (check-equal? (poo-flow-user-module-selection-key
                     (car (use-module nono-sandbox +nono +doctor)))
                    '(sandbox . nono-sandbox))
      (check-equal? (poo-flow-user-module-selection-flags
                     (car (use-module nono-sandbox +nono +doctor)))
                    '(+nono +doctor))
      (check-equal? (poo-flow-user-module-when #f
                     (sandbox cubeSandbox +doctor))
                    '())
        (check-equal? (poo-flow-user-module-selection->alist
                     (car test-poo-flow-user-modules))
                    '((group . flow)
                      (module . funflow)
                      (key flow . funflow)
                      (source-ref . #f)
                      (entrypoint . #f)
                      (flags +functional +dag +typed-receipts
                             +runtime-manifest
                             (+cicd
                              (checks +parallel +typed-receipts)
                              (artifacts +export)
                              (release +manual-gate)
                              (webhook +server)
                              (runtime +manifest-handoff)))
                      (enabled? . #t))))
    (test-case "loads custom module bundles through init-style declarations"
      (let* ((custom-config
              (pooFlowUserConfigFromProfile test-poo-flow-user-custom-profile))
             (custom-modules
              (poo-flow-user-config-modules custom-config))
             (custom-module
              (car (cddddr custom-modules)))
             (custom-facts
              (poo-flow-user-config-feature-facts custom-config))
             (custom-fact
              (car (cddddr custom-facts)))
             (custom-source
              (poo-flow-user-module-selection-source-ref custom-module)))
        (check-equal? (length custom-modules) 5)
        (check-equal? (poo-flow-user-module-selection-key custom-module)
                      '(custom . my-module))
        (check-equal? (poo-flow-user-module-selection-flags custom-module)
                      '(+private +doctor))
        (check-equal? (poo-flow-user-module-selection-entrypoint custom-module)
                      "./custom/my-module/config.ss")
        (check-equal? (poo-flow-module-source-ref-kind custom-source) 'local)
        (check-equal? (poo-flow-module-source-ref-value custom-source)
                      "./custom/my-module/config.ss")
        (check-equal? (alist-value 'entrypoint custom-fact)
                      "./custom/my-module/config.ss")
        (check-equal? (alist-value 'declaration-index custom-fact)
                      4)
        (check-equal? (alist-value 'declaration-phase custom-fact)
                      'init-selection)
        (check-equal? (alist-value 'package-management? custom-fact)
                      #f)
        (check-equal? (alist-value 'loader-executed? custom-fact)
                      #f)
        (check-equal? (poo-flow-user-profile-doctor-ok?
                       (pooFlowUserProfileDoctor test-poo-flow-user-custom-profile))
                      #t)))
    (test-case "loads root modules directory facade through top-level config"
      (let* ((root-modules
              (poo-flow-user-config-modules root-poo-flow-user-config))
             (root-flow-module
              (car root-modules))
             (root-custom-module
              (car (cddddr root-modules))))
        (check-equal? (poo-flow-user-profile? root-poo-flow-user-profile) #t)
        (check-equal? (poo-flow-user-profile-name root-poo-flow-user-profile)
                      'users)
        (check-equal? (poo-flow-user-profile-doctor-ok?
                       (pooFlowUserProfileDoctor root-poo-flow-user-profile))
                      #t)
        (check-equal? (length (poo-flow-user-profile-module-bundles
                               root-poo-flow-user-profile))
                      5)
        (check-equal? (length poo-flow-user-module-bundles) 4)
        (check-equal? (length root-modules) 5)
        (check-equal? (poo-flow-user-module-selection-flags root-flow-module)
                      '(+functional +dag +typed-receipts +runtime-manifest
                        (+cicd
                         (checks +parallel +typed-receipts)
                         (artifacts +export)
                         (release +manual-gate)
                         (webhook +server)
                         (runtime +manifest-handoff))))
        (check-equal? (poo-flow-user-module-selection-key root-custom-module)
                      '(custom . my-module))
        (check-equal? (poo-flow-user-module-selection-entrypoint root-custom-module)
                      "./custom/my-module/config.ss")))
    (test-case "loads upstream agent sandbox profile defaults"
      (let* ((presentation
              (poo-flow-default-sandbox-profile-presentation))
             (nono-profile
              (poo-flow-sandbox-profile-by-name
               poo-flow-default-sandbox-profiles
               'agent/nono))
             (cube-profile
              (poo-flow-sandbox-profile-by-name
               poo-flow-default-sandbox-profiles
               'agent/cube)))
        (check-equal? poo-flow-default-sandbox-profile-names
                      '(agent/nono agent/cube))
        (check-equal? (.ref presentation 'profile-count) 2)
        (check-equal? (poo-flow-sandbox-profile-backend-kind nono-profile)
                      'nono)
        (check-equal? (poo-flow-sandbox-profile-backend-ref cube-profile)
                      'cube-local)
        (check-equal? (poo-flow-sandbox-profile-network-policy cube-profile)
                      '(allowlisted "github.com" "crates.io"))
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f)))
    (test-case "declares sandbox and loop module flags without descriptors"
      (let ((loop-module
             (cadr (poo-flow-user-config-modules test-poo-flow-user-config)))
            (nono-module
             (caddr (poo-flow-user-config-modules test-poo-flow-user-config)))
            (cube-module
             (cadddr (poo-flow-user-config-modules test-poo-flow-user-config))))
        (check-equal? (poo-flow-user-module-selection? loop-module) #t)
        (check-equal? (poo-flow-user-module-selection-flags loop-module)
                      '(+strategy +policy +marlin-handoff +runtime-manifest
                        +l1-report))
        (check-equal? (poo-flow-user-module-selection-has-flags?
                       loop-module
                       '(+strategy +policy +marlin-handoff
                         +runtime-manifest +l1-report))
                      #t)
        (check-equal? (poo-flow-user-module-selection-has-flag?
                       nono-module
                       '+nono)
                      #t)
        (check-equal? (poo-flow-user-module-selection-has-flag?
                       cube-module
                       '+cube)
                      #t)))
    (test-case "queries selected module features without package management"
      (let* ((custom-config
              (pooFlowUserConfigFromProfile test-poo-flow-user-custom-profile)))
        (check-equal? (poo-flow-user-config-feature?
                       test-poo-flow-user-config
                       'flow
                       'funflow
                       '+functional
                       '+dag
                       '+typed-receipts
                       '+runtime-manifest)
                      #t)
        (check-equal? (poo-flow-user-config-feature?
                       test-poo-flow-user-config
                       'flow
                       'funflow
                       '+cicd)
                      #t)
        (check-equal? (poo-flow-user-config-feature?
                       root-poo-flow-user-config
                       'flow
                       'funflow
                       '+functional
                       '+dag
                       '+typed-receipts
                       '+runtime-manifest
                       '+cicd)
                      #t)
        (check-equal? (poo-flow-user-config-feature?
                       test-poo-flow-user-config
                       'loop
                       'governor
                       '+strategy
                       '+policy
                       '+marlin-handoff
                       '+runtime-manifest
                       '+l1-report)
                      #t)
        (check-equal? (poo-flow-user-config-feature?
                       test-poo-flow-user-config
                       'loop
                       'governor
                       '+missing)
                      #f)
        (check-equal? (poo-flow-user-config-feature?
                       test-poo-flow-user-config
                       'sandbox
                       'nono-sandbox
                       '+nono
                       '+doctor)
                      #t)
        (check-equal? (poo-flow-user-config-feature?
                       test-poo-flow-user-config
                       'sandbox
                       'cubeSandbox
                       '+cube
                       '+doctor)
                      #t)
        (check-equal? (poo-flow-user-config-feature?
                       custom-config
                       'custom
                       'my-module
                       '+doctor)
                      #t)))
    (test-case "keeps flow loop and sandbox settings declarative"
      (let ((settings (poo-flow-user-config-settings test-poo-flow-user-config)))
        (check-equal? (.ref settings 'surface) "poo-flow")
        (check-equal? (.ref settings 'flow-mode) 'funflow)
        (check-equal? (.ref settings 'loop-strategy) 'governed)
        (check-equal? (.ref settings 'sandbox-policy) 'module-gated)
        (check-equal? (.ref settings 'sandbox-backends)
                      '(nono cube))))
    (test-case "manages Doom-style profile sets before realization"
      (let* ((selected-profile
              (poo-flow-user-profile-set-default-profile test-poo-flow-user-profile-set))
             (presentation
              (pooFlowUserProfileSetPresentation test-poo-flow-user-profile-set)))
        (check-equal? (poo-flow-user-profile-set? test-poo-flow-user-profile-set) #t)
        (check-equal? (poo-flow-user-profile-set-name test-poo-flow-user-profile-set)
                      'workspace)
        (check-equal? (poo-flow-user-profile-set-default-profile-name
                       test-poo-flow-user-profile-set)
                      'developer)
        (check-equal? (poo-flow-user-profile-set-profile-names
                       test-poo-flow-user-profile-set)
                      '(developer custom-developer))
        (check-equal? (poo-flow-user-profile-name selected-profile) 'developer)
        (check-equal? (.ref presentation 'kind)
                      poo-flow-user-profile-set-presentation-kind)
        (check-equal? (.ref presentation 'profile-count) 2)
        (check-equal? (.ref presentation 'selected-profile-name)
                      'developer)
        (check-equal? (.ref presentation 'selected-profile?) #t)
        (check-equal? (not
                       (not
                        (member "poo-flow-profile-set"
                                (.ref presentation 'user-entrypoints))))
                      #t)
        (check-equal? (not
                       (not
                        (member "pooFlowUserProfileSetPresentation"
                                (.ref presentation 'user-entrypoints))))
                      #t)
        (check-equal? (.ref presentation 'package-management?) #f)
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f)))
    (test-case "doctors Doom-style profile sets before selection"
      (let* ((valid-report
              (pooFlowUserProfileSetDoctor test-poo-flow-user-profile-set))
             (broken-presentation
              (pooFlowUserProfileSetDoctorPresentation
               test-poo-flow-user-broken-profile-set))
             (diagnostics (.ref broken-presentation 'profile-diagnostics)))
        (check-equal? (poo-flow-user-profile-set-doctor-ok? valid-report) #t)
        (check-equal? (.ref valid-report 'diagnostic-count) 0)
        (check-equal? (.ref broken-presentation 'doctor-status) 'error)
        (check-equal? (.ref broken-presentation 'doctor-ok) #f)
        (check-equal? (.ref broken-presentation 'diagnostic-count) 2)
        (check-equal? (diagnostic-code-member?
                       'duplicate-profile-name
                       diagnostics)
                      #t)
        (check-equal? (diagnostic-code-member?
                       'missing-default-profile
                       diagnostics)
                      #t)
        (check-equal? (.ref broken-presentation 'selected-profile?) #f)
        (check-equal? (.ref broken-presentation 'package-management?) #f)
        (check-equal? (.ref broken-presentation 'runtime-executed) #f)))))

(run-tests! user-interface-config-test)
