;;; -*- Gerbil -*-
;;; Boundary: module extension performance gates cover List slot operation merge.
;;; Invariant: extension operations stay graph data and never execute runtime work.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        :poo-flow/t/support/performance
        (only-in :poo-flow/src/module-system/extension
                 poo-flow-module-extension-contribution
                 poo-flow-module-extension-fixed-point
                 poo-flow-module-extension-node
                 poo-flow-module-extension-node-slots
                 poo-flow-module-extension-result-root
                 poo-flow-module-extension-slot-append))

(export module-extension-list-merge-performance-test)

;; : String
(def module-extension-list-merge-fixture-path
  "t/scenarios/performance/module-extension-list-merge/benchmark.ss")

;; : Alist
(def module-extension-list-merge-fixture
  (call-with-input-file module-extension-list-merge-fixture-path read))

;; : PooModuleExtensionNode
(def module-extension-list-merge-root
  (poo-flow-module-extension-node
   'extension.root
   '((capabilities . ()))
   '()))

;; : (-> Alist Symbol Value)
(def (module-extension-list-merge-ref alist key)
  (cdr (assoc key alist)))

;; : (-> Integer Integer Integer [Integer])
(def (module-extension-list-merge-batch start size step)
  (poo-flow-performance-build-list
   size
   (lambda (index)
     (+ start (* index step)))))

;; : (-> Integer Integer Integer [PooModuleExtensionOperation])
(def (module-extension-list-merge-operations batch-count batch-size overlap-step)
  (poo-flow-performance-build-list
   batch-count
   (lambda (batch-index)
     (poo-flow-module-extension-slot-append
      'capabilities
      (module-extension-list-merge-batch
       (* batch-index overlap-step)
       batch-size
       1)))))

;; : (-> [Object] Object)
(def (module-extension-list-merge-last values)
  (if (null? (cdr values))
    (car values)
    (module-extension-list-merge-last (cdr values))))

;; : (-> [PooModuleExtensionOperation] Alist)
(def (module-extension-list-merge-summary/from-operations operations)
  (let* ((result
          (poo-flow-module-extension-fixed-point
           module-extension-list-merge-root
           (list
            (poo-flow-module-extension-contribution
             'extension.root
             operations))))
         (node (poo-flow-module-extension-result-root result))
         (slots (poo-flow-module-extension-node-slots node))
         (capabilities
          (module-extension-list-merge-ref slots 'capabilities)))
    (list (cons 'capability-count (length capabilities))
          (cons 'first-capability (car capabilities))
          (cons 'last-capability
                (module-extension-list-merge-last capabilities)))))

;; : TestSuite
(def module-extension-list-merge-performance-test
  (test-suite "module extension list merge performance"
    (test-case "keeps repeated extension list appends inside benchmark contract"
      (let* ((batch-count 240)
             (batch-size 48)
             (overlap-step 24)
             (expected-count
              (+ (* (- batch-count 1) overlap-step) batch-size))
             (operations
              (module-extension-list-merge-operations
               batch-count
               batch-size
               overlap-step))
             (receipt
              (benchmark-run
               module-extension-list-merge-fixture
               (lambda ()
                 (module-extension-list-merge-summary/from-operations
                  operations))))
             (summary
              (module-extension-list-merge-summary/from-operations
               operations)))
        (check-equal?
         (benchmark-fixture-contract-pass? module-extension-list-merge-fixture)
         #t)
        (check-equal?
         (module-extension-list-merge-ref summary 'capability-count)
         expected-count)
        (check-equal?
         (module-extension-list-merge-ref summary 'first-capability)
         0)
        (check-equal?
         (module-extension-list-merge-ref summary 'last-capability)
         (- expected-count 1))
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
