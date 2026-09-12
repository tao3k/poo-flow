;;; -*- Gerbil -*-
;;; Boundary: module object validation gates cover catalog summary aggregation.
;;; Invariant: summary aggregation stays report-only and never realizes runtime descriptors.

(import :gerbil/gambit
        (only-in :clan/poo/object .o .ref object?)
        (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :std/srfi/1 first last)
        (only-in :asp-gerbil-scheme/build-api
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        "./support/performance"
        (only-in :poo-flow/src/module-system/object-validation/interface
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

;; : (-> Integer POOObject)
(def (module-objects-validation-summary-validation index)
  (let* ((object-name (module-objects-validation-summary-name index))
         (valid? (not (= (modulo index 10) 0))))
    (.o object: object-name
        inheritance-chain: (list object-name 'validation-root)
        direct-field-count: 3
        direct-field-identities: '(alpha beta gamma)
        resolved-field-count: 5
        resolved-field-identities: '(alpha beta gamma delta epsilon)
        field-origins: '((alpha . direct) (delta . inherited))
        inherit-count: 2
        validationPhases: '(source-ref harness-validation diagnostics)
        valid: valid?)))

;; : (-> Integer [POOObject])
(def (module-objects-validation-summary-validations count)
  (poo-flow-performance-build-list
   count
   module-objects-validation-summary-validation))

;; : (-> POOObject [Symbol])
(def (module-objects-validation-summary-object-identities summary)
  (.ref summary 'object-identities))

;; : (-> POOObject [Symbol])
(def (module-objects-validation-summary-invalid-objects summary)
  (.ref summary 'invalid-objects))

;; : (-> POOObject Symbol Pair)
(def (module-objects-validation-summary-field summary key)
  (cons key (.ref summary key)))

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
        (check-equal? (andmap object? validations) #t)
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
