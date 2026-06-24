;;; -*- Gerbil -*-
;;; Boundary: gxtest enters workflow, tutorial, runtime, and UI integration cases here.
;;; Invariant: the unit root stays focused on local contracts and small object checks.

(import :poo-flow/t/funflow-config-pipeline-test
        :poo-flow/t/funflow-tutorial-alignment-report-test
        :poo-flow/t/workflow-cicd-check-map-test
        :poo-flow/t/workflow-cicd-runtime-handoff-test
        :poo-flow/t/agent-sandbox-profile-user-interface-test
        :poo-flow/t/module-object-catalog-validation-test
        :poo-flow/t/module-object-load-validation-test
        :poo-flow/t/module-system-kernel-profile-test
        :poo-flow/t/module-system-user-interface-test
        :poo-flow/t/nono-sandbox-live-profile-test
        :poo-flow/t/runtime-bridge-test
        :poo-flow/t/runtime-manifest-test
        :poo-flow/t/sandbox-core-profile-authoring-diagnostics-test
        :poo-flow/t/store-funflow-alignment-test
        :poo-flow/t/tutorial-feature-batch-test
        :poo-flow/t/tutorial-makefile-runtime-test
        :poo-flow/t/tutorial-runtime-result-test
        :poo-flow/t/tutorial-result-test
        :poo-flow/t/declaration-case-test
        :poo-flow/t/user-interface-config-test
        :poo-flow/t/user-interface-custom-loop-engine-capability-test
        :poo-flow/t/user-interface-custom-loop-engine-memory-policy-test
        :poo-flow/t/user-interface-custom-loop-engine-profile-test
        :poo-flow/t/user-interface-custom-loop-engine-result-contract-test
        :poo-flow/t/user-interface-custom-loop-engine-runtime-manifest-test
        :poo-flow/t/user-interface-custom-loop-engine-slot-contract-test
        :poo-flow/t/user-interface-custom-loop-engine-test
        :poo-flow/t/user-interface-custom-loop-sandbox-agreement-test
        :poo-flow/t/user-interface-custom-loop-workflow-agreement-test
        :poo-flow/t/user-interface-presentation-test
        :poo-flow/t/user-interface-live-cicd-case-test
        :poo-flow/t/user-interface-cicd-test
        :poo-flow/t/user-interface-cicd-pipeline-run-test
        :poo-flow/t/user-interface-cicd-runtime-projection-test
        :poo-flow/t/user-interface-cicd-runtime-graph-test)
