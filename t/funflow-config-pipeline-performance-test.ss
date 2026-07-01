;;; -*- Gerbil -*-
;;; Boundary: Funflow user-interface pipeline benchmark gate.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run/result)
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-cicd-module
                 poo-flow-custom-my-module-funflow-cicd-case)
        :poo-flow/t/support/funflow-config-pipeline-performance)

(export funflow-config-pipeline-performance-test)

;; : String
(def funflow-config-pipeline-fixture-path
  "t/scenarios/performance/funflow-config-pipeline/benchmark.ss")

;; : Alist
(def funflow-config-pipeline-fixture
  (call-with-input-file funflow-config-pipeline-fixture-path read))

;; : (-> Alist Void)
(def (funflow-config-pipeline-display-receipt receipt)
  (display "[poo-flow-benchmark] funflow-config-pipeline ")
  (write receipt)
  (newline)
  (force-output))

;; : (-> [[PooUserModuleSelection]])
(def (funflow-config-pipeline-module-bundles)
  (append poo-flow-custom-my-module-cicd-module
          poo-flow-custom-my-module-funflow-cicd-case))

;; : TestSuite
(def funflow-config-pipeline-performance-test
  (test-suite "funflow config pipeline performance"
    (test-case "keeps user-interface Funflow pipeline projection inside benchmark contract"
      (let-values (((receipt summary)
                    (benchmark-run/result
                     funflow-config-pipeline-fixture
                     (lambda ()
                       (funflow-performance-summary
                        (funflow-config-pipeline-module-bundles)
                        funflow-config-pipeline-scenario-count)))))
        (check-equal?
         (benchmark-fixture-contract-pass? funflow-config-pipeline-fixture)
         #t)
        (check-equal?
         (funflow-performance-summary-contract-pass? summary)
         #t)
        (funflow-config-pipeline-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
