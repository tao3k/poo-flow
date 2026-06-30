((max_total . 100ms)
 (maxCollectMs . 100)
 (maxParseMs . 75)
 (maxFileMs . 25)
 (maxPhaseMs . 25)
 (observedCollectMs . 1)
 (observedParseMs . 1)
 (observedFileMs . 1)
 (observedPhaseMs . 20)
 (observed_total . 20ms)
 (target_total . 25ms)
 (regression_budget . 5ms)
 (expected_over_input_budget . 5ms)
 (observedTimings . (((name . collect-before) (durationMs . 12))
                     ((name . policy-before) (durationMs . 10))
                     ((name . collect-after) (durationMs . 11))
                     ((name . policy-after) (durationMs . 9))))
 (targetRationale . "durable recovery scenarios combine runtime-store, memory, session graph, communication, workflow, sandbox, and observability receipts before Marlin handoff.")
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 3)
 (unit . "ms")
 (sourcePath . "t/scenarios/performance/durable-recovery-scenario/benchmark.ss")
 (purpose . "observe crash/replay/repair scenario projection into bounded handoff rows")
 (feature . durable-recovery-scenario)
 (rule . POO-FLOW-DURABLE-RECOVERY-SCENARIO-PERFORMANCE-001)
 (optimizationFocus . "defstruct receipt projection with one bounded alist handoff")
 (inputShape . "ninety-six durable recovery scenario receipts projected from shared runtime-store and memory durable job rows")
 (expectedRepair . "keep recovery projection batched; do not make runtime consumers traverse POO object graphs")
 (nativePooAuthoring . #t)
 (receiptRepresentation . defstruct)
 (adapterBoundary . "durable recovery scenario rows are report-only ABI alists at Marlin handoff")
 (hotPathExemption . durable-recovery-scenario)
 (hotPathEvidence durable-recovery
                  runtime-store-receipt
                  memory-durable-job
                  session-agent-graph
                  observability-rows
                  bounded-alist-boundary
                  benchmark-contract)
 (expectedQualitySignals batch-projection
                         valid-recovery-scenarios
                         recovery-observability
                         durable-recovery-performance-gate)
 (measurementPhases collect-before
                    policy-before
                    collect-after
                    policy-after
                    assert-time-gate
                    assert-memory-gate)
 (tags durable recovery performance scenario receipt-projection))
