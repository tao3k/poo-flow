;;; -*- Gerbil -*-
;;; Boundary: loop-engine runtime handoff vocabulary and schema ids.
;;; Invariant: constants are data contracts only, not executable callbacks.

(export +poo-flow-user-loop-engine-handoff-contracts+
        +poo-flow-user-loop-engine-runtime-command-contract+
        +poo-flow-user-loop-engine-result-contract+
        +poo-flow-user-loop-engine-default-result-contract+
        +poo-flow-user-loop-engine-result-contract-roles+
        +poo-flow-user-loop-engine-receipt-contracts+
        +poo-flow-user-loop-engine-runtime-capability-descriptor-contract+
        +poo-flow-user-loop-engine-policy-profile-packet-contract+
        +poo-flow-user-loop-engine-runtime-action-packet-contract+
        +poo-flow-user-loop-engine-runtime-receipt-batch-contract+
        +poo-flow-user-loop-engine-runtime-packet-contracts+
        +poo-flow-user-loop-engine-runtime-command-name+
        +poo-flow-user-loop-engine-runtime-command-executable+
        +poo-flow-user-loop-engine-runtime-command-arguments+
        +poo-flow-user-loop-engine-runtime-object-families+)

;;; Runtime handoff contracts are names, not function pointers. Scheme exposes
;;; the command shape that Rust or another runtime can implement later.
;; : [Symbol]
(def +poo-flow-user-loop-engine-handoff-contracts+
  '(start-workflow-run
    admit-dispatch
    open-agent-session
    execute-agent-operation
    stream-events
    read-runtime-snapshot))

;;; The runtime command contract is a schema identifier shared with Marlin. It
;;; must stay data-only so Scheme never claims runtime implementation ownership.
;; : Symbol
(def +poo-flow-user-loop-engine-runtime-command-contract+
  'poo-flow.loop-governor.runtime-command-manifest.v1)

;;; Result contracts are schema identifiers for reviewer output. They stay
;;; separate from the runtime-command manifest so agents can audit structured
;;; result expectations before Marlin executes an operation.
;; : Symbol
(def +poo-flow-user-loop-engine-result-contract+
  'poo-flow.loop-governor.result-contract.v1)

;; : Symbol
(def +poo-flow-user-loop-engine-default-result-contract+
  'poo-flow.loop-governor.node-result.v1)

;; : [Symbol]
(def +poo-flow-user-loop-engine-result-contract-roles+
  '(default auditor verifier reviewer governor human-audit))

;;; Receipt contracts are stable data schemas that Marlin can consume without
;;; guessing which report-only rows accompany a loop-engine handoff.
;; : Alist
(def +poo-flow-user-loop-engine-receipt-contracts+
  '((lineage-receipt
     . poo-flow.loop-engine.lineage-receipt.v1)
    (selector-receipt
     . poo-flow.loop-engine.selector-receipt.v1)
    (session-agent-graph
     . poo-flow.modules.session.agent-graph.v1)
    (resource-dispatch-receipt
     . poo-flow.loop-engine.resource-dispatch-receipt.v1)
    (capability-receipt
     . poo-flow.loop-engine.capability-receipt.v1)
    (memory-receipt
     . poo-flow.loop-engine.memory-receipt.v1)
    (compression-receipt
     . poo-flow.loop-engine.compression-receipt.v1)
    (policy-extension-receipt
     . poo-flow.loop-engine.policy-extension-receipt.v1)
    (spec-evolution-review
     . poo-flow.spec-evolution.review-item.v1)
    (spec-evolution-runtime-manifest-row
     . poo-flow.spec-evolution.runtime-manifest-row.v1)
    (runtime-capability-descriptor
     . poo-flow.runtime.capability-descriptor.v1)
    (policy-profile-packet
     . poo-flow.runtime.policy-profile-packet.v1)
    (runtime-action-packet
     . poo-flow.runtime.action-packet.v1)
    (runtime-receipt-batch
     . poo-flow.runtime.receipt-batch.v1)
    (sandbox-handoff-agreement
     . poo-flow.loop-engine.sandbox-handoff-agreement.v1)))

;;; Pressure-relief packet contracts are the Marlin-facing ABI reduction layer:
;;; they describe normalized policy facts, not user-authored POO objects.
;; : Symbol
(def +poo-flow-user-loop-engine-runtime-capability-descriptor-contract+
  'poo-flow.runtime.capability-descriptor.v1)

;; : Symbol
(def +poo-flow-user-loop-engine-policy-profile-packet-contract+
  'poo-flow.runtime.policy-profile-packet.v1)

;; : Symbol
(def +poo-flow-user-loop-engine-runtime-action-packet-contract+
  'poo-flow.runtime.action-packet.v1)

;; : Symbol
(def +poo-flow-user-loop-engine-runtime-receipt-batch-contract+
  'poo-flow.runtime.receipt-batch.v1)

;; : Alist
(def +poo-flow-user-loop-engine-runtime-packet-contracts+
  `((runtime-capability-descriptor
     . ,+poo-flow-user-loop-engine-runtime-capability-descriptor-contract+)
    (policy-profile-packet
     . ,+poo-flow-user-loop-engine-policy-profile-packet-contract+)
    (runtime-action-packet
     . ,+poo-flow-user-loop-engine-runtime-action-packet-contract+)
    (runtime-receipt-batch
     . ,+poo-flow-user-loop-engine-runtime-receipt-batch-contract+)))

;;; The command name is stable receipt vocabulary for handoff manifests, not an
;;; executable selector or shell command.
;; : Symbol
(def +poo-flow-user-loop-engine-runtime-command-name+
  'loop-engine-runtime-handoff)

;; : String
(def +poo-flow-user-loop-engine-runtime-command-executable+
  "marlin-agent-core")

;; : [String]
(def +poo-flow-user-loop-engine-runtime-command-arguments+
  '("poo-flow" "runtime" "loop-engine-handoff"))

;;; Object family names document which control-plane projections the runtime
;;; must understand when it consumes a loop-engine handoff.
;; : [Symbol]
(def +poo-flow-user-loop-engine-runtime-object-families+
  '(agent-profile
    agent-harness
    agent-session
    session-agent-graph
    workflow-run
    dispatch-receipt
    agent-operation
    lineage-receipt
    selector-receipt
    resource-dispatch-receipt
    capability-receipt
    memory-receipt
    compression-receipt
    policy-extension-receipt
    spec-evolution-review-item
    spec-evolution-runtime-manifest-row
    runtime-capability-descriptor
    policy-profile-packet
    runtime-action-packet
    runtime-receipt-batch
    runtime-snapshot))
