;;; -*- Gerbil -*-
;;; Boundary: public loop-engine POO prototype objects.
;;; Invariant: prototypes are declaration data and never execute runtime work.

(import (only-in :clan/poo/object .o))

(export +poo-flow-user-loop-engine-use-case-prototype-kind+
        +poo-flow-user-loop-engine-governor-prototype-kind+
        +poo-flow-user-loop-engine-agent-judges-prototype-kind+
        +poo-flow-user-loop-engine-human-audit-prototype-kind+
        +poo-flow-user-loop-engine-schedule-prototype-kind+
        +poo-flow-user-loop-engine-state-prototype-kind+
        +poo-flow-user-loop-engine-sandbox-prototype-kind+
        +poo-flow-user-loop-engine-budget-prototype-kind+
        +poo-flow-user-loop-engine-result-prototype-kind+
        +poo-flow-user-loop-engine-observability-prototype-kind+
        +poo-flow-user-loop-engine-runtime-prototype-kind+
        +poo-flow-user-loop-engine-lineage-policy-prototype-kind+
        +poo-flow-user-loop-engine-selector-policy-prototype-kind+
        +poo-flow-user-loop-engine-resource-policy-prototype-kind+
        +poo-flow-user-loop-engine-capability-policy-prototype-kind+
        +poo-flow-user-loop-engine-memory-policy-prototype-kind+
        +poo-flow-user-loop-engine-compression-policy-prototype-kind+
        +poo-flow-user-loop-engine-profile-prototype-kind+
        loop-engine-use-case
        loop-engine-governor
        loop-engine-agent-judges
        loop-engine-human-audit
        loop-engine-schedule
        loop-engine-state
        loop-engine-sandbox
        loop-engine-budget
        loop-engine-result
        loop-engine-observability
        loop-engine-runtime
        loop-engine-lineage-policy
        loop-engine-selector-policy
        loop-engine-resource-policy
        loop-engine-capability-policy
        loop-engine-memory-policy
        loop-engine-compression-policy
        loop-engine-profile)

;;; Prototype kind symbols are the inheritance anchors used by POO slot
;;; validation and report lowering. They are intentionally separate from schema
;;; contract ids consumed by Marlin.
;; : Symbol
(def +poo-flow-user-loop-engine-use-case-prototype-kind+
  'poo-flow.loop-engine.use-case.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-governor-prototype-kind+
  'poo-flow.loop-engine.governor.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-agent-judges-prototype-kind+
  'poo-flow.loop-engine.agent-judges.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-human-audit-prototype-kind+
  'poo-flow.loop-engine.human-audit.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-schedule-prototype-kind+
  'poo-flow.loop-engine.schedule.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-state-prototype-kind+
  'poo-flow.loop-engine.state.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-sandbox-prototype-kind+
  'poo-flow.loop-engine.sandbox.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-budget-prototype-kind+
  'poo-flow.loop-engine.budget.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-result-prototype-kind+
  'poo-flow.loop-engine.result.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-observability-prototype-kind+
  'poo-flow.loop-engine.observability.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-runtime-prototype-kind+
  'poo-flow.loop-engine.runtime.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-lineage-policy-prototype-kind+
  'poo-flow.loop-engine.lineage-policy.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-selector-policy-prototype-kind+
  'poo-flow.loop-engine.selector-policy.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-resource-policy-prototype-kind+
  'poo-flow.loop-engine.resource-policy.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-capability-policy-prototype-kind+
  'poo-flow.loop-engine.capability-policy.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-memory-policy-prototype-kind+
  'poo-flow.loop-engine.memory-policy.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-compression-policy-prototype-kind+
  'poo-flow.loop-engine.compression-policy.prototype)

;; : Symbol
(def +poo-flow-user-loop-engine-profile-prototype-kind+
  'poo-flow.loop-engine.profile.prototype)

;;; A use-case object is the named work item in a loop profile. The workflow ref
;;; stays optional because not every loop is backed by a Funflow DAG yet.
;; : PooFlowLoopEngineUseCasePrototype
(def loop-engine-use-case
  (.o kind: +poo-flow-user-loop-engine-use-case-prototype-kind+
      name: #f
      level: #f
      mode: #f
      goal: #f
      workflow: #f
      metadata: '()
      runtime-executed: #f))

;;; Governor capabilities are strategy knobs. They are not executable handlers.
;; : PooFlowLoopEngineGovernorPrototype
(def loop-engine-governor
  (.o kind: +poo-flow-user-loop-engine-governor-prototype-kind+
      capabilities: '()
      metadata: '()
      runtime-executed: #f))

;;; Agent judge objects name roles and profile refs used by Marlin later.
;; : PooFlowLoopEngineAgentJudgesPrototype
(def loop-engine-agent-judges
  (.o kind: +poo-flow-user-loop-engine-agent-judges-prototype-kind+
      auditor: #f
      verifier: #f
      reviewer: #f
      governor: #f
      metadata: '()
      runtime-executed: #f))

;; : PooFlowLoopEngineHumanAuditPrototype
(def loop-engine-human-audit
  (.o kind: +poo-flow-user-loop-engine-human-audit-prototype-kind+
      actions: '()
      metadata: '()
      runtime-executed: #f))

;; : PooFlowLoopEngineSchedulePrototype
(def loop-engine-schedule
  (.o kind: +poo-flow-user-loop-engine-schedule-prototype-kind+
      trigger: #f
      cadence: #f
      entries: '()
      runtime-executed: #f))

;; : PooFlowLoopEngineStatePrototype
(def loop-engine-state
  (.o kind: +poo-flow-user-loop-engine-state-prototype-kind+
      store: #f
      path: #f
      acting-on: #f
      entries: '()
      runtime-executed: #f))

;;; Sandbox refs can be global profile refs or per-use-case profile refs.
;; : PooFlowLoopEngineSandboxPrototype
(def loop-engine-sandbox
  (.o kind: +poo-flow-user-loop-engine-sandbox-prototype-kind+
      profile: #f
      isolation: #f
      profile-refs: '()
      case-profile-refs: '()
      entries: '()
      runtime-executed: #f))

;; : PooFlowLoopEngineBudgetPrototype
(def loop-engine-budget
  (.o kind: +poo-flow-user-loop-engine-budget-prototype-kind+
      max-actionable: #f
      max-attempts: #f
      weekly-runs: #f
      entries: '()
      runtime-executed: #f))

;; : PooFlowLoopEngineResultPrototype
(def loop-engine-result
  (.o kind: +poo-flow-user-loop-engine-result-prototype-kind+
      default: #f
      auditor: #f
      verifier: #f
      reviewer: #f
      governor: #f
      human-audit: #f
      format: 'structured-alist
      required-fields: '(decision summary evidence)
      entries: '()
      runtime-executed: #f))

;; : PooFlowLoopEngineObservabilityPrototype
(def loop-engine-observability
  (.o kind: +poo-flow-user-loop-engine-observability-prototype-kind+
      receipt: #f
      run-log: #f
      entries: '()
      runtime-executed: #f))

;; : PooFlowLoopEngineRuntimePrototype
(def loop-engine-runtime
  (.o kind: +poo-flow-user-loop-engine-runtime-prototype-kind+
      capabilities: '(+manifest-handoff)
      handoff: 'loop-governor-marlin-runtime-manifest
      owner: "marlin-agent-core"
      entries: '()
      runtime-executed: #f))

;;; Lineage policy mirrors OpenRath's session-first audit trail without making
;;; Scheme persist sessions. It only describes the report-only receipt shape.
;; : PooFlowLoopEngineLineagePolicyPrototype
(def loop-engine-lineage-policy
  (.o kind: +poo-flow-user-loop-engine-lineage-policy-prototype-kind+
      parent-session-refs: '()
      lineage-kind: #f
      lineage-operator: #f
      journal: #f
      export: #f
      entries: '()
      runtime-executed: #f))

;;; Selector policy keeps branch selection inspectable while model scoring and
;;; runtime routing stay Marlin-owned.
;; : PooFlowLoopEngineSelectorPolicyPrototype
(def loop-engine-selector-policy
  (.o kind: +poo-flow-user-loop-engine-selector-policy-prototype-kind+
      candidates: '()
      judge-inputs: '()
      fallback: #f
      selected-branch: #f
      entries: '()
      runtime-executed: #f))

;;; Resource policy models OpenRath-style resource keys as declaration data.
;;; The Scheme side may project serial/parallel groups but never schedules them.
;; : PooFlowLoopEngineResourcePolicyPrototype
(def loop-engine-resource-policy
  (.o kind: +poo-flow-user-loop-engine-resource-policy-prototype-kind+
      tool-refs: '()
      resource-keys: '()
      collision-classes: '()
      dispatch-groups: '()
      entries: '()
      runtime-executed: #f))

;;; Capability policy declares backend and sandbox capability expectations.
;;; Marlin owns probing and enforcement; Scheme only projects report receipts.
;; : PooFlowLoopEngineCapabilityPolicyPrototype
(def loop-engine-capability-policy
  (.o kind: +poo-flow-user-loop-engine-capability-policy-prototype-kind+
      backend: #f
      isolation: #f
      required: '()
      optional: '()
      unsupported-behavior: #f
      entries: '()
      runtime-executed: #f))

;;; Memory policy declares recall/commit intent as report-only loop facts.
;;; Marlin owns storage, ranking, retention, and all memory mutation.
;; : PooFlowLoopEngineMemoryPolicyPrototype
(def loop-engine-memory-policy
  (.o kind: +poo-flow-user-loop-engine-memory-policy-prototype-kind+
      use-case: #f
      store: #f
      state-path: #f
      scope: #f
      recall: '()
      commit: '()
      ranking: #f
      retention: #f
      entries: '()
      runtime-executed: #f))

;;; Compression policy declares summary/session compaction expectations as
;;; report-only facts. Marlin owns transcript compression and session creation.
;; : PooFlowLoopEngineCompressionPolicyPrototype
(def loop-engine-compression-policy
  (.o kind: +poo-flow-user-loop-engine-compression-policy-prototype-kind+
      strategy: #f
      trigger: #f
      summary-format: #f
      lineage-kind: #f
      retention: #f
      entries: '()
      runtime-executed: #f))

;;; The profile object is the single public root accepted by loop-engine
;;; `:config`; all other objects feed slots on this profile.
;; : PooFlowLoopEngineProfilePrototype
(def loop-engine-profile
  (.o kind: +poo-flow-user-loop-engine-profile-prototype-kind+
      profile-name: #f
      use-case: #f
      use-cases: '()
      governor: #f
      agent-judges: #f
      human-audit: #f
      schedule: #f
      state: #f
      sandbox: #f
      budget: #f
      result: #f
      observability: #f
      runtime: #f
      lineage-policy: #f
      selector-policy: #f
      resource-policy: #f
      capability-policy: #f
      memory-policies: '()
      compression-policy: #f
      policy-extensions: '()
      metadata: '()
      runtime-executed: #f))
