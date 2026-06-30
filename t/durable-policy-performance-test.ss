;;; -*- Gerbil -*-
;;; Boundary: durable policy projection hot path stays bounded.
;;; Invariant: authoring stays POO-native; runtime handoff sees struct receipts
;;; and bounded alist serialization.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        (only-in :clan/poo/object object?)
        :poo-flow/t/support/performance
        :poo-flow/src/module-system/durable-policy)

(export durable-policy-performance-test)

;; : String
(def durable-policy-projection-fixture-path
  "t/scenarios/performance/durable-policy-batch-projection/benchmark.ss")

;; : Alist
(def durable-policy-projection-fixture
  (call-with-input-file durable-policy-projection-fixture-path read))

;; : Integer
(def durable-policy-projection-count 64)

;; : (-> Alist Symbol Value)
(def (durable-policy-performance-ref row key)
  (let (entry (assoc key row))
    (and entry (cdr entry))))

;; : (-> [Value] Boolean)
(def (durable-policy-performance-all-receipts? values)
  (cond
   ((null? values) #t)
   ((poo-flow-durable-policy-receipt? (car values))
    (durable-policy-performance-all-receipts? (cdr values)))
   (else #f)))

;; : (-> [Value] Boolean)
(def (durable-policy-performance-all-bounded-alists? values)
  (cond
   ((null? values) #t)
   ((and (pair? (car values))
         (not (object? (car values)))
         (eq? (durable-policy-performance-ref (car values) 'schema)
              +poo-flow-durable-policy-receipt-schema+))
    (durable-policy-performance-all-bounded-alists? (cdr values)))
   (else #f)))

;; : (-> Integer [PooDurablePolicy])
(def (durable-policy-performance-policies count)
  (poo-flow-performance-build-list
   count
   (lambda (index)
     (poo-flow-durable-policy
      (string->symbol (string-append "durable/batch-" (number->string index)))
      'session/performance
      (list
       (cons 'repair-mode (if (even? index) 'fail-closed 'retry))
       (cons 'action-classes '(replayable idempotent compensatable))
       (cons 'metadata
             (list (cons 'index index)
                   (cons 'fixture 'durable-policy-performance))))))))

;; : (-> Integer Alist)
(def (durable-policy-performance-summary count)
  (let* ((policies (durable-policy-performance-policies count))
         (receipts (poo-flow-durable-policies->receipts policies))
         (rows (poo-flow-durable-policy-receipts->alists receipts)))
    (list
     (cons 'policy-count (length policies))
     (cons 'receipt-count (length receipts))
     (cons 'row-count (length rows))
     (cons 'struct-receipts?
           (durable-policy-performance-all-receipts? receipts))
     (cons 'bounded-alists?
           (durable-policy-performance-all-bounded-alists? rows))
     (cons 'runtime-executed #f))))

;; : (-> Alist Void)
(def (durable-policy-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] durable-policy-batch-projection ")
  (write receipt)
  (newline)
  (force-output))

;; : TestSuite
(def durable-policy-performance-test
  (test-suite "durable policy projection performance"
    (test-case "keeps durable policy batch projection inside benchmark contract"
      (let* ((summary
              (durable-policy-performance-summary
               durable-policy-projection-count))
             (receipt
              (benchmark-run
               durable-policy-projection-fixture
               (lambda ()
                 (durable-policy-performance-summary
                  durable-policy-projection-count)))))
        (check-equal?
         (benchmark-fixture-contract-pass? durable-policy-projection-fixture)
         #t)
        (check-equal?
         (durable-policy-performance-ref summary 'policy-count)
         durable-policy-projection-count)
        (check-equal?
         (durable-policy-performance-ref summary 'receipt-count)
         durable-policy-projection-count)
        (check-equal?
         (durable-policy-performance-ref summary 'row-count)
         durable-policy-projection-count)
        (check-equal?
         (durable-policy-performance-ref summary 'struct-receipts?)
         #t)
        (check-equal?
         (durable-policy-performance-ref summary 'bounded-alists?)
         #t)
        (check-equal?
         (durable-policy-performance-ref summary 'runtime-executed)
         #f)
        (durable-policy-performance-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
