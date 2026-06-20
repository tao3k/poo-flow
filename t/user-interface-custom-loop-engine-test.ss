;;; -*- Gerbil -*-
;;; Boundary: tests verify custom user-interface loop-engine declarations.
;;; Invariant: custom loop cases project intent data and never execute loops.

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
                 poo-flow-custom-my-module-loop-engine-case
                 poo-flow-custom-my-module-loops-module))

(export user-interface-custom-loop-engine-test)

;; : (-> UserInterfaceEntry Alist MaybeValue)
(def (test-ref alist key)
  (cdr (assoc key alist)))

;; : (-> [PooUserModuleSelection] POOObject)
(def (custom-loop-presentation module-bundle)
  (pooFlowUserConfigPresentation
   (pooFlowUserConfig
    (poo-flow-user-module-bundles->modules (list module-bundle))
    (poo-flow-settings))))

;; : TestSuite
(def user-interface-custom-loop-engine-test
  (test-suite "poo-flow custom user-interface loop-engine cases"
    (test-case "projects custom loop-engine profile use cases"
      (let* ((presentation
              (custom-loop-presentation
               poo-flow-custom-my-module-loops-module))
             (intent
              (car (.ref presentation 'loop-engine-intents))))
        (check-equal? (.ref presentation 'module-count) 1)
        (check-equal? (.ref presentation 'module-keys)
                      '((flow . loop-engine)))
        (check-equal? (.ref presentation 'loop-engine-intent-count) 1)
        (check-equal? (test-ref intent 'workflow-owned?) #t)
        (check-equal? (test-ref intent 'governor)
                      '(+strategy +policy +node-graph))
        (check-equal? (map car (test-ref intent 'use-cases))
                      '(repo-doctor pull-request-review release-approval))
        (check-equal? (test-ref intent 'sandbox)
                      '((repo-doctor . agent/task)
                        (pull-request-review . agent/task-cache)
                        (release-approval . ci/build)))
        (check-equal? (test-ref intent 'runtime-handoff)
                      'loop-governor-marlin-runtime-manifest)
        (check-equal? (test-ref intent 'runtime-executed) #f)))
    (test-case "projects custom concrete loop-engine case"
      (let* ((presentation
              (custom-loop-presentation
               poo-flow-custom-my-module-loop-engine-case))
             (intent
              (car (.ref presentation 'loop-engine-intents))))
        (check-equal? (.ref presentation 'module-count) 1)
        (check-equal? (test-ref intent 'use-case)
                      '(current-system-build-loop
                        (level . l2)
                        (mode . guarded-handoff)
                        (workflow . funflow-cicd)))
        (check-equal? (test-ref intent 'agent-judges)
                      '((auditor ci-audit-agent)
                        (verifier build-verifier-agent)
                        (governor ci-loop-governor)))
        (check-equal? (test-ref intent 'human-audit)
                      '(+manual-gate +changes-requested))
        (check-equal? (test-ref intent 'sandbox)
                      '((profile . ci/build)
                        (isolation . project-copy)))
        (check-equal? (test-ref intent 'runtime-executed) #f)))))

(run-tests! user-interface-custom-loop-engine-test)
