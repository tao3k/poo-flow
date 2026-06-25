;;; -*- Gerbil -*-
;;; Boundary: module object validation gates cover inheritance chain projection.
;;; Invariant: validation metadata projection stays descriptor-only.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        (only-in :std/srfi/1 fold)
        :poo-flow/t/support/performance
        (only-in :poo-flow/src/module-system/object-core
                 poo-flow-module-object)
        (only-in :poo-flow/src/module-system/object-validation
                 poo-flow-module-object-inheritance-chain))

(export module-object-inheritance-chain-performance-test)

;; : String
(def module-object-inheritance-chain-fixture-path
  "t/scenarios/performance/module-object-inheritance-chain/benchmark.ss")

;; : Alist
(def module-object-inheritance-chain-fixture
  (call-with-input-file module-object-inheritance-chain-fixture-path read))

;; : (-> Alist Symbol Value)
(def (module-object-inheritance-chain-ref alist key)
  (cdr (assoc key alist)))

;; : (-> Integer Symbol)
(def (module-object-inheritance-chain-name index)
  (string->symbol
   (string-append "inheritance-node-" (number->string index))))

;; : (-> Integer PooModuleObject)
(def (module-object-inheritance-chain-build count)
  (fold (lambda (index parent)
          (poo-flow-module-object
           (module-object-inheritance-chain-name index)
           (if parent (list parent) '())
           '()
           '()))
        #f
        (poo-flow-performance-build-list count (lambda (index) index))))

;; : (-> [Object] Object)
(def (module-object-inheritance-chain-last values)
  (if (null? (cdr values))
    (car values)
    (module-object-inheritance-chain-last (cdr values))))

;; : (-> PooModuleObject Alist)
(def (module-object-inheritance-chain-summary object)
  (let (chain (poo-flow-module-object-inheritance-chain object))
    (list (cons 'chain-count (length chain))
          (cons 'first-node (car chain))
          (cons 'last-node
                (module-object-inheritance-chain-last chain)))))

;; : TestSuite
(def module-object-inheritance-chain-performance-test
  (test-suite "module object inheritance chain performance"
    (test-case "keeps large inheritance chain projection inside benchmark contract"
      (let* ((object-count 1600)
             (object (module-object-inheritance-chain-build object-count))
             (receipt
              (benchmark-run
               module-object-inheritance-chain-fixture
               (lambda ()
                 (module-object-inheritance-chain-summary object))))
             (summary (module-object-inheritance-chain-summary object)))
        (check-equal?
         (benchmark-fixture-contract-pass? module-object-inheritance-chain-fixture)
         #t)
        (check-equal?
         (module-object-inheritance-chain-ref summary 'chain-count)
         object-count)
        (check-equal?
         (module-object-inheritance-chain-ref summary 'first-node)
         (module-object-inheritance-chain-name (- object-count 1)))
        (check-equal?
         (module-object-inheritance-chain-ref summary 'last-node)
         (module-object-inheritance-chain-name 0))
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
