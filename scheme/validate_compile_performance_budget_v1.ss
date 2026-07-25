#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Boundary: JSON adapter for the Scheme-owned relative compile budget.
;;; Policy and comparison semantics remain in project-compile-performance-budget.

(export main)

(import :gerbil/gambit
        :std/text/json
        :poo-flow/src/build-api/project-compile-performance-budget)

(def +poo-flow-compile-performance-input-schema+
  "poo-flow.ci.scheme-compile-performance-comparison-input.v1")

(def +poo-flow-compile-performance-observation-fields+
  '("revision"
    "runner"
    "hostSessionId"
    "toolchainIdentity"
    "sourceDigest"
    "executionPolicy"
    "logicalCpuCount"
    "workerCount"
    "specCount"
    "coldnessClass"
    "dependencyCacheState"
    "elapsedMs"))

(def (contract-assert condition message . irritants)
  (unless condition
    (apply error message irritants)))

(def (required-fields! value fields label)
  (contract-assert
   (hash-table? value)
   "performance budget value must be a JSON object"
   label)
  (for-each
   (lambda (field)
     (contract-assert
      (hash-key? value field)
      "missing required performance budget field"
      label
      field))
   fields))

(def (observation->poo-object observation label)
  (required-fields!
   observation
   +poo-flow-compile-performance-observation-fields+
   label)
  (poo-flow-scheme-compile-performance-observation
   (hash-ref observation "revision")
   (hash-ref observation "runner")
   (hash-ref observation "hostSessionId")
   (hash-ref observation "toolchainIdentity")
   (hash-ref observation "sourceDigest")
   (string->symbol (hash-ref observation "executionPolicy"))
   (hash-ref observation "logicalCpuCount")
   (hash-ref observation "workerCount")
   (hash-ref observation "specCount")
   (string->symbol (hash-ref observation "coldnessClass"))
   (string->symbol (hash-ref observation "dependencyCacheState"))
   (hash-ref observation "elapsedMs")))

(def (observations->poo-objects observations label)
  (contract-assert
   (list? observations)
   "performance budget observations must be a JSON array"
   label)
  (let loop ((remaining observations)
             (index 0)
             (result-reversed '()))
    (if (null? remaining)
      (reverse result-reversed)
      (loop
       (cdr remaining)
       (+ index 1)
       (cons
        (observation->poo-object
         (car remaining)
         (cons label index))
        result-reversed)))))

(def (write-performance-receipt! output-path receipt)
  (call-with-output-file
   output-path
   (lambda (port)
     (display
      (poo-flow-scheme-compile-performance-budget-receipt->json-string
       receipt)
      port)
     (newline port))))

(def (main input-path output-path)
  (let* ((input (call-with-input-file input-path read-json))
         (_required
          (required-fields!
           input
           '("schema"
             "maximumRegressionBasisPoints"
             "baselineObservations"
             "candidateObservations")
           input-path))
         (_schema
          (contract-assert
           (string=?
            (hash-ref input "schema")
            +poo-flow-compile-performance-input-schema+)
           "invalid Scheme compile performance comparison input schema"))
         (baseline-observations
          (observations->poo-objects
           (hash-ref input "baselineObservations")
           'baseline))
         (candidate-observations
          (observations->poo-objects
           (hash-ref input "candidateObservations")
           'candidate))
         (receipt
          (poo-flow-scheme-compile-performance-budget-receipt
           baseline-observations
           candidate-observations
           (hash-ref input "maximumRegressionBasisPoints"))))
    (write-performance-receipt! output-path receipt)
    (unless
     (poo-flow-scheme-compile-performance-budget-receipt-accepted?
      receipt)
     (error
      "Scheme compile performance comparison did not pass"
      (poo-flow-scheme-compile-performance-budget-receipt->alist
       receipt)))))
