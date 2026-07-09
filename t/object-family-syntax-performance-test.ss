;;; -*- Gerbil -*-
;;; Boundary: POO object-family syntax performance gate.
;;; Invariant: repeated stable object-family accessors are generated once.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run/result)
        (only-in :clan/poo/object object<-alist)
        (only-in :poo-flow/t/support/poo-performance-object-scenarios
                 poo-performance-build-list)
        :poo-flow/src/module-system/object-family-syntax)

(export object-family-syntax-performance-test)

(def +poo-object-family-performance-kind+
  'poo-object-family-performance)

(defpoo-object-family +poo-object-family-performance-kind+
  poo-object-family-performance?
  (accessors
   (poo-object-family-performance-ref ref)
   (poo-object-family-performance-provider provider)
   (poo-object-family-performance-capabilities capabilities))
  (projections
   (poo-object-family-performance->alist
    (ref ref)
    (provider provider)
    (capabilities capabilities)
    (runtime-executed runtime-executed))))

;; : String
(def object-family-syntax-performance-fixture-path
  "t/scenarios/performance/poo-object-family-syntax/benchmark.ss")

;; : Alist
(def object-family-syntax-performance-fixture
  (call-with-input-file object-family-syntax-performance-fixture-path read))

;; : (-> Alist Symbol MaybeValue)
(def (object-family-syntax-performance-ref row key)
  (let (entry (assq key row))
    (if entry (cdr entry) #f)))

;; : (-> String Integer Symbol)
(def (object-family-syntax-performance-symbol prefix index)
  (string->symbol
   (string-append prefix "/" (number->string index))))

;; : (-> Integer PooObject)
(def (object-family-syntax-performance-model index)
  (object<-alist
   (list
    (cons 'kind +poo-object-family-performance-kind+)
    (cons 'ref
          (object-family-syntax-performance-symbol "model" index))
    (cons 'provider 'runtime-local)
    (cons 'capabilities '(chat text json tool-calling))
    (cons 'runtime-executed #f))))

;; : (-> Integer [Alist])
(def (object-family-syntax-performance-rows count)
  (map poo-object-family-performance->alist
       (poo-performance-build-list
        count
        object-family-syntax-performance-model)))

;; : (-> Integer Alist)
(def (object-family-syntax-performance-summary count)
  (let* ((rows (object-family-syntax-performance-rows count))
         (first-row (car rows))
         (last-row (list-ref rows (- count 1))))
    (list
     (cons 'object-count (length rows))
     (cons 'first-ref
           (object-family-syntax-performance-ref first-row 'ref))
     (cons 'last-ref
           (object-family-syntax-performance-ref last-row 'ref))
     (cons 'capability-count
           (length
            (object-family-syntax-performance-ref first-row 'capabilities)))
     (cons 'runtime-executed
           (object-family-syntax-performance-ref
            first-row
            'runtime-executed)))))

;; : (-> Alist Void)
(def (object-family-syntax-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] poo-object-family-syntax ")
  (write receipt)
  (newline)
  (force-output))

;; : TestSuite
(def object-family-syntax-performance-test
  (test-suite "object family syntax performance"
    (test-case "keeps generated POO object-family projections inside benchmark contract"
      (let-values (((receipt summary)
                    (benchmark-run/result
                     object-family-syntax-performance-fixture
                     (lambda ()
                       (object-family-syntax-performance-summary 128)))))
        (check-equal?
         (benchmark-fixture-contract-pass?
          object-family-syntax-performance-fixture)
         #t)
        (check-equal?
         (object-family-syntax-performance-ref summary 'object-count)
         128)
        (check-equal?
         (object-family-syntax-performance-ref summary 'first-ref)
         'model/0)
        (check-equal?
         (object-family-syntax-performance-ref summary 'last-ref)
         'model/127)
        (check-equal?
         (object-family-syntax-performance-ref summary 'capability-count)
         4)
        (check-equal?
         (object-family-syntax-performance-ref summary 'runtime-executed)
         #f)
        (object-family-syntax-performance-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))

(run-tests! object-family-syntax-performance-test)
