;;; -*- Gerbil -*-
;;; Boundary: POO performance contract and API-evidence test cases.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-fixture-ref
                 benchmark-receipt-pass?)
        :poo-flow/t/support/poo-performance
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/object-validation)

(export module-system-poo-performance-contracts-test)

;; : TestCase
(def module-system-poo-performance-fixture-contract-case
  (test-case "keeps every POO performance fixture inside upstream benchmark contract"
        (check-equal? (length poo-performance-fixtures) 11)
        (check-equal?
         (map (lambda (fixture)
                (benchmark-fixture-ref fixture 'sourcePath))
              poo-performance-fixtures)
         poo-performance-fixture-paths)
        (check-equal?
         (map benchmark-fixture-contract-pass? poo-performance-fixtures)
         '(#t #t #t #t #t #t #t #t #t #t #t))
        (check-equal?
         (map (lambda (fixture)
                (benchmark-fixture-ref fixture 'maxRssMb))
              poo-performance-fixtures)
         '(512 512 512 512 512 512 512 512 512 512 512))
        (check-equal?
         (map benchmark-fixture-memory-contract-pass?
              poo-performance-fixtures)
         '(#t #t #t #t #t #t #t #t #t #t #t))
        (check-equal?
         (map poo-performance-api-evidence-contract-pass?
              poo-performance-fixtures)
         '(#t #t #t #t #t #t #t #t #t #t #t))))

;; : TestCase
(def module-system-poo-performance-api-evidence-case
  (test-case "keeps POO benchmark evidence anchored to gerbil-poo APIs"
        (let (receipt (poo-performance-api-usage-call-receipt))
          (check-equal? (cdr (assoc 'name receipt)) 'poo-api-evidence)
          (check-equal? (cdr (assoc 'color receipt)) 'blue)
          (check-equal? (cdr (assoc 'fallback receipt)) 'defaulted)
          (check-equal? (cdr (assoc 'dynamic receipt)) 'slot-added-through-api)
          (check-equal?
           (poo-performance-symbol-member?
            (cdr (assoc 'slots receipt))
            'dynamic)
           #t))))

;; : TestSuite
(def module-system-poo-performance-contracts-test
  (test-suite "poo-flow module system POO performance contracts"
    module-system-poo-performance-fixture-contract-case
    module-system-poo-performance-api-evidence-case))
