;;; -*- Gerbil -*-
;;; Boundary: custom user-interface session-selector scenario.
;;; Invariant: selectors are pending routing receipts; Marlin owns scoring,
;;; dispatch, and selected result materialization.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-selection-key)
        :poo-flow/src/module-system/init-syntax)

(export user-interface-custom-session-selector-test)

(load! "../user-interface/custom/my-module/cases/session-selector")

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : (-> [PooUserModuleSelection] [Alist])
(def (module-config-rows module-selection-bundle)
  (let* ((selection (car module-selection-bundle))
         (entry
          (poo-flow-user-module-selection-flag-entry selection ':session-rows)))
    (if entry (cdr entry) '())))

;; : TestSuite
(def user-interface-custom-session-selector-test
  (test-suite "poo-flow custom user-interface session-selector case"
    (test-case "projects custom selector receipt without dispatch"
      (let* ((selection (car poo-flow-custom-module-session-selector-case))
             (rows
              (module-config-rows poo-flow-custom-module-session-selector-case))
             (row (car rows))
             (candidates (test-ref row 'candidates))
             (build-candidate (car candidates))
             (governor-candidate (list-ref candidates 2)))
        (check-equal? (poo-flow-user-module-selection-key selection)
                      '(session . session-core))
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
        (check-equal? (test-ref row 'resolved-candidate-ids)
                      '(candidate/build candidate/audit candidate/governor))
        (check-equal? (test-ref row 'unresolved-candidate-ids)
                      '())
        (check-equal? (length candidates) 3)
        (check-equal? (test-ref build-candidate 'description)
                      "Run the build sub-agent transform.")
        (check-equal? (test-ref governor-candidate 'target-ref)
                      'agent-param/custom-build)
        (check-equal? (test-ref row 'selection-state) 'pending)
        (check-equal? (test-ref row 'fallback-ref) 'empty-workflow)
        (check-equal? (test-ref row 'fallback-resolved?) #t)
        (check-equal? (test-ref row 'valid?) #t)
        (check-equal? (test-ref row 'diagnostic-count) 0)
        (check-equal? (test-ref row 'diagnostics) '())
        (check-equal? (test-ref row 'runtime-executed) #f)))))

(run-tests! user-interface-custom-session-selector-test)
