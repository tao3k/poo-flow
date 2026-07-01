;;; -*- Gerbil -*-
;;; Boundary: gxtest enters large benchmark fixtures through this performance root.
;;; Invariant: unit tests can run without loading performance fixture datasets.

(import :poo-flow/t/flow-strand-performance-test
        :poo-flow/t/durable-policy-performance-test
        :poo-flow/t/durable-recovery-scenario-performance-test
        :poo-flow/t/loop-engine-session-agent-graph-performance-test
        :poo-flow/t/loop-agent-descriptor-performance-test
        :poo-flow/t/loop-governor-performance-test
        :poo-flow/t/loop-human-audit-performance-test
        :poo-flow/t/loop-strategy-performance-test
        :poo-flow/t/memory-core-performance-test
        :poo-flow/t/module-extension-list-merge-performance-test
        :poo-flow/t/module-object-inheritance-chain-performance-test
        :poo-flow/t/module-object-list-merge-performance-test
        :poo-flow/t/module-objects-validation-summary-performance-test
        :poo-flow/t/module-system-poo-performance-test
        :poo-flow/t/session-agent-param-contract-performance-test
        :poo-flow/t/session-communication-receipt-performance-test
        :poo-flow/t/session-graph-performance-test
        :poo-flow/t/session-materialization-receipt-performance-test
        :poo-flow/t/session-policy-validation-performance-test
        :poo-flow/t/session-registry-receipt-performance-test
        :poo-flow/t/session-selector-receipt-performance-test
        :poo-flow/t/session-transform-performance-test
        :poo-flow/t/tool-core-performance-test
        :poo-flow/t/user-interface-custom-scenario-batch-performance-test
        :poo-flow/t/user-interface-presentation-performance-test)
