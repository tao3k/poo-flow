;;; -*- Gerbil -*-
;;; Boundary: module object validation gates cover catalog summary aggregation.
;;; Invariant: summary aggregation stays report-only and never realizes runtime descriptors.

(import :gerbil/gambit
        (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :std/srfi/1 first last)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        :poo-flow/t/support/performance
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

;; : (-> Integer [HashTable])
(def (module-objects-validation-summary-validations count)
  (poo-flow-performance-build-list
   count
   module-objects-validation-summary-validation))

;; : (-> HashTable [Symbol])
(def (module-objects-validation-summary-object-identities summary)
  (hash-get summary 'object-identities))

;; : (-> HashTable [Symbol])
(def (module-objects-validation-summary-invalid-objects summary)
  (hash-get summary 'invalid-objects))

;; : (-> HashTable Symbol Pair)
(def (module-objects-validation-summary-field summary key)
  (cons key (hash-get summary key)))

;; : (-> HashTable [Pair])
(def (module-objects-validation-summary-core-fields summary)
  (map (lambda (key)
         (module-objects-validation-summary-field summary key))
       '(object-count invalid-count valid runtime-executed)))

;; : (-> HashTable Pair)
(def (module-objects-validation-summary-first-object-field summary)
  (cons 'first-object
        (first
         (module-objects-validation-summary-object-identities summary))))

;; : (-> HashTable Pair)
(def (module-objects-validation-summary-last-invalid-field summary)
  (cons 'last-invalid
        (last
         (module-objects-validation-summary-invalid-objects summary))))

;; : (-> HashTable Alist)
(def (module-objects-validation-summary-snapshot summary)
  (append (module-objects-validation-summary-core-fields summary)
          (list
           (module-objects-validation-summary-first-object-field summary)
           (module-objects-validation-summary-last-invalid-field summary))))

;; : (-> Alist Symbol Value)
(def (module-objects-validation-summary-ref alist key)
  (cdr (assoc key alist)))

;; : (-> Alist Unit)
(def (module-objects-validation-summary-display-receipt receipt)
  (display "[poo-flow-benchmark] module-objects-validation-summary ")
  (write receipt)
  (newline)
  (force-output))

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
        (module-objects-validation-summary-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
