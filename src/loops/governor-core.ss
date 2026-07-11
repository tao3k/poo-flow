;;; -*- Gerbil -*-
;;; Boundary: loop governor POO roles, constructors, nodes, and slot accessors.
;;; Invariant: this owner stores policy data only and never evaluates runtime state.

(import (only-in :clan/poo/object .o object?)
        :poo-flow/src/core/roles
        :poo-flow/src/core/failure
        :poo-flow/src/core/object-syntax
        (only-in "./strategy.ss"
                 loop-strategy-engine-role
                 loop-strategy-plan?)
        (only-in "../utilities/contracts.ss"
                 poo-flow-contract-alist?
                 poo-flow-contract-list-of?
                 poo-flow-contract-check-slot!
                 poo-flow-object-type-contract->alist)
        (only-in "../utilities/contract-syntax.ss"
                 defcontract-family))

(export +loop-governor-schema+
        +loop-governor-node-schema+
        +loop-governor-default-state-key+
        +loop-governor-default-collision-policy+
        +loop-governor-default-aggregate-budget+
        +loop-governor-default-agent-judges+
        +loop-governor-default-human-inbox+
        +loop-governor-default-handoff+
        +loop-governor-node-slot-contracts+
        +loop-governor-slot-contracts+
        +loop-governor-node-type-contract+
        +loop-governor-type-contract+
        loop-governor-role
        loop-governor-node-role
        loop-governor-agent-node-role
        loop-governor-human-node-role
        loop-governor-priority-role
        loop-governor-state-role
        loop-governor-budget-role
        loop-governor-collision-role
        loop-governor-agent-judge-role
        loop-governor-inbox-role
        loop-governor-handoff-role
        loop-governor-node-prototype
        make-loop-governor-agent-node
        make-loop-governor-human-node
        loop-governor-prototype
        make-loop-governor
        loop-governor-node?
        loop-governor-node-slot
        loop-governor-node-name
        loop-governor-node-kind
        loop-governor-node-responsibility
        loop-governor-node-human-intervention?
        loop-governor-node-control-owner
        loop-governor-node-execution-owner
        loop-governor-node-metadata
        loop-governor-node->contract
        loop-governor-node-contracts
        loop-governor-alist?
        loop-governor-list-of?
        loop-governor-action-key?
        loop-governor-action-key-list?
        loop-governor-node-type-contract->alist
        loop-governor-type-contract->alist
        loop-governor-check-slot!
        loop-governor-require-node-slots!
        loop-governor-require-slots!
        loop-governor?
        loop-governor-slot
        loop-governor-name
        loop-governor-strategy
        loop-governor-priority-table
        loop-governor-shared-denylist
        loop-governor-aggregate-budget
        loop-governor-state-key
        loop-governor-collision-policy
        loop-governor-agent-judges
        loop-governor-agent-judge-nodes
        loop-governor-human-inbox
        loop-governor-handoff
        loop-governor-control-owner
        loop-governor-execution-owner
        loop-governor-metadata
        loop-governor-alist-ref)


;;; Governor schema tags the Marlin-facing contract object, not a runtime loop
;;; handle. Keeping it domain-named prevents schema constants from collapsing
;;; into generic symbols in policy reports.
;; : (-> Unit LoopGovernorSchema)
(def +loop-governor-schema+ 'poo-flow.loop-governor.v1)

;;; Node schema names one participant in the governor chain.
;;; Agent and human nodes share the same projection surface.
;; : (-> Unit LoopGovernorNodeSchema)
(def +loop-governor-node-schema+ 'poo-flow.loop-governor.node.v1)

;;; The state-key default names the runtime field that Marlin should persist
;;; before an action loop mutates a branch, ticket, file set, or connector item.
;; : (-> Unit Alist)
(def +loop-governor-default-state-key+
  '((field . acting_on)
    (scope . loop-state)
    (empty . #f)))

;;; Collision policy is a pre-runtime fact check over snapshots supplied by the
;;; runtime owner. Scheme only reports the conflict.
;; : (-> Unit Alist)
(def +loop-governor-default-collision-policy+
  '((mode . acting_on)
    (block-on-conflict . #t)))

;;; Aggregate budget is deliberately small by default so early loop governors
;;; recommend at most one effect-capable candidate per handoff.
;; : (-> Unit Alist)
(def +loop-governor-default-aggregate-budget+
  '((max-actionable . 1)
    (max-attempts . 1)))

;;; Agent judges describe governor-side review among agents. This is not human
;;; approval; a separate human audit loop owns real human intervention.
;; : (-> Unit Alist)
(def +loop-governor-default-agent-judges+
  '((mode . multi-agent-governance)
    (judge-mode . mutual-review)
    (human-intervention . #f)
    (participants . ((auditor . agent-auditor)
                     (verifier . agent-verifier)
                     (governor . loop-governor)))))

;;; Human inbox is a projection channel for blocked or escalated loop facts.
;;; It is not a notification transport and does not contact users.
;; : (-> Unit Alist)
(def +loop-governor-default-human-inbox+
  '((target . human-inbox)
    (mode . projection-only)))

;;; Governor handoff uses the same Marlin target while naming the governor
;;; contract so Rust can distinguish it from a single strategy plan.
;; : (-> Unit Alist)
(def +loop-governor-default-handoff+
  '((target . marlin-agent-core)
    (transport . scheme-abi)
    (contract . poo-flow.loop-governor.v1)))

;;; Boundary: root governor role owns multi-loop policy composition only.
;;; The runtime observes this role as data before it schedules anything.
;; : (-> Unit Role)
(def loop-governor-role
  (.o (:: @ loop-strategy-engine-role)
      (name 'loop-governor)
      (kind 'loop-control)
      (responsibility 'multi-loop-governance)
      (runtime-owner 'gerbil)
      (loop-capability 'governor-contract-projection)))

;;; Boundary: governance nodes are POO participants in the governor chain.
;;; They may be agent nodes or human nodes, but they share contract shape.
;; : (-> Unit Role)
(def loop-governor-node-role
  (.o (:: @ loop-governor-role)
      (name 'loop-governor-node)
      (kind 'loop-control)
      (responsibility 'governance-chain-node)
      (loop-capability 'governance-node)
      (loop-policy-slot 'governance-node)))

;;; Boundary: agent nodes are machine judges such as auditor or verifier.
;; : (-> Unit Role)
(def loop-governor-agent-node-role
  (.o (:: @ loop-governor-node-role)
      (name 'loop-governor-agent-node)
      (kind 'loop-policy)
      (responsibility 'agent-governance-node)
      (governance-node-kind 'agent)
      (human-intervention #f)))

;;; Boundary: human nodes keep governor lineage while marking human authority.
;; : (-> Unit Role)
(def loop-governor-human-node-role
  (.o (:: @ loop-governor-node-role)
      (name 'loop-governor-human-node)
      (kind 'loop-control)
      (responsibility 'human-governance-node)
      (governance-node-kind 'human)
      (human-intervention #t)))

;;; Boundary: priority stays a role so repository policy can override default
;;; ordering without changing descriptor or strategy constructors.
;; : (-> Unit Role)
(def loop-governor-priority-role
  (.o (:: @ loop-governor-role)
      (name 'loop-governor-priority)
      (kind 'loop-policy)
      (responsibility 'static-priority-table)
      (loop-policy-slot 'priority-table)))

;;; Boundary: state role records the key convention for runtime snapshots.
;;; Scheme reads supplied facts but never persists the state.
;; : (-> Unit Role)
(def loop-governor-state-role
  (.o (:: @ loop-governor-role)
      (name 'loop-governor-state)
      (kind 'loop-policy)
      (responsibility 'state-key-convention)
      (loop-policy-slot 'state-key)))

;;; Boundary: aggregate budget is a governor role because it spans patterns.
;;; Per-pattern budgets remain owned by loop descriptors.
;; : (-> Unit Role)
(def loop-governor-budget-role
  (.o (:: @ loop-governor-role)
      (name 'loop-governor-budget)
      (kind 'loop-policy)
      (responsibility 'aggregate-budget-envelope)
      (loop-policy-slot 'aggregate-budget)))

;;; Boundary: collision detection is a fact projection over runtime snapshots.
;;; It blocks recommendations but does not lock or write the contested target.
;; : (-> Unit Role)
(def loop-governor-collision-role
  (.o (:: @ loop-governor-role)
      (name 'loop-governor-collision)
      (kind 'loop-policy)
      (responsibility 'acting-on-collision-policy)
      (loop-policy-slot 'collision-policy)))

;;; Boundary: agent judges are governor facts for multi-agent review.
;;; Human approval remains owned by the separate human audit loop.
;; : (-> Unit Role)
(def loop-governor-agent-judge-role
  (.o (:: @ loop-governor-role)
      (name 'loop-governor-agent-judge)
      (kind 'loop-policy)
      (responsibility 'multi-agent-judgement-policy)
      (loop-policy-slot 'agent-judges)))

;;; Boundary: inbox projection explains blocked work to humans as data.
;;; Delivery and acknowledgement remain outside the Scheme control plane.
;; : (-> Unit Role)
(def loop-governor-inbox-role
  (.o (:: @ loop-governor-role)
      (name 'loop-governor-inbox)
      (kind 'loop-policy)
      (responsibility 'human-inbox-projection)
      (loop-policy-slot 'human-inbox)))

;;; Boundary: handoff role carries the Marlin target through C3 composition.
;;; Runtime request construction remains a later Rust boundary.
;; : (-> Unit Role)
(def loop-governor-handoff-role
  (.o (:: @ loop-governor-role)
      (name 'loop-governor-handoff)
      (kind 'loop-boundary)
      (responsibility 'marlin-governor-contract)
      (loop-policy-slot 'handoff)))

;;; Governance node prototype keeps participants in the POO graph instead of
;;; flattening auditor/verifier/governor roles into ad hoc symbols.
;; : (-> Unit LoopGovernorNodePrototype)
(def loop-governor-node-prototype
  (poo-core-role-object
   (slots ((node-schema +loop-governor-node-schema+)
           (kind 'loop-governance-node)
           (name #f)
           (governance-node-kind 'agent)
           (governance-responsibility 'judge)
           (human-intervention #f)
           (control-owner 'gerbil)
           (execution-owner 'marlin-agent-core)
           (metadata '())))
   (supers loop-governor-node-role)))

;; : (-> Alist Alist Alist)
(def (loop-governor-slot-rows/tail rows tail)
  (foldr cons tail rows))

;; : (-> Symbol Symbol Symbol Boolean Alist Alist)
(def (loop-governor-node-slot-rows name
                                   governance-node-kind
                                   responsibility
                                   human-intervention?
                                   overrides)
  (loop-governor-slot-rows/tail
   (list
    (cons 'name name)
    (cons 'governance-node-kind governance-node-kind)
    (cons 'governance-responsibility responsibility)
    (cons 'human-intervention human-intervention?))
   overrides))

;;; Agent governor nodes model machine-side judges such as auditor/verifier.
;; : (-> Symbol Symbol [Alist] LoopGovernorNode)
(def (make-loop-governor-agent-node name responsibility . maybe-overrides)
  (poo-core-role-object
   (slot-rows
    (loop-governor-node-slot-rows
     name
     'agent
     responsibility
     #f
     (if (null? maybe-overrides) '() (car maybe-overrides))))
   (supers loop-governor-agent-node-role
           loop-governor-node-prototype)))

;;; Human governor nodes retain governor lineage while marking human authority.
;; : (-> Symbol Symbol [Alist] LoopGovernorNode)
(def (make-loop-governor-human-node name responsibility . maybe-overrides)
  (poo-core-role-object
   (slot-rows
    (loop-governor-node-slot-rows
     name
     'human
     responsibility
     #t
     (if (null? maybe-overrides) '() (car maybe-overrides))))
   (supers loop-governor-human-node-role
           loop-governor-node-prototype)))

;;; Default agent judges are POO nodes so downstream contracts can inspect
;;; the judge graph without parsing symbols from the aggregate policy alist.
;; : (-> Unit [LoopGovernorNode])
(def (loop-governor-default-agent-judge-nodes)
  (list (make-loop-governor-agent-node 'agent-auditor 'audit)
        (make-loop-governor-agent-node 'agent-verifier 'verify)
        (make-loop-governor-agent-node 'loop-governor 'govern)))

;;; Governor prototype composes only policy roles and inert default slots.
;;; No slot stores runtime handles, timers, locks, or connector clients.
;; : (-> Unit LoopGovernorPrototype)
(def loop-governor-prototype
  (poo-core-role-object
   (slots ((schema +loop-governor-schema+)
           (kind 'loop-governor)
           (name #f)
           (strategy #f)
           (priority-table '())
           (shared-denylist '())
           (aggregate-budget +loop-governor-default-aggregate-budget+)
           (state-key +loop-governor-default-state-key+)
           (collision-policy +loop-governor-default-collision-policy+)
           (agent-judges +loop-governor-default-agent-judges+)
           (agent-judge-nodes
            (loop-governor-default-agent-judge-nodes))
           (human-inbox +loop-governor-default-human-inbox+)
           (handoff +loop-governor-default-handoff+)
           (control-owner 'gerbil)
           (execution-owner 'marlin-agent-core)
           (metadata '())))
   (supers loop-governor-handoff-role
           loop-governor-inbox-role
           loop-governor-agent-judge-role
           loop-governor-collision-role
           loop-governor-budget-role
           loop-governor-state-role
           loop-governor-priority-role
           loop-governor-role)))

;; : (-> Symbol LoopStrategyPlan Alist Alist)

;;; Constructor binds a validated strategy plan to governor policy overrides.
;;; Runtime state snapshots are supplied later to projection helpers.
;; : (-> Symbol LoopStrategyPlan [Alist] LoopGovernor)

;; : (-> LoopGovernorCandidate Boolean)

;;; Slot probing goes through role helpers so C3-composed overrides keep the
;;; same access boundary as pattern descriptors and strategy plans.
;; : (-> LoopGovernor Symbol LoopGovernorSlotValue LoopGovernorSlotValue)

;; : (-> LoopGovernorNodeCandidate Boolean)

;; : (-> LoopGovernorNode Symbol Value Value)

;; : (-> LoopGovernorNode Symbol)

;; : (-> LoopGovernorNode Symbol)

;;; Boundary: loop governor node responsibility is the policy-visible edge for
;;; loop, core behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> LoopGovernorNode Symbol)

;; : (-> LoopGovernorNode Boolean)

;; : (-> LoopGovernorNode Symbol)

;; : (-> LoopGovernorNode Symbol)

;; : (-> LoopGovernorNode Alist)

;;; Node contracts are the common projection for agent judges and human nodes.
;; : (-> LoopGovernorNode Alist)
(include "governor-projection-implementation.inc")

;;; Node contract projection is a map over validated governance nodes, keeping
;;; review/report consumers independent from the internal role object shape.
;; : (-> [LoopGovernorNode] [Alist])

;;; Governor alist lookup is local because state facts and policy slots share
;;; the same simple alist shape but stay semantically separate.
;; : (-> Alist Symbol AlistValue AlistValue)

;; loop-governor-alist?
;;   : (-> PooFlowValue Boolean)
;;   | doc m%
;;       Recognize the alist contract shape used by governor policy slots.
;;       # Examples
;;       (loop-governor-alist? '((field . acting_on)))
;;       # Result
;;       #t for proper association lists.
;;     %

;; loop-governor-list-of?
;;   : (-> (-> PooFlowValue Boolean) PooFlowValue Boolean)
;;   | doc m%
;;       Recognize proper governor lists whose elements satisfy a predicate.
;;       # Examples
;;       (loop-governor-list-of? symbol? '(audit verify))
;;       # Result
;;       #t when every element satisfies the supplied predicate.
;;     %

;; : (-> PooFlowValue Boolean)

;; : (-> PooFlowValue Boolean)

;; : (-> PooFlowValue Boolean)

;; : (-> PooFlowValue Boolean)

;; loop-governor-node-type-contract->alist
;;   : (-> Unit Alist)
;;   | doc m%
;;       Project the structured contract for governor node POO objects.
;;       # Examples
;;       (loop-governor-node-type-contract->alist)
;;       # Result
;;       An alist representation suitable for doctor and manifest output.
;;     %

;; loop-governor-type-contract->alist
;;   : (-> Unit Alist)
;;   | doc m%
;;       Project the structured contract for loop governor POO objects.
;;       # Examples
;;       (loop-governor-type-contract->alist)
;;       # Result
;;       An alist representation suitable for validator and proof facts.
;;     %

;; loop-governor-check-slot!
;;   : (-> PooFlowSlotContract PooFlowValue PooFlowValue)
;;   | doc m%
;;       Execute one governor slot contract through the utilities layer.
;;       # Examples
;;       (loop-governor-check-slot! +loop-governor-name-contract+ 'repo)
;;       # Result
;;       The original value when valid; otherwise raises a contract error.
;;     %

;; loop-governor-require-node-slots!
;;   : (-> Symbol Symbol Symbol Boolean Symbol Symbol Alist Boolean)
;;   | doc m%
;;       Enforce generated slot contracts for one governor node projection.
;;       # Examples
;;       (loop-governor-require-node-slots!
;;        'audit 'agent 'verify #f 'gerbil 'marlin-agent-core '())
;;       # Result
;;       #t when every node slot satisfies its contract.
;;     %

;; loop-governor-require-slots!
;;   : (-> Symbol LoopStrategyPlan Alist [ActionKey] Alist Alist Alist Alist Alist [LoopGovernorNode] Alist Alist Symbol Symbol Alist Boolean)
;;   | doc m%
;;       Enforce generated slot contracts for the governor contract boundary.
;;       # Examples
;;       (loop-governor-require-slots!
;;        'repo strategy '() '() state-key collision budget judges nodes inbox handoff 'gerbil 'marlin-agent-core '())
;;       # Result
;;       #t when every governor slot satisfies its contract.
;;     %
(def (loop-governor-require-slots! name strategy priority-table shared-denylist state-key collision-policy aggregate-budget agent-judges agent-judge-nodes human-inbox handoff control-owner execution-owner metadata)
  (loop-governor-require-slots/validated!
   name
   strategy
   priority-table
   shared-denylist
   state-key
   collision-policy
   aggregate-budget
   agent-judges
   agent-judge-nodes
   human-inbox
   handoff
   control-owner
   execution-owner
   metadata))

;; : (-> LoopGovernor Symbol)

;; : (-> LoopGovernor LoopStrategyPlan)

;; : (-> LoopGovernor Alist)

;; : (-> LoopGovernor [ActionKey])

;; : (-> LoopGovernor Alist)

;; : (-> LoopGovernor Alist)

;; : (-> LoopGovernor Alist)

;; : (-> LoopGovernor Alist)

;; : (-> LoopGovernor [LoopGovernorNode])

;; : (-> LoopGovernor Alist)

;; : (-> LoopGovernor Alist)

;; : (-> LoopGovernor Symbol)

;; : (-> LoopGovernor Symbol)

;; : (-> LoopGovernor Alist)

(defcontract-family
  +loop-governor-node-slot-contracts+
  +loop-governor-node-type-contract+
  'loop-governor/node
  'loops
  'LoopGovernorNode
  '((boundary . loop-governor) (projection . governance-node))
  ((+loop-governor-node-name-contract+
    'loop-governor.node/name
    'name
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-governor-node-governance-node-kind-contract+
    'loop-governor.node/governance-node-kind
    'governance-node-kind
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-governor-node-governance-responsibility-contract+
    'loop-governor.node/governance-responsibility
    'governance-responsibility
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-governor-node-human-intervention-contract+
    'loop-governor.node/human-intervention
    'human-intervention
    'Boolean
    'boolean?
    boolean?
    #t
    '())
   (+loop-governor-node-control-owner-contract+
    'loop-governor.node/control-owner
    'control-owner
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-governor-node-execution-owner-contract+
    'loop-governor.node/execution-owner
    'execution-owner
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-governor-node-metadata-contract+
    'loop-governor.node/metadata
    'metadata
    'Alist
    'loop-governor-alist?
    loop-governor-alist?
    #t
    '())))

(defcontract-family
  +loop-governor-slot-contracts+
  +loop-governor-type-contract+
  'loop-governor
  'loops
  'LoopGovernor
  '((boundary . loop-governor) (projection . marlin-contract))
  ((+loop-governor-name-contract+
    'loop-governor/name
    'name
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-governor-strategy-contract+
    'loop-governor/strategy
    'strategy
    'LoopStrategyPlan
    'loop-governor-strategy-plan-slot?
    loop-governor-strategy-plan-slot?
    #t
    '())
   (+loop-governor-priority-table-contract+
    'loop-governor/priority-table
    'priority-table
    'Alist
    'loop-governor-alist?
    loop-governor-alist?
    #t
    '())
   (+loop-governor-shared-denylist-contract+
    'loop-governor/shared-denylist
    'shared-denylist
    '[ActionKey]
    'loop-governor-action-key-list?
    loop-governor-action-key-list?
    #t
    '())
   (+loop-governor-state-key-contract+
    'loop-governor/state-key
    'state-key
    'Alist
    'loop-governor-alist?
    loop-governor-alist?
    #t
    '())
   (+loop-governor-collision-policy-contract+
    'loop-governor/collision-policy
    'collision-policy
    'Alist
    'loop-governor-alist?
    loop-governor-alist?
    #t
    '())
   (+loop-governor-aggregate-budget-contract+
    'loop-governor/aggregate-budget
    'aggregate-budget
    'Alist
    'loop-governor-alist?
    loop-governor-alist?
    #t
    '())
   (+loop-governor-agent-judges-contract+
    'loop-governor/agent-judges
    'agent-judges
    'Alist
    'loop-governor-alist?
    loop-governor-alist?
    #t
    '())
   (+loop-governor-agent-judge-nodes-contract+
    'loop-governor/agent-judge-nodes
    'agent-judge-nodes
    '[LoopGovernorNode]
    'loop-governor-node-list?
    loop-governor-node-list?
    #t
    '())
   (+loop-governor-human-inbox-contract+
    'loop-governor/human-inbox
    'human-inbox
    'Alist
    'loop-governor-alist?
    loop-governor-alist?
    #t
    '())
   (+loop-governor-handoff-contract+
    'loop-governor/handoff
    'handoff
    'Alist
    'loop-governor-alist?
    loop-governor-alist?
    #t
    '())
   (+loop-governor-control-owner-contract+
    'loop-governor/control-owner
    'control-owner
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-governor-execution-owner-contract+
    'loop-governor/execution-owner
    'execution-owner
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-governor-metadata-contract+
    'loop-governor/metadata
    'metadata
    'Alist
    'loop-governor-alist?
    loop-governor-alist?
    #t
    '())))
