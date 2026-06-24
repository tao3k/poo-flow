;;; -*- Gerbil -*-
;;; Boundary: module object validation gates cover catalog summary aggregation.
;;; Invariant: summary aggregation stays report-only and never realizes runtime descriptors.

(import :gerbil/gambit
        (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        (only-in :poo-flow/src/module-system/object-validation
                 poo-flow-module-objects-validation-summary))

(export module-objects-validation-summary-performance-test)

;; : String
(def module-objects-validation-summary-fixture-path
  "t/scenarios/performance/module-objects-validation-summary/benchmark.ss")

;; : Alist
(def module-objects-validation-summary-fixture
  (call-with-input-file module-objects-validation-summary-fixture-path read))

;; : (-> Integer Symbol)
(def (module-objects-validation-summary-name index)
  (string->symbol
   (string-append "validation-object-" (number->string index))))

;; : (-> HashTable Symbol Value HashTable)
(def (module-objects-validation-summary-put! table key value)
  (hash-put! table key value)
  table)

;; : (-> Integer HashTable)
(def (module-objects-validation-summary-validation index)
  (let* ((table (make-hash-table))
         (object-name (module-objects-validation-summary-name index))
         (valid? (not (= (modulo index 10) 0))))
    (module-objects-validation-summary-put! table 'object object-name)
    (module-objects-validation-summary-put!
     table
     'inheritance-chain
     (list object-name 'validation-root))
    (module-objects-validation-summary-put! table 'direct-field-count 3)
    (module-objects-validation-summary-put!
     table
     'direct-field-identities
     '(alpha beta gamma))
    (module-objects-validation-summary-put! table 'resolved-field-count 5)
    (module-objects-validation-summary-put!
     table
     'resolved-field-identities
     '(alpha beta gamma delta epsilon))
    (module-objects-validation-summary-put!
     table
     'field-origins
     '((alpha . direct) (delta . inherited)))
    (module-objects-validation-summary-put! table 'inherit-count 2)
    (module-objects-validation-summary-put!
     table
     'validationPhases
     '(source-ref harness-validation diagnostics))
    (module-objects-validation-summary-put! table 'valid valid?)
    table))

;; : (-> Integer (-> Integer Value) [Value])
(def (module-objects-validation-summary-build-list count make-value)
  (let loop ((index 0) (values '()))
    (if (= index count)
      (reverse values)
      (loop (+ index 1)
            (cons (make-value index) values)))))

;; : (-> Integer [HashTable])
(def (module-objects-validation-summary-validations count)
  (module-objects-validation-summary-build-list
   count
   module-objects-validation-summary-validation))

;; : (-> HashTable Alist)
(def (module-objects-validation-summary-snapshot summary)
  (list (cons 'object-count (hash-get summary 'object-count))
        (cons 'invalid-count (hash-get summary 'invalid-count))
        (cons 'valid (hash-get summary 'valid))
        (cons 'runtime-executed (hash-get summary 'runtime-executed))
        (cons 'first-object
              (car (hash-get summary 'object-identities)))
        (cons 'last-invalid
              (let (invalids (hash-get summary 'invalid-objects))
                (car (reverse invalids))))))

;; : (-> Alist Symbol Value)
(def (module-objects-validation-summary-ref alist key)
  (cdr (assoc key alist)))

;; : TestSuite
(def module-objects-validation-summary-performance-test
  (test-suite "module objects validation summary performance"
    (test-case "keeps large catalog validation summary inside benchmark contract"
      (let* ((validation-count 5000)
             (validations
              (module-objects-validation-summary-validations validation-count))
             (receipt
              (benchmark-run
               module-objects-validation-summary-fixture
               (lambda ()
                 (module-objects-validation-summary-snapshot
                  (poo-flow-module-objects-validation-summary validations)))))
             (summary
              (module-objects-validation-summary-snapshot
               (poo-flow-module-objects-validation-summary validations))))
        (check-equal?
         (benchmark-fixture-contract-pass? module-objects-validation-summary-fixture)
         #t)
        (check-equal?
         (module-objects-validation-summary-ref summary 'object-count)
         validation-count)
        (check-equal?
         (module-objects-validation-summary-ref summary 'invalid-count)
         500)
        (check-equal?
         (module-objects-validation-summary-ref summary 'valid)
         #f)
        (check-equal?
         (module-objects-validation-summary-ref summary 'runtime-executed)
         #f)
        (check-equal?
         (module-objects-validation-summary-ref summary 'first-object)
         (module-objects-validation-summary-name 0))
        (check-equal?
         (module-objects-validation-summary-ref summary 'last-invalid)
         (module-objects-validation-summary-name 4990))
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
