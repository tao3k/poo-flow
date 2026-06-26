;;; -*- Gerbil -*-
;;; Boundary: gxtest enters the package through this stable unit test root.
;;; Performance gates live in t/performance-tests.ss so ordinary unit runs do
;;; not load large benchmark fixtures.
;;; Integration workflows live in t/integration-tests.ss.
;;; Harness-backed structural contracts live in t/contract-tests.ss.

(import :poo-flow/t/agent-sandbox-descriptor-test
        :poo-flow/t/agent-sandbox-bridge-test
        :poo-flow/t/agent-sandbox-cube-interface-test
        :poo-flow/t/agent-sandbox-marlin-interface-test
        :poo-flow/t/agent-harness-object-test
        :poo-flow/t/agent-sandbox-profile-test
        :poo-flow/t/cli-test
        :poo-flow/t/config-test
        :poo-flow/t/control-plane-role-test
        :poo-flow/t/control-plane-test
        :poo-flow/t/descriptor-registry-test
        :poo-flow/t/docker-descriptor-test
        :poo-flow/t/failure-test
        :poo-flow/t/flow-descriptor-test
        :poo-flow/t/functional-flow-kernel-test
        :poo-flow/t/functional-flow-kleisli-test
        :poo-flow/t/loop-engine-policy-extension-test
        :poo-flow/t/loop-agent-descriptor-test
        :poo-flow/t/loop-governor-test
        :poo-flow/t/loop-strategy-test
        :poo-flow/t/module-system-lazy-loader-test
        :poo-flow/t/module-system-observability-test
        :poo-flow/t/module-object-practice-test
        :poo-flow/t/module-system-test
        :poo-flow/t/nono-sandbox-c-binding-test
        :poo-flow/t/nono-sandbox-c-language-test
        :poo-flow/t/nono-sandbox-native-ffi-test
        :poo-flow/t/sandbox-resource-test
        :poo-flow/t/session-object-test
        :poo-flow/t/session-transform-test
        :poo-flow/t/task-family-descriptor-test)
