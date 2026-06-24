;;; -*- Gerbil -*-
;;; Boundary: POO performance field tests apply harness scenarios to poo-flow APIs.
;;; Invariant: hot loops reuse boundary objects, snapshots, validation, and indexes.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-fixture-ref
                 benchmark-receipt-pass?
                 benchmark-run)
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/object-validation)

(export module-system-poo-performance-test)

;; : (-> String Alist)
(def (poo-performance-load-fixture path)
  (call-with-input-file path read))

;; : String
(def poo-performance-construction-fixture-path
  "t/scenarios/performance/poo-construction/benchmark.ss")
;; : Alist
(def poo-performance-construction-fixture
  (poo-performance-load-fixture poo-performance-construction-fixture-path))

;; : String
(def poo-performance-materialization-fixture-path
  "t/scenarios/performance/poo-loop-materialization/benchmark.ss")
;; : Alist
(def poo-performance-materialization-fixture
  (poo-performance-load-fixture poo-performance-materialization-fixture-path))

;; : String
(def poo-performance-validation-fixture-path
  "t/scenarios/performance/poo-loop-validation/benchmark.ss")
;; : Alist
(def poo-performance-validation-fixture
  (poo-performance-load-fixture poo-performance-validation-fixture-path))

;; : String
(def poo-performance-catalog-validation-fixture-path
  "t/scenarios/performance/poo-catalog-validation/benchmark.ss")
;; : Alist
(def poo-performance-catalog-validation-fixture
  (poo-performance-load-fixture poo-performance-catalog-validation-fixture-path))

;; : String
(def poo-performance-object-iteration-fixture-path
  "t/scenarios/performance/poo-object-iteration/benchmark.ss")
;; : Alist
(def poo-performance-object-iteration-fixture
  (poo-performance-load-fixture poo-performance-object-iteration-fixture-path))

;; : String
(def poo-performance-clone-override-fixture-path
  "t/scenarios/performance/poo-clone-override/benchmark.ss")
;; : Alist
(def poo-performance-clone-override-fixture
  (poo-performance-load-fixture poo-performance-clone-override-fixture-path))

;; : String
(def poo-performance-field-lookup-fixture-path
  "t/scenarios/performance/poo-field-lookup-loop/benchmark.ss")
;; : Alist
(def poo-performance-field-lookup-fixture
  (poo-performance-load-fixture poo-performance-field-lookup-fixture-path))

;; : String
(def poo-performance-composition-fixture-path
  "t/scenarios/performance/poo-loop-composition/benchmark.ss")
;; : Alist
(def poo-performance-composition-fixture
  (poo-performance-load-fixture poo-performance-composition-fixture-path))

;; : [String]
(def poo-performance-fixture-paths
  (list poo-performance-construction-fixture-path
        poo-performance-materialization-fixture-path
        poo-performance-validation-fixture-path
        poo-performance-catalog-validation-fixture-path
        poo-performance-object-iteration-fixture-path
        poo-performance-clone-override-fixture-path
        poo-performance-field-lookup-fixture-path
        poo-performance-composition-fixture-path))

;; : [Alist]
(def poo-performance-fixtures
  (list poo-performance-construction-fixture
        poo-performance-materialization-fixture
        poo-performance-validation-fixture
        poo-performance-catalog-validation-fixture
        poo-performance-object-iteration-fixture
        poo-performance-clone-override-fixture
        poo-performance-field-lookup-fixture
        poo-performance-composition-fixture))

;; : (-> Alist Boolean)
(def (benchmark-fixture-memory-contract-pass? fixture)
  (let (max-rss-mb (benchmark-fixture-ref fixture 'maxRssMb))
    (and (integer? max-rss-mb)
         (> max-rss-mb 0))))

;; : (-> Alist (-> Value) Alist)
(def (poo-performance-run-gate fixture thunk)
  (if (benchmark-fixture-contract-pass? fixture)
    (benchmark-run fixture thunk)
    (error "poo performance fixture contract failed" fixture)))

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

;; : (-> Integer Integer [PooModuleObject])
(def (poo-performance-module-object-catalog object-count field-count)
  (let (base-object
        (poo-flow-module-object
         'performance-base
         '()
         (poo-performance-field-contracts field-count)
         '((scenario . poo-performance-base))))
    (poo-performance-build-list
     object-count
     (lambda (index)
       (poo-flow-module-object
        (string->symbol
         (string-append "performance-child-"
                        (number->string index)))
        (list base-object)
        '()
        '((scenario . poo-performance-child)))))))

;; : (-> Integer PooModuleObjectContributionEntries)
(def (poo-performance-contribution-entries count)
  (poo-performance-build-list
   count
   (lambda (index)
     (cons (poo-performance-field-name index)
           (+ index 1000)))))

;; : (-> Integer Integer PooModuleSlotMap)
(def (poo-performance-override-slots count key-span)
  (poo-performance-build-list
   count
   (lambda (index)
     (cons (poo-performance-field-name (modulo index key-span))
           (+ index 2000)))))

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

;; : (-> PooModuleExtensionNode [Symbol] Integer Integer)
(def (poo-performance-object-node-lookup-count objects-node identities rounds)
  (let (objects-index (poo-flow-module-objects-index objects-node))
    (let loop-round ((remaining rounds)
                     (count 0))
      (if (= remaining 0)
        count
        (loop-round
         (- remaining 1)
         (+ count
            (let loop-identity ((remaining-identities identities)
                                (identity-count 0))
              (cond
               ((null? remaining-identities) identity-count)
               ((poo-flow-module-objects-ref/index objects-index
                                                   (car remaining-identities))
                (loop-identity (cdr remaining-identities)
                               (+ identity-count 1)))
               (else
                (loop-identity (cdr remaining-identities)
                               identity-count))))))))))

;; : TestSuite
(def module-system-poo-performance-test
  (test-suite "poo-flow module system POO performance"
    (test-case "keeps every POO performance fixture inside upstream benchmark contract"
      (check-equal? (length poo-performance-fixtures) 8)
      (check-equal?
       (map (lambda (fixture)
              (benchmark-fixture-ref fixture 'sourcePath))
            poo-performance-fixtures)
       poo-performance-fixture-paths)
      (check-equal?
       (map benchmark-fixture-contract-pass? poo-performance-fixtures)
       '(#t #t #t #t #t #t #t #t))
      (check-equal?
       (map (lambda (fixture)
              (benchmark-fixture-ref fixture 'maxRssMb))
            poo-performance-fixtures)
       '(512 512 512 512 512 512 512 512))
      (check-equal?
       (map benchmark-fixture-memory-contract-pass?
            poo-performance-fixtures)
       '(#t #t #t #t #t #t #t #t)))

    (test-case "constructs large module objects at one boundary"
      (let* ((field-count 600)
             (object (poo-performance-module-object field-count))
             (receipt
              (poo-performance-run-gate
                poo-performance-construction-fixture
               (lambda ()
                 (poo-performance-module-object field-count))))
             (best-ms
              (benchmark-fixture-ref receipt 'elapsedMs)))
        (check-equal? (poo-flow-module-object-identity object)
                      'performance-object)
        (check-equal? (length (poo-flow-module-object-fields object))
                      field-count)
        (check-equal? (< best-ms
                         (benchmark-fixture-ref
                          poo-performance-construction-fixture
                          'maxTotalMs))
                      #t)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))

    (test-case "materializes default slots once before repeated work"
      (let* ((object (poo-performance-module-object 400))
             (slots (poo-flow-module-object-default-slots object))
            (receipt
              (poo-performance-run-gate
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
              (poo-performance-run-gate
               poo-performance-validation-fixture
               (lambda ()
                 (if valid?
                   (poo-performance-snapshot-sum slots 20)
                   0)))))
        (check-equal? valid? #t)
        (check-equal? (length slots) 300)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))

    (test-case "validates inherited object catalogs with indexed field origins"
      (let* ((objects
              (poo-performance-module-object-catalog 40 160))
             (validations
              (poo-flow-module-objects-validation objects))
             (summary
              (poo-flow-module-objects-validation-summary validations))
             (receipt
              (poo-performance-run-gate
               poo-performance-catalog-validation-fixture
               (lambda ()
                 (poo-flow-module-objects-validation objects)))))
        (check-equal? (length validations) 40)
        (check-equal? (hash-get summary 'valid) #t)
        (check-equal? (car (hash-get summary 'resolved-field-counts))
                      160)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))

    (test-case "iterates object graph nodes after one materialization boundary"
      (let* ((objects
              (poo-performance-module-object-catalog 80 120))
             (objects-node (poo-flow-module-objects-node objects))
             (identities
              (map poo-flow-module-object-identity objects))
             (receipt
              (poo-performance-run-gate
               poo-performance-object-iteration-fixture
               (lambda ()
                 (poo-performance-object-node-lookup-count
                  objects-node
                  identities
                  12)))))
        (check-equal? (length identities) 80)
        (check-equal?
         (poo-performance-object-node-lookup-count objects-node identities 1)
         80)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))

    (test-case "applies clone overrides after one default-slot materialization"
      (let* ((object (poo-performance-module-object 320))
             (default-slots
              (poo-flow-module-object-default-slots object))
             (override-slots
              (poo-performance-override-slots 1200 160))
             (receipt
              (poo-performance-run-gate
               poo-performance-clone-override-fixture
               (lambda ()
                 (poo-flow-module-object-node/default-slots
                  object
                  default-slots
                  override-slots
                  '()))))
             (node
              (poo-flow-module-object-node/default-slots
               object
               default-slots
               override-slots
               '())))
        (check-equal? (length default-slots) 320)
        (check-equal? (length override-slots) 1200)
        (check-equal? (length (poo-flow-module-extension-node-slots node))
                      320)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))

    (test-case "reuses field contract lookup through contribution loops"
      (let* ((field-count 600)
             (object (poo-performance-module-object field-count))
             (entries
              (poo-performance-contribution-entries field-count))
            (receipt
              (poo-performance-run-gate
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
             (objects-node
              (poo-flow-module-objects-node (list object)))
             (entries
              (poo-performance-contribution-entries field-count))
             (contributions
              (poo-flow-module-object-contributions object entries))
            (receipt
              (poo-performance-run-gate
               poo-performance-composition-fixture
               (lambda ()
                 (poo-flow-module-objects-mk-merge/node
                  objects-node
                  contributions)))))
        (check-equal? (length contributions) field-count)
        (check-equal?
         (poo-flow-module-config-merge-result-stable?
          (poo-flow-module-objects-mk-merge/node
           objects-node
           contributions))
         #t)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
