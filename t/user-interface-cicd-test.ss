;;; -*- Gerbil -*-
;;; Boundary: tests verify Funflow CI/CD user intent presentation.
;;; Invariant: CI/CD facts stay declarative and never execute adapters.

(import :std/test
        (only-in :clan/poo/object .ref)
        :modules/module-system
        :user-interface-fixtures)

(export user-interface-cicd-test)

;; : (-> Unit TestSuite)
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
