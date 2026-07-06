(import (only-in :clan/poo/object .o .ref))

(export poo-flow-graph-reducer-intent
        poo-flow-graph-command-intent
        poo-flow-graph-fanout-intent
        poo-flow-graph-barrier-intent
        poo-flow-checkpoint-cadence-intent
        poo-flow-checkpoint-before-intent
        poo-flow-subgraph-node-intent
        poo-flow-subagent-node-intent
        poo-flow-stream-intent
        poo-flow-retry-intent
        poo-flow-timeout-intent
        poo-flow-error-route-intent
        poo-flow-replay-fork-intent
        poo-flow-store-scope-intent
        poo-flow-observability-intent
        poo-flow-state-version-intent
        poo-flow-scenario-gap-plan
        poo-flow-scenario-gap-plan-intents
        poo-flow-scenario-gap-plan-facts
        poo-flow-scenario-gap-plan-complete?
        poo-flow-scenario-gap-plan->lean-facts
        poo-flow-scenario-gap-intent-kinds
        poo-flow-scenario-gap-receipt-missing-kinds
        poo-flow-scenario-gap-runtime-row-plan-ok?
        poo-flow-scenario-gap-runtime-row-rejections-ok?
        poo-flow-scenario-gap-runtime-row-accepted-ok?
        poo-flow-scenario-gap-runtime-row-ok?
        poo-flow-scenario-gap-runtime-row->lean-facts)

;; P0: graph/platform primitives.
(def (poo-flow-graph-reducer-intent name state-key reducer value-type update-type)
  (.o kind: 'graph.reducer
      priority: 'P0
      name: name
      state-key: state-key
      reducer: reducer
      value-type: value-type
      update-type: update-type))

(def (poo-flow-graph-command-intent name from-node update-keys goto-targets)
  (.o kind: 'graph.command
      priority: 'P0
      name: name
      from-node: from-node
      update-keys: update-keys
      goto-targets: goto-targets))

(def (poo-flow-graph-fanout-intent name from-node task-key target-node result-key)
  (.o kind: 'graph.fanout
      priority: 'P0
      name: name
      from-node: from-node
      task-key: task-key
      target-node: target-node
      result-key: result-key))

(def (poo-flow-graph-barrier-intent name wait-for join-node merge-keys)
  (.o kind: 'graph.barrier
      priority: 'P0
      name: name
      wait-for: wait-for
      join-node: join-node
      merge-keys: merge-keys))

(def (poo-flow-checkpoint-cadence-intent name cadence scope)
  (.o kind: 'checkpoint.cadence
      priority: 'P0
      name: name
      cadence: cadence
      scope: scope))

(def (poo-flow-checkpoint-before-intent name before-node checkpoint-key)
  (.o kind: 'checkpoint.before
      priority: 'P0
      name: name
      before-node: before-node
      checkpoint-key: checkpoint-key))

(def (poo-flow-subgraph-node-intent name node child-graph parent-state child-state)
  (.o kind: 'graph.subgraph-node
      priority: 'P0
      name: name
      node: node
      child-graph: child-graph
      parent-state: parent-state
      child-state: child-state))

(def (poo-flow-subagent-node-intent name node session-key scope-key handoff-target)
  (.o kind: 'graph.subagent-node
      priority: 'P0
      name: name
      node: node
      session-key: session-key
      scope-key: scope-key
      handoff-target: handoff-target))

;; P1: runtime-owned, Scheme-declared primitives.
(def (poo-flow-stream-intent name event-classes projection-labels)
  (.o kind: 'runtime.stream
      priority: 'P1
      name: name
      event-classes: event-classes
      projection-labels: projection-labels))

(def (poo-flow-retry-intent name node attempts backoff)
  (.o kind: 'runtime.retry
      priority: 'P1
      name: name
      node: node
      attempts: attempts
      backoff: backoff))

(def (poo-flow-timeout-intent name node timeout-ms)
  (.o kind: 'runtime.timeout
      priority: 'P1
      name: name
      node: node
      timeout-ms: timeout-ms))

(def (poo-flow-error-route-intent name node after-retries target)
  (.o kind: 'runtime.error-route
      priority: 'P1
      name: name
      node: node
      after-retries: after-retries
      target: target))

(def (poo-flow-replay-fork-intent name checkpoint-key fork-key policy)
  (.o kind: 'runtime.replay-fork
      priority: 'P1
      name: name
      checkpoint-key: checkpoint-key
      fork-key: fork-key
      policy: policy))

(def (poo-flow-store-scope-intent name store-key scope access)
  (.o kind: 'runtime.store-scope
      priority: 'P1
      name: name
      store-key: store-key
      scope: scope
      access: access))

(def (poo-flow-observability-intent name labels receipt-keys)
  (.o kind: 'runtime.observability
      priority: 'P1
      name: name
      labels: labels
      receipt-keys: receipt-keys))

;; P2: production evolution hardening.
(def (poo-flow-state-version-intent name state-key from-version to-version drain-policy)
  (.o kind: 'profile.state-version
      priority: 'P2
      name: name
      state-key: state-key
      from-version: from-version
      to-version: to-version
      drain-policy: drain-policy))

(def (poo-flow-scenario-gap-plan name p0 p1 p2)
  (.o kind: 'scenario.gap-plan
      plan-id: name
      phase0: p0
      phase1: p1
      phase2: p2))

(def (poo-flow-scenario-gap-plan-intents plan)
  (append (.ref plan 'phase0)
          (.ref plan 'phase1)
          (.ref plan 'phase2)))

(def (poo-flow-count-priority intents priority)
  (let loop ((rest intents) (count 0))
    (if (null? rest)
      count
      (loop (cdr rest)
            (if (eq? (.ref (car rest) 'priority) priority)
              (+ count 1)
              count)))))

(def (poo-flow-kind-present? intents kind)
  (let loop ((rest intents))
    (cond
     ((null? rest) #f)
     ((eq? (.ref (car rest) 'kind) kind) #t)
     (else (loop (cdr rest))))))

(def (poo-flow-scenario-gap-plan-facts plan)
  (let* ((intents (poo-flow-scenario-gap-plan-intents plan))
         (p0-count (poo-flow-count-priority intents 'P0))
         (p1-count (poo-flow-count-priority intents 'P1))
         (p2-count (poo-flow-count-priority intents 'P2)))
    (.o kind: 'scenario.gap-facts
        plan: (.ref plan 'plan-id)
        phase0-count: p0-count
        phase1-count: p1-count
        phase2-count: p2-count
        reducer?: (poo-flow-kind-present? intents 'graph.reducer)
        command?: (poo-flow-kind-present? intents 'graph.command)
        fanout?: (poo-flow-kind-present? intents 'graph.fanout)
        barrier?: (poo-flow-kind-present? intents 'graph.barrier)
        checkpoint-before?: (poo-flow-kind-present? intents 'checkpoint.before)
        checkpoint-cadence?: (poo-flow-kind-present? intents 'checkpoint.cadence)
        subgraph-node?: (poo-flow-kind-present? intents 'graph.subgraph-node)
        subagent-node?: (poo-flow-kind-present? intents 'graph.subagent-node)
        stream?: (poo-flow-kind-present? intents 'runtime.stream)
        retry?: (poo-flow-kind-present? intents 'runtime.retry)
        timeout?: (poo-flow-kind-present? intents 'runtime.timeout)
        error-route?: (poo-flow-kind-present? intents 'runtime.error-route)
        replay-fork?: (poo-flow-kind-present? intents 'runtime.replay-fork)
        store-scope?: (poo-flow-kind-present? intents 'runtime.store-scope)
        observability?: (poo-flow-kind-present? intents 'runtime.observability)
        state-version?: (poo-flow-kind-present? intents 'profile.state-version))))

(def (poo-flow-scenario-gap-plan-complete? plan)
  (let ((facts (poo-flow-scenario-gap-plan-facts plan)))
    (and (> (.ref facts 'phase0-count) 0)
         (> (.ref facts 'phase1-count) 0)
         (> (.ref facts 'phase2-count) 0)
         (.ref facts 'reducer?)
         (.ref facts 'command?)
         (.ref facts 'fanout?)
         (.ref facts 'barrier?)
         (.ref facts 'checkpoint-before?)
         (.ref facts 'checkpoint-cadence?)
         (.ref facts 'subgraph-node?)
         (.ref facts 'subagent-node?)
         (.ref facts 'stream?)
         (.ref facts 'retry?)
         (.ref facts 'timeout?)
         (.ref facts 'error-route?)
         (.ref facts 'replay-fork?)
         (.ref facts 'store-scope?)
         (.ref facts 'observability?)
         (.ref facts 'state-version?))))

(def (poo-flow-scenario-gap-intent-kinds plan)
  (map (lambda (intent) (.ref intent 'kind))
       (poo-flow-scenario-gap-plan-intents plan)))

(def (poo-flow-symbol-member? value values)
  (let loop ((rest values))
    (cond
     ((null? rest) #f)
     ((eq? value (car rest)) #t)
     (else (loop (cdr rest))))))

(def (poo-flow-scenario-gap-receipt-missing-kinds plan accepted-kinds)
  (let loop ((required (poo-flow-scenario-gap-intent-kinds plan))
             (missing '()))
    (cond
     ((null? required) (reverse missing))
     ((poo-flow-symbol-member? (car required) accepted-kinds)
      (loop (cdr required) missing))
     (else
      (loop (cdr required) (cons (car required) missing))))))

(def (poo-flow-scenario-gap-runtime-row-value row key)
  (let ((cell (assq key row)))
    (if cell (cdr cell) #f)))

(def (poo-flow-scenario-gap-runtime-row-list row key)
  (let ((value (poo-flow-scenario-gap-runtime-row-value row key)))
    (if (list? value) value '())))

(def (poo-flow-scenario-gap-runtime-row-plan-ok? plan row)
  (eq? (poo-flow-scenario-gap-runtime-row-value row 'plan-id)
       (.ref plan 'plan-id)))

(def (poo-flow-scenario-gap-runtime-row-rejections-ok? row)
  (null? (poo-flow-scenario-gap-runtime-row-list row 'rejected-kinds)))

(def (poo-flow-scenario-gap-runtime-row-accepted-ok? plan row)
  (null? (poo-flow-scenario-gap-receipt-missing-kinds
          plan
          (poo-flow-scenario-gap-runtime-row-list row 'accepted-kinds))))

(def (poo-flow-scenario-gap-runtime-row-ok? plan row)
  (and (poo-flow-scenario-gap-runtime-row-plan-ok? plan row)
       (poo-flow-scenario-gap-runtime-row-rejections-ok? row)
       (poo-flow-scenario-gap-runtime-row-accepted-ok? plan row)))

(def (poo-flow-lean-bool value)
  (if value "true" "false"))

(def (poo-flow-scenario-gap-plan->lean-facts plan module-name)
  (let ((facts (poo-flow-scenario-gap-plan-facts plan)))
    (string-append
     "import PooFlowProof.PooC3.LangChainLangGraph\n\n"
     "namespace PooFlowProof\n\n"
     "def " module-name "P0Count : Nat := "
     (number->string (.ref facts 'phase0-count)) "\n"
     "def " module-name "P1Count : Nat := "
     (number->string (.ref facts 'phase1-count)) "\n"
     "def " module-name "P2Count : Nat := "
     (number->string (.ref facts 'phase2-count)) "\n"
     "def " module-name "HasReducer : Bool := "
     (poo-flow-lean-bool (.ref facts 'reducer?)) "\n"
     "def " module-name "HasCommand : Bool := "
     (poo-flow-lean-bool (.ref facts 'command?)) "\n"
     "def " module-name "HasCheckpointBefore : Bool := "
     (poo-flow-lean-bool (.ref facts 'checkpoint-before?)) "\n"
     "def " module-name "Complete : Bool := "
     (poo-flow-lean-bool (poo-flow-scenario-gap-plan-complete? plan)) "\n\n"
     "theorem " module-name "Complete_ok : "
     module-name "Complete = true := by\n"
     "  rfl\n\n"
     "end PooFlowProof\n")))

(def (poo-flow-scenario-gap-runtime-row->lean-facts plan row module-name)
  (let ((plan-ok
         (poo-flow-scenario-gap-runtime-row-plan-ok? plan row))
        (rejections-ok
         (poo-flow-scenario-gap-runtime-row-rejections-ok? row))
        (accepted-ok
         (poo-flow-scenario-gap-runtime-row-accepted-ok? plan row))
        (row-ok
         (poo-flow-scenario-gap-runtime-row-ok? plan row)))
    (string-append
     "import PooFlowProof.PooC3.ScenarioGap\n\n"
     "namespace PooFlowProof\n\n"
     "def " module-name "RuntimeRowFacts : ScenarioRuntimeRowFacts :=\n"
     "  { planOk := " (poo-flow-lean-bool plan-ok) "\n"
     "    rejectionsOk := " (poo-flow-lean-bool rejections-ok) "\n"
     "    acceptedOk := " (poo-flow-lean-bool accepted-ok) " }\n\n"
     "def " module-name "RuntimeRowComplete : Bool := "
     (poo-flow-lean-bool row-ok) "\n\n"
     "theorem " module-name "RuntimeRowComplete_ok : "
     module-name "RuntimeRowComplete = true := by\n"
     "  rfl\n\n"
     (if row-ok
       (string-append
        "theorem " module-name "RuntimeRowMatches :\n"
        "    runtimeRowMatchesPlan " module-name "RuntimeRowFacts := by\n"
        "  unfold runtimeRowMatchesPlan " module-name "RuntimeRowFacts\n"
        "  decide\n\n")
       "")
     "end PooFlowProof\n")))
