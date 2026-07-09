;;; -*- Gerbil -*-
;;; Thin POO Flow testing project declaration shared by runtime test commands.

(import :gslph/src/testing/build)

(export poo-flow-testing-project)

;; : [String]
(def +poo-flow-harness-policy-scenarios+
  ["harness-policy-performance-fixture-gates.org"
   "harness-policy-poo-big-o-scenarios.org"
   "harness-policy-composition-observability.org"
   "harness-policy-build-cache-freshness.org"
   "harness-policy-user-interface-composition.org"
   "harness-policy-runtime-boundary.org"])

;; : Alist
(def +poo-flow-harness-policy-scenario-metadata+
  `(("harness-policy-performance-fixture-gates.org"
     .
     ((downstreamRepairTarget . "t/support/poo-performance.ss")
      (idiom . "GSLPH testing-build policy scenario")
      (expectedRepair . "Performance fixtures must enter poo-performance-run-gate through the full local policy contract.")
      (benchmarkPhases . (assert-time-gate assert-memory-gate assert-policy-evidence))
      (nextRepairAction . "Reject missing fixture evidence before benchmark execution.")))
    ("harness-policy-composition-observability.org"
     .
     ((downstreamRepairTarget . "t/module-system-poo-performance-test-support/composition-scenarios.ss")
      (idiom . "composition construction-count gate")
      (expectedRepair . "Macro-expanded POO composition must be constructed once outside the hot benchmark loop.")
      (benchmarkPhases . (construct-once validate-hot-path assert-receipt))
      (nextRepairAction . "Keep construction-count equal to 1 for every composition scenario.")))
    ("harness-policy-poo-big-o-scenarios.org"
     .
     ((downstreamRepairTarget . "t/scenarios/performance/poo-big-o-scenario-coverage.org")
      (idiom . "GSLPH input/expected scenario families")
      (expectedRepair . "POO Big-O benchmarks must include downstream input and optimized expected repair files.")
      (benchmarkPhases . (declare-input declare-expected assert-family-contract))
      (nextRepairAction . "Reject benchmark-only POO performance scenarios as incomplete.")))
    ("harness-policy-build-cache-freshness.org"
     .
     ((downstreamRepairTarget . "src/cli-support/package-build.ss")
      (idiom . "primary output freshness gate")
      (expectedRepair . "Build cache stamps must not hide stale .ssi or .scm outputs.")
      (benchmarkPhases . (assert-stamp assert-primary-outputs assert-receipt))
      (nextRepairAction . "Require primary source/output freshness before stamp-current or receipt-current.")))
    ("harness-policy-user-interface-composition.org"
     .
     ((downstreamRepairTarget . "user-interface/cases")
      (idiom . "Doom-style declarative composition")
      (expectedRepair . "User composition cases must stay native POO object based and reusable.")
      (benchmarkPhases . (declare-profile compose-profile assert-native-poo))
      (nextRepairAction . "Reject drift back to raw alist or lambda patch DSLs.")))
    ("harness-policy-runtime-boundary.org"
     .
     ((downstreamRepairTarget . "src/core/runtime-protocol.ss")
      (idiom . "Scheme control plane to runtime language boundary")
      (expectedRepair . "Runtime execution remains outside Scheme while policy receipts stay typed and proof-addressable.")
      (benchmarkPhases . (declare-policy project-receipt handoff-runtime))
      (nextRepairAction . "Keep runtime handoff explicit and receipt-backed.")))))

;; : [String]
(def +poo-flow-harness-support-files+
  ["t/support/performance.ss"
   "t/support/json-schema-contract-performance.ss"
   "t/support/type-contract-performance.ss"
   "t/support/poo-performance.ss"
   "t/support/loop-engine-runtime-manifest-receipts.ss"
   "t/module-system-poo-performance-test-support/composition-gates.ss"
   "t/module-system-poo-performance-test-support/composition-large-library.ss"
   "t/module-system-poo-performance-test-support/composition-scenarios.ss"
   "t/module-system-poo-performance-test-support/extensions.ss"
   "t/module-system-poo-performance-test-support/contracts.ss"
   "t/module-system-poo-performance-test-support/projection.ss"
   "t/module-system-poo-performance-test-support/objects.ss"
   "t/module-system-poo-performance-test-support/composition.ss"
   "t/module-system-poo-performance-test-support/tool-calling.ss"])

;; : (-> [String] [String])
(def (poo-flow-common-suite-support extra)
  (append extra +poo-flow-harness-support-files+))

;; : (-> GxTestSuiteSpec GxTestSuiteSupportSpec)
(def (poo-flow-suite-support spec)
  (let (suite-name (car spec))
    (cons suite-name
          (cond
           ((equal? suite-name "performance")
            (poo-flow-common-suite-support []))
           ((equal? suite-name "scenario-user-interface-profile-library")
            (poo-flow-common-suite-support []))
           ((equal? suite-name "scenario-agent-lifecycle-gate")
            (poo-flow-common-suite-support []))
           ((equal? suite-name "scenario-poo-flow-composition")
            (poo-flow-common-suite-support []))
           ((equal? suite-name "scenario-boundary-namespace")
            [])
           ((equal? suite-name "scenario-observability-feedback")
            [])
           ((equal? suite-name "scenario-utilities-contracts")
            [])
           ((equal? suite-name "scenario-utilities-functional")
            [])
           ((equal? suite-name "scenario-json-schema-contract-bridge")
            [])
           ((equal? suite-name "scenario-funflow-github-ci-json-schema-contract")
            [])
           ((equal? suite-name "scenario-json-schema-contract-performance")
            (poo-flow-common-suite-support []))
           ((equal? suite-name "scenario-sandbox-resource-utilities-contract")
            [])
           ((equal? suite-name "scenario-graph-utilities-contract")
            [])
           ((equal? suite-name "scenario-loop-governor-utilities-contract")
            [])
           ((equal? suite-name "scenario-loop-human-audit-utilities-contract")
            [])
           ((equal? suite-name "scenario-session-policy-utilities-contract")
            [])
           ((equal? suite-name "scenario-type-facts-contract-projection")
            [])
           (else
            (poo-flow-common-suite-support
             ["t/user-interface-fixtures.ss"
              "t/fixtures/object-load-valid/objects.ss"]))))))

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
         ["scenario-user-interface-profile-library" "t/scenarios/user-interface-profile-library-gate-test.ss"]
         ["scenario-agent-lifecycle-gate" "t/scenarios/agent-lifecycle-gate-test.ss"]
         ["scenario-poo-flow-composition" "t/scenarios/poo-flow-composition-test.ss"]
         ["scenario-boundary-namespace" "t/boundary-namespace-test.ss"]
         ["scenario-observability-feedback" "t/observability-feedback-test.ss"]
         ["scenario-utilities-contracts" "t/utilities-contracts-test.ss"]
         ["scenario-utilities-functional" "t/utilities-functional-test.ss"]
         ["scenario-json-schema-contract-bridge" "t/json-schema-contract-bridge-test.ss"]
         ["scenario-funflow-github-ci-json-schema-contract" "t/funflow-github-ci-json-schema-contract-test.ss"]
         ["scenario-json-schema-contract-performance" "t/json-schema-contract-performance-test.ss"]
         ["scenario-sandbox-resource-utilities-contract" "t/sandbox-resource-utilities-contract-test.ss"]
         ["scenario-graph-utilities-contract" "t/graph-utilities-contract-test.ss"]
         ["scenario-loop-governor-utilities-contract" "t/loop-governor-utilities-contract-test.ss"]
         ["scenario-loop-human-audit-utilities-contract" "t/loop-human-audit-utilities-contract-test.ss"]
         ["scenario-session-policy-utilities-contract" "t/session-policy-utilities-contract-test.ss"]
         ["scenario-type-facts-contract-projection" "t/type-facts-contract-projection-test.ss"]
         ["integration" "t/integration-tests.ss"]
         ["performance" "t/performance-tests.ss"]])
    (testing-build
     name: "poo-flow"
     root: root
     contract-root: contract-root
     gxtest: gxtest-suites
     suite-support-files: (map poo-flow-suite-support gxtest-suites)
     support-directories: []
     scenarios: +poo-flow-harness-policy-scenarios+
     scenario-metadata: +poo-flow-harness-policy-scenario-metadata+
     scenario-root: "t/scenarios/policy"
     scenario-suite-name: "policy-scenarios"
     roots: ["src" "user-interface" "t"]
     policy: #t
     batch-size: 2
     max-selected-files: 4
     max-selected-sources: 8
     max-selected-outputs: 8)))
