#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; POO Flow consumer validation for the stable Gerbil project receipt v1.

(export main)

(import :gerbil/gambit :std/text/json)

(def +project-receipt-schema+ "gerbil-bazel.project-receipt.v1")
(def +build-receipt-schema+ "poo-flow.project-compile-guard.v1")
(def +source-identity-schema+
  "poo-flow.project-build-source-identity.v1")
(def +dependency-source-resolution-schema+
  "gerbil-bazel.dependency-source-resolution-receipt.v1")
(def +dependency-source-contract-schema+
  "poo-flow.dependency-source-contract.1")
(def +dependency-source-contract-projection-schema+
  "poo-flow.dependency-source-contract.projection.v1")

(def +required-build-receipt-fields+
  '("kind"
    "schema"
    "version"
    "outcome"
    "build-owner"
    "build-mode"
    "execution-policy"
    "source-identity"
    "source-identity-materialization-elapsed-ms"
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

(def (nonnegative-integer? value)
  (and (exact-integer? value) (>= value 0)))

(def (sha256-hex-string? value)
  (and (string? value)
       (= (string-length value) 64)
       (andmap
        (lambda (character)
          (member character
                  (string->list "0123456789abcdef")))
        (string->list value))))

(def (dependency-source-contract-entry dependencies logical-package)
  (cond
   ((null? dependencies) #f)
   ((string=? (hash-ref (car dependencies) "logicalPackage")
              logical-package)
    (car dependencies))
   (else
    (dependency-source-contract-entry
     (cdr dependencies)
     logical-package))))

(def (validate-dependency-source-resolutions!
      resolutions
      contract-projection)
  (required-fields!
   contract-projection
   '("schema" "contractKind" "contractSchema" "contractVersion"
     "dependencies")
   "dependency-source-contract-projection")
  (contract-assert
   (string=? (hash-ref contract-projection "schema")
             +dependency-source-contract-projection-schema+)
   "invalid dependency source contract projection schema")
  (contract-assert
   (string=? (hash-ref contract-projection "contractKind")
             +dependency-source-contract-schema+)
   "invalid dependency source contract kind")
  (contract-assert
   (string=? (hash-ref contract-projection "contractSchema")
             +dependency-source-contract-schema+)
   "invalid dependency source contract schema")
  (contract-assert (= (hash-ref contract-projection "contractVersion") 1)
                   "invalid dependency source contract version")
  (let (dependencies (hash-ref contract-projection "dependencies"))
    (contract-assert (list? dependencies)
                     "dependency source contract dependencies must be a list")
    (contract-assert (= (length resolutions) (length dependencies))
                     "dependency source resolution count mismatch")
    (let loop ((remaining resolutions) (seen '()))
      (unless (null? remaining)
        (let* ((resolution (car remaining))
               (_required
                (required-fields!
                 resolution
                 '("schema" "logicalPackage" "resolutionMode"
                   "canonicalPackagePath" "canonicalUri"
                   "expectedRevision" "observedRevision"
                   "sourceSnapshotDigest" "sourceFileCount"
                   "worktreeDirty" "outcome")
                 "dependency-source-resolution"))
               (logical-package (hash-ref resolution "logicalPackage"))
               (dependency
                (dependency-source-contract-entry
                 dependencies
                 logical-package)))
          (contract-assert dependency
                           "dependency source resolution is not canonical"
                           logical-package)
          (contract-assert (not (member logical-package seen))
                           "duplicate dependency source resolution"
                           logical-package)
          (contract-assert
           (string=? (hash-ref resolution "schema")
                     +dependency-source-resolution-schema+)
           "invalid dependency source resolution schema"
           logical-package)
          (contract-assert
           (string=? (hash-ref resolution "resolutionMode")
                     "hermetic-archive")
           "dependency source was not resolved from a hermetic archive"
           logical-package)
          (contract-assert
           (string=? (hash-ref resolution "canonicalPackagePath") "")
           "hermetic dependency unexpectedly has a local canonical path"
           logical-package)
          (contract-assert
           (string=? (hash-ref resolution "canonicalUri")
                     (hash-ref dependency "canonicalUri"))
           "dependency source canonical URI mismatch"
           logical-package)
          (for-each
           (lambda (field)
             (contract-assert
              (string=? (hash-ref resolution field)
                        (hash-ref dependency "revision"))
              "dependency source revision mismatch"
              logical-package
              field))
           '("expectedRevision" "observedRevision"))
          (contract-assert
           (string=? (hash-ref resolution "sourceSnapshotDigest")
                     (string-append
                      "sha256:"
                      (hash-ref dependency "sha256")))
           "dependency source snapshot digest mismatch"
           logical-package)
          (contract-assert
           (positive-integer? (hash-ref resolution "sourceFileCount"))
           "dependency source file count must be positive"
           logical-package)
          (contract-assert
           (eq? (hash-ref resolution "worktreeDirty") #f)
           "hermetic dependency source must not be dirty"
           logical-package)
          (contract-assert
           (string=? (hash-ref resolution "outcome") "resolved")
           "dependency source resolution did not complete"
           logical-package)
          (loop (cdr remaining) (cons logical-package seen)))))))

(def (main receipt-path contract-projection-path)
  (let* ((receipt (call-with-input-file receipt-path read-json))
         (contract-projection
          (call-with-input-file contract-projection-path read-json))
         (_ (required-fields!
             receipt
             '("schema" "buildReceipt" "dependencySourceResolutions")
             receipt-path))
         (build-receipt (hash-ref receipt "buildReceipt"))
         (source-identity
          (hash-ref build-receipt "source-identity")))
    (contract-assert
     (string=? (hash-ref receipt "schema") +project-receipt-schema+)
     "invalid Gerbil project receipt schema" receipt-path)
    (validate-dependency-source-resolutions!
     (hash-ref receipt "dependencySourceResolutions")
     contract-projection)
    (required-fields!
     build-receipt +required-build-receipt-fields+ "buildReceipt")
    (required-fields!
     source-identity
     '("kind" "schema" "version" "algorithm" "digest"
       "stage-count" "spec-count" "stages")
     "source-identity")
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
             '("topology" "adaptive" "adaptive-window"))
     "invalid POO Flow execution policy")
    (for-each
     (lambda (field)
       (contract-assert
        (string=? (hash-ref source-identity field)
                  +source-identity-schema+)
        "invalid source identity schema" field))
     '("kind" "schema"))
    (contract-assert (= (hash-ref source-identity "version") 1)
                     "invalid source identity version")
    (contract-assert
     (string=? (hash-ref source-identity "algorithm") "sha256")
     "invalid source identity algorithm")
    (contract-assert
     (sha256-hex-string? (hash-ref source-identity "digest"))
     "invalid source identity digest")
    (contract-assert
     (positive-integer? (hash-ref source-identity "stage-count"))
     "invalid source identity stage count")
    (contract-assert
     (positive-integer? (hash-ref source-identity "spec-count"))
     "invalid source identity spec count")
    (contract-assert
     (= (length (hash-ref source-identity "stages"))
        (hash-ref source-identity "stage-count"))
     "source identity stage count mismatch")
    (contract-assert
     (nonnegative-integer?
      (hash-ref build-receipt
                "source-identity-materialization-elapsed-ms"))
     "invalid source identity materialization duration")
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
