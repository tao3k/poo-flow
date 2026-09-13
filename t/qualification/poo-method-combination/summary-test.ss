;;; -*- Gerbil -*-
(import (only-in :std/test test-suite test-case check-equal? check-exception)
        (only-in :clan/poo/object .o .ref)
        (only-in "summary.ss" combination-performance-summaries))
(export summary-test)

(def (measurement checksum wall-ms allocation)
  ;; POO slot initializers are self-aware; distinct lexical names prevent a
  ;; same-named slot from recursively demanding itself.
  (let ((checksum-value checksum)
        (wall-ms-value wall-ms)
        (allocation-value allocation))
    (.o checksum: checksum-value
        wall-ms: wall-ms-value
        gc-ms: 0
        gc-count: 0
        allocated-bytes: allocation-value)))

(def (trial index elapsed expected: (expected-value 3))
  (.o kind: 'poo-combination/performance-trial
      schema: 'v1
      producer: 'poo-flow/module-system/poo-method-combination
      runtime-executed?: #t
      depth: 1
      from: 'instance
      qualifiers: 'primary
      iterations: 2
      trial: index
      order: 'combination-first
      expected: expected-value
      plan-reused?: #t
      combination: (measurement 3 elapsed 32)
      functional: (measurement 3 1 16)))

(def summary-test
  (test-suite "module: native POO performance summary"
    (test-case "summary is computed from repeated compatible POO receipts"
      (let* ((summaries
              (combination-performance-summaries
               (list (trial 0 2) (trial 1 4))))
             (value (car summaries))
             (distribution (.ref value 'combination-ms)))
        (check-equal? (length summaries) 1)
        (check-equal? (.ref value 'key) '(1 instance primary))
        (check-equal? (.ref value 'trials) 2)
        (check-equal? (.ref distribution 'median) 3)
        (check-equal? (.ref distribution 'min) 2)
        (check-equal? (.ref distribution 'max) 4)
        (check-equal? (.ref value 'median-ratio) 3)))
    (test-case "empty, duplicate and inconsistent receipts reject"
      (check-exception
       (combination-performance-summaries '()) (lambda (_) #t))
      (check-exception
       (combination-performance-summaries
        (list (trial 0 2) (trial 0 4)))
       (lambda (_) #t))
      (check-exception
       (combination-performance-summaries
        (list (trial 0 2) (trial 1 4 expected: 4)))
       (lambda (_) #t)))))
