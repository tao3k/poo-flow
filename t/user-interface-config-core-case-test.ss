;;; -*- Gerbil -*-
;;; Boundary: core cases exercise the thin declarative user-interface surface.
;;; These checks intentionally stop before sandbox realization or runtime work.

(import :std/test
        (only-in :clan/poo/object .ref)
        "user-interface-fixtures.ss"
        (only-in :poo-flow/user-interface/init
                 poo-flow-user-module-bundles)
        :modules/module-system)

(export user-interface-config-core-case-test)

;; : (-> Unit PooUserProfile)
(def root-poo-flow-user-profile
  (pooFlowUserInterfaceProfile poo-flow-user-module-bundles))

;; : (-> Unit PooUserConfig)
(def root-poo-flow-user-config
  (pooFlowUserConfigFromProfile root-poo-flow-user-profile))

;; : (-> Unit TestSuite)
(def user-interface-config-core-case-test
  (test-suite "poo-flow user interface core config"
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
                      "./custom/my-module/config.ss")))))
