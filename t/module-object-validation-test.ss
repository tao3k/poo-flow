;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO Flow integration with Core's native module-schema admission.

(import :gerbil/core
        (only-in :clan/poo/object .ref object?)
        (only-in :std/test test-suite check-equal? check-exception)
        (only-in :poo-flow/src/module-system/observability/testing-case
                 poo-flow-test-case)
        :core/module-schema/interface
        :core/module-schema/validation)

(export module-object-validation-test)

(def validation-shared-sandbox-object
  (poo-flow-module-object
   'objects.validation.shared
   '()
   (list
    (poo-flow-module-field-contract
     'flags PooFlowModuleListType 'override '() '((scope . validation)))
    (poo-flow-module-field-contract
     'runtime-args PooFlowModuleListType 'override '() '((scope . validation))))
   '((domain . validation))))

(def validation-nono-sandbox-object
  (poo-flow-module-object
   'objects.validation.nono
   (list validation-shared-sandbox-object)
   (list
    (poo-flow-module-field-contract
     'backend PooFlowModuleSymbolType 'override 'nono '((scope . validation)))
    (poo-flow-module-field-contract
     'binding PooFlowModuleSymbolType 'override 'native-ffi
     '((scope . validation))))
   '((domain . validation))))

(def module-object-validation-test
  (test-suite "poo-flow native module object validation"
    (poo-flow-test-case "admits inherited module objects through native Type and C4"
      (let* ((validation
              (poo-flow-module-object-validation validation-nono-sandbox-object))
             (field-validations (.ref validation 'fieldContractValidations))
             (field-origins (.ref validation 'field-origins)))
        (check-equal? (poo-flow-module-object-validation? validation) #t)
        (check-equal? (eq? validation
                          (poo-flow-module-object-validation
                           validation-nono-sandbox-object))
                      #t)
        (check-equal? (and (object? validation)
                           (andmap object? field-validations)
                           (andmap object? field-origins))
                      #t)
        (check-equal? (poo-flow-module-object-validation-valid? validation) #t)
        (check-equal? (.ref validation 'inheritance-chain)
                      '(objects.validation.nono objects.validation.shared))
        (check-equal? (.ref validation 'direct-field-identities)
                      '(backend binding))
        (check-equal? (.ref validation 'resolved-field-identities)
                      '(flags runtime-args backend binding))
        (check-equal? (map (lambda (origin)
                             (cons (.ref origin 'field) (.ref origin 'provider)))
                           field-origins)
                      '((flags . objects.validation.shared)
                        (runtime-args . objects.validation.shared)
                        (backend . objects.validation.nono)
                        (binding . objects.validation.nono)))
        (check-equal? (map (lambda (entry) (.ref entry 'valueKind))
                           field-validations)
                      '(List List Symbol Symbol))
        (check-equal? (andmap poo-flow-module-field-contract-validation-valid?
                              field-validations)
                      #t)
        (check-equal? (poo-flow-module-object-validation-diagnostics validation)
                      '())))

    (poo-flow-test-case "rejects symbolic field kinds at the native Type boundary"
      (check-exception
       (poo-flow-module-field-contract
        'broken 'Unknown 'override #f '((scope . validation)))
       true))

    (poo-flow-test-case "reports native field contract diagnostics"
      (let* ((broken-object
              (poo-flow-module-object
               'objects.validation.broken
               '()
               (list (poo-flow-module-field-contract
                      'broken PooFlowModuleStringType 'merge-strategy 42
                      'not-an-alist))
               '((domain . validation))))
             (validation (poo-flow-module-object-validation broken-object))
             (field-validation
              (car (.ref validation 'fieldContractValidations))))
        (check-equal? (poo-flow-module-object-validation-valid? validation) #f)
        (check-equal? (map (lambda (diagnostic) (.ref diagnostic 'code))
                           (poo-flow-module-object-validation-diagnostics
                            validation))
                      '(unsupported-merge metadata-not-association-list
                        default-not-in-native-type))
        (check-equal? (poo-flow-module-field-contract-validation-valid?
                       field-validation)
                      #f)
        (check-equal?
         (with-catch
          (lambda (_) #t)
          (lambda ()
            (poo-flow-require-module-object-validation! broken-object)
            #f))
         #t)))

    (poo-flow-test-case "requires every catalog object to pass native admission"
      (check-equal?
       (poo-flow-require-module-objects-validation!
        (list validation-shared-sandbox-object
              validation-nono-sandbox-object))
       (list validation-shared-sandbox-object
             validation-nono-sandbox-object)))))
