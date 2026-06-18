;;; -*- Gerbil -*-
;;; Boundary: tests verify user-interface practice through stable module APIs.
;;; Invariant: root practice files stay top-level and outside test load paths.

(import :std/test
        (only-in :clan/poo/object .ref)
        :modules/module-system)

(export user-interface-config-test)

;; [PooUserModuleSelection] <- Unit
(def test-poo-user-modules
  (list (poo-user-module-selection 'flow 'workflow '(+typed-receipts))
        (poo-user-module-selection 'loop 'governor '(+strategy +policy))
        (poo-user-module-selection 'sandbox 'marlin '(+nono +cube +doctor))))

;; POOObject <- Unit
(def test-poo-user-settings
  (poo-settings
   surface: "poo-flow"
   profile: "developer"
   flow-mode: 'workflow
   loop-strategy: 'governed
   sandbox-policy: 'module-gated
   sandbox-backends: '(nono cube marlin)
   mode-lock: "stable"))

;; PooUserConfig <- Unit
(def test-poo-user-config
  (pooUserConfig
   test-poo-user-modules
   test-poo-user-settings))

;; TestSuite <- Unit
(def user-interface-config-test
  (test-suite "poo user interface config"
    (test-case "keeps user practice config thin and inspectable"
      (check-equal? (poo-user-config? test-poo-user-config) #t)
      (check-equal? (poo-user-config-module-keys test-poo-user-config)
                    '((flow . workflow)
                      (loop . governor)
                      (sandbox . marlin))))
    (test-case "declares sandbox and loop module flags without descriptors"
      (let ((loop-module
             (cadr (poo-user-config-modules test-poo-user-config)))
            (sandbox-module
             (caddr (poo-user-config-modules test-poo-user-config))))
        (check-equal? (poo-user-module-selection? loop-module) #t)
        (check-equal? (poo-user-module-selection-flags loop-module)
                      '(+strategy +policy))
        (check-equal? (poo-user-module-selection-has-flag?
                       sandbox-module
                       '+cube)
                      #t)))
    (test-case "keeps flow loop and sandbox settings declarative"
      (let ((settings (poo-user-config-settings test-poo-user-config)))
        (check-equal? (.ref settings 'surface) "poo-flow")
        (check-equal? (.ref settings 'flow-mode) 'workflow)
        (check-equal? (.ref settings 'loop-strategy) 'governed)
        (check-equal? (.ref settings 'sandbox-policy) 'module-gated)
        (check-equal? (.ref settings 'sandbox-backends)
                      '(nono cube marlin))))))

(run-tests! user-interface-config-test)
