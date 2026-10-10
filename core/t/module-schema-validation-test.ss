;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref object?)
        (only-in :std/test check-equal? test-suite)
        (only-in :core/observability/testing-case poo-flow-test-case)
        :core/module-system/schema/interface
        :core/module-system/schema/validation)

(export module-schema-validation-test)

(def (schema-field identity type merge default metadata)
  (poo-flow-module-field-contract identity type merge default metadata))

(def module-schema-validation-test
  (test-suite "native POO module schema validation"
    (poo-flow-test-case "uses native Type and C4 without an ASP harness"
      (let* ((parent
              (poo-flow-module-object
               'schema.parent '()
               (list (schema-field 'name PooFlowModuleStringType
                                   'override "parent" '()))
               '()))
             (child
              (poo-flow-module-object
               'schema.child (list parent)
               (list (schema-field 'enabled PooFlowModuleBooleanType
                                   'override #t '()))
               '()))
             (validation (poo-flow-module-object-validation child))
             (summary
              (poo-flow-module-objects-validation-summary
               (poo-flow-module-objects-validation (list parent child)))))
        (check-equal? (poo-flow-module-object-validation? validation) #t)
        (check-equal? (eq? validation
                          (poo-flow-module-object-validation child))
                      #t)
        (check-equal? (poo-flow-module-object-validation-valid? validation)
                      #t)
        (check-equal? (.ref validation 'inheritance-chain)
                      '(schema.child schema.parent))
        (check-equal? (.ref validation 'resolved-field-identities)
                      '(name enabled))
        (check-equal? (map (lambda (origin) (.ref origin 'provider))
                           (.ref validation 'field-origins))
                      '(schema.parent schema.child))
        (check-equal? (.ref summary 'object-count) 2)
        (check-equal? (.ref summary 'invalid-count) 0)))

    (poo-flow-test-case "rejects invalid merge, metadata, and native default"
      (let* ((bad
              (poo-flow-module-object
               'schema.invalid '()
               (list (schema-field 'name PooFlowModuleStringType
                                   'unknown 42 'bad-metadata))
               '()))
             (validation (poo-flow-module-object-validation bad))
             (field-validation
              (car (.ref validation 'fieldContractValidations))))
        (check-equal? (poo-flow-module-object-validation-valid? validation)
                      #f)
        (check-equal? (object? field-validation) #t)
        (check-equal? (map (lambda (diagnostic) (.ref diagnostic 'code))
                           (.ref field-validation 'diagnostics))
                      '(unsupported-merge metadata-not-association-list
                        default-not-in-native-type))))

    (poo-flow-test-case "rejects merge operations incompatible with native types"
      (let* ((bad
              (poo-flow-module-object
               'schema.bad-merge '()
               (list (schema-field 'node PooFlowModuleStringType
                                   'node-extend #f '())
                     (schema-field 'target PooFlowModuleStringType
                                   'node-remove #f '()))
               '()))
             (validation (poo-flow-module-object-validation bad)))
        (check-equal? (poo-flow-module-object-validation-valid? validation) #f)
        (check-equal? (map (lambda (diagnostic) (.ref diagnostic 'code))
                           (.ref validation 'diagnostics))
                      '(merge-type-incompatible merge-type-incompatible))))

    (poo-flow-test-case "returns diagnostics for malformed field entries"
      (let* ((bad (poo-flow-module-object
                   'schema.bad-field '() '(not-a-contract) '()))
             (validation (poo-flow-module-object-validation bad)))
        (check-equal? (poo-flow-module-object-validation-valid? validation) #f)
        (check-equal? (map (lambda (diagnostic) (.ref diagnostic 'code))
                           (.ref validation 'diagnostics))
                      '(invalid-field-contract))))

    (poo-flow-test-case "rejects duplicate catalog identities"
      (let* ((first (poo-flow-module-object 'schema.duplicate '() '() '()))
             (second (poo-flow-module-object 'schema.duplicate '() '() '()))
             (summary (poo-flow-module-objects-validation-summary
                       (poo-flow-module-objects-validation
                        (list first second)))))
        (check-equal? (.ref summary 'valid) #f)
        (check-equal? (.ref summary 'duplicate-identities)
                      '(schema.duplicate))
        (check-equal?
         (with-catch
          (lambda (_) #t)
          (lambda ()
            (poo-flow-require-module-objects-validation!
             (list first second))
            #f))
         #t)))))
