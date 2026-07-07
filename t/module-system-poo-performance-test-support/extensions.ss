;;; -*- Gerbil -*-
;;; Boundary: POO performance extension graph test cases.

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

(export module-system-poo-performance-extensions-test)

;; : TestCase
(def module-system-poo-performance-extension-children-case
  (test-case "merges extension children through indexed override boundary"
        (let* ((base-count 500)
               (extra-count 1600)
               (key-span 700)
               (base (poo-performance-extension-merge-root base-count))
               (operations
                (poo-performance-extension-node-extend-operations extra-count
                                                                  key-span))
               (contribution
                (poo-flow-module-extension-contribution 'extension-root
                                                        operations))
               (merged
                (poo-flow-module-extension-apply-contribution base
                                                              contribution))
               (receipt
                (poo-performance-run-gate
                 (poo-performance-extension-children-merge-fixture)
                 (lambda ()
                   (poo-flow-module-extension-apply-contribution
                    base
                    contribution)))))
          (check-equal?
           (length (poo-flow-module-extension-node-children merged))
           key-span)
          (check-equal?
           (cdar
            (poo-flow-module-extension-node-slots
             (car (poo-flow-module-extension-node-children merged))))
           3400)
          (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-cross-targeting-case
  (test-case "preserves same-pass targeting after cross contribution child creation"
        (let* ((child-count 900)
               (target
                (poo-performance-cross-contribution-child-name 640))
               (base (poo-performance-extension-merge-root 0))
               (contributions
                (poo-performance-cross-contribution-targeting-contributions
                 child-count
                 target))
               (merged
                (poo-flow-module-extension-apply-contributions base
                                                               contributions))
               (target-child
                (poo-flow-module-extension-child-ref
                 (poo-flow-module-extension-node-children merged)
                 target))
               (receipt
                (poo-performance-run-gate
                 (poo-performance-cross-contribution-targeting-fixture)
                 (lambda ()
                   (poo-flow-module-extension-apply-contributions
                    base
                    contributions)))))
          (check-equal?
           (length (poo-flow-module-extension-node-children merged))
           child-count)
          (check-equal?
           (poo-performance-slot-ref/default
            (poo-flow-module-extension-node-slots target-child)
            'targeted?
            #f)
           #t)
          (check-equal?
           (poo-performance-slot-ref/default
            (poo-flow-module-extension-node-slots target-child)
            'target-phase
            #f)
           'same-pass)
          (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-local-coalescing-case
  (test-case "coalesces adjacent local contributions before graph traversal"
        (let* ((child-count 900)
               (contribution-count 900)
               (base (poo-performance-extension-merge-root child-count))
               (contributions
                (poo-performance-local-slot-contributions 'extension-root
                                                          contribution-count))
               (merged
                (poo-flow-module-extension-apply-contributions base
                                                               contributions))
               (receipt
                (poo-performance-run-gate
                 (poo-performance-local-contribution-coalescing-fixture)
                 (lambda ()
                   (poo-flow-module-extension-apply-contributions
                    base
                    contributions)))))
          (check-equal?
           (length (poo-flow-module-extension-node-children merged))
           child-count)
          (check-equal?
           (length (poo-flow-module-extension-node-slots merged))
           (+ contribution-count 1))
          (check-equal?
           (poo-performance-slot-ref/default
            (poo-flow-module-extension-node-slots merged)
            'field-640
            #f)
           640)
          (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestSuite
(def module-system-poo-performance-extensions-test
  (test-suite "poo-flow module system POO extension performance"
    module-system-poo-performance-extension-children-case
    module-system-poo-performance-cross-targeting-case
    module-system-poo-performance-local-coalescing-case))
