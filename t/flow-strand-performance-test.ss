;;; -*- Gerbil -*-
;;; Boundary: flow strand performance gates cover batch registry extension.
;;; Invariant: strand registries stay descriptor data, not runtime execution.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        :poo-flow/t/support/performance
        (only-in :poo-flow/src/core/flow-strand
                 default-flow-strand-registry
                 flow-strand-for-kind-in
                 flow-strand-names
                 flow-strand-registry-merge
                 flow-strand-registry->alist
                 flow-strand-task-families
                 make-flow-strand-descriptor))

(export flow-strand-performance-test)

;; : String
(def flow-strand-registry-merge-fixture-path
  "t/scenarios/performance/flow-strand-registry-merge/benchmark.ss")

;; : Alist
(def flow-strand-registry-merge-fixture
  (call-with-input-file flow-strand-registry-merge-fixture-path read))

;; : (-> Alist Symbol Value)
(def (flow-strand-performance-ref alist key)
  (cdr (assoc key alist)))

;; : (-> Integer Symbol)
(def (flow-strand-performance-name index)
  (string->symbol
   (string-append "generated-strand-" (number->string index))))

;; : (-> Integer FlowStrandDescriptor)
(def (flow-strand-performance-descriptor index)
  (make-flow-strand-descriptor
   (flow-strand-performance-name index)
   '(generated external)
   '(runtime-command extension-hook)
   'adapter
   'rust-or-external-runtime
   #f))

;; : (-> Integer [FlowStrandDescriptor])
(def (flow-strand-performance-descriptors count)
  (poo-flow-performance-build-list
   count
   flow-strand-performance-descriptor))

;; : (-> FlowStrandRegistry Alist)
(def (flow-strand-performance-summary registry)
  (let (snapshot (flow-strand-registry->alist registry))
    (list (cons 'strand-count
                (length (flow-strand-performance-ref snapshot 'strand-names)))
          (cons 'descriptor-count
                (length (flow-strand-performance-ref snapshot 'descriptors)))
          (cons 'runtime-executed
                (flow-strand-performance-ref snapshot 'runtime-executed)))))

;; : (-> Integer Alist)
(def (flow-strand-performance-merge-summary count)
  (let* ((descriptors
          (append
           (flow-strand-performance-descriptors count)
           (list (make-flow-strand-descriptor
                  'simple
                  '(pure scheme generated-override)
                  '(pure-function io-continuation local-kleisli extension-hook)
                  'local
                  'gerbil
                  #t))))
         (registry
          (flow-strand-registry-merge
           default-flow-strand-registry
           descriptors))
         (simple (flow-strand-for-kind-in registry 'simple))
         (summary (flow-strand-performance-summary registry)))
    (cons (cons 'simple-task-families (flow-strand-task-families simple))
          summary)))

;; : TestSuite
(def flow-strand-performance-test
  (test-suite "flow strand performance"
    (test-case "keeps large strand registry merge inside benchmark contract"
      (let* ((extension-count 900)
             (summary (flow-strand-performance-merge-summary extension-count))
             (receipt
              (benchmark-run
               flow-strand-registry-merge-fixture
               (lambda ()
                 (flow-strand-performance-merge-summary extension-count)))))
        (check-equal?
         (benchmark-fixture-contract-pass? flow-strand-registry-merge-fixture)
         #t)
        (check-equal?
         (flow-strand-performance-ref summary 'strand-count)
         (+ extension-count 3))
        (check-equal?
         (flow-strand-performance-ref summary 'descriptor-count)
         (+ extension-count 3))
        (check-equal?
         (flow-strand-performance-ref summary 'simple-task-families)
         '(pure scheme generated-override))
        (check-equal?
         (flow-strand-performance-ref summary 'runtime-executed)
         #f)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
