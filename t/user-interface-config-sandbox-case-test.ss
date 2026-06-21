;;; -*- Gerbil -*-
;;; Boundary: sandbox cases prove declarations stay data-only before realization.
;;; Backend descriptors are inspected as upstream module facts, not executed here.

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
        :poo-flow/src/module-system/facade)

(export user-interface-config-sandbox-case-test)

;; : (-> Unit TestSuite)
;;; This suite protects sandbox configuration cases as declarative user-facing
;;; data rather than backend implementation code.
(def user-interface-config-sandbox-case-test
  (test-suite "poo-flow user interface sandbox config"
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
               'agent/cube))
             (docker-profile
              (poo-flow-sandbox-profile-by-name
               poo-flow-default-sandbox-profiles
               'agent/docker)))
        (check-equal? poo-flow-default-sandbox-profile-names
                      '(agent/nono agent/cube agent/docker))
        (check-equal? (.ref presentation 'profile-count) 3)
        (check-equal? (poo-flow-sandbox-profile-backend-kind nono-profile)
                      'nono)
        (check-equal? (poo-flow-sandbox-profile-resource-policy nono-profile)
                      '((filesystem . scoped)
                        (cpu . 2)
                        (memory . "4Gi")
                        (timeout-ms . 300000)))
        (check-equal? (poo-flow-sandbox-profile-backend-ref cube-profile)
                      'cube-local)
        (check-equal? (poo-flow-sandbox-profile-network-policy cube-profile)
                      '(allowlisted "github.com" "crates.io"))
        (check-equal? (poo-flow-sandbox-profile-backend-kind docker-profile)
                      'docker)
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f)))
    (test-case "declares sandbox and loop module flags without descriptors"
      (let ((loop-module
             (cadr (poo-flow-user-config-modules test-poo-flow-user-config)))
            (nono-module
             (caddr (poo-flow-user-config-modules test-poo-flow-user-config)))
            (cube-module
             (cadddr (poo-flow-user-config-modules test-poo-flow-user-config)))
            (docker-module
             (car (cddddr
                   (poo-flow-user-config-modules test-poo-flow-user-config)))))
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
                      #t)
        (check-equal? (poo-flow-user-module-selection-has-flag?
                       docker-module
                       '+docker)
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
                       test-poo-flow-user-config
                       'sandbox
                       'docker-sandbox
                       '+docker
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
                      '(nono cube docker))))))
