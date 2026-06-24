;;; -*- Gerbil -*-
;;; Boundary: load! fixture module objects are integration validation cases.
;;; Invariant: unit receipt-shape tests do not import fixture packages.

(import (only-in :std/test
                 test-suite
                 test-case
                 check-equal?)
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/object-validation
        :poo-flow/t/fixtures/object-load-valid/objects)

(export module-object-load-validation-test)

;; : (-> HashTable Symbol Value)
(def (receipt-ref receipt key)
  (hash-get receipt key))

;; : TestSuite
(def module-object-load-validation-test
  (test-suite "poo-flow module object load validation"
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
                      "(list Symbol)")))))
