;;; -*- Gerbil -*-
;;; Boundary: custom user-interface session-selector scenario.
;;; Invariant: selectors are pending routing receipts; Marlin owns scoring,
;;; dispatch, and selected result materialization.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/module-system/init-syntax)

(export user-interface-custom-session-selector-test)

(load! "../user-interface/custom/my-module/cases/session-selector")

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def user-interface-custom-session-selector-test
  (test-suite "poo-flow custom user-interface session-selector case"
    (test-case "projects custom selector receipt without dispatch"
      (let (row poo-flow-custom-module-session-selector-case)
        (check-equal? (test-ref row 'kind)
                      'poo-flow.session.selector-receipt)
        (check-equal? (test-ref row 'selector-id)
                      'selector/custom-router)
        (check-equal? (test-ref row 'candidate-count) 3)
        (check-equal? (test-ref row 'candidate-ids)
                      '(candidate/build candidate/audit candidate/governor))
        (check-equal? (test-ref row 'workflow-candidate-ids)
                      '(candidate/audit))
        (check-equal? (test-ref row 'transform-candidate-ids)
                      '(candidate/build))
        (check-equal? (test-ref row 'agent-param-candidate-ids)
                      '(candidate/governor))
        (check-equal? (test-ref row 'selection-state) 'pending)
        (check-equal? (test-ref row 'fallback-ref) 'empty-workflow)
        (check-equal? (test-ref row 'runtime-executed) #f)))))

(run-tests! user-interface-custom-session-selector-test)
