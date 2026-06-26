;;; -*- Gerbil -*-
;;; Boundary: POO performance object and object-catalog test cases.

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

(export module-system-poo-performance-objects-test)

;; : (-> Alist Unit)
(def (module-system-poo-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] ")
  (write (benchmark-fixture-ref receipt 'feature))
  (display " ")
  (write receipt)
  (newline)
  (force-output))

;; : TestCase
(def module-system-poo-performance-construction-case
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
          (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-materialization-case
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
          (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-validation-case
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
          (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-catalog-validation-case
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
          (module-system-poo-performance-display-receipt receipt)
          (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-object-iteration-case
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
          (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-clone-override-case
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
          (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-field-lookup-case
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
          (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-composition-case
  (test-case "composes object contributions through one merge boundary"
        (let* ((object-count 32)
               (field-count 80)
               (objects
                (poo-performance-module-object-catalog object-count field-count))
               (objects-node
                (poo-flow-module-objects-node objects))
               (contributions
                (poo-performance-catalog-contributions objects field-count))
               (result
                (poo-flow-module-objects-mk-merge/node objects-node
                                                     contributions))
              (receipt
                (poo-performance-run-gate
                 poo-performance-composition-fixture
                 (lambda ()
                   (poo-flow-module-objects-mk-merge/node
                    objects-node
                    contributions)))))
          (check-equal? (length contributions) (* object-count field-count))
          (check-equal?
           (poo-flow-module-config-merge-result-stable? result)
           #t)
          (check-equal? (poo-flow-module-config-merge-result-iterations result)
                        1)
          (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestSuite
(def module-system-poo-performance-objects-test
  (test-suite "poo-flow module system POO object performance"
    module-system-poo-performance-construction-case
    module-system-poo-performance-materialization-case
    module-system-poo-performance-validation-case
    module-system-poo-performance-catalog-validation-case
    module-system-poo-performance-object-iteration-case
    module-system-poo-performance-clone-override-case
    module-system-poo-performance-field-lookup-case
    module-system-poo-performance-composition-case))
