;;; -*- Gerbil -*-
;;; Boundary: JSON Schema recursive contract benchmark gates.
;;; Invariant: benchmark thunks exclude gxi startup, package install, schema
;;; download, Python execution, GitHub Actions execution, and external IO.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in "./support/performance.ss"
                 poo-flow-performance-best-elapsed-ms
                 poo-flow-performance-best-elapsed-us)
        "./support/json-schema-contract-performance.ss")

(export json-schema-contract-performance-test)

;; : (-> Alist Void)
(def (json-schema-contract-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] json-schema-contract-performance ")
  (write receipt)
  (newline)
  (force-output))

;; : (-> Rational Rational Boolean)
(def (json-schema-contract-performance-within-budget? observed-ms max-ms)
  (and observed-ms
       (<= observed-ms max-ms)))

;; : (-> Symbol Rational Rational Void)
(def (json-schema-contract-performance-check-budget! name observed-ms max-ms)
  (check-equal?
   (json-schema-contract-performance-within-budget? observed-ms max-ms)
   #t))

;; : (-> Integer (-> Integer) Rational)
(def (json-schema-contract-performance-best-ms attempts workload)
  (poo-flow-performance-best-elapsed-ms
   attempts
   (lambda ()
     (workload))))

;; : (-> Integer (-> Integer) Integer)
(def (json-schema-contract-performance-best-us attempts workload)
  (poo-flow-performance-best-elapsed-us
   attempts
   (lambda ()
     (workload))))

;; : (-> Number Integer Number)
(def (json-schema-contract-performance-average-us total-us rounds)
  (/ total-us rounds))

;; : (-> Alist)
(def (json-schema-contract-performance-receipt)
  (let* ((attempts 5)
         (job-count 24)
         (step-count 4)
         (rounds 80)
         (micro-job-count 1)
         (micro-step-count 1)
         (micro-rounds 5000)
         (alist-workflow
          (json-schema-contract-performance-workflow job-count step-count))
         (poo-workflow
          (json-schema-contract-performance-poo-workflow job-count step-count))
         (micro-workflow
          (json-schema-contract-performance-workflow
           micro-job-count
           micro-step-count))
         (micro-fast-validations
          (json-schema-contract-performance-fast-validate-rounds
           micro-workflow
           micro-rounds))
         (alist-validations
          (json-schema-contract-performance-validate-rounds
           alist-workflow
           rounds))
         (poo-validations
          (json-schema-contract-performance-validate-rounds
           poo-workflow
           rounds))
         (alist-ms
          (json-schema-contract-performance-best-ms
           attempts
           (lambda ()
             (json-schema-contract-performance-validate-rounds
              alist-workflow
              rounds))))
         (poo-ms
          (json-schema-contract-performance-best-ms
           attempts
           (lambda ()
             (json-schema-contract-performance-validate-rounds
              poo-workflow
              rounds))))
         (micro-fast-us
          (json-schema-contract-performance-best-us
           attempts
           (lambda ()
             (json-schema-contract-performance-fast-validate-rounds
              micro-workflow
              micro-rounds))))
         (micro-receipt-us
          (json-schema-contract-performance-best-us
           attempts
           (lambda ()
             (json-schema-contract-performance-validate-rounds
              micro-workflow
              micro-rounds)))))
    (list
     (cons 'attempts attempts)
     (cons 'job-count job-count)
     (cons 'step-count step-count)
     (cons 'rounds rounds)
     (cons 'micro-job-count micro-job-count)
     (cons 'micro-step-count micro-step-count)
     (cons 'micro-rounds micro-rounds)
     (cons 'micro-fast-validations micro-fast-validations)
     (cons 'alist-validations alist-validations)
     (cons 'poo-validations poo-validations)
     (cons 'alist-ms alist-ms)
     (cons 'alist-ms-max-ms 300)
     (cons 'poo-ms poo-ms)
     (cons 'poo-ms-max-ms 300)
     (cons 'micro-fast-us micro-fast-us)
     (cons 'micro-fast-average-us
           (json-schema-contract-performance-average-us
            micro-fast-us
            micro-rounds))
     (cons 'micro-fast-average-us-max-us 50)
     (cons 'micro-receipt-us micro-receipt-us)
     (cons 'micro-receipt-average-us
           (json-schema-contract-performance-average-us
            micro-receipt-us
            micro-rounds))
     (cons 'micro-receipt-average-us-max-us 90))))

;; : TestSuite
(def json-schema-contract-performance-test
  (test-suite "json schema contract performance"
    (test-case "keeps recursive map-value validation inside regression budgets"
      (let (receipt (json-schema-contract-performance-receipt))
        (json-schema-contract-performance-display-receipt receipt)
        (check-equal?
         (json-schema-contract-performance-ref receipt 'alist-validations)
         (json-schema-contract-performance-ref receipt 'rounds))
        (check-equal?
         (json-schema-contract-performance-ref receipt 'poo-validations)
         (json-schema-contract-performance-ref receipt 'rounds))
        (check-equal?
         (json-schema-contract-performance-ref receipt 'micro-fast-validations)
         (json-schema-contract-performance-ref receipt 'micro-rounds))
        (json-schema-contract-performance-check-budget!
         'alist-ms
         (json-schema-contract-performance-ref receipt 'alist-ms)
         (json-schema-contract-performance-ref receipt 'alist-ms-max-ms))
        (json-schema-contract-performance-check-budget!
         'poo-ms
         (json-schema-contract-performance-ref receipt 'poo-ms)
         (json-schema-contract-performance-ref receipt 'poo-ms-max-ms))
        (json-schema-contract-performance-check-budget!
         'micro-fast-average-us
         (json-schema-contract-performance-ref receipt 'micro-fast-average-us)
         (json-schema-contract-performance-ref
          receipt
          'micro-fast-average-us-max-us))
        (json-schema-contract-performance-check-budget!
         'micro-receipt-average-us
         (json-schema-contract-performance-ref receipt 'micro-receipt-average-us)
         (json-schema-contract-performance-ref
          receipt
          'micro-receipt-average-us-max-us))))))
