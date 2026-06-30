;;; -*- Gerbil -*-
;;; Boundary: harness-backed structural contract tests.
;;; Invariant: unit root stays focused on small local behavior checks.

(import :poo-flow/t/module-object-validation-test
        :poo-flow/t/durable-runtime-store-contract-test
        :poo-flow/t/durable-runtime-store-backend-test
        :poo-flow/t/durable-runtime-store-operation-test
        :poo-flow/t/durable-recovery-scenario-test
        :poo-flow/t/memory-durable-job-receipt-test
        :poo-flow/t/module-system-facade-test
        :poo-flow/t/sandbox-core-resource-contract-test
        :poo-flow/t/session-policy-contract-test)
