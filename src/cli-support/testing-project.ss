;;; -*- Gerbil -*-
;;; Thin POO Flow testing project declaration shared by runtime test commands.

(import :gslph/src/testing/build)

(export +poo-flow-testing-project+)

(def +poo-flow-testing-project+
  (testing-build
   name: "poo-flow"
   root: "."
   contract-root: "."
   gxtest: [["unit" "t/unit-tests.ss"]
            ["contract" "t/contract-tests.ss"]
            ["integration" "t/integration-tests.ss"]
            ["performance" "t/performance-tests.ss"]]
   support-files: ["t/support/performance.ss"
                   "t/support/poo-performance.ss"
                   "t/user-interface-fixtures.ss"
                   "t/fixtures/object-load-valid/objects.ss"
                   "t/module-system-poo-performance-test-support/contracts.ss"
                   "t/module-system-poo-performance-test-support/objects.ss"
                   "t/module-system-poo-performance-test-support/extensions.ss"]
   support-output-root: ".gerbil/lib/poo-flow"
   roots: ["src" "user-interface" "t"]
   import-prefix: ":poo-flow/t/"
   policy-file: "t/poo-flow-policy-test.ss"
   scope-env: "POO_FLOW_TEST_FILES"
   batch-size: 2
   max-selected-files: 4
   max-selected-sources: 8
   max-selected-outputs: 8))
