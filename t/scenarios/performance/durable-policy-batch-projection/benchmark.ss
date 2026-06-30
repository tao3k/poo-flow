((max_total . 100ms)
 (maxCollectMs . 25)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 10)
 (observedCollectMs . 8)
 (observedParseMs . 0)
 (observedFileMs . 0)
 (observedPhaseMs . 6)
 (observed_total . 10ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 8ms)
 (observedTimings . (((name . collect-before) (durationMs . 5))
                     ((name . policy-before) (durationMs . 3))
                     ((name . collect-after) (durationMs . 4))
                     ((name . policy-after) (durationMs . 2))))
 (targetRationale . "durable policy projection is a shared hot path: session, memory, workflow, sandbox, and artifact policies must lower to fixed receipts before runtime handoff.")
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 3)
 (unit . "ms")
 (sourcePath . "t/scenarios/performance/durable-policy-batch-projection/benchmark.ss")
 (purpose . "observe POO durable policy batch projection into struct receipts and bounded alist ABI rows")
 (feature . durable-policy-batch-projection)
 (rule . POO-FLOW-DURABLE-POLICY-PERFORMANCE-001)
 (optimizationFocus . "POO durable authoring with defstruct runtime receipts and one bounded serialization pass")
 (inputShape . "sixty-four POO durable policy objects projected to struct receipts and bounded alists")
 (expectedRepair . "keep durable policy validation/projection batched; do not make runtime consumers traverse POO object graphs")
 (nativePooAuthoring . #t)
 (receiptRepresentation . defstruct)
 (adapterBoundary . "durable policy receipts are structs until ABI alist projection")
 (hotPathExemption . durable-policy-batch-projection)
 (hotPathEvidence native-poo-authoring
                  defstruct-runtime-receipt
                  durable-policy
                  batch-projection
                  bounded-alist-boundary
                  benchmark-contract)
 (expectedQualitySignals batch-projection
                         struct-durable-receipts
                         bounded-abi-rows
                         durable-performance-gate)
 (measurementPhases collect-before
                    policy-before
                    collect-after
                    policy-after
                    assert-time-gate
                    assert-memory-gate)
 (tags poo durable performance receipt-projection))
