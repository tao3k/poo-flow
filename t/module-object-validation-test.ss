;;; -*- Gerbil -*-
;;; Boundary: module object validation receipts bridge POO Flow objects to the
;;; Gerbil harness structural validation vocabulary.

(import :std/test
        :poo-flow/src/modules/object-core
        :poo-flow/src/modules/object-validation
        :poo-flow/src/modules/objects
        :poo-flow/src/modules/sandbox-core/objects
        :poo-flow/src/modules/user-interface/objects
        :poo-flow/src/modules/nono-sandbox/objects
        :poo-flow/src/modules/cubeSandbox/objects
        :poo-flow/src/modules/docker-sandbox/objects)

(export module-object-validation-test)

;; : (-> HashTable Symbol Value)
(def (receipt-ref receipt key)
  (hash-get receipt key))

;; : (-> [HashTable] [Symbol])
(def (diagnostic-codes diagnostics)
  (map (lambda (diagnostic) (receipt-ref diagnostic 'code))
       diagnostics))

;; : TestSuite
(def module-object-validation-test
  (test-suite "poo-flow module object validation"
    (test-case "projects module objects into harness validation receipts"
      (let* ((validation
              (poo-flow-module-object-validation
               poo-flow-nono-sandbox-object))
             (harness-validation
              (receipt-ref validation 'harnessValidation))
             (source-ref
              (receipt-ref validation 'sourceRef)))
        (check-equal? (poo-flow-module-object-validation? validation) #t)
        (check-equal? (receipt-ref validation 'kind)
                      poo-flow-module-object-validation-kind)
        (check-equal? (receipt-ref validation 'schema)
                      poo-flow-module-object-validation-schema)
        (check-equal? (receipt-ref validation 'object)
                      'objects.nono-sandbox.sandbox)
        (check-equal? (receipt-ref harness-validation 'kind)
                      "poo-pattern-structural-validation")
        (check-equal? (receipt-ref harness-validation 'schema)
                      "poo-pattern-evidence/v1")
        (check-equal? (receipt-ref harness-validation 'patternKind)
                      "type-validation")
        (check-equal? (receipt-ref harness-validation 'valid) #t)
        (check-equal? (receipt-ref harness-validation 'diagnostics) '())
        (check-equal? (not (not (member
                                 "source-ref-shape"
                                 (receipt-ref harness-validation
                                              'checkedSignals))))
                      #t)
        (check-equal? (receipt-ref source-ref 'dependency)
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
                      '(#t #t #t #t #t #t #t #t #t))))

    (test-case "reports local contract diagnostics without dropping harness evidence"
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
             (diagnostics
              (poo-flow-module-object-validation-diagnostics validation)))
        (check-equal? (poo-flow-module-object-validation-valid? validation)
                      #f)
        (check-equal? (receipt-ref harness-validation 'patternKind)
                      "type-validation")
        (check-equal? (receipt-ref harness-validation 'valid) #t)
        (check-equal? (diagnostic-codes diagnostics)
                      '(invalid-merge
                        default-kind-mismatch
                        metadata-not-list))))))

(run-tests! module-object-validation-test)
