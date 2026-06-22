;;; -*- Gerbil -*-
;;; Boundary: loop-engine operational policy-extension declarations.
;;; Invariant: these POO objects lower to report-only receipts; runtime
;;; enforcement remains owned by Marlin.

(import (only-in :clan/poo/object .o)
        :poo-flow/src/module-system/loop-engine-policy-extension-contract
        :poo-flow/src/module-system/loop-engine-policy-extension-receipt)

(export +poo-flow-user-loop-engine-policy-extension-prototype-kind+
        loop-engine-policy-extension
        loop-engine-coordination-policy-extension
        loop-engine-observability-policy-extension
        loop-engine-safety-policy-extension
        poo-flow-user-loop-engine-poo-policy-extensions->receipts)

;;; Policy extension objects let operational policy families project report-only
;;; receipts without teaching the runtime core about each concrete family.
;; : PooFlowLoopEnginePolicyExtensionPrototype
(def loop-engine-policy-extension
  (.o kind: +poo-flow-user-loop-engine-policy-extension-prototype-kind+
      name: #f
      receipt-kind: #f
      contract: #f
      scope: #f
      entries: '()
      runtime-executed: #f))

;;; Coordination is a concrete policy-extension prototype over the generic
;;; receipt channel. Scheme declares collision intent; Marlin enforces it.
;; : PooFlowLoopEngineCoordinationPolicyExtensionPrototype
(def loop-engine-coordination-policy-extension
  (.o (:: @ loop-engine-policy-extension)
      receipt-kind: 'coordination-receipt
      contract: 'poo-flow.loop-engine.coordination-receipt.v1
      priority: '()
      state-files: '()
      acting-on-key: #f
      conflict-action: #f
      branch-lock-scope: #f
      human-inbox: #f))

;;; Observability extension declares run-log and lifecycle signals without
;;; scheduling, pausing, or killing loops from Scheme.
;; : PooFlowLoopEngineObservabilityPolicyExtensionPrototype
(def loop-engine-observability-policy-extension
  (.o (:: @ loop-engine-policy-extension)
      receipt-kind: 'observability-receipt
      contract: 'poo-flow.loop-engine.observability-receipt.v1
      run-log: #f
      run-log-schema: '()
      budget-path: #f
      metric-keys: '()
      retention-window: #f
      slow-signals: '()
      pause-signals: '()
      kill-signals: '()))

;;; Safety extension declares path, connector, and human gate policy as
;;; report-only guardrail facts for the runtime owner.
;; : PooFlowLoopEngineSafetyPolicyExtensionPrototype
(def loop-engine-safety-policy-extension
  (.o (:: @ loop-engine-policy-extension)
      receipt-kind: 'safety-receipt
      contract: 'poo-flow.loop-engine.safety-receipt.v1
      denylist-paths: '()
      allowlist-paths: '()
      human-gates: '()
      connector-scopes: '()
      auto-merge: #f
      max-attempts: #f))
