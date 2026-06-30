;;; -*- Gerbil -*-
;;; Boundary: report-only selector receipts over workflow/transform candidates.
;;; Invariant: Scheme never scores candidates, calls a model, dispatches a
;;; workflow, or returns an EmptyWorkflow; it emits pending routing receipts.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/modules/session/config)

(export session-selector-receipt-test)

;; : (-> Alist Symbol MaybeValue)
(def (test-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def session-selector-receipt-test
  (test-suite "poo-flow session selector receipts"
    (test-case "declares pending selector routing without runtime dispatch"
      (let* ((build-candidate
              (poo-flow-session-selector-candidate
               'candidate/build
               'transform
               'transform/build
               "Run build verification."
               '(derived-session handoff-intent)))
             (audit-candidate
              (poo-flow-session-selector-candidate
               'candidate/audit
               'workflow
               'workflow/audit
               "Audit the build result."
               '(runtime-handoff diagnostics)))
             (governor-candidate
              (poo-flow-session-selector-candidate
               'candidate/governor
               'agent-param
               'agent-param/governor
               "Route to a policy governor agent."
               '(validation-valid? runtime-owner)))
             (receipt
              (poo-flow-session-selector-receipt
               'selector/build-router
               'project/selector
               'session/root
               'session/root
               (list build-candidate audit-candidate governor-candidate)
               '((strategy . llm-router)
                 (judge-inputs . (summary last-failure))
                 (result-contract . workflow-ref))
               'empty-workflow
               '((case . unit))))
             (row (poo-flow-session-selector-receipt->alist receipt)))
        (check-equal? (poo-flow-session-selector-candidate?
                       build-candidate)
                      #t)
        (check-equal? (poo-flow-session-selector-candidate-id
                       build-candidate)
                      'candidate/build)
        (check-equal? (poo-flow-session-selector-candidate-kind
                       audit-candidate)
                      'workflow)
        (check-equal? (poo-flow-session-selector-candidate-target-ref
                       governor-candidate)
                      'agent-param/governor)
        (check-equal? (poo-flow-session-selector-receipt? receipt) #t)
        (check-equal? (poo-flow-session-selector-receipt-selector-id
                       receipt)
                      'selector/build-router)
        (check-equal? (poo-flow-session-selector-receipt-candidate-ids
                       receipt)
                      '(candidate/build candidate/audit candidate/governor))
        (check-equal? (.ref receipt 'transform-candidate-ids)
                      '(candidate/build))
        (check-equal? (.ref receipt 'workflow-candidate-ids)
                      '(candidate/audit))
        (check-equal? (.ref receipt 'agent-param-candidate-ids)
                      '(candidate/governor))
        (check-equal?
         (poo-flow-session-selector-receipt-selection-state receipt)
         'pending)
        (check-equal?
         (poo-flow-session-selector-receipt-selected-candidate-ref receipt)
         #f)
        (check-equal? (test-ref row 'fallback-ref) 'empty-workflow)
        (check-equal? (test-ref (test-ref row 'pending-selected-result)
                                'state)
                      'pending)
        (check-equal? (.ref receipt 'runtime-executed) #f)))
    (test-case "allows no-candidate selectors only through explicit fallback"
      (let (receipt
            (poo-flow-session-selector-receipt
             'selector/no-candidate
             'project/selector
             'session/root
             'session/root
             '()
             '((strategy . no-candidate))
             'empty-workflow))
        (check-equal? (.ref receipt 'candidate-count) 0)
        (check-equal? (.ref receipt 'candidate-ids) '())
        (check-equal? (.ref receipt 'fallback-ref) 'empty-workflow)
        (check-equal? (.ref receipt 'selected-candidate-ref) #f)))))

(run-tests! session-selector-receipt-test)
