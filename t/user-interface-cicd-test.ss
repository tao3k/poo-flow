;;; -*- Gerbil -*-
;;; Boundary: tests verify Funflow CI/CD user intent presentation.
;;; Invariant: CI/CD facts stay declarative and never execute adapters.

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
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-cicd-case)
        :poo-flow/t/user-interface-fixtures)

(export user-interface-cicd-test)

;; : (-> Unit TestSuite)
;;; This suite keeps CI/CD user-interface assembly separate from runtime
;;; execution.
(def user-interface-cicd-test
  (test-suite "poo-flow user interface cicd payload"
    (test-case "presents Funflow CI/CD payload as user intent data"
      (let* ((intents
              (poo-flow-user-config-cicd-intents test-poo-flow-user-config))
             (intent (car intents)))
        (check-equal? (length intents) 1)
        (check-equal? (alist-value 'key intent) '(flow . funflow))
        (check-equal? (alist-value 'feature intent) '+cicd)
        (check-equal? (alist-value 'checks intent)
                      '(+parallel +typed-receipts))
        (check-equal? (alist-value 'artifacts intent) '(+export))
        (check-equal? (alist-value 'release intent) '(+manual-gate))
        (check-equal? (alist-value 'webhook intent) '(+server))
        (check-equal? (alist-value 'runtime intent) '(+manifest-handoff))
        (check-equal? (alist-value 'runtime-handoff intent)
                      'runtime-command-manifest)
        (check-equal? (alist-value 'runtime-owner intent)
                      "marlin-agent-core")
        (check-equal? (alist-value 'runtime-executed intent) #f)))
    (test-case "loads downstream CI/CD case through load! and use-module"
      (let* ((selection (car poo-flow-custom-my-module-cicd-case))
             (inherits
              (poo-flow-user-module-selection-flag-entry selection ':inherits))
             (command
              (poo-flow-user-module-selection-flag-entry selection ':command))
             (nono
              (poo-flow-user-module-selection-flag-entry selection ':nono)))
        (check-equal? (poo-flow-user-module-selection-key selection)
                      '(sandbox . nono-sandbox))
        (check-equal? inherits '(:inherits . ci/build))
        (check-equal? command
                      '(:command
                        (program . "gxpkg")
                        (args . ("build"))))
        (check-equal? nono
                      '(:nono
                        (network . blocked)
                        (audit . disabled)))))
    (test-case "traces CI/CD presentation projection without runtime work"
      (let* ((presentation
              (pooFlowUserConfigPresentation
               test-poo-flow-user-config
               '(surface profile flow-mode loop-strategy
                 sandbox-policy sandbox-backends mode-lock)))
             (trace (.ref presentation 'presentation-trace))
             (cicd-step (caddr trace)))
        (check-equal? (.ref presentation 'cicd-intent-count) 1)
        (check-equal? (alist-value 'stage cicd-step) 'cicd-intents)
        (check-equal? (alist-value 'count cicd-step) 1)
        (check-equal? (alist-value 'descriptor-realized? cicd-step) #f)
        (check-equal? (alist-value 'runtime-executed cicd-step) #f)))))

(run-tests! user-interface-cicd-test)
