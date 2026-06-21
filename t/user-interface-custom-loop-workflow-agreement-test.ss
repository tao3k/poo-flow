;;; -*- Gerbil -*-
;;; Boundary: focused tests for loop-engine to Funflow workflow agreement.
;;; Invariant: workflow agreement is report-only and never executes a pipeline.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/facade
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-funflow-cicd-case
                 poo-flow-custom-my-module-loop-engine-case))

(export user-interface-custom-loop-workflow-agreement-test)

;;; Local lookup keeps the assertions on public receipt rows instead of pulling
;;; in private loop-engine or Funflow constructors.
;; : (-> Alist Symbol MaybeValue)
(def (test-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;;; Diagnostics are asserted by field values so tests stay insensitive to
;;; future diagnostic metadata while still checking the visible error code.
;; : (-> [Alist] Symbol [Value])
(def (test-field-values rows key)
  (map (lambda (row) (test-ref row key)) rows))

;;; Module bundles are passed through the same config presentation path used by
;;; real user profiles, preserving declaration order and selected check maps.
;; : (-> [[PooUserModuleSelection]] POOObject)
(def (custom-workflow-presentation module-bundles)
  (pooFlowUserConfigPresentation
   (pooFlowUserConfig
    (poo-flow-user-module-bundles->modules module-bundles)
    (poo-flow-settings))))

;;; A loop-engine use-case that references `funflow-cicd` without selecting the
;;; Funflow pipeline should be visibly unbacked by Funflow config.
;; : TestCase
(def custom-loop-workflow-missing-funflow-case
  (test-case "reports missing Funflow workflow pipeline agreement"
    (let* ((presentation
            (custom-workflow-presentation
             (list poo-flow-custom-my-module-loop-engine-case)))
           (intent (car (.ref presentation 'loop-engine-intents)))
           (runtime-manifest
            (test-ref intent 'runtime-command-manifest))
           (runtime-request
            (test-ref runtime-manifest 'request))
           (runtime-snapshot
            (test-ref intent 'runtime-snapshot))
           (workflow-agreement
            (test-ref intent 'workflow-agreement)))
      (check-equal? (test-ref workflow-agreement 'workflow-ref)
                    'funflow-cicd)
      (check-equal? (test-ref workflow-agreement 'funflow-owned?) #t)
      (check-equal? (test-ref workflow-agreement 'valid?) #f)
      (check-equal? (test-ref workflow-agreement 'pipeline-count) 0)
      (check-equal? (test-field-values
                     (test-ref workflow-agreement 'diagnostics)
                     'code)
                    '(missing-funflow-workflow-pipeline))
      (check-equal? (test-ref runtime-request 'workflow-agreement)
                    workflow-agreement)
      (check-equal? (test-ref (test-ref intent 'runtime-handoff-facts)
                              'workflow-agreement)
                    workflow-agreement)
      (check-equal? (test-ref (test-ref runtime-snapshot 'metadata)
                              'workflow-agreement)
                    workflow-agreement)
      (check-equal? (car (.ref presentation
                                'loop-engine-workflow-agreements))
                    workflow-agreement)
      (check-equal? (test-ref intent 'runtime-executed) #f))))

;;; Selecting the Funflow CI/CD pipeline gives the loop-engine workflow ref a
;;; concrete pipeline/check-map owner without executing that pipeline.
;; : TestCase
(def custom-loop-workflow-funflow-backed-case
  (test-case "backs loop-engine workflow ref with Funflow pipeline config"
    (let* ((presentation
            (custom-workflow-presentation
             (list poo-flow-custom-my-module-funflow-cicd-case
                   poo-flow-custom-my-module-loop-engine-case)))
           (intent (car (.ref presentation 'loop-engine-intents)))
           (runtime-manifest
            (test-ref intent 'runtime-command-manifest))
           (runtime-request
            (test-ref runtime-manifest 'request))
           (workflow-agreement
            (test-ref intent 'workflow-agreement)))
      (check-equal? (.ref presentation 'workflow-cicd-pipeline-count) 1)
      (check-equal? (test-ref workflow-agreement 'workflow-ref)
                    'funflow-cicd)
      (check-equal? (test-ref workflow-agreement 'funflow-owned?) #t)
      (check-equal? (test-ref workflow-agreement 'valid?) #t)
      (check-equal? (test-ref workflow-agreement 'pipeline-count) 1)
      (check-equal? (test-ref workflow-agreement 'pipeline-names)
                    '(default))
      (check-equal? (test-ref workflow-agreement 'diagnostics) '())
      (check-equal? (test-ref runtime-request 'workflow-agreement)
                    workflow-agreement)
      (check-equal? (car (.ref presentation
                                'loop-engine-workflow-agreements))
                    workflow-agreement)
      (check-equal? (test-ref intent 'runtime-executed) #f))))

;; : TestSuite
(def user-interface-custom-loop-workflow-agreement-test
  (test-suite "poo-flow custom user-interface loop workflow agreement"
    custom-loop-workflow-missing-funflow-case
    custom-loop-workflow-funflow-backed-case))

(run-tests! user-interface-custom-loop-workflow-agreement-test)
