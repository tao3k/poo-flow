;;; -*- Gerbil -*-
;;; Boundary: sandbox resource POO prototypes use harness-backed typed contracts.

(import (only-in :clan/poo/object .def)
        (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/modules/sandbox-core/profile)

(export sandbox-core-resource-contract-test)

;; : PooSandboxResourcesPrototype
(.def invalid-cpu-resources-prototype
  filesystem: poo-flow-runtime-volume-filesystem-prototype
  cpu: "two"
  memory: "4Gi")

;; : PooSandboxResourcesPrototype
(.def missing-filesystem-resources-prototype
  cpu: 2
  memory: "4Gi")

;; : PooSandboxResourcesPrototype
(.def unreadable-root-mixin-resources-prototype
  filesystem: =>.+ poo-flow-runtime-volume-filesystem-prototype
  cpu: 2
  memory: "4Gi")

;; : PooSandboxFilesystemPrototype
(.def unstructured-filesystem-prototype
  scope: 'volume)

;; : PooSandboxResourcesPrototype
(.def unstructured-filesystem-resources-prototype
  filesystem: unstructured-filesystem-prototype
  cpu: 2
  memory: "4Gi")

;; : (-> HashTable Symbol Value)
(def (receipt-ref receipt key)
  (hash-get receipt key))

;; : (-> Alist Symbol Value)
(def (alist-ref/default entries key default-value)
  (cond
   ((null? entries) default-value)
   ((equal? key (caar entries)) (cdar entries))
   (else
    (alist-ref/default (cdr entries) key default-value))))

;; : (-> Value Value)
(def (diagnostic-code diagnostic)
  (if (list? diagnostic)
    (alist-ref/default diagnostic 'code #f)
    #f))

;; : (-> [Value] [Value])
(def (diagnostic-codes diagnostics)
  (cond
   ((null? diagnostics) '())
   (else
    (let (code (diagnostic-code (car diagnostics)))
      (if code
        (cons code (diagnostic-codes (cdr diagnostics)))
        (diagnostic-codes (cdr diagnostics)))))))

;; : (-> Thunk Boolean)
(def (contract-error? thunk)
  (with-catch
   (lambda (_failure) #t)
   (lambda ()
     (thunk)
     #f)))

;; : TestSuite
(def sandbox-core-resource-contract-test
  (test-suite "sandbox-core resource prototype typed contracts"
    (test-case "validates runtime volume resources through harness facade"
      (let* ((validation
              (poo-flow-sandbox-resources-prototype-contract-validation
               poo-flow-runtime-volume-resources-prototype))
             (harness-validation (receipt-ref validation 'harnessValidation))
             (summary
              (poo-flow-sandbox-resources-prototype-contract-validation->alist
               validation)))
        (check-equal?
         (poo-flow-sandbox-resources-prototype-contract-validation-valid?
          validation)
         #t)
        (check-equal? (receipt-ref validation 'diagnostics) '())
        (check-equal? (receipt-ref harness-validation 'kind)
                      "poo-object-contract-validation")
        (check-equal? (alist-ref/default summary 'harness-valid #f) #t)
        (check-equal? (alist-ref/default summary 'diagnostic-count #f) 0)))
    (test-case "reports typed cpu contract failures from harness diagnostics"
      (let* ((validation
              (poo-flow-sandbox-resources-prototype-contract-validation
               invalid-cpu-resources-prototype))
             (diagnostics (receipt-ref validation 'diagnostics)))
        (check-equal?
         (poo-flow-sandbox-resources-prototype-contract-validation-valid?
          validation)
         #f)
        (check-equal?
         (not (not (member
                    "field:cpu:default-not-compatible-with-type:Number"
                    diagnostics)))
         #t)
        (check-equal?
         (contract-error?
          (lambda ()
            (poo-flow-require-sandbox-resources-prototype-contract!
             invalid-cpu-resources-prototype)))
         #t)))
    (test-case "reports missing filesystem as sandbox-core structure failure"
      (let ((validation
             (poo-flow-sandbox-resources-prototype-contract-validation
              missing-filesystem-resources-prototype)))
        (check-equal?
         (poo-flow-sandbox-resources-prototype-contract-validation-valid?
          validation)
         #f)
        (check-equal?
         (diagnostic-codes (receipt-ref validation 'diagnostics))
         '(missing-filesystem-slot))))
    (test-case "reports root resource mixins without parent slot"
      (let ((validation
             (poo-flow-sandbox-resources-prototype-contract-validation
              unreadable-root-mixin-resources-prototype)))
        (check-equal?
         (poo-flow-sandbox-resources-prototype-contract-validation-valid?
          validation)
         #f)
        (check-equal?
         (diagnostic-codes (receipt-ref validation 'diagnostics))
         '(unreadable-filesystem-slot))))
    (test-case "reports unstructured filesystem projection"
      (let ((validation
             (poo-flow-sandbox-resources-prototype-contract-validation
              unstructured-filesystem-resources-prototype)))
        (check-equal?
         (poo-flow-sandbox-resources-prototype-contract-validation-valid?
          validation)
         #f)
        (check-equal?
         (diagnostic-codes (receipt-ref validation 'diagnostics))
         '(filesystem-not-structured))))))
