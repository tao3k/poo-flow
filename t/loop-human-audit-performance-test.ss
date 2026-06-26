;;; -*- Gerbil -*-
;;; Boundary: loop human-audit performance gates cover reused governor facts.
;;; Invariant: audit projection is review data and never mutates runtime state.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        :poo-flow/t/support/performance
        (only-in :poo-flow/src/loops/descriptor
                 make-loop-pattern-descriptor)
        (only-in :poo-flow/src/loops/strategy
                 make-loop-strategy-plan)
        (only-in :poo-flow/src/loops/governor-core
                 make-loop-governor)
        (only-in :poo-flow/src/loops/governor
                 loop-governor->contract)
        (only-in :poo-flow/src/loops/human-audit
                 make-loop-human-audit
                 loop-human-audit-contract-from-governor-contract))

(export loop-human-audit-performance-test)

;; : String
(def loop-human-audit-contract-projection-fixture-path
  "t/scenarios/performance/loop-human-audit-contract-projection/benchmark.ss")

;; : Alist
(def loop-human-audit-contract-projection-fixture
  (call-with-input-file loop-human-audit-contract-projection-fixture-path read))

;; : (-> Alist Symbol Value)
(def (loop-human-audit-performance-ref alist key)
  (cdr (assoc key alist)))

;; : (-> Integer String)
(def (loop-human-audit-performance-action-key index)
  (string-append "src/audit/" (number->string index)))

;; : (-> Integer LoopPatternDescriptor)
(def (loop-human-audit-performance-pattern index)
  (make-loop-pattern-descriptor
   (string->symbol
    (string-append "audit-pattern-" (number->string index)))
   "Exercise human audit projection on large governor facts."
   (list (cons 'level 'l2)
         (cons 'priority index)
         (cons 'metadata
               (list (cons 'acting_on
                           (loop-human-audit-performance-action-key index)))))))

;; : (-> Integer [LoopPatternDescriptor])
(def (loop-human-audit-performance-patterns count)
  (poo-flow-performance-build-list
   count
   loop-human-audit-performance-pattern))

;; : (-> Integer Integer [String])
(def (loop-human-audit-performance-action-keys start count)
  (poo-flow-performance-build-list
   count
   (lambda (offset)
     (loop-human-audit-performance-action-key (+ start offset)))))

;; : (-> Integer Integer [Alist])
(def (loop-human-audit-performance-states start count)
  (poo-flow-performance-build-list
   count
   (lambda (offset)
     (list (cons 'acting_on
                 (loop-human-audit-performance-action-key (+ start offset)))))))

;; : (-> Integer LoopGovernor)
(def (loop-human-audit-performance-governor pattern-count)
  (let* ((strategy
          (make-loop-strategy-plan
           'large-human-audit-strategy
           (loop-human-audit-performance-patterns pattern-count)
           (list (cons 'level-ceiling 'l2))))
         (denylist
          (loop-human-audit-performance-action-keys 0 50)))
    (make-loop-governor
     'large-human-audit-governor
     strategy
     (list (cons 'shared-denylist denylist)
           (cons 'aggregate-budget
                 '((max-actionable . 25)
                   (max-attempts . 2)))
           (cons 'metadata '((source . loop-human-audit-performance-test)))))))

;; : (-> LoopHumanAudit Alist Alist)
(def (loop-human-audit-performance-contract-summary audit governor-contract)
  (let (contract
        (loop-human-audit-contract-from-governor-contract
         audit
         governor-contract))
    (list (cons 'review-count
                (loop-human-audit-performance-ref contract 'review-count))
          (cons 'open-count
                (length (loop-human-audit-performance-ref
                         (loop-human-audit-performance-ref contract 'governor)
                         'open-patterns)))
          (cons 'human-inbox-count
                (length (loop-human-audit-performance-ref
                         (loop-human-audit-performance-ref contract 'governor)
                         'human-inbox-items)))
          (cons 'runtime-kind
                (loop-human-audit-performance-ref
                 (loop-human-audit-performance-ref contract 'runtime-snapshot)
                 'kind)))))

;; : TestSuite
(def loop-human-audit-performance-test
  (test-suite "loop human-audit performance"
    (test-case "keeps human audit projection inside benchmark contract"
      (let* ((pattern-count 600)
             (governor
              (loop-human-audit-performance-governor pattern-count))
             (states
              (loop-human-audit-performance-states 50 50))
             (audit
              (make-loop-human-audit
               'large-human-audit
               governor
               states
               '()))
             (governor-contract
              (loop-governor->contract governor states))
             (summary
              (loop-human-audit-performance-contract-summary
               audit
               governor-contract))
             (receipt
              (benchmark-run
               loop-human-audit-contract-projection-fixture
               (lambda ()
                 (loop-human-audit-performance-contract-summary
                  audit
                  governor-contract)))))
        (check-equal?
         (benchmark-fixture-contract-pass?
          loop-human-audit-contract-projection-fixture)
         #t)
        (check-equal?
         (loop-human-audit-performance-ref summary 'review-count)
         125)
        (check-equal?
         (loop-human-audit-performance-ref summary 'open-count)
         25)
        (check-equal?
         (loop-human-audit-performance-ref summary 'human-inbox-count)
         100)
        (check-equal?
         (loop-human-audit-performance-ref summary 'runtime-kind)
         'runtime-snapshot)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
