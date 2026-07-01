;;; -*- Gerbil -*-
;;; Boundary: gxtest enters large benchmark fixtures through this performance root.
;;; Invariant: unit tests can run without loading performance fixture datasets.

(import (only-in :std/test run-tests!)
        (rename-in :poo-flow/t/flow-strand-performance-test
                   (flow-strand-performance-test
                    flow-strand-performance-suite))
        (rename-in :poo-flow/t/durable-policy-performance-test
                   (durable-policy-performance-test
                    durable-policy-performance-suite))
        (rename-in :poo-flow/t/durable-recovery-scenario-performance-test
                   (durable-recovery-scenario-performance-test
                    durable-recovery-scenario-performance-suite))
        (rename-in :poo-flow/t/funflow-config-pipeline-performance-test
                   (funflow-config-pipeline-performance-test
                    funflow-config-pipeline-performance-suite))
        (rename-in :poo-flow/t/loop-engine-session-agent-graph-performance-test
                   (loop-engine-session-agent-graph-performance-test
                    loop-engine-session-agent-graph-performance-suite))
        (rename-in :poo-flow/t/loop-agent-descriptor-performance-test
                   (loop-agent-descriptor-performance-test
                    loop-agent-descriptor-performance-suite))
        (rename-in :poo-flow/t/loop-governor-performance-test
                   (loop-governor-performance-test
                    loop-governor-performance-suite))
        (rename-in :poo-flow/t/loop-human-audit-performance-test
                   (loop-human-audit-performance-test
                    loop-human-audit-performance-suite))
        (rename-in :poo-flow/t/loop-strategy-performance-test
                   (loop-strategy-performance-test
                    loop-strategy-performance-suite))
        (rename-in :poo-flow/t/memory-core-performance-test
                   (memory-core-performance-test
                    memory-core-performance-suite))
        (rename-in :poo-flow/t/module-extension-list-merge-performance-test
                   (module-extension-list-merge-performance-test
                    module-extension-list-merge-performance-suite))
        (rename-in :poo-flow/t/module-object-inheritance-chain-performance-test
                   (module-object-inheritance-chain-performance-test
                    module-object-inheritance-chain-performance-suite))
        (rename-in :poo-flow/t/module-object-list-merge-performance-test
                   (module-object-list-merge-performance-test
                    module-object-list-merge-performance-suite))
        (rename-in :poo-flow/t/module-objects-validation-summary-performance-test
                   (module-objects-validation-summary-performance-test
                    module-objects-validation-summary-performance-suite))
        (rename-in :poo-flow/t/module-system-poo-performance-test
                   (module-system-poo-performance-test
                    module-system-poo-performance-suite))
        (rename-in :poo-flow/t/session-agent-param-contract-performance-test
                   (session-agent-param-contract-performance-test
                    session-agent-param-contract-performance-suite))
        (rename-in :poo-flow/t/session-communication-receipt-performance-test
                   (session-communication-receipt-performance-test
                    session-communication-receipt-performance-suite))
        (rename-in :poo-flow/t/session-graph-performance-test
                   (session-graph-performance-test
                    session-graph-performance-suite))
        (rename-in :poo-flow/t/session-materialization-receipt-performance-test
                   (session-materialization-receipt-performance-test
                    session-materialization-receipt-performance-suite))
        (rename-in :poo-flow/t/session-policy-family-performance-test
                   (session-policy-family-performance-test
                    session-policy-family-performance-suite))
        (rename-in :poo-flow/t/session-policy-validation-performance-test
                   (session-policy-validation-performance-test
                    session-policy-validation-performance-suite))
        (rename-in :poo-flow/t/session-registry-receipt-performance-test
                   (session-registry-receipt-performance-test
                    session-registry-receipt-performance-suite))
        (rename-in :poo-flow/t/session-selector-receipt-performance-test
                   (session-selector-receipt-performance-test
                    session-selector-receipt-performance-suite))
        (rename-in :poo-flow/t/session-transform-performance-test
                   (session-transform-performance-test
                    session-transform-performance-suite))
        (rename-in :poo-flow/t/tool-core-performance-test
                   (tool-core-performance-test
                    tool-core-performance-suite))
        (rename-in :poo-flow/t/user-interface-sandbox-config-performance-test
                   (user-interface-sandbox-config-performance-test
                    user-interface-sandbox-config-performance-suite))
        (rename-in :poo-flow/t/user-interface-custom-scenario-batch-performance-test
                   (user-interface-custom-scenario-batch-performance-test
                    user-interface-custom-scenario-batch-performance-suite))
        (rename-in :poo-flow/t/user-interface-presentation-performance-test
                   (user-interface-presentation-performance-test
                    user-interface-presentation-performance-suite)))

(run-tests! flow-strand-performance-suite)
(run-tests! durable-policy-performance-suite)
(run-tests! durable-recovery-scenario-performance-suite)
(run-tests! funflow-config-pipeline-performance-suite)
(run-tests! loop-engine-session-agent-graph-performance-suite)
(run-tests! loop-agent-descriptor-performance-suite)
(run-tests! loop-governor-performance-suite)
(run-tests! loop-human-audit-performance-suite)
(run-tests! loop-strategy-performance-suite)
(run-tests! memory-core-performance-suite)
(run-tests! module-extension-list-merge-performance-suite)
(run-tests! module-object-inheritance-chain-performance-suite)
(run-tests! module-object-list-merge-performance-suite)
(run-tests! module-objects-validation-summary-performance-suite)
(run-tests! module-system-poo-performance-suite)
(run-tests! session-agent-param-contract-performance-suite)
(run-tests! session-communication-receipt-performance-suite)
(run-tests! session-graph-performance-suite)
(run-tests! session-materialization-receipt-performance-suite)
(run-tests! session-policy-family-performance-suite)
(run-tests! session-policy-validation-performance-suite)
(run-tests! session-registry-receipt-performance-suite)
(run-tests! session-selector-receipt-performance-suite)
(run-tests! session-transform-performance-suite)
(run-tests! tool-core-performance-suite)
(run-tests! user-interface-sandbox-config-performance-suite)
(run-tests! user-interface-custom-scenario-batch-performance-suite)
(run-tests! user-interface-presentation-performance-suite)
