;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: load! fixture module objects are integration validation cases.
;;; Invariant: unit receipt-shape tests do not import fixture packages.

(import (only-in :poo-flow/src/module-system/observability/testing-case poo-flow-test-case)
         (only-in :clan/poo/object .ref object?)
        (only-in :std/test
                 test-suite
                 check-equal?)
        :core/module-schema/interface
        :poo-flow/src/module-system/object-validation/interface
        "./fixtures/object-load-valid/objects")

(export module-object-load-validation-test)

;; : (-> POOObject Symbol Value)
(def (receipt-ref receipt key)
  (.ref receipt key))

;; : TestSuite
(def module-object-load-validation-test
  (test-suite "poo-flow module object load validation"
    (poo-flow-test-case "wraps load! object fragments with upstream object validation"
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
        (check-equal? (and (object? validation)
                           (andmap object? field-validations)
                           (object? type-validation))
                      #t)
        (check-equal? (receipt-ref type-validation 'valid) #t)
        (check-equal? (receipt-ref type-validation 'typeDisplay)
                      "List")))))
