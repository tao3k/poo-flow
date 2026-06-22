;;; -*- Gerbil -*-
;;; Boundary: loop-engine declaration helpers and shared runtime vocabulary.
;;; Invariant: this owner normalizes user rows but never builds command manifests.

(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-sandbox-profile-by-name
                 poo-flow-sandbox-profile-handoff-summary
                 poo-flow-sandbox-profile-runtime-summary)
        :poo-flow/src/module-system/base)

(export poo-flow-user-loop-engine-section
        +poo-flow-user-loop-engine-use-case-prototype-kind+
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
        loop-engine-profile
        poo-flow-user-loop-engine-poo-use-case?
        poo-flow-user-loop-engine-poo-profile?
        poo-flow-user-loop-engine-poo-config-flags
        poo-flow-user-loop-engine-selection-poo-intent
        +poo-flow-user-loop-engine-runtime-command-arguments+
        +poo-flow-user-loop-engine-runtime-command-contract+
        +poo-flow-user-loop-engine-runtime-command-executable+
        +poo-flow-user-loop-engine-runtime-command-name+
        +poo-flow-user-loop-engine-runtime-object-families+
        +poo-flow-user-loop-engine-receipt-contracts+
        +poo-flow-user-loop-engine-result-contract+
        +poo-flow-user-loop-engine-default-result-contract+
        +poo-flow-user-loop-engine-result-contract-roles+
        +poo-flow-user-loop-engine-sandbox-handoff-agreement-contract+
        +poo-flow-user-loop-engine-handoff-contracts+
        poo-flow-user-loop-engine-intent-ref
        poo-flow-user-loop-engine-section-ref
        poo-flow-user-loop-engine-use-case-name
        poo-flow-user-loop-engine-intent-use-case-name
        poo-flow-user-loop-engine-use-case-names/add
        poo-flow-user-loop-engine-use-case-names
        poo-flow-user-loop-engine-use-case-name?
        poo-flow-user-loop-engine-sandbox-entry-profile-ref
        poo-flow-user-loop-engine-profile-ref-member?
        poo-flow-user-loop-engine-profile-ref-add
        poo-flow-user-loop-engine-sandbox-profile-refs/add
        poo-flow-user-loop-engine-sandbox-profile-refs
        poo-flow-user-loop-engine-sandbox-profile-ref->profile
        poo-flow-user-loop-engine-sandbox-profile-ref->runtime-summary
        poo-flow-user-loop-engine-sandbox-profile-ref->handoff-summary
        poo-flow-user-loop-engine-sandbox-runtime-summaries
        poo-flow-user-loop-engine-sandbox-handoff-summaries
        poo-flow-user-loop-engine-sandbox-unresolved-profile-refs
        poo-flow-user-loop-engine-sandbox-handoff-agreement
        poo-flow-user-loop-engine-runtime-id
        poo-flow-user-loop-engine-intent-workflow-ref)

(def (poo-flow-user-loop-engine-section selection section)
  (let (entry (poo-flow-user-module-selection-flag-entry selection section))
    (cond
     ((and entry (pair? entry)) (cdr entry))
     (entry (list entry))
     (else '()))))

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
      store: #f
      scope: #f
      recall: '()
      commit: '()
      ranking: #f
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
      memory-policy: #f
      metadata: '()
      runtime-executed: #f))

;; : (-> String Boolean Value Unit)
(def (poo-flow-user-loop-engine-require message ok? value)
  (if ok? (void) (error message value)))

;; : (-> Value Boolean)
(def (poo-flow-user-loop-engine-alist? value)
  (cond
   ((null? value) #t)
   ((and (pair? value) (pair? (car value)))
    (poo-flow-user-loop-engine-alist? (cdr value)))
   (else #f)))

;; : (-> (Value -> Boolean) Value Boolean)
(def (poo-flow-user-loop-engine-list-of? predicate value)
  (cond
   ((null? value) #t)
   ((and (pair? value) (predicate (car value)))
    (poo-flow-user-loop-engine-list-of? predicate (cdr value)))
   (else #f)))

;; : (-> Value Boolean)
(def (poo-flow-user-loop-engine-maybe-symbol? value)
  (or (not value) (symbol? value)))

;; : (-> Value Boolean)
(def (poo-flow-user-loop-engine-maybe-string? value)
  (or (not value) (string? value)))

;; : (-> Value Boolean)
(def (poo-flow-user-loop-engine-maybe-integer? value)
  (or (not value) (integer? value)))

;; : (-> Value Boolean)
(def (poo-flow-user-loop-engine-maybe-symbol-or-string? value)
  (or (not value) (symbol? value) (string? value)))

;; : (-> Value Boolean)
(def (poo-flow-user-loop-engine-symbol-list? value)
  (poo-flow-user-loop-engine-list-of? symbol? value))

;; : (-> Symbol Symbol Symbol Boolean Value Unit)
(def (poo-flow-user-loop-engine-require-slot object slot expected ok? value)
  (poo-flow-user-loop-engine-require
   "loop-engine POO object slot contract failed"
   ok?
   (list (cons 'object object)
         (cons 'slot slot)
         (cons 'expected expected)
         (cons 'value value))))

;; : (-> Symbol Symbol Value Unit)
(def (poo-flow-user-loop-engine-require-alist-slot object slot value)
  (poo-flow-user-loop-engine-require-slot
   object
   slot
   'alist
   (poo-flow-user-loop-engine-alist? value)
   value))

;; : (-> Symbol Symbol Value Unit)
(def (poo-flow-user-loop-engine-require-symbol-list-slot object slot value)
  (poo-flow-user-loop-engine-require-slot
   object
   slot
   '(list symbol)
   (poo-flow-user-loop-engine-symbol-list? value)
   value))

;; : (-> Symbol Symbol Value Unit)
(def (poo-flow-user-loop-engine-require-maybe-symbol-slot object slot value)
  (poo-flow-user-loop-engine-require-slot
   object
   slot
   '(maybe symbol)
   (poo-flow-user-loop-engine-maybe-symbol? value)
   value))

;; : (-> Symbol Symbol Value Unit)
(def (poo-flow-user-loop-engine-require-maybe-string-slot object slot value)
  (poo-flow-user-loop-engine-require-slot
   object
   slot
   '(maybe string)
   (poo-flow-user-loop-engine-maybe-string? value)
   value))

;; : (-> Symbol Symbol Value Unit)
(def (poo-flow-user-loop-engine-require-maybe-integer-slot object slot value)
  (poo-flow-user-loop-engine-require-slot
   object
   slot
   '(maybe integer)
   (poo-flow-user-loop-engine-maybe-integer? value)
   value))

;; : (-> Symbol Symbol Value Unit)
(def (poo-flow-user-loop-engine-require-maybe-symbol-or-string-slot
      object
      slot
      value)
  (poo-flow-user-loop-engine-require-slot
   object
   slot
   '(maybe symbol-or-string)
   (poo-flow-user-loop-engine-maybe-symbol-or-string? value)
   value))

;; : (-> Value Symbol Boolean)
(def (poo-flow-user-loop-engine-poo-kind? value kind)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) kind)))

;; : (-> Value Boolean)
(def (poo-flow-user-loop-engine-poo-use-case? value)
  (poo-flow-user-loop-engine-poo-kind?
   value
   +poo-flow-user-loop-engine-use-case-prototype-kind+))

;; : (-> Value Boolean)
(def (poo-flow-user-loop-engine-poo-profile? value)
  (poo-flow-user-loop-engine-poo-kind?
   value
   +poo-flow-user-loop-engine-profile-prototype-kind+))

;; : (-> Symbol Value [Pair])
(def (poo-flow-user-loop-engine-optional-row key value)
  (if value (list (cons key value)) '()))

;; : (-> Symbol Value [Pair])
(def (poo-flow-user-loop-engine-optional-list-row key value)
  (if (null? value) '() (list (cons key value))))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-use-case->row use-case)
  (poo-flow-user-loop-engine-require
   "loop-engine use-case config object must extend loop-engine-use-case"
   (poo-flow-user-loop-engine-poo-use-case? use-case)
   use-case)
  (let ((name (.ref use-case 'name))
        (level (.ref use-case 'level))
        (mode (.ref use-case 'mode))
        (goal (.ref use-case 'goal))
        (workflow (.ref use-case 'workflow))
        (metadata (.ref use-case 'metadata)))
    (poo-flow-user-loop-engine-require
     "loop-engine use-case name must be a symbol"
     (symbol? name)
     name)
    (poo-flow-user-loop-engine-require-maybe-symbol-slot
     'loop-engine-use-case 'level level)
    (poo-flow-user-loop-engine-require-maybe-symbol-slot
     'loop-engine-use-case 'mode mode)
    (poo-flow-user-loop-engine-require-maybe-symbol-or-string-slot
     'loop-engine-use-case 'goal goal)
    (poo-flow-user-loop-engine-require-maybe-symbol-slot
     'loop-engine-use-case 'workflow workflow)
    (poo-flow-user-loop-engine-require-alist-slot
     'loop-engine-use-case 'metadata metadata)
    (cons name
          (append
           (poo-flow-user-loop-engine-optional-row 'level level)
           (poo-flow-user-loop-engine-optional-row 'mode mode)
           (poo-flow-user-loop-engine-optional-row 'goal goal)
           (poo-flow-user-loop-engine-optional-row 'workflow workflow)
           metadata))))

;; : (-> [PooFlowLoopEngineUseCasePrototype] [Pair])
(def (poo-flow-user-loop-engine-poo-use-cases->rows use-cases)
  (cond
   ((null? use-cases) '())
   ((pair? use-cases)
    (cons
     (poo-flow-user-loop-engine-poo-use-case->row (car use-cases))
     (poo-flow-user-loop-engine-poo-use-cases->rows (cdr use-cases))))
   (else
    (error "loop-engine profile use-cases slot must be a list" use-cases))))

;; : (-> Value [Value])
(def (poo-flow-user-loop-engine-poo-governor->rows governor)
  (cond
   ((not governor) '())
   ((poo-flow-user-loop-engine-poo-kind?
     governor
     +poo-flow-user-loop-engine-governor-prototype-kind+)
    (let ((capabilities (.ref governor 'capabilities))
          (metadata (.ref governor 'metadata)))
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-governor 'capabilities capabilities)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-governor 'metadata metadata)
      (append capabilities metadata)))
   (else
    (error "loop-engine governor slot must extend loop-engine-governor"
           governor))))

;; : (-> Symbol Value [Pair])
(def (poo-flow-user-loop-engine-judge-row role value)
  (if value (list (list role value)) '()))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-agent-judges->rows agent-judges)
  (cond
   ((not agent-judges) '())
   ((poo-flow-user-loop-engine-poo-kind?
     agent-judges
     +poo-flow-user-loop-engine-agent-judges-prototype-kind+)
    (let ((auditor (.ref agent-judges 'auditor))
          (verifier (.ref agent-judges 'verifier))
          (reviewer (.ref agent-judges 'reviewer))
          (governor (.ref agent-judges 'governor))
          (metadata (.ref agent-judges 'metadata)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-agent-judges 'auditor auditor)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-agent-judges 'verifier verifier)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-agent-judges 'reviewer reviewer)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-agent-judges 'governor governor)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-agent-judges 'metadata metadata)
      (append
       (poo-flow-user-loop-engine-judge-row 'auditor auditor)
       (poo-flow-user-loop-engine-judge-row 'verifier verifier)
       (poo-flow-user-loop-engine-judge-row 'reviewer reviewer)
       (poo-flow-user-loop-engine-judge-row 'governor governor)
       metadata)))
   (else
    (error "loop-engine agent-judges slot must extend loop-engine-agent-judges"
           agent-judges))))

;; : (-> Value [Value])
(def (poo-flow-user-loop-engine-poo-human-audit->rows human-audit)
  (cond
   ((not human-audit) '())
   ((poo-flow-user-loop-engine-poo-kind?
     human-audit
     +poo-flow-user-loop-engine-human-audit-prototype-kind+)
    (let ((actions (.ref human-audit 'actions))
          (metadata (.ref human-audit 'metadata)))
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-human-audit 'actions actions)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-human-audit 'metadata metadata)
      (append actions metadata)))
   (else
    (error "loop-engine human-audit slot must extend loop-engine-human-audit"
           human-audit))))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-schedule->rows schedule)
  (cond
   ((not schedule) '())
   ((poo-flow-user-loop-engine-poo-kind?
     schedule
     +poo-flow-user-loop-engine-schedule-prototype-kind+)
    (let ((trigger (.ref schedule 'trigger))
          (cadence (.ref schedule 'cadence))
          (entries (.ref schedule 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-schedule 'trigger trigger)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-schedule 'cadence cadence)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-schedule 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row 'trigger trigger)
       (poo-flow-user-loop-engine-optional-row 'cadence cadence)
       entries)))
   (else
    (error "loop-engine schedule slot must extend loop-engine-schedule"
           schedule))))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-state->rows state)
  (cond
   ((not state) '())
   ((poo-flow-user-loop-engine-poo-kind?
     state
     +poo-flow-user-loop-engine-state-prototype-kind+)
    (let ((store (.ref state 'store))
          (path (.ref state 'path))
          (acting-on (.ref state 'acting-on))
          (entries (.ref state 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-state 'store store)
      (poo-flow-user-loop-engine-require-maybe-string-slot
       'loop-engine-state 'path path)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-state 'acting-on acting-on)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-state 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row 'store store)
       (poo-flow-user-loop-engine-optional-row 'path path)
       (poo-flow-user-loop-engine-optional-row 'acting-on acting-on)
       entries)))
   (else
    (error "loop-engine state slot must extend loop-engine-state" state))))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-sandbox->rows sandbox)
  (cond
   ((not sandbox) '())
   ((poo-flow-user-loop-engine-poo-kind?
     sandbox
     +poo-flow-user-loop-engine-sandbox-prototype-kind+)
    (let ((profile (.ref sandbox 'profile))
          (isolation (.ref sandbox 'isolation))
          (profile-refs (.ref sandbox 'profile-refs))
          (case-profile-refs (.ref sandbox 'case-profile-refs))
          (entries (.ref sandbox 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-sandbox 'profile profile)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-sandbox 'isolation isolation)
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-sandbox 'profile-refs profile-refs)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-sandbox 'case-profile-refs case-profile-refs)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-sandbox 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row 'profile profile)
       (poo-flow-user-loop-engine-optional-row 'isolation isolation)
       profile-refs
       case-profile-refs
       entries)))
   (else
    (error "loop-engine sandbox slot must extend loop-engine-sandbox"
           sandbox))))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-budget->rows budget)
  (cond
   ((not budget) '())
   ((poo-flow-user-loop-engine-poo-kind?
     budget
     +poo-flow-user-loop-engine-budget-prototype-kind+)
    (let ((max-actionable (.ref budget 'max-actionable))
          (max-attempts (.ref budget 'max-attempts))
          (weekly-runs (.ref budget 'weekly-runs))
          (entries (.ref budget 'entries)))
      (poo-flow-user-loop-engine-require-maybe-integer-slot
       'loop-engine-budget 'max-actionable max-actionable)
      (poo-flow-user-loop-engine-require-maybe-integer-slot
       'loop-engine-budget 'max-attempts max-attempts)
      (poo-flow-user-loop-engine-require-maybe-integer-slot
       'loop-engine-budget 'weekly-runs weekly-runs)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-budget 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row
        'max-actionable
        max-actionable)
       (poo-flow-user-loop-engine-optional-row 'max-attempts max-attempts)
       (poo-flow-user-loop-engine-optional-row 'weekly-runs weekly-runs)
       entries)))
   (else
    (error "loop-engine budget slot must extend loop-engine-budget" budget))))

;; : (-> Symbol Value [Pair])
(def (poo-flow-user-loop-engine-result-role-row role value)
  (if value (list (cons role value)) '()))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-result->rows result)
  (cond
   ((not result) '())
   ((poo-flow-user-loop-engine-poo-kind?
     result
     +poo-flow-user-loop-engine-result-prototype-kind+)
    (let ((default (.ref result 'default))
          (auditor (.ref result 'auditor))
          (verifier (.ref result 'verifier))
          (reviewer (.ref result 'reviewer))
          (governor (.ref result 'governor))
          (human-audit (.ref result 'human-audit))
          (format (.ref result 'format))
          (required-fields (.ref result 'required-fields))
          (entries (.ref result 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'default default)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'auditor auditor)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'verifier verifier)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'reviewer reviewer)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'governor governor)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'human-audit human-audit)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'format format)
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-result 'required-fields required-fields)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-result 'entries entries)
      (append
       (poo-flow-user-loop-engine-result-role-row 'default default)
       (poo-flow-user-loop-engine-result-role-row 'auditor auditor)
       (poo-flow-user-loop-engine-result-role-row 'verifier verifier)
       (poo-flow-user-loop-engine-result-role-row 'reviewer reviewer)
       (poo-flow-user-loop-engine-result-role-row 'governor governor)
       (poo-flow-user-loop-engine-result-role-row 'human-audit human-audit)
       (list (cons 'format format)
             (cons 'required-fields required-fields))
       entries)))
   (else
    (error "loop-engine result slot must extend loop-engine-result" result))))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-observability->rows observability)
  (cond
   ((not observability) '())
   ((poo-flow-user-loop-engine-poo-kind?
     observability
     +poo-flow-user-loop-engine-observability-prototype-kind+)
    (let ((receipt (.ref observability 'receipt))
          (run-log (.ref observability 'run-log))
          (entries (.ref observability 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-observability 'receipt receipt)
      (poo-flow-user-loop-engine-require-maybe-string-slot
       'loop-engine-observability 'run-log run-log)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-observability 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row 'receipt receipt)
       (poo-flow-user-loop-engine-optional-row 'run-log run-log)
       entries)))
   (else
    (error
     "loop-engine observability slot must extend loop-engine-observability"
     observability))))

;; : (-> Value [Value])
(def (poo-flow-user-loop-engine-poo-runtime->rows runtime)
  (cond
   ((not runtime) '())
   ((poo-flow-user-loop-engine-poo-kind?
     runtime
     +poo-flow-user-loop-engine-runtime-prototype-kind+)
    (let ((capabilities (.ref runtime 'capabilities))
          (handoff (.ref runtime 'handoff))
          (owner (.ref runtime 'owner))
          (entries (.ref runtime 'entries)))
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-runtime 'capabilities capabilities)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-runtime 'handoff handoff)
      (poo-flow-user-loop-engine-require-maybe-string-slot
       'loop-engine-runtime 'owner owner)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-runtime 'entries entries)
      (append capabilities entries)))
   (else
    (error "loop-engine runtime slot must extend loop-engine-runtime"
           runtime))))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-lineage-policy->rows lineage-policy)
  (cond
   ((not lineage-policy) '())
   ((poo-flow-user-loop-engine-poo-kind?
     lineage-policy
     +poo-flow-user-loop-engine-lineage-policy-prototype-kind+)
    (let ((parent-session-refs (.ref lineage-policy 'parent-session-refs))
          (lineage-kind (.ref lineage-policy 'lineage-kind))
          (lineage-operator (.ref lineage-policy 'lineage-operator))
          (journal (.ref lineage-policy 'journal))
          (export (.ref lineage-policy 'export))
          (entries (.ref lineage-policy 'entries)))
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-lineage-policy
       'parent-session-refs
       parent-session-refs)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-lineage-policy 'lineage-kind lineage-kind)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-lineage-policy 'lineage-operator lineage-operator)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-lineage-policy 'journal journal)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-lineage-policy 'export export)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-lineage-policy 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-list-row
        'parent-session-refs
        parent-session-refs)
       (poo-flow-user-loop-engine-optional-row
        'lineage-kind
        lineage-kind)
       (poo-flow-user-loop-engine-optional-row
        'lineage-operator
        lineage-operator)
       (poo-flow-user-loop-engine-optional-row 'journal journal)
       (poo-flow-user-loop-engine-optional-row 'export export)
       entries)))
   (else
    (error
     "loop-engine lineage-policy slot must extend loop-engine-lineage-policy"
     lineage-policy))))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-selector-policy->rows selector-policy)
  (cond
   ((not selector-policy) '())
   ((poo-flow-user-loop-engine-poo-kind?
     selector-policy
     +poo-flow-user-loop-engine-selector-policy-prototype-kind+)
    (let ((candidates (.ref selector-policy 'candidates))
          (judge-inputs (.ref selector-policy 'judge-inputs))
          (fallback (.ref selector-policy 'fallback))
          (selected-branch (.ref selector-policy 'selected-branch))
          (entries (.ref selector-policy 'entries)))
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-selector-policy 'candidates candidates)
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-selector-policy 'judge-inputs judge-inputs)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-selector-policy 'fallback fallback)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-selector-policy 'selected-branch selected-branch)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-selector-policy 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-list-row 'candidates candidates)
       (poo-flow-user-loop-engine-optional-list-row 'judge-inputs judge-inputs)
       (poo-flow-user-loop-engine-optional-row 'fallback fallback)
       (poo-flow-user-loop-engine-optional-row
        'selected-branch
        selected-branch)
       entries)))
   (else
    (error
     "loop-engine selector-policy slot must extend loop-engine-selector-policy"
     selector-policy))))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-resource-policy->rows resource-policy)
  (cond
   ((not resource-policy) '())
   ((poo-flow-user-loop-engine-poo-kind?
     resource-policy
     +poo-flow-user-loop-engine-resource-policy-prototype-kind+)
    (let ((tool-refs (.ref resource-policy 'tool-refs))
          (resource-keys (.ref resource-policy 'resource-keys))
          (collision-classes (.ref resource-policy 'collision-classes))
          (dispatch-groups (.ref resource-policy 'dispatch-groups))
          (entries (.ref resource-policy 'entries)))
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-resource-policy 'tool-refs tool-refs)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-resource-policy 'resource-keys resource-keys)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-resource-policy 'collision-classes collision-classes)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-resource-policy 'dispatch-groups dispatch-groups)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-resource-policy 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-list-row 'tool-refs tool-refs)
       (poo-flow-user-loop-engine-optional-list-row
        'resource-keys
        resource-keys)
       (poo-flow-user-loop-engine-optional-list-row
        'collision-classes
        collision-classes)
       (poo-flow-user-loop-engine-optional-list-row
        'dispatch-groups
        dispatch-groups)
       entries)))
   (else
    (error
     "loop-engine resource-policy slot must extend loop-engine-resource-policy"
     resource-policy))))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-capability-policy->rows capability-policy)
  (cond
   ((not capability-policy) '())
   ((poo-flow-user-loop-engine-poo-kind?
     capability-policy
     +poo-flow-user-loop-engine-capability-policy-prototype-kind+)
    (let ((backend (.ref capability-policy 'backend))
          (isolation (.ref capability-policy 'isolation))
          (required (.ref capability-policy 'required))
          (optional (.ref capability-policy 'optional))
          (unsupported-behavior (.ref capability-policy 'unsupported-behavior))
          (entries (.ref capability-policy 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-capability-policy 'backend backend)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-capability-policy 'isolation isolation)
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-capability-policy 'required required)
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-capability-policy 'optional optional)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-capability-policy
       'unsupported-behavior
       unsupported-behavior)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-capability-policy 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row 'backend backend)
       (poo-flow-user-loop-engine-optional-row 'isolation isolation)
       (poo-flow-user-loop-engine-optional-list-row 'required required)
       (poo-flow-user-loop-engine-optional-list-row 'optional optional)
       (poo-flow-user-loop-engine-optional-row
        'unsupported-behavior
        unsupported-behavior)
       entries)))
   (else
    (error
     "loop-engine capability-policy slot must extend loop-engine-capability-policy"
     capability-policy))))

;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-memory-policy->rows memory-policy)
  (cond
   ((not memory-policy) '())
   ((poo-flow-user-loop-engine-poo-kind?
     memory-policy
     +poo-flow-user-loop-engine-memory-policy-prototype-kind+)
    (let ((store (.ref memory-policy 'store))
          (scope (.ref memory-policy 'scope))
          (recall (.ref memory-policy 'recall))
          (commit (.ref memory-policy 'commit))
          (ranking (.ref memory-policy 'ranking))
          (retention (.ref memory-policy 'retention))
          (entries (.ref memory-policy 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-memory-policy 'store store)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-memory-policy 'scope scope)
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-memory-policy 'recall recall)
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-memory-policy 'commit commit)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-memory-policy 'ranking ranking)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-memory-policy 'retention retention)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-memory-policy 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row 'store store)
       (poo-flow-user-loop-engine-optional-row 'scope scope)
       (poo-flow-user-loop-engine-optional-list-row 'recall recall)
       (poo-flow-user-loop-engine-optional-list-row 'commit commit)
       (poo-flow-user-loop-engine-optional-row 'ranking ranking)
       (poo-flow-user-loop-engine-optional-row 'retention retention)
       entries)))
   (else
    (error
     "loop-engine memory-policy slot must extend loop-engine-memory-policy"
     memory-policy))))

;; : (-> PooFlowLoopEngineProfilePrototype Alist)
(def (poo-flow-user-loop-engine-poo-profile->intent-fields profile)
  (poo-flow-user-loop-engine-require
   "loop-engine config object must extend loop-engine-profile"
   (poo-flow-user-loop-engine-poo-profile? profile)
   profile)
  (let ((profile-name (.ref profile 'profile-name))
        (use-case (.ref profile 'use-case))
        (use-cases (.ref profile 'use-cases))
        (runtime (.ref profile 'runtime))
        (metadata (.ref profile 'metadata)))
    (poo-flow-user-loop-engine-require-maybe-symbol-slot
     'loop-engine-profile 'profile-name profile-name)
    (poo-flow-user-loop-engine-require-slot
     'loop-engine-profile
     'use-cases
     'list
     (list? use-cases)
     use-cases)
    (poo-flow-user-loop-engine-require-alist-slot
     'loop-engine-profile 'metadata metadata)
    (append
     (list
      (cons 'use-case
            (if use-case
              (poo-flow-user-loop-engine-poo-use-case->row use-case)
              '()))
      (cons 'use-cases
            (poo-flow-user-loop-engine-poo-use-cases->rows use-cases))
      (cons 'governor
            (poo-flow-user-loop-engine-poo-governor->rows
             (.ref profile 'governor)))
      (cons 'agent-judges
            (poo-flow-user-loop-engine-poo-agent-judges->rows
             (.ref profile 'agent-judges)))
      (cons 'human-audit
            (poo-flow-user-loop-engine-poo-human-audit->rows
             (.ref profile 'human-audit)))
      (cons 'schedule
            (poo-flow-user-loop-engine-poo-schedule->rows
             (.ref profile 'schedule)))
      (cons 'state
            (poo-flow-user-loop-engine-poo-state->rows
             (.ref profile 'state)))
      (cons 'sandbox
            (poo-flow-user-loop-engine-poo-sandbox->rows
             (.ref profile 'sandbox)))
      (cons 'budget
            (poo-flow-user-loop-engine-poo-budget->rows
             (.ref profile 'budget)))
      (cons 'observability
            (poo-flow-user-loop-engine-poo-observability->rows
             (.ref profile 'observability)))
      (cons 'result
            (poo-flow-user-loop-engine-poo-result->rows
             (.ref profile 'result)))
      (cons 'runtime
            (poo-flow-user-loop-engine-poo-runtime->rows runtime))
      (cons 'lineage-policy
            (poo-flow-user-loop-engine-poo-lineage-policy->rows
             (.ref profile 'lineage-policy)))
      (cons 'selector-policy
            (poo-flow-user-loop-engine-poo-selector-policy->rows
             (.ref profile 'selector-policy)))
      (cons 'resource-policy
            (poo-flow-user-loop-engine-poo-resource-policy->rows
             (.ref profile 'resource-policy)))
      (cons 'capability-policy
            (poo-flow-user-loop-engine-poo-capability-policy->rows
             (.ref profile 'capability-policy)))
      (cons 'memory-policy
            (poo-flow-user-loop-engine-poo-memory-policy->rows
             (.ref profile 'memory-policy)))
      (cons 'runtime-handoff
            (if runtime
              (.ref runtime 'handoff)
              'loop-governor-marlin-runtime-manifest))
      (cons 'runtime-owner
            (if runtime
              (.ref runtime 'owner)
              "marlin-agent-core")))
     metadata)))

;; : (-> [PooFlowLoopEngineConfigPrototype] [PooFlowLoopEngineProfilePrototype])
(def (poo-flow-user-loop-engine-poo-config-profiles prototypes)
  (cond
   ((null? prototypes) '())
   ((poo-flow-user-loop-engine-poo-profile? (car prototypes))
    (cons (car prototypes)
          (poo-flow-user-loop-engine-poo-config-profiles (cdr prototypes))))
   ((pair? prototypes)
    (poo-flow-user-loop-engine-poo-config-profiles (cdr prototypes)))
   (else
    (error "loop-engine POO config prototypes must be a list" prototypes))))

;; : (-> [PooFlowLoopEngineConfigPrototype] Alist [UserModuleFlagEntry])
(def (poo-flow-user-loop-engine-poo-config-flags prototypes user-config)
  (let (profiles (poo-flow-user-loop-engine-poo-config-profiles prototypes))
    (poo-flow-user-loop-engine-require
     "loop-engine POO config must define exactly one loop-engine-profile"
     (= (length profiles) 1)
     prototypes)
    (let (intent-fields
          (poo-flow-user-loop-engine-poo-profile->intent-fields
           (car profiles)))
      (list '+loop-engine
            '+runtime-manifest
            (cons ':config (list (car profiles)))
            (cons ':loop-engine-intent intent-fields)
            (cons ':user-config user-config)))))

;; : (-> PooUserModuleSelection MaybeAlist)
(def (poo-flow-user-loop-engine-selection-poo-intent selection)
  (let (entry
        (poo-flow-user-module-selection-flag-entry
         selection
         ':loop-engine-intent))
    (and entry (pair? entry) (cdr entry))))

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

;;; Sandbox handoff agreement is the loop-engine receipt that compares declared
;;; refs, runtime summaries, and bridge-ready handoff summaries without raising.
;; : Symbol
(def +poo-flow-user-loop-engine-sandbox-handoff-agreement-contract+
  'poo-flow.loop-engine.sandbox-handoff-agreement.v1)

;;; Receipt contracts are stable data schemas that Marlin can consume without
;;; guessing which report-only rows accompany a loop-engine handoff.
;; : Alist
(def +poo-flow-user-loop-engine-receipt-contracts+
  '((lineage-receipt
     . poo-flow.loop-engine.lineage-receipt.v1)
    (selector-receipt
     . poo-flow.loop-engine.selector-receipt.v1)
    (resource-dispatch-receipt
     . poo-flow.loop-engine.resource-dispatch-receipt.v1)
    (capability-receipt
     . poo-flow.loop-engine.capability-receipt.v1)
    (memory-receipt
     . poo-flow.loop-engine.memory-receipt.v1)
    (sandbox-handoff-agreement
     . poo-flow.loop-engine.sandbox-handoff-agreement.v1)))

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
    workflow-run
    dispatch-receipt
    agent-operation
    lineage-receipt
    selector-receipt
    resource-dispatch-receipt
    capability-receipt
    memory-receipt
    runtime-snapshot))

;;; Intent lookup is total because partial loop declarations still need a
;;; presentable handoff report and unresolved sandbox diagnostics.
;; : (-> Alist Symbol Value Value)
(def (poo-flow-user-loop-engine-intent-ref intent key default-value)
  (let (entry (assoc key intent))
    (if entry (cdr entry) default-value)))

;;; Section lookup supports the Doom-style nested config rows where section
;;; names are carried as association keys inside init declarations.
;; : (-> [Value] Symbol Value Value)
(def (poo-flow-user-loop-engine-section-ref entries key default-value)
  (cond
   ((null? entries) default-value)
   ((and (pair? (car entries))
         (equal? (caar entries) key))
    (cdar entries))
   (else
    (poo-flow-user-loop-engine-section-ref (cdr entries) key default-value))))

;;; Use-case names become runtime ids, so this normalizer accepts an explicit
;;; single use-case row, then falls back to the first declared use-case list row.
;; : (-> Value [Value] Symbol)
(def (poo-flow-user-loop-engine-use-case-name use-case use-cases)
  (cond
   ((and (pair? use-case) (symbol? (car use-case))) (car use-case))
   ((and (pair? use-cases)
         (pair? (car use-cases))
         (symbol? (caar use-cases)))
    (caar use-cases))
   (else 'loop-engine)))

;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-use-case-name intent)
  (poo-flow-user-loop-engine-use-case-name
   (poo-flow-user-loop-engine-intent-ref intent 'use-case '())
   (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))

;;; Use-case accumulation preserves declaration order while ignoring malformed
;;; rows that cannot produce stable runtime identifiers.
;; : (-> [Value] [Symbol])
(def (poo-flow-user-loop-engine-use-case-names/add use-cases)
  (cond
   ((null? use-cases) '())
   ((and (pair? (car use-cases))
         (symbol? (caar use-cases)))
    (cons (caar use-cases)
          (poo-flow-user-loop-engine-use-case-names/add (cdr use-cases))))
   (else
    (poo-flow-user-loop-engine-use-case-names/add (cdr use-cases)))))

;;; The use-case set is intentionally empty when no explicit rows exist. The
;;; runtime workflow ref still falls back through the single-use-case path.
;; : (-> Alist [Symbol])
(def (poo-flow-user-loop-engine-use-case-names intent)
  (let ((use-case
         (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
        (use-cases
         (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))
    (append
     (if (and (pair? use-case) (symbol? (car use-case)))
       (list (car use-case))
       '())
     (poo-flow-user-loop-engine-use-case-names/add use-cases))))

;;; Use-case membership is Boolean-normalized for sandbox rows that use
;;; `(case . profile)` shorthand.
;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-user-loop-engine-use-case-name? value use-case-names)
  (and (member value use-case-names) #t))

;;; Sandbox entries accept profile rows and per-use-case shorthand. Returning
;;; `#f` keeps malformed rows visible to unresolved-ref diagnostics.
;; : (-> Value [Symbol] MaybeSymbol)
(def (poo-flow-user-loop-engine-sandbox-entry-profile-ref entry use-case-names)
  (cond
   ((symbol? entry) entry)
   ((and (pair? entry)
         (eq? (car entry) 'profile)
         (symbol? (cdr entry)))
    (cdr entry))
   ((and (pair? entry)
         (symbol? (car entry))
         (poo-flow-user-loop-engine-use-case-name? (car entry)
                                                   use-case-names)
         (symbol? (cdr entry)))
    (cdr entry))
   (else #f)))

;;; Profile ref membership is Boolean-normalized for deterministic duplicate
;;; filtering in profile-ref accumulation.
;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-user-loop-engine-profile-ref-member? value refs)
  (and (member value refs) #t))

;;; Profile refs preserve first declaration order. Later duplicates do not
;;; change the runtime handoff order.
;; : (-> MaybeSymbol [Symbol] [Symbol])
(def (poo-flow-user-loop-engine-profile-ref-add value refs)
  (if (and value
           (not (poo-flow-user-loop-engine-profile-ref-member? value refs)))
    (append refs (list value))
    refs))

;;; Sandbox profile refs are collected from user rows without resolving the
;;; profile catalog so missing refs can be reported separately.
;; : (-> [Value] [Symbol] [Symbol] [Symbol])
(def (poo-flow-user-loop-engine-sandbox-profile-refs/add entries
                                                         use-case-names
                                                         refs)
  (cond
   ((null? entries) refs)
   (else
    (poo-flow-user-loop-engine-sandbox-profile-refs/add
     (cdr entries)
     use-case-names
     (poo-flow-user-loop-engine-profile-ref-add
      (poo-flow-user-loop-engine-sandbox-entry-profile-ref
       (car entries)
       use-case-names)
      refs)))))

;; : (-> Alist [Symbol])
(def (poo-flow-user-loop-engine-sandbox-profile-refs intent)
  (poo-flow-user-loop-engine-sandbox-profile-refs/add
   (poo-flow-user-loop-engine-intent-ref intent 'sandbox '())
   (poo-flow-user-loop-engine-use-case-names intent)
   '()))

;;; Sandbox profile lookup is intentionally catalog-only here; loop-engine
;;; projection must not construct or repair profiles during presentation.
;; : (-> Symbol [PooSandboxProfile] MaybePooSandboxProfile)
(def (poo-flow-user-loop-engine-sandbox-profile-ref->profile profile-ref
                                                             profile-catalog)
  (poo-flow-sandbox-profile-by-name profile-catalog profile-ref))

;;; Runtime summaries are optional evidence rows. Missing profiles are surfaced
;;; by the unresolved-ref scan instead of throwing inside this lookup.
;; : (-> Symbol [PooSandboxProfile] MaybeAlist)
(def (poo-flow-user-loop-engine-sandbox-profile-ref->runtime-summary
      profile-ref
      profile-catalog)
  (let (profile
        (poo-flow-user-loop-engine-sandbox-profile-ref->profile
         profile-ref
         profile-catalog))
    (and profile (poo-flow-sandbox-profile-runtime-summary profile))))

;;; Handoff summaries follow the same optional lookup path as runtime summaries
;;; so presentation can report partial profile catalogs deterministically.
;; : (-> Symbol [PooSandboxProfile] MaybeAlist)
(def (poo-flow-user-loop-engine-sandbox-profile-ref->handoff-summary
      profile-ref
      profile-catalog)
  (let* ((profile
          (poo-flow-user-loop-engine-sandbox-profile-ref->profile
           profile-ref
           profile-catalog))
         (runtime-summary
          (and profile (poo-flow-sandbox-profile-runtime-summary profile))))
    (and profile
         (poo-flow-user-loop-engine-intent-ref
          runtime-summary
          'valid?
          #f)
         (poo-flow-sandbox-profile-handoff-summary profile))))

;;; Runtime summary collection preserves reference order and skips missing
;;; profiles; unresolved refs are recorded by a sibling diagnostic pass.
;; : (-> [Symbol] [PooSandboxProfile] [Alist])
(def (poo-flow-user-loop-engine-sandbox-runtime-summaries refs profile-catalog)
  (cond
   ((null? refs) '())
   ((poo-flow-user-loop-engine-sandbox-profile-ref->runtime-summary
     (car refs)
     profile-catalog)
    => (lambda (summary)
         (cons summary
               (poo-flow-user-loop-engine-sandbox-runtime-summaries
                (cdr refs)
                profile-catalog))))
   (else
    (poo-flow-user-loop-engine-sandbox-runtime-summaries
     (cdr refs)
     profile-catalog))))

;;; Handoff summary collection mirrors runtime summary collection so the two
;;; projections stay comparable in tests and presentation traces.
;; : (-> [Symbol] [PooSandboxProfile] [Alist])
(def (poo-flow-user-loop-engine-sandbox-handoff-summaries refs profile-catalog)
  (cond
   ((null? refs) '())
   ((poo-flow-user-loop-engine-sandbox-profile-ref->handoff-summary
     (car refs)
     profile-catalog)
    => (lambda (summary)
         (cons summary
               (poo-flow-user-loop-engine-sandbox-handoff-summaries
                (cdr refs)
                profile-catalog))))
   (else
    (poo-flow-user-loop-engine-sandbox-handoff-summaries
     (cdr refs)
     profile-catalog))))

;;; Unresolved refs are the safety channel for profile catalog holes. This keeps
;;; runtime handoff pure while still rejecting fake completeness in tests.
;; : (-> [Symbol] [PooSandboxProfile] [Symbol])
(def (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs refs
                                                                profile-catalog)
  (cond
   ((null? refs) '())
   ((poo-flow-user-loop-engine-sandbox-profile-ref->profile
     (car refs)
     profile-catalog)
    (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs
     (cdr refs)
     profile-catalog))
   (else
    (cons (car refs)
          (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs
           (cdr refs)
           profile-catalog)))))

;;; Invalid runtime summaries stay reportable facts. They are not filtered out
;;; of the intent because doctor and handoff agreement need the validation rows.
;; : (-> [Alist] [Alist])
(def (poo-flow-user-loop-engine-invalid-sandbox-runtime-summaries summaries)
  (cond
   ((null? summaries) '())
   ((poo-flow-user-loop-engine-intent-ref (car summaries) 'valid? #f)
    (poo-flow-user-loop-engine-invalid-sandbox-runtime-summaries
     (cdr summaries)))
   (else
    (cons
     (car summaries)
     (poo-flow-user-loop-engine-invalid-sandbox-runtime-summaries
      (cdr summaries))))))

;;; Agreement diagnostics are aggregate rows so profile doctor can present one
;;; actionable sandbox issue per loop intent instead of one row per mount.
;; : (-> [Symbol] [Alist] [Alist] [Symbol] [Alist])
(def (poo-flow-user-loop-engine-sandbox-handoff-agreement-diagnostics
      refs
      runtime-summaries
      handoff-summaries
      unresolved-refs)
  (let ((invalid-runtime-summaries
         (poo-flow-user-loop-engine-invalid-sandbox-runtime-summaries
          runtime-summaries)))
    (append
     (if (null? unresolved-refs)
       '()
       (list
        (list (cons 'field 'sandbox-profile-refs)
              (cons 'code 'unresolved-sandbox-profile-refs)
              (cons 'profile-refs unresolved-refs))))
     (if (null? invalid-runtime-summaries)
       '()
       (list
        (list (cons 'field 'sandbox-runtime-summaries)
              (cons 'code 'invalid-sandbox-runtime-summaries)
              (cons 'summary-count (length invalid-runtime-summaries))
              (cons 'summaries invalid-runtime-summaries))))
     (if (= (length refs)
            (+ (length handoff-summaries)
               (length unresolved-refs)
               (length invalid-runtime-summaries)))
       '()
       (list
        (list (cons 'field 'sandbox-handoff-summaries)
              (cons 'code 'sandbox-handoff-summary-count-mismatch)
              (cons 'profile-ref-count (length refs))
              (cons 'handoff-summary-count (length handoff-summaries))
              (cons 'unresolved-profile-ref-count
                    (length unresolved-refs))
              (cons 'invalid-runtime-summary-count
                    (length invalid-runtime-summaries))))))))

;;; The agreement is the stable loop-engine view over sandbox readiness. It is
;;; report-only and total; invalid profiles become diagnostics instead of throws.
;; : (-> [Symbol] [Alist] [Alist] [Symbol] Alist)
(def (poo-flow-user-loop-engine-sandbox-handoff-agreement
      refs
      runtime-summaries
      handoff-summaries
      unresolved-refs)
  (let* ((invalid-runtime-summaries
          (poo-flow-user-loop-engine-invalid-sandbox-runtime-summaries
           runtime-summaries))
         (diagnostics
          (poo-flow-user-loop-engine-sandbox-handoff-agreement-diagnostics
           refs
           runtime-summaries
           handoff-summaries
           unresolved-refs)))
    (list
     (cons 'kind 'loop-engine-sandbox-handoff-agreement)
     (cons 'contract
           +poo-flow-user-loop-engine-sandbox-handoff-agreement-contract+)
     (cons 'profile-refs refs)
     (cons 'profile-ref-count (length refs))
     (cons 'runtime-summary-count (length runtime-summaries))
     (cons 'handoff-summary-count (length handoff-summaries))
     (cons 'unresolved-profile-refs unresolved-refs)
     (cons 'unresolved-profile-ref-count (length unresolved-refs))
     (cons 'invalid-runtime-summaries invalid-runtime-summaries)
     (cons 'invalid-runtime-summary-count
           (length invalid-runtime-summaries))
     (cons 'diagnostic-count (length diagnostics))
     (cons 'diagnostics diagnostics)
     (cons 'valid? (null? diagnostics))
     (cons 'handoff-ready? (null? diagnostics))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

;; : (-> Symbol String Symbol)
(def (poo-flow-user-loop-engine-runtime-id use-case-name suffix)
  (string->symbol
   (string-append "loop-engine/"
                  (symbol->string use-case-name)
                  "/"
                  suffix)))

;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-workflow-ref intent)
  (let ((workflow-ref
         (poo-flow-user-loop-engine-section-ref
          (poo-flow-user-loop-engine-intent-ref intent 'use-case '())
          'workflow
          #f)))
    (if workflow-ref workflow-ref 'loop-engine)))
