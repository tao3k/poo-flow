;;; -*- Gerbil -*-
;;; Boundary: POO performance field tests apply harness scenarios to poo-flow APIs.
;;; Invariant: hot loops reuse boundary objects, snapshots, validation, and indexes.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-ref
                 benchmark-receipt-pass?
                 benchmark-run
                 make-benchmark-fixture)
        :poo-flow/src/module-system/object-core)

(export module-system-poo-performance-test)

;; : [Symbol]
(def poo-performance-benchmark-tags
  '(poo module-system performance))

;; : Alist
(def poo-performance-construction-fixture
  (make-benchmark-fixture
   'GERBIL-SCHEME-AGENT-R027
   'poo-construction
   "large module object construction"
   "large stable field-contract list"
   "construct one POO module object at the boundary"
   poo-performance-benchmark-tags))

;; : Alist
(def poo-performance-materialization-fixture
  (make-benchmark-fixture
   'GERBIL-SCHEME-AGENT-R029
   'poo-loop-materialization
   "loop-local materialization"
   "repeated work over module object default slots"
   "materialize default slots once before repeated scalar work"
   poo-performance-benchmark-tags))

;; : Alist
(def poo-performance-validation-fixture
  (make-benchmark-fixture
   'GERBIL-SCHEME-AGENT-R031
   'poo-loop-validation
   "loop-local validation"
   "stable module object shape"
   "validate once before repeated scalar work"
   poo-performance-benchmark-tags))

;; : Alist
(def poo-performance-field-lookup-fixture
  (make-benchmark-fixture
   'GERBIL-SCHEME-AGENT-R029
   'poo-field-lookup-loop
   "repeated field lookup"
   "contribution entries over a large object field set"
   "build one resolved field index inside the contribution boundary"
   poo-performance-benchmark-tags))

;; : Alist
(def poo-performance-composition-fixture
  (make-benchmark-fixture
   'GERBIL-SCHEME-AGENT-R030
   'poo-loop-composition
   "loop-local POO composition"
   "many object field contributions"
   "accumulate contributions and apply one final merge boundary"
   poo-performance-benchmark-tags))

;; : (-> Integer (-> Integer Value) [Value])
(def (poo-performance-build-list count make-value)
  (let loop ((index 0) (values '()))
    (if (= index count)
      (reverse values)
      (loop (+ index 1)
            (cons (make-value index) values)))))

;; : (-> Integer Symbol)
(def (poo-performance-field-name index)
  (string->symbol
   (string-append "field-" (number->string index))))

;; : (-> Integer PooModuleFieldContract)
(def (poo-performance-field-contract index)
  (poo-flow-module-field-contract
   (poo-performance-field-name index)
   'Any
   'override
   index
   '((scenario . poo-performance))))

;; : (-> Integer [PooModuleFieldContract])
(def (poo-performance-field-contracts count)
  (poo-performance-build-list count poo-performance-field-contract))

;; : (-> Integer PooModuleObject)
(def (poo-performance-module-object field-count)
  (poo-flow-module-object
   'performance-object
   '()
   (poo-performance-field-contracts field-count)
   '((scenario . poo-performance))))

;; : (-> Integer PooModuleObjectContributionEntries)
(def (poo-performance-contribution-entries count)
  (poo-performance-build-list
   count
   (lambda (index)
     (cons (poo-performance-field-name index)
           (+ index 1000)))))

;; : (-> [Pair] Integer Integer)
(def (poo-performance-snapshot-sum slots rounds)
  (let loop-round ((remaining rounds)
                   (sum 0))
    (if (= remaining 0)
      sum
      (loop-round
       (- remaining 1)
       (+ sum
          (let loop-slot ((remaining-slots slots)
                          (slot-sum 0))
            (if (null? remaining-slots)
              slot-sum
              (loop-slot (cdr remaining-slots)
                         (+ slot-sum (cdar remaining-slots))))))))))

;; : TestSuite
(def module-system-poo-performance-test
  (test-suite "poo-flow module system POO performance"
    (test-case "constructs large module objects at one boundary"
      (let* ((field-count 600)
             (object (poo-performance-module-object field-count))
             (best-ms
              (benchmark-fixture-ref
               (benchmark-run
                poo-performance-construction-fixture
               (lambda ()
                 (poo-performance-module-object field-count)))
               'elapsedMs)))
        (check-equal? (poo-flow-module-object-identity object)
                      'performance-object)
        (check-equal? (length (poo-flow-module-object-fields object))
                      field-count)
        (check-equal? (< best-ms
                         (benchmark-fixture-ref
                          poo-performance-construction-fixture
                          'maxTotalMs))
                      #t)))

    (test-case "materializes default slots once before repeated work"
      (let* ((object (poo-performance-module-object 400))
             (slots (poo-flow-module-object-default-slots object))
            (receipt
              (benchmark-run
               poo-performance-materialization-fixture
               (lambda ()
                 (poo-performance-snapshot-sum slots 20)))))
        (check-equal? (length slots) 400)
        (check-equal? (poo-performance-snapshot-sum slots 1)
                      79800)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))

    (test-case "validates stable POO object shape once before scalar loop"
      (let* ((object (poo-performance-module-object 300))
             (valid? (poo-flow-module-object? object))
             (slots (poo-flow-module-object-default-slots object))
            (receipt
              (benchmark-run
               poo-performance-validation-fixture
               (lambda ()
                 (if valid?
                   (poo-performance-snapshot-sum slots 20)
                   0)))))
        (check-equal? valid? #t)
        (check-equal? (length slots) 300)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))

    (test-case "reuses field contract lookup through contribution loops"
      (let* ((field-count 600)
             (object (poo-performance-module-object field-count))
             (entries
              (poo-performance-contribution-entries field-count))
            (receipt
              (benchmark-run
               poo-performance-field-lookup-fixture
               (lambda ()
                 (poo-flow-module-object-contributions object entries)))))
        (check-equal?
         (poo-flow-module-field-contract-identity
          (poo-flow-module-object-field object 'field-599))
         'field-599)
        (check-equal? (length entries) field-count)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))

    (test-case "composes object contributions through one merge boundary"
      (let* ((field-count 200)
             (object (poo-performance-module-object field-count))
             (entries
              (poo-performance-contribution-entries field-count))
             (contributions
              (poo-flow-module-object-contributions object entries))
            (receipt
              (benchmark-run
               poo-performance-composition-fixture
               (lambda ()
                 (poo-flow-module-objects-mk-merge
                  (list object)
                  contributions)))))
        (check-equal? (length contributions) field-count)
        (check-equal?
         (poo-flow-module-config-merge-result-stable?
          (poo-flow-module-objects-mk-merge
          (list object)
          contributions))
         #t)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
