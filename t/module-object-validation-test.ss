;;; -*- Gerbil -*-
;;; Boundary: module object validation receipts bridge POO Flow objects to the
;;; Gerbil harness structural validation vocabulary.

(import (only-in :std/test
                 test-suite
                 test-case
                 check-equal?
                 run-tests!)
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/object-validation
        :poo-flow/src/module-system/objects)

(export module-object-validation-test)

;; : (-> HashTable Symbol Value)
(def (receipt-ref receipt key)
  (hash-get receipt key))

;; : (-> Alist Symbol Value Value)
(def (alist-ref entries key default)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default)))

;;; Receipt projection boundary: keep the field list assertion independent from
;;; harness-private receipt nesting.
;; : (-> [HashTable] [Symbol])
(def (field-contract-validation-fields validations)
  (map (lambda (validation) (receipt-ref validation 'field))
       validations))

;; : PooModuleObject
(def validation-shared-sandbox-object
  (poo-flow-module-object
   'objects.validation.shared
   '()
   (list
    (poo-flow-module-field-contract
     'flags 'List 'override '() '((scope . validation)))
    (poo-flow-module-field-contract
     'runtime-args 'List 'override '() '((scope . validation))))
   '((domain . validation))))

;; : PooModuleObject
(def validation-nono-sandbox-object
  (poo-flow-module-object
   'objects.validation.nono
   (list validation-shared-sandbox-object)
   (list
    (poo-flow-module-field-contract
     'backend 'Symbol 'override 'nono '((scope . validation)))
    (poo-flow-module-field-contract
     'binding 'Symbol 'override 'native-ffi '((scope . validation))))
   '((domain . validation))))

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
               validation-nono-sandbox-object))
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
             (field-origins
              (receipt-ref validation 'field-origins))
             (validation-phases
              (receipt-ref validation 'validationPhases))
             (harness-checked-signals
              (receipt-ref harness-validation 'checkedSignals))
             (checked-signals
              (receipt-ref validation 'checkedSignals))
             (harness-dependency
              (receipt-ref source-ref 'dependency)))
        (check-equal? (poo-flow-module-object-validation? validation) #t)
        (check-equal? (receipt-ref validation 'kind)
                      poo-flow-module-object-validation-kind)
        (check-equal? (receipt-ref validation 'schema)
                      poo-flow-module-object-validation-schema)
        (check-equal? (receipt-ref validation 'object)
                      'objects.validation.nono)
        (check-equal? (receipt-ref validation 'inheritance-chain)
                      '(objects.validation.nono
                        objects.validation.shared))
        (check-equal? (receipt-ref validation 'direct-field-identities)
                      '(backend binding))
        (check-equal? (receipt-ref validation 'resolved-field-identities)
                      '(flags runtime-args backend binding))
        (check-equal? (map (lambda (origin)
                             (cons (alist-ref origin 'field #f)
                                   (alist-ref origin 'origin #f)))
                           field-origins)
                      '((flags . inherited)
                        (runtime-args . inherited)
                        (backend . direct)
                        (binding . direct)))
        (check-equal? (map (lambda (origin)
                             (cons (alist-ref origin 'field #f)
                                   (alist-ref origin 'provider #f)))
                           field-origins)
                      '((flags . objects.validation.shared)
                        (runtime-args . objects.validation.shared)
                        (backend . objects.validation.nono)
                        (binding . objects.validation.nono)))
        (check-equal? (map (lambda (phase)
                             (receipt-ref phase 'phase))
                           validation-phases)
                      '(source-reference
                        harness-object-contract
                        field-contracts
                        local-object-diagnostics))
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
        (check-equal? (not (not (member
                                 'object-field-origin-contract
                                 checked-signals)))
                      #t)
        (check-equal? (not (not (member
                                 'object-validation-phase-contract
                                 checked-signals)))
                      #t)
        (check-equal? harness-dependency
                      "github.com/tao3k/gerbil-scheme-language-project-harness")
        (check-equal? (poo-flow-module-object-validation-valid? validation)
                      #t)
        (check-equal? (poo-flow-module-object-validation-diagnostics
                       validation)
                      '())))

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
                       (list validation-nono-sandbox-object))
                      (list validation-nono-sandbox-object))
        (check-equal?
         (with-catch
          (lambda (_) #t)
          (lambda ()
            (poo-flow-require-module-object-validation! broken-object)
            #f))
         #t)))))
