;;; -*- Gerbil -*-
;;; Boundary: selector receipt performance gate.
;;; Invariant: selector candidate projection stays bounded and report-only.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        :poo-flow/t/support/performance
        :poo-flow/src/modules/session/config)

(export session-selector-receipt-performance-test)

;; : String
(def session-selector-receipt-fixture-path
  "t/scenarios/performance/session-selector-receipt/benchmark.ss")

;; : Alist
(def session-selector-receipt-fixture
  (call-with-input-file session-selector-receipt-fixture-path read))

;; : (-> Alist Symbol MaybeValue)
(def (selector-performance-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : (-> Alist Void)
(def (selector-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] session-selector-receipt ")
  (write receipt)
  (newline)
  (force-output))

;; : (-> Integer Symbol)
(def (selector-performance-candidate-id index)
  (string->symbol
   (string-append "candidate/" (number->string index))))

;; : (-> Integer Symbol)
(def (selector-performance-target-ref index)
  (string->symbol
   (string-append "transform/" (number->string index))))

;; : (-> Integer Symbol)
(def (selector-performance-candidate-kind index)
  (cond
   ((= (modulo index 3) 0) 'workflow)
   ((= (modulo index 3) 1) 'transform)
   (else 'agent-param)))

;; : (-> Integer PooSessionSelectorCandidate)
(def (selector-performance-candidate index)
  (poo-flow-session-selector-candidate
   (selector-performance-candidate-id index)
   (selector-performance-candidate-kind index)
   (selector-performance-target-ref index)
   "Synthetic selector candidate for batch projection."
   '(runtime-owner runtime-executed)))

;; : (-> Integer Alist)
(def (selector-performance-summary candidate-count)
  (let* ((candidates
          (poo-flow-performance-build-list
           candidate-count
           selector-performance-candidate))
         (receipt
          (poo-flow-session-selector-receipt
           'selector/performance
           'project/selector
           'session/root
           'session/root
           candidates
           '((strategy . llm-router)
             (judge-inputs . (summary last-failure)))
           'empty-workflow))
         (row (poo-flow-session-selector-receipt->alist receipt))
         (projected-candidates (selector-performance-ref row 'candidates)))
    (list (cons 'candidate-count
                (selector-performance-ref row 'candidate-count))
          (cons 'projected-candidate-count (length projected-candidates))
          (cons 'workflow-count
                (length (selector-performance-ref
                         row
                         'workflow-candidate-ids)))
          (cons 'transform-count
                (length (selector-performance-ref
                         row
                         'transform-candidate-ids)))
          (cons 'agent-param-count
                (length (selector-performance-ref
                         row
                         'agent-param-candidate-ids)))
          (cons 'selection-state
                (selector-performance-ref row 'selection-state))
          (cons 'selected-candidate-ref
                (selector-performance-ref row 'selected-candidate-ref))
          (cons 'runtime-executed
                (selector-performance-ref row 'runtime-executed)))))

;; : TestSuite
(def session-selector-receipt-performance-test
  (test-suite "session selector receipt performance"
    (test-case "keeps selector candidate projection inside benchmark contract"
      (let* ((candidate-count 300)
             (summary (selector-performance-summary candidate-count))
             (receipt
              (benchmark-run
               session-selector-receipt-fixture
               (lambda ()
                 (selector-performance-summary candidate-count)))))
        (check-equal?
         (benchmark-fixture-contract-pass? session-selector-receipt-fixture)
         #t)
        (check-equal? (selector-performance-ref summary 'candidate-count)
                      candidate-count)
        (check-equal?
         (selector-performance-ref summary 'projected-candidate-count)
         candidate-count)
        (check-equal? (selector-performance-ref summary 'workflow-count)
                      100)
        (check-equal? (selector-performance-ref summary 'transform-count)
                      100)
        (check-equal? (selector-performance-ref summary 'agent-param-count)
                      100)
        (check-equal? (selector-performance-ref summary 'selection-state)
                      'pending)
        (check-equal? (selector-performance-ref summary
                                                'selected-candidate-ref)
                      #f)
        (check-equal? (selector-performance-ref summary 'runtime-executed)
                      #f)
        (selector-performance-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
