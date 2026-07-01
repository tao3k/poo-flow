;;; -*- Gerbil -*-
;;; Boundary: Funflow user-interface pipeline benchmark fixture smoke.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?))

(export funflow-config-pipeline-performance-test)

;; : String
(def funflow-config-pipeline-fixture-path
  "t/scenarios/performance/funflow-config-pipeline/benchmark.ss")

;; : Alist
(def funflow-config-pipeline-fixture
  (call-with-input-file funflow-config-pipeline-fixture-path read))

;; : TestSuite
(def funflow-config-pipeline-performance-test
  (test-suite "funflow config pipeline performance"
    (test-case "keeps benchmark fixture contract valid"
      (check-equal?
       (benchmark-fixture-contract-pass? funflow-config-pipeline-fixture)
       #t))))
