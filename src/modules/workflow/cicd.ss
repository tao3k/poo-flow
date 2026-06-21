;;; -*- Gerbil -*-
;;; Boundary: public facade for workflow CI/CD declarations and runtime handoff facts.
;;; Invariant: CI/CD remains a workflow feature backed by POO objects.

(import :poo-flow/src/modules/workflow/cicd-core
        :poo-flow/src/modules/workflow/cicd-sandbox
        :poo-flow/src/modules/workflow/cicd-runtime)

(export +poo-flow-cicd-check-map-schema+
        +poo-flow-cicd-check-receipt-schema+
        +poo-flow-cicd-runtime-manifest-readiness-schema+
        +poo-flow-cicd-marlin-runtime-handoff-abi-schema+
        +poo-flow-cicd-marlin-runtime-owner+
        poo-flow-cicd-check-kind
        poo-flow-cicd-check-map-kind
        poo-flow-cicd-check
        poo-flow-cicd-check?
        poo-flow-cicd-check-map
        poo-flow-cicd-check-map?
        poo-flow-cicd-check-name
        poo-flow-cicd-check-profile
        poo-flow-cicd-check-command
        poo-flow-cicd-check-dependency-refs
        poo-flow-cicd-check-artifacts
        poo-flow-cicd-check-cache
        poo-flow-cicd-check-secrets
        poo-flow-cicd-check-runtime
        poo-flow-cicd-check-map-name
        poo-flow-cicd-check-map-checks
        poo-flow-cicd-check-profile-refs
        poo-flow-cicd-check-sandbox-runtime-summaries
        poo-flow-cicd-check-sandbox-handoff-summaries
        poo-flow-cicd-check-sandbox-unresolved-profile-refs
        poo-flow-cicd-check-map->dependency-graph
        poo-flow-cicd-check->receipt
        poo-flow-cicd-check-map->receipts
        poo-flow-cicd-check->runtime-manifest-readiness
        poo-flow-cicd-check-map->runtime-manifest-readiness
        poo-flow-cicd-check->runtime-command-manifest
        poo-flow-cicd-check-map->runtime-command-manifests
        poo-flow-cicd-runtime-command-manifest-map->marlin-runtime-handoff-abi
        poo-flow-cicd-check-map->marlin-runtime-handoff-abi)
