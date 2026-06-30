((max_total . 100ms)
 (maxCollectMs . 25)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 10)
 (observedCollectMs . 10)
 (observedParseMs . 0)
 (observedFileMs . 0)
 (observedPhaseMs . 8)
 (observed_total . 12ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 8ms)
 (observedTimings . (((name . "collect-before") (durationMs . 8))
                     ((name . "policy-before") (durationMs . 4))
                     ((name . "collect-after") (durationMs . 7))
                     ((name . "policy-after") (durationMs . 3))))
 (targetRationale . "user-interface presentation batch projection is a hot path: repeated loop-engine receipts must stay below the shared 100ms hard ceiling.")
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 3)
 (unit . "ms")
 (purpose . "observe user-interface presentation projection over repeated loop-engine modules")
 (feature . user-interface-presentation-batch-projection)
 (rule . POO-FLOW-USER-INTERFACE-PERFORMANCE-001)
 (optimizationFocus . "batch field projection for loop-engine and workflow-cicd presentation slots")
 (inputShape . "eight real custom loop-engine user-interface module declarations projected through pooFlowUserConfigPresentation")
 (expectedRepair . "walk intent/check rows once per presentation family, keep generated capability receipts as fixed structs, and serialize only runtime handoff ABI payloads")
 (nativePooAuthoring . #t)
 (receiptRepresentation . defstruct)
 (adapterBoundary . "presentation loop-engine capability receipts are structs; runtime handoff capability receipts are alists")
 (hotPathExemption . user-interface-presentation-batch-projection)
 (hotPathEvidence native-poo-authoring
                  defstruct-runtime-receipt
                  user-interface-presentation
                  batch-field-projection
                  scalar-summary
                  adapter-boundary
                  benchmark-contract)
 (optimizerVisibility . "presentation-config names field sets and performs one batch projection per row family instead of one traversal per public slot")
 (expectedQualitySignals batch-field-projection
                         struct-capability-receipts
                         serialized-runtime-handoff-boundary
                         user-interface-performance-gate)
 (learnedStyleSources
  "agent-semantic-protocols/languages/gerbil-scheme-language-project-harness/t/scenarios/policy/list-random-access-loop-performance/benchmark.ss"
  "agent-semantic-protocols/languages/gerbil-scheme-language-project-harness/t/scenarios/policy/poo-real-dashboard-workflow-performance/benchmark.ss"
  "agent-semantic-protocols/languages/gerbil-scheme-language-project-harness/t/scenarios/policy/poo-marlin-config-interface-large-object-performance/benchmark.ss")
 (styleRewriteBoundary . "do not reintroduce per-slot repeated scans over loop-engine-intent-rows or workflow-cicd check rows without tightening this benchmark")
 (measurementPhases collect-before
                    collect-after
                    policy-before
                    policy-after
                    assert-time-gate
                    assert-memory-gate)
 (tags poo user-interface presentation performance))
