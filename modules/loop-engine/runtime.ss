;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Public Loop Runtime orchestration owner.
;;; Focused owners hold the only implementations; this file only assembles the
;;; stable runtime surface used by config and downstream consumers.
(import "proof-abi.ss"
        "runtime-base.ss"
        "runtime-capability.ss"
        "runtime-agent.ss"
        "runtime-intent.ss"
        "runtime-projection.ss"
        "result-contract.ss")

(export make-loop-engine-capability-receipt
        loop-engine-capability-receipt?
        loop-engine-capability-receipt-backend
        loop-engine-capability-receipt-backend-kind
        loop-engine-capability-receipt-backend-capabilities
        loop-engine-capability-receipt-supported-backends
        loop-engine-capability-receipt-valid?
        loop-engine-capability-receipt-diagnostics
        loop-engine-capability-receipt-isolation
        loop-engine-capability-receipt-required
        loop-engine-capability-receipt-optional
        loop-engine-capability-receipt-unsupported-behavior
        loop-engine-capability-receipt-sandbox-ref
        loop-engine-capability-receipt-session-ref
        loop-engine-capability-receipt->alist
        poo-flow-user-loop-engine-primary-agent
        poo-flow-user-loop-engine-intent-status
        poo-flow-user-loop-engine-intent-operation-kind
        poo-flow-user-loop-engine-intent-result-contract
        poo-flow-user-loop-engine-result-contract-valid?
        poo-flow-user-loop-engine-result-contract-diagnostics
        poo-flow-user-loop-engine-intent-role-result-contract
        poo-flow-user-loop-engine-intent-operation-result-contract
        poo-flow-user-loop-engine-intent-agent-profiles
        poo-flow-user-loop-engine-intent-agent-harnesses
        poo-flow-user-loop-engine-intent-agent-sessions
        poo-flow-user-loop-engine-intent-session-agent-graph
        poo-flow-user-loop-engine-intent-session-agent-topology-trace
        poo-flow-user-loop-engine-intent-agent-operation
        poo-flow-user-loop-engine-intent-delegated-operation
        poo-flow-user-loop-engine-intent-dispatch-receipt
        poo-flow-user-loop-engine-intent-runtime-command-manifest
        poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
        poo-flow-user-loop-engine-intent-proof-manifest
        +poo-flow-loop-engine-proof-abi-version+
        +poo-flow-loop-engine-proof-obligation-tags+
        +poo-flow-loop-engine-proof-obligations+
        +poo-flow-loop-engine-proof-obligation-count+
        +poo-flow-loop-engine-proof-required-obligation-mask+
        +poo-flow-loop-engine-proof-abi-tag-width+
        poo-flow-loop-engine-proof-obligation
        poo-flow-loop-engine-proof-obligation-mask
        poo-flow-loop-engine-proof-c-abi
        poo-flow-loop-engine-proof-manifest
        poo-flow-user-loop-engine-intent-runtime-capability-descriptor
        poo-flow-user-loop-engine-intent-policy-profile-packet
        poo-flow-user-loop-engine-intent-runtime-action-packet
        poo-flow-user-loop-engine-intent-runtime-receipt-batch-template
        poo-flow-user-loop-engine-intent-workflow-agreement
        poo-flow-user-loop-engine-intent-runtime-envelope
        poo-flow-user-loop-engine-intent-runtime-handoff-facts
        poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
        poo-flow-user-loop-engine-intent-runtime-snapshot
        poo-flow-user-loop-engine-capability-receipt-ref
        poo-flow-user-loop-engine-capability-receipt->alist
        poo-flow-user-loop-engine-intent-workflow-run
        poo-flow-user-loop-engine-intent-runtime-intent
        poo-flow-user-loop-engine-intent-policy)
