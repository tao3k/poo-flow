;;; -*- Gerbil -*-
(import (only-in :std/test check-equal? test-case test-suite)
        (only-in :asp-gerbil-scheme/src/benchmark/gate
                 benchmark-fixture-ref
                 benchmark-receipt-pass?)
        (only-in :clan/poo/object .ref)
        (only-in :poo-flow/t/support/poo-performance
                 poo-performance-fixture-policy-contract-pass?
                 poo-performance-run-gate)
        (only-in :poo-flow/t/support/poo-performance-fixtures
                 poo-performance-observability-slot-guard-fixture)
        "scenarios/performance/poo-observability-slot-guard/scenario.ss")
(export observability-slot-performance-test)

(def observability-slot-performance-test
  (test-suite "observability slot phase performance"
    (test-case "keeps authoring, cold demand, warm cache, and trace distinct"
      (let* ((fixture (poo-performance-observability-slot-guard-fixture))
             (receipt #f)
             (gate
              (poo-performance-run-gate
               fixture
               (lambda ()
                 (set! receipt (observability-slot-performance-scenario))
                 receipt))))
        (display "[poo-flow-benchmark] observability-slot ")
        (write
         (cons (cons 'gate-elapsed-us
                     (benchmark-fixture-ref gate 'elapsedMicros))
               (observability-slot-performance-receipt-sexp receipt)))
        (newline)
        (force-output)
        (check-equal? (poo-performance-fixture-policy-contract-pass? fixture) #t)
        (check-equal? (benchmark-receipt-pass? gate) #t)
        (check-equal? (.ref receipt 'recommended-installation-phase) 'before-first-demand)
        (check-equal? (.ref receipt 'prototype-lookup-placement)
                      'before-repeated-construction)
        (check-equal? (.ref receipt 'cold-checksum) (.ref receipt 'expected-cold-checksum))
        (check-equal? (.ref receipt 'trace-checksum) (.ref receipt 'expected-trace-checksum))
        (check-equal? (.ref receipt 'evaluation-count) 1)
        (check-equal? (.ref receipt 'within-budget?) #t)))))
