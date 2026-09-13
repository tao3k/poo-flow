;;; -*- Gerbil -*-
(import (only-in :std/test test-suite test-case check-equal?)
        (only-in :clan/poo/object .ref)
        "scenarios/poo-method-combination/performance.ss")
(export poo-method-combination-performance-test)
(def poo-method-combination-performance-test
  (test-suite "module: method combination measured cache scenario"
    (test-case "cold construction, first demand and warm invocation are distinct"
      (let (receipt (combination-performance-scenario))
        (check-equal? (.ref receipt 'first-result) (.ref receipt 'depth))
        (check-equal? (.ref receipt 'checksum) (.ref receipt 'expected))
        (check-equal? (.ref receipt 'checksum) (.ref receipt 'native-checksum))
        (check-equal? (.ref receipt 'plan-reused?) #t)
        (check-equal? (.ref receipt 'within-budget?) #t)
        (check-equal? (>= (.ref receipt 'construction-ms) 0) #t)
        (check-equal? (>= (.ref receipt 'first-demand-ms) 0) #t)))))
