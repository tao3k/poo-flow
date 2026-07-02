;;; -*- Gerbil -*-
;;; Thin POO Flow testing project declaration shared by runtime test commands.

(import :gslph/src/testing/build)

(export poo-flow-testing-project)

;; : (-> GxTestSuiteSpec GxTestSuiteSupportSpec)
(def (poo-flow-suite-support spec)
  (let (suite-name (car spec))
    (cons suite-name
          (if (equal? suite-name "performance")
            ["t/support/performance.ss"
             "t/support/poo-performance.ss"]
            ["t/user-interface-fixtures.ss"
             "t/fixtures/object-load-valid/objects.ss"
             "t/support/loop-engine-runtime-manifest-receipts.ss"]))))

;; : (-> ProjectRoot ContractRoot PooFlowTestingProject)
(def (poo-flow-testing-project root contract-root)
  (let (gxtest-suites
        [["unit" "t/unit-tests.ss"]
         ["contract" "t/contract-tests.ss"]
         ["scenario-funflow-cicd" "t/user-interface-cicd-test.ss"]
         ["scenario-loop-workflow-agreement" "t/user-interface-custom-loop-workflow-agreement-test.ss"]
         ["scenario-loop-sandbox-agreement" "t/user-interface-custom-loop-sandbox-agreement-test.ss"]
         ["scenario-loop-session-agent-topology" "t/user-interface-custom-loop-engine-test.ss"]
         ["scenario-session-transform" "t/user-interface-custom-session-transform-test.ss"]
         ["scenario-session-registry" "t/user-interface-custom-session-registry-test.ss"]
         ["scenario-session-agent-graph" "t/user-interface-custom-session-agent-graph-test.ss"]
         ["scenario-session-communication" "t/user-interface-custom-session-communication-test.ss"]
         ["scenario-session-policy" "t/user-interface-custom-session-policy-test.ss"]
         ["scenario-session-selector" "t/user-interface-custom-session-selector-test.ss"]
         ["scenario-session-materialization" "t/user-interface-custom-session-materialization-test.ss"]
         ["scenario-session-agent-param" "t/user-interface-custom-session-agent-param-test.ss"]
         ["scenario-session-memory-durable" "t/user-interface-custom-session-memory-durable-test.ss"]
         ["scenario-tool-core" "t/user-interface-custom-tool-core-test.ss"]
         ["scenario-memory-core" "t/user-interface-custom-memory-core-test.ss"]
         ["scenario-durable-recovery" "t/user-interface-custom-durable-recovery-test.ss"]
         ["scenario-user-interface-sandbox-config" "t/user-interface-sandbox-config-performance-test.ss"]
         ["scenario-user-interface-custom-scenario-batch" "t/user-interface-custom-scenario-batch-performance-test.ss"]
         ["integration" "t/integration-tests.ss"]
         ["performance" "t/performance-tests.ss"]])
    (testing-build
     name: "poo-flow"
     root: root
     contract-root: contract-root
     gxtest: gxtest-suites
     suite-support-files: (map poo-flow-suite-support gxtest-suites)
     support-directories: ["t/module-system-poo-performance-test-support"]
     roots: ["src" "user-interface" "t"]
     policy: #t
     batch-size: 2
     max-selected-files: 4
     max-selected-sources: 8
     max-selected-outputs: 8)))
