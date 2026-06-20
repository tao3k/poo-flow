;;; -*- Gerbil -*-
;;; Boundary: module object validation receipts bridge POO Flow objects to the
;;; Gerbil harness structural validation vocabulary.

(import (only-in :std/test
                 test-suite
                 test-case
                 check-equal?
                 run-tests!)
        :poo-flow/src/modules/object-core
        :poo-flow/src/modules/object-validation
        :poo-flow/src/modules/objects
        :poo-flow/src/modules/sandbox-core/objects
        :poo-flow/src/modules/user-interface/objects
        :poo-flow/src/modules/nono-sandbox/objects
        :poo-flow/src/modules/cubeSandbox/objects
        :poo-flow/src/modules/docker-sandbox/objects
        :poo-flow/t/fixtures/object-load-valid/objects)

(export module-object-validation-test)

;; : (-> HashTable Symbol Value)
(def (receipt-ref receipt key)
  (hash-get receipt key))

;;; Receipt projection boundary: keep the field list assertion independent from
;;; harness-private receipt nesting.
;; : (-> [HashTable] [Symbol])
(def (field-contract-validation-fields validations)
  (map (lambda (validation) (receipt-ref validation 'field))
       validations))

;;; Suite boundary: these tests pin the downstream adapter contract while
;;; leaving upstream harness internals free to evolve behind receipt fields.
;; : TestSuite
(def module-object-validation-test
  (test-suite "poo-flow module object validation"
    (test-case "projects module objects into harness validation receipts"
      ;; This case locks the downstream receipt shape to the upstream facade
      ;; contract without asserting harness-private implementation details.
      (let* ((validation
              (poo-flow-module-object-validation
               poo-flow-nono-sandbox-object))
             (harness-validation
              (receipt-ref validation 'harnessValidation))
             (source-ref
              (receipt-ref validation 'sourceRef))
             (field-contract-validations
              (receipt-ref validation 'fieldContractValidations))
             (first-field-validation
              (car field-contract-validations))
             (structural-validation
              (receipt-ref harness-validation 'structuralValidation))
             (field-contracts-validation
              (receipt-ref harness-validation 'fieldContractsValidation))
             (first-field-structural-validation
              (receipt-ref first-field-validation 'structuralValidation))
             (first-field-type-validation
              (receipt-ref first-field-validation 'typeValidation))
             (harness-checked-signals
              (receipt-ref harness-validation 'checkedSignals))
             (harness-dependency
              (receipt-ref source-ref 'dependency)))
        (check-equal? (poo-flow-module-object-validation? validation) #t)
        (check-equal? (receipt-ref validation 'kind)
                      poo-flow-module-object-validation-kind)
        (check-equal? (receipt-ref validation 'schema)
                      poo-flow-module-object-validation-schema)
        (check-equal? (receipt-ref validation 'object)
                      'objects.nono-sandbox.sandbox)
        (check-equal? (receipt-ref harness-validation 'kind)
                      "poo-object-contract-validation")
        (check-equal? (receipt-ref harness-validation 'schema)
                      "poo-object-contract-validation/v1")
        (check-equal? (receipt-ref structural-validation 'kind)
                      "poo-pattern-structural-validation")
        (check-equal? (receipt-ref structural-validation 'patternKind)
                      "type-validation")
        (check-equal? (receipt-ref harness-validation 'valid) #t)
        (check-equal? (receipt-ref harness-validation 'diagnostics) '())
        (check-equal? (receipt-ref field-contracts-validation 'kind)
                      "poo-object-field-contracts-validation")
        (check-equal? (receipt-ref field-contracts-validation 'valid) #t)
        (check-equal? (not (not (member
                                 "field-contracts-validation"
                                 harness-checked-signals)))
                      #t)
        (check-equal? (receipt-ref first-field-validation 'kind)
                      poo-flow-module-field-contract-validation-kind)
        (check-equal? (receipt-ref first-field-type-validation 'kind)
                      "poo-object-type-spec-validation")
        (check-equal? (receipt-ref first-field-type-validation 'valid)
                      #t)
        (check-equal? (receipt-ref first-field-structural-validation
                                   'patternKind)
                      "type-validation")
        (check-equal? (andmap
                       poo-flow-module-field-contract-validation-valid?
                       field-contract-validations)
                      #t)
        (check-equal? (not (not (member
                                 'backend
                                 (field-contract-validation-fields
                                  field-contract-validations))))
                      #t)
        (check-equal? harness-dependency
                      "github.com/tao3k/gerbil-scheme-language-project-harness")
        (check-equal? (poo-flow-module-object-validation-valid? validation)
                      #t)
        (check-equal? (poo-flow-module-object-validation-diagnostics
                       validation)
                      '())))

    (test-case "validates real module object sets"
      (let* ((objects
              (append poo-flow-shared-module-objects
                      poo-flow-sandbox-core-module-objects
                      poo-flow-user-interface-root-module-objects
                      poo-flow-nono-sandbox-module-objects
                      poo-flow-cubeSandbox-module-objects
                      poo-flow-docker-sandbox-module-objects))
             (validations
              (poo-flow-module-objects-validation objects)))
        (check-equal? (length validations) 9)
        (check-equal? (map poo-flow-module-object-validation-valid?
                           validations)
                      '(#t #t #t #t #t #t #t #t #t))
        (check-equal? (receipt-ref
                       (poo-flow-module-objects-validation-summary
                        validations)
                       'valid)
                      #t)
        (check-equal? (receipt-ref
                       (poo-flow-module-objects-validation-summary
                        validations)
                       'invalid-count)
                      0)))

    (test-case "wraps load! object fragments with upstream object validation"
      (let* ((objects poo-flow-custom-module-object1-module)
             (validation
              (poo-flow-module-object-validation (car objects)))
             (field-validations
              (receipt-ref validation 'fieldContractValidations))
             (typed-field-validation
              (cadr field-validations))
             (type-validation
              (receipt-ref typed-field-validation 'typeValidation)))
        (check-equal? (length objects) 1)
        (check-equal? (poo-flow-module-object-identity (car objects))
                      'objects.fixture.loaded)
        (check-equal? (poo-flow-module-object-validation-valid? validation)
                      #t)
        (check-equal? (receipt-ref type-validation 'valid) #t)
        (check-equal? (receipt-ref type-validation 'typeDisplay)
                      "(list Symbol)")))

    (test-case "fails invalid TypeSpec fields through upstream type validation"
      (let* ((broken-field
              (poo-flow-module-field-contract
               'broken 'Unknown 'override #f '((scope . validation))))
             (broken-object
              (poo-flow-module-object
               'objects.validation.bad-type
               '()
               (list broken-field)
               '((domain . validation))))
             (validation
              (poo-flow-module-object-validation broken-object))
             (field-validation
              (car (receipt-ref validation 'fieldContractValidations)))
             (type-validation
              (receipt-ref field-validation 'typeValidation))
             (validation-alist
              (poo-flow-module-object-validation->alist validation))
             (field-alist
              (car (cdr (assoc 'field-validations validation-alist))))
             (type-alist
              (cdr (assoc 'type-validation field-alist)))
             (summary
              (poo-flow-module-objects-validation-summary
               (list validation))))
        (check-equal? (poo-flow-module-object-validation-valid? validation)
                      #f)
        (check-equal? (receipt-ref type-validation 'kind)
                      "poo-object-type-spec-validation")
        (check-equal? (receipt-ref type-validation 'valid) #f)
        (check-equal? (receipt-ref type-validation 'diagnostics)
                      '("unknown-type"))
        (check-equal? (poo-flow-module-object-validation-diagnostics
                       validation)
                      '("unknown-type"))
        (check-equal? (cdr (assoc 'invalid-fields validation-alist))
                      '(broken))
        (check-equal? (cdr (assoc 'valid type-alist)) #f)
        (check-equal? (cdr (assoc 'diagnostics type-alist))
                      '("unknown-type"))
        (check-equal? (receipt-ref summary 'invalid-objects)
                      '(objects.validation.bad-type))))

    (test-case "reports upstream contract diagnostics without dropping harness evidence"
      ;; Broken field metadata, defaults, and merge strategy should all be
      ;; reported by the harness facade rather than reimplemented in poo-flow.
      (let* ((broken-field
              (poo-flow-module-field-contract
               'broken 'String 'merge-strategy 42 'not-an-alist))
             (broken-object
              (poo-flow-module-object
               'objects.validation.broken
               '()
               (list broken-field)
               '((domain . validation))))
             (validation
              (poo-flow-module-object-validation broken-object))
             (harness-validation
              (receipt-ref validation 'harnessValidation))
             (structural-validation
              (receipt-ref harness-validation 'structuralValidation))
             (field-contract-validations
              (receipt-ref validation 'fieldContractValidations))
             (field-validation
              (car field-contract-validations))
             (diagnostics
              (poo-flow-module-object-validation-diagnostics validation)))
        (check-equal? (poo-flow-module-object-validation-valid? validation)
                      #f)
        (check-equal? (receipt-ref harness-validation 'kind)
                      "poo-object-contract-validation")
        (check-equal? (receipt-ref structural-validation 'patternKind)
                      "type-validation")
        (check-equal? (receipt-ref structural-validation 'valid) #t)
        (check-equal? (receipt-ref harness-validation 'valid) #f)
        (check-equal? (map poo-flow-module-field-contract-validation-valid?
                           field-contract-validations)
                      '(#f))
        (check-equal? diagnostics
                      '("field:broken:unsupported-merge:merge-strategy"
                        "field:broken:metadata-not-association-list"
                        "field:broken:default-not-compatible-with-type:String"))
        (check-equal? (receipt-ref field-validation 'diagnostics)
                      diagnostics)))

    (test-case "requires catalog objects to pass upstream harness validation"
      (let* ((broken-field
              (poo-flow-module-field-contract
               'broken 'String 'merge-strategy 42 'not-an-alist))
             (broken-object
              (poo-flow-module-object
               'objects.validation.broken
               '()
               (list broken-field)
               '((domain . validation)))))
        (check-equal? (poo-flow-require-module-objects-validation!
                       (list poo-flow-nono-sandbox-object))
                      (list poo-flow-nono-sandbox-object))
        (check-equal?
         (with-catch
          (lambda (_) #t)
          (lambda ()
            (poo-flow-require-module-object-validation! broken-object)
            #f))
         #t)))))

(run-tests! module-object-validation-test)
