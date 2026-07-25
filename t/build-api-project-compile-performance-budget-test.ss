;;; -*- Gerbil -*-
;;; Boundary: relative, identity-scoped Scheme compile performance policy.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/build-api/project-compile-performance-budget)

(export build-api-project-compile-performance-budget-test)

(def (make-observation revision source-digest elapsed-ms
                       host-session-id:
                       (host-session-id "host-session/1")
                       spec-count:
                       (spec-count 389))
  (poo-flow-scheme-compile-performance-observation
   revision
   "Linux-X64"
   host-session-id
   "gerbil-0.18.2+gslph-revision"
   source-digest
   'topology
   12
   12
   spec-count
   'isolated-runtime-action-cold
   'dependency-actions-seeded
   elapsed-ms))

(def (make-observations revision source-digest elapsed-values
                        host-session-id:
                        (host-session-id "host-session/1")
                        spec-count:
                        (spec-count 389))
  (map
   (lambda (elapsed-ms)
     (make-observation
      revision
      source-digest
      elapsed-ms
      host-session-id: host-session-id
      spec-count: spec-count))
   elapsed-values))

(def build-api-project-compile-performance-budget-test
  (test-suite "POO Flow Scheme compile performance budget"
    (test-case "accepts a same-host median within a relative budget"
      (let (receipt
            (poo-flow-scheme-compile-performance-budget-receipt
             (make-observations "base" "sha256:base" '(120 100 110))
             (make-observations
              "head"
              "sha256:head"
              '(119 111 115)
              spec-count: 391)
             500))
        (check-equal?
         (poo-flow-scheme-compile-performance-budget-receipt-accepted?
          receipt)
         #t)
        (check-equal? (.ref receipt 'baseline-median-ms) 110)
        (check-equal? (.ref receipt 'candidate-median-ms) 115)
        (check-equal? (.ref receipt 'relative-ceiling-ms) 116)
        (check-equal? (.ref receipt 'outcome) 'accepted)
        (check-equal? (.ref receipt 'sample-count) 3)
        (check-equal? (.ref receipt 'baseline-spec-count) 389)
        (check-equal? (.ref receipt 'candidate-spec-count) 391)
        (check-equal? (.ref receipt 'runtime-executed) #f)
        (check-equal?
         (hash-ref
          (hash-ref
           (poo-flow-scheme-compile-performance-budget-receipt->json-object
            receipt)
           "comparisonIdentity")
          "hostSessionId")
         "host-session/1")))

    (test-case "rejects a comparable median regression"
      (let (receipt
            (poo-flow-scheme-compile-performance-budget-receipt
             (make-observations "base" "sha256:base" '(100 110 120))
             (make-observations "head" "sha256:head" '(116 120 125))
             500))
        (check-equal?
         (poo-flow-scheme-compile-performance-budget-receipt-accepted?
          receipt)
         #f)
        (check-equal? (.ref receipt 'comparable) #t)
        (check-equal? (.ref receipt 'within-budget) #f)
        (check-equal? (.ref receipt 'outcome) 'regressed)
        (check-equal?
         (.ref receipt 'diagnostics)
         '(relative-performance-budget-exceeded))))

    (test-case "fails closed when host-session identity differs"
      (let (receipt
            (poo-flow-scheme-compile-performance-budget-receipt
             (make-observations "base" "sha256:base" '(100 110 120))
             (make-observations
              "head"
              "sha256:head"
              '(100 101 102)
              host-session-id: "host-session/2")
             500))
        (check-equal?
         (poo-flow-scheme-compile-performance-budget-receipt-accepted?
          receipt)
         #f)
        (check-equal? (.ref receipt 'comparable) #f)
        (check-equal? (.ref receipt 'outcome) 'incomparable)
        (check-equal?
         (.ref receipt 'diagnostics)
         '(comparison-identity-mismatch))))))

(run-tests! build-api-project-compile-performance-budget-test)
