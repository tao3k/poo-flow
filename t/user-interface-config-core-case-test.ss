;;; -*- Gerbil -*-
;;; Boundary: core cases exercise the thin declarative user-interface surface.
;;; These checks intentionally stop before sandbox realization or runtime work.

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
        "user-interface-fixtures.ss"
        (only-in :poo-flow/user-interface/init
                 poo-flow-user-module-bundles)
        :poo-flow/src/module-system/facade)

(export user-interface-config-core-case-test)

;; : (-> Unit PooUserProfile)
(def root-poo-flow-user-profile
  (pooFlowRootProfile poo-flow-user-module-bundles))

;; : (-> Unit PooUserConfig)
(def root-poo-flow-user-config
  (pooFlowUserConfigFromProfile root-poo-flow-user-profile))

;; : (-> Unit [Pair])
(def expected-poo-flow-core-module-keys
  '((flow . funflow)
    (loop . governor)
    (sandbox . nono-sandbox)
    (sandbox . cubeSandbox)
    (sandbox . docker-sandbox)
    (flow . loop-engine)))

;; : (-> Unit [Pair])
(def expected-poo-flow-root-module-keys
  (append expected-poo-flow-core-module-keys
          '((custom . my-module))))

;; : (-> [PooUserModuleSelection] Pair MaybePooUserModuleSelection)
(def (module-selection-by-key modules key)
  (cond
   ((null? modules) #f)
   ((equal? (poo-flow-user-module-selection-key (car modules)) key)
    (car modules))
   (else
    (module-selection-by-key (cdr modules) key))))

;; : (-> [Alist] Pair MaybeAlist)
(def (feature-fact-by-key facts key)
  (cond
   ((null? facts) #f)
   ((equal? (alist-value 'key (car facts)) key)
    (car facts))
   (else
    (feature-fact-by-key (cdr facts) key))))

;; : (-> Unit TestSuite)
;;; This suite guards the core user config case as the minimal declarative
;;; surface exposed to downstream users.
(def user-interface-config-core-case-test
  (test-suite "poo-flow user interface core config"
    (test-case "keeps user practice config thin and inspectable"
      (check-equal? (poo-flow-user-profile? test-poo-flow-user-profile) #t)
      (check-equal? (poo-flow-user-profile-name test-poo-flow-user-profile)
                    'developer)
      (check-equal? (length (poo-flow-user-profile-module-bundles
                             test-poo-flow-user-profile))
                    6)
      (check-equal? (poo-flow-user-config? test-poo-flow-user-config) #t)
      (check-equal? (poo-flow-user-config-module-keys test-poo-flow-user-config)
                    expected-poo-flow-core-module-keys))
    (test-case "builds profile module bundles and conditional gates"
      (check-equal? (length test-poo-flow-user-modules) 6)
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
    (test-case "validates use-module declarations before projection"
      (let* ((valid-selections (use-module nono-sandbox +nono +doctor))
             (valid-validation
              (poo-flow-use-module-contract-validation
               'nono-sandbox
               valid-selections))
             (invalid-selection
              (poo-flow-user-module-selection 'custom 'workflow '())))
        (check-equal? (alist-value 'valid valid-validation) #t)
        (check-equal? (alist-value 'module valid-validation) 'nono-sandbox)
        (check-equal? (alist-value 'selection-count valid-validation) 1)
        (check-equal? (poo-flow-require-use-module-contract!
                       'nono-sandbox
                       valid-selections)
                      valid-selections)
        (check-equal?
         (poo-flow-use-module-contract-validation-valid?
          (poo-flow-use-module-contract-validation
           'workflow
           (list invalid-selection)))
         #f)
        (check-equal?
         (with-catch
          (lambda (_) #t)
          (lambda ()
            (use-module workflow)
            #f))
         #t)
        (check-equal?
         (with-catch
          (lambda (_) #t)
          (lambda ()
            (poo-flow-require-use-module-contract!
             'nono-sandbox
             '(not-a-selection))
            #f))
         #t)))
    (test-case "loads custom module bundles through init-style declarations"
      (let* ((custom-config
              (pooFlowUserConfigFromProfile test-poo-flow-user-custom-profile))
             (custom-modules
              (poo-flow-user-config-modules custom-config))
             (custom-module
              (module-selection-by-key custom-modules
                                       '(custom . my-module)))
             (custom-facts
              (poo-flow-user-config-feature-facts custom-config))
             (custom-fact
              (feature-fact-by-key custom-facts
                                   '(custom . my-module)))
             (custom-source
              (poo-flow-user-module-selection-source-ref custom-module)))
        (check-equal? (length custom-modules) 6)
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
                      5)
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
              (module-selection-by-key root-modules
                                       '(flow . funflow)))
             (root-custom-module
              (module-selection-by-key root-modules
                                       '(custom . my-module))))
        (check-equal? (poo-flow-user-profile? root-poo-flow-user-profile) #t)
        (check-equal? (poo-flow-user-profile-name root-poo-flow-user-profile)
                      'users)
        (check-equal? (poo-flow-user-profile-doctor-ok?
                       (pooFlowUserProfileDoctor root-poo-flow-user-profile))
                      #t)
        (check-equal? (length (poo-flow-user-profile-module-bundles
                               root-poo-flow-user-profile))
                      7)
        (check-equal? (length poo-flow-user-module-bundles) 5)
        (check-equal? (length root-modules) 7)
        (check-equal? (poo-flow-user-config-module-keys root-poo-flow-user-config)
                      expected-poo-flow-root-module-keys)
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
