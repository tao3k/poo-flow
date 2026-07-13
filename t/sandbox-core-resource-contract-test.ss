;;; -*- Gerbil -*-
;;; Boundary: sandbox resource POO prototypes use harness-backed typed contracts.

(import (only-in :clan/poo/object .def)
        (only-in :std/sugar filter-map)
        (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :poo-flow/src/type-facts/objects
                 poo-flow-type-validation-receipt-harness-validation)
        :poo-flow/src/modules/sandbox-core/resource-contract)

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

;; : PooSandboxResourcesPrototype
(.def runtime-volume-ports-resources-prototype
  filesystem: poo-flow-runtime-volume-filesystem-prototype
  ports: '((scope . runtime)
           (published-by . runtime))
  cpu: 2
  memory: "4Gi")

;; : (-> HashTable Symbol Value)
(def (receipt-ref receipt key)
  (hash-get receipt key))

;; : (-> Alist Symbol Object Object)
(def (alist-ref/default entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;; : (-> Object Object)
(def (diagnostic-code diagnostic)
  (if (list? diagnostic)
    (alist-ref/default diagnostic 'code #f)
    #f))

;; diagnostic-codes
;;   : (-> [Object] [Object])
;;   | doc m%
;;       Projects structured diagnostics to their code rows and drops raw string
;;       diagnostics so contract tests can assert the structural failure path.
;;
;;       # Examples
;;       ```scheme
;;       (diagnostic-codes '(((code . missing-filesystem-slot)) "raw"))
;;       ;; => (missing-filesystem-slot)
;;       ```
;;     %
(def (diagnostic-codes diagnostics)
  (filter-map diagnostic-code diagnostics))

;; : (-> Object [Object] Boolean)
(def (diagnostic-member? diagnostic diagnostics)
  (if (member diagnostic diagnostics) #t #f))

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
    (test-case "projects shared filesystem fragments to resource policies"
      (check-equal?
       (poo-flow-sandbox-filesystem-prototype->resource-entry
        poo-flow-runtime-filesystem-prototype)
       '(filesystem
         (scope . runtime)
         (materialized-by . runtime)
         (mounts . runtime)))
      (check-equal?
       (poo-flow-sandbox-filesystem-prototype->resource-entry
        poo-flow-runtime-volume-filesystem-prototype)
       '(filesystem
         (scope . volume)
         (materialized-by . runtime)
         (mounts . runtime)))
      (check-equal?
       (poo-flow-sandbox-filesystem-prototype->resource-entry
        poo-flow-snapshot-filesystem-prototype)
       '(filesystem
         (scope . snapshot)
         (snapshot . clone))))
    (test-case "projects shared resources with ports, cpu, and memory"
      (let ((validation
             (poo-flow-sandbox-resources-prototype-contract-validation
              runtime-volume-ports-resources-prototype)))
        (check-equal?
         (poo-flow-sandbox-resources-prototype-contract-validation-valid?
          validation)
         #t)
        (check-equal?
         (poo-flow-sandbox-resources-prototype->resource-policy
          runtime-volume-ports-resources-prototype)
         '((filesystem
            (scope . volume)
            (materialized-by . runtime)
            (mounts . runtime))
           (ports
            (scope . runtime)
            (published-by . runtime))
           (cpu . 2)
           (memory . "4Gi")))))
    (test-case "validates runtime volume resources through harness facade"
      (let* ((validation
              (poo-flow-sandbox-resources-prototype-contract-validation
               poo-flow-runtime-volume-resources-prototype))
             (harness-validation
              (poo-flow-type-validation-receipt-harness-validation
               validation))
             (summary
              (poo-flow-sandbox-resources-prototype-contract-validation->alist
               validation)))
        (check-equal?
         (poo-flow-sandbox-resources-prototype-contract-validation-valid?
          validation)
         #t)
        (check-equal?
         (poo-flow-sandbox-resources-prototype-contract-validation-diagnostics
          validation)
         '())
        (check-equal? (receipt-ref harness-validation 'kind)
                      "poo-object-contract-validation")
        (check-equal? (alist-ref/default summary 'harness-valid #f) #t)
        (check-equal? (alist-ref/default summary 'diagnostic-count #f) 0)))
    (test-case "reports typed cpu contract failures from harness diagnostics"
      (let* ((validation
              (poo-flow-sandbox-resources-prototype-contract-validation
               invalid-cpu-resources-prototype))
             (diagnostics
              (poo-flow-sandbox-resources-prototype-contract-validation-diagnostics
               validation)))
        (check-equal?
         (poo-flow-sandbox-resources-prototype-contract-validation-valid?
          validation)
         #f)
        (check-equal?
         (diagnostic-member?
          "field:cpu:default-not-compatible-with-type:Number"
          diagnostics)
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
         (diagnostic-codes
          (poo-flow-sandbox-resources-prototype-contract-validation-diagnostics
           validation))
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
         (diagnostic-codes
          (poo-flow-sandbox-resources-prototype-contract-validation-diagnostics
           validation))
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
         (diagnostic-codes
          (poo-flow-sandbox-resources-prototype-contract-validation-diagnostics
           validation))
         '(filesystem-not-structured))))))
