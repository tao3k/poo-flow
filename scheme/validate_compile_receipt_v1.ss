#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; POO Flow consumer validation for the stable Gerbil project receipt v1.

(export main)

(import :gerbil/gambit :std/text/json)

(def +project-receipt-schema+ "gerbil-bazel.project-receipt.v1")
(def +build-receipt-schema+ "poo-flow.project-compile-guard.v1")

(def +required-build-receipt-fields+
  '("kind"
    "schema"
    "version"
    "outcome"
    "build-owner"
    "build-mode"
    "execution-policy"
    "admission-outcome"
    "logical-cpu-count"
    "worker-count"
    "build-summary"))

(def (contract-assert condition message . irritants)
  (unless condition (apply error message irritants)))

(def (required-fields! value fields label)
  (contract-assert (hash-table? value) "receipt value must be a JSON object" label)
  (for-each
   (lambda (field)
     (contract-assert (hash-key? value field)
                      "missing required receipt field" label field))
   fields))

(def (positive-integer? value)
  (and (exact-integer? value) (> value 0)))

(def (main receipt-path)
  (let* ((receipt (call-with-input-file receipt-path read-json))
         (_ (required-fields! receipt '("schema" "buildReceipt") receipt-path))
         (build-receipt (hash-ref receipt "buildReceipt")))
    (contract-assert
     (string=? (hash-ref receipt "schema") +project-receipt-schema+)
     "invalid Gerbil project receipt schema" receipt-path)
    (required-fields!
     build-receipt +required-build-receipt-fields+ "buildReceipt")
    (for-each
     (lambda (field)
       (contract-assert
        (string=? (hash-ref build-receipt field) +build-receipt-schema+)
        "invalid POO Flow build receipt identity" field))
     '("kind" "schema"))
    (contract-assert (= (hash-ref build-receipt "version") 1)
                     "invalid POO Flow build receipt version")
    (contract-assert (string=? (hash-ref build-receipt "outcome") "completed")
                     "POO Flow build receipt did not complete")
    (contract-assert
     (string=? (hash-ref build-receipt "build-owner")
               "gslph-building-framework")
     "invalid POO Flow build owner")
    (contract-assert
     (string=? (hash-ref build-receipt "build-mode")
               "standard-gerbil-make-project")
     "invalid POO Flow build mode")
    (contract-assert
     (member (hash-ref build-receipt "execution-policy")
             '("topology" "adaptive"))
     "invalid POO Flow execution policy")
    (contract-assert
     (string=? (hash-ref build-receipt "admission-outcome") "ready")
     "POO Flow build admission was not ready")
    (contract-assert
     (positive-integer? (hash-ref build-receipt "logical-cpu-count"))
     "invalid detected logical CPU count")
    (contract-assert
     (positive-integer? (hash-ref build-receipt "worker-count"))
     "invalid configured worker count")
    (contract-assert
     (hash-table? (hash-ref build-receipt "build-summary"))
     "invalid POO Flow build summary")))
