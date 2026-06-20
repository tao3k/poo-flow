;;; -*- Gerbil -*-
;;; Boundary: loop governors coordinate strategy contracts with runtime state facts.
;;; Invariant: this module never polls, locks, writes state, or executes loops.

(import (only-in :clan/poo/object .o .mix object?)
        :poo-flow/src/core/roles
        :poo-flow/src/core/failure
        :poo-flow/src/loops/descriptor
        :poo-flow/src/loops/strategy)

(export +loop-governor-schema+
        +loop-governor-node-schema+
        +loop-governor-default-state-key+
        +loop-governor-default-collision-policy+
        +loop-governor-default-aggregate-budget+
        +loop-governor-default-agent-judges+
        +loop-governor-default-human-inbox+
        +loop-governor-default-handoff+
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
        loop-governor-state-field
        loop-governor-budget-limit
        loop-governor-pattern-action-key
        loop-governor-state-action-key
        loop-governor-pattern-denied?
        loop-governor-pattern-conflicted?
        loop-governor-denied-patterns
        loop-governor-conflicting-patterns
        loop-governor-open-patterns
        loop-governor-human-inbox-items
        loop-governor-validation-errors
        validate-loop-governor
        loop-governor->contract)

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
  (.mix slots: (role-constant-slots
                (list (cons 'node-schema +loop-governor-node-schema+)
                      (cons 'kind 'loop-governance-node)
                      (cons 'name #f)
                      (cons 'governance-node-kind 'agent)
                      (cons 'governance-responsibility 'judge)
                      (cons 'human-intervention #f)
                      (cons 'control-owner 'gerbil)
                      (cons 'execution-owner 'marlin-agent-core)
                      (cons 'metadata '())))
        loop-governor-node-role))

;;; Agent governor nodes model machine-side judges such as auditor/verifier.
;; : (-> Symbol Symbol [Alist] LoopGovernorNode)
(def (make-loop-governor-agent-node name responsibility . maybe-overrides)
  (.mix slots: (role-constant-slots
                (append
                 (list (cons 'name name)
                       (cons 'governance-node-kind 'agent)
                       (cons 'governance-responsibility responsibility)
                       (cons 'human-intervention #f))
                 (if (null? maybe-overrides) '() (car maybe-overrides))))
        loop-governor-agent-node-role
        loop-governor-node-prototype))

;;; Human governor nodes retain governor lineage while marking human authority.
;; : (-> Symbol Symbol [Alist] LoopGovernorNode)
(def (make-loop-governor-human-node name responsibility . maybe-overrides)
  (.mix slots: (role-constant-slots
                (append
                 (list (cons 'name name)
                       (cons 'governance-node-kind 'human)
                       (cons 'governance-responsibility responsibility)
                       (cons 'human-intervention #t))
                 (if (null? maybe-overrides) '() (car maybe-overrides))))
        loop-governor-human-node-role
        loop-governor-node-prototype))

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
  (.mix slots: (role-constant-slots
                (list (cons 'schema +loop-governor-schema+)
                      (cons 'kind 'loop-governor)
                      (cons 'name #f)
                      (cons 'strategy #f)
                      (cons 'priority-table '())
                      (cons 'shared-denylist '())
                      (cons 'aggregate-budget +loop-governor-default-aggregate-budget+)
                      (cons 'state-key +loop-governor-default-state-key+)
                      (cons 'collision-policy +loop-governor-default-collision-policy+)
                      (cons 'agent-judges +loop-governor-default-agent-judges+)
                      (cons 'agent-judge-nodes
                            (loop-governor-default-agent-judge-nodes))
                      (cons 'human-inbox +loop-governor-default-human-inbox+)
                      (cons 'handoff +loop-governor-default-handoff+)
                      (cons 'control-owner 'gerbil)
                      (cons 'execution-owner 'marlin-agent-core)
                      (cons 'metadata '())))
        loop-governor-handoff-role
        loop-governor-inbox-role
        loop-governor-agent-judge-role
        loop-governor-collision-role
        loop-governor-budget-role
        loop-governor-state-role
        loop-governor-priority-role
        loop-governor-role))

;;; Constructor binds a validated strategy plan to governor policy overrides.
;;; Runtime state snapshots are supplied later to projection helpers.
;; : (-> Symbol LoopStrategyPlan [Alist] LoopGovernor)
(def (make-loop-governor name strategy . maybe-overrides)
  (.mix slots: (role-constant-slots
                (append
                 (list (cons 'name name)
                       (cons 'strategy strategy))
                 (if (null? maybe-overrides) '() (car maybe-overrides))))
        loop-governor-prototype))

;; : (-> LoopGovernorCandidate Boolean)
(def (loop-governor? governor)
  (and (object? governor)
       (eq? (loop-governor-slot governor 'kind #f)
            'loop-governor)))

;;; Slot probing goes through role helpers so C3-composed overrides keep the
;;; same access boundary as pattern descriptors and strategy plans.
;; : (-> LoopGovernor Symbol LoopGovernorSlotValue LoopGovernorSlotValue)
(def (loop-governor-slot governor slot default)
  (role-slot/default governor slot default))

;; : (-> LoopGovernorNodeCandidate Boolean)
(def (loop-governor-node? node)
  (and (object? node)
       (loop-governor-node-kind node)
       #t))

;; : (-> LoopGovernorNode Symbol Value Value)
(def (loop-governor-node-slot node slot default)
  (role-slot/default node slot default))

;; : (-> LoopGovernorNode Symbol)
(def (loop-governor-node-name node)
  (loop-governor-node-slot node 'name #f))

;; : (-> LoopGovernorNode Symbol)
(def (loop-governor-node-kind node)
  (loop-governor-node-slot node 'governance-node-kind #f))

;; : (-> LoopGovernorNode Symbol)
(def (loop-governor-node-responsibility node)
  (let (specific
        (loop-governor-node-slot node 'governance-responsibility #f))
    (if specific
      specific
      (loop-governor-node-slot node 'responsibility #f))))

;; : (-> LoopGovernorNode Boolean)
(def (loop-governor-node-human-intervention? node)
  (loop-governor-node-slot node 'human-intervention #f))

;; : (-> LoopGovernorNode Symbol)
(def (loop-governor-node-control-owner node)
  (loop-governor-node-slot node 'control-owner #f))

;; : (-> LoopGovernorNode Symbol)
(def (loop-governor-node-execution-owner node)
  (loop-governor-node-slot node 'execution-owner #f))

;; : (-> LoopGovernorNode Alist)
(def (loop-governor-node-metadata node)
  (loop-governor-node-slot node 'metadata '()))

;;; Node contracts are the common projection for agent judges and human nodes.
;; : (-> LoopGovernorNode Alist)
(def (loop-governor-node->contract node)
  (list (cons 'schema +loop-governor-node-schema+)
        (cons 'kind 'loop-governance-node)
        (cons 'name (loop-governor-node-name node))
        (cons 'governance-node-kind (loop-governor-node-kind node))
        (cons 'governance-responsibility
              (loop-governor-node-responsibility node))
        (cons 'human-intervention
              (loop-governor-node-human-intervention? node))
        (cons 'control-owner (loop-governor-node-control-owner node))
        (cons 'execution-owner (loop-governor-node-execution-owner node))
        (cons 'metadata (loop-governor-node-metadata node))))

;;; Node contract projection is a map over validated governance nodes, keeping
;;; review/report consumers independent from the internal role object shape.
;; : (-> [LoopGovernorNode] [Alist])
(def (loop-governor-node-contracts nodes)
  (map loop-governor-node->contract nodes))

;;; Governor alist lookup is local because state facts and policy slots share
;;; the same simple alist shape but stay semantically separate.
;; : (-> Alist Symbol AlistValue AlistValue)
(def (loop-governor-alist-ref alist key default)
  (cond
   ((assoc key alist) => cdr)
   (else default)))

;; : (-> LoopGovernor Symbol)
(def (loop-governor-name governor)
  (loop-governor-slot governor 'name #f))

;; : (-> LoopGovernor LoopStrategyPlan)
(def (loop-governor-strategy governor)
  (loop-governor-slot governor 'strategy #f))

;; : (-> LoopGovernor Alist)
(def (loop-governor-priority-table governor)
  (loop-governor-slot governor 'priority-table '()))

;; : (-> LoopGovernor [ActionKey])
(def (loop-governor-shared-denylist governor)
  (loop-governor-slot governor 'shared-denylist '()))

;; : (-> LoopGovernor Alist)
(def (loop-governor-aggregate-budget governor)
  (loop-governor-slot governor 'aggregate-budget '()))

;; : (-> LoopGovernor Alist)
(def (loop-governor-state-key governor)
  (loop-governor-slot governor 'state-key '()))

;; : (-> LoopGovernor Alist)
(def (loop-governor-collision-policy governor)
  (loop-governor-slot governor 'collision-policy '()))

;; : (-> LoopGovernor Alist)
(def (loop-governor-agent-judges governor)
  (loop-governor-slot governor 'agent-judges '()))

;; : (-> LoopGovernor [LoopGovernorNode])
(def (loop-governor-agent-judge-nodes governor)
  (loop-governor-slot governor 'agent-judge-nodes '()))

;; : (-> LoopGovernor Alist)
(def (loop-governor-human-inbox governor)
  (loop-governor-slot governor 'human-inbox '()))

;; : (-> LoopGovernor Alist)
(def (loop-governor-handoff governor)
  (loop-governor-slot governor 'handoff '()))

;; : (-> LoopGovernor Symbol)
(def (loop-governor-control-owner governor)
  (loop-governor-slot governor 'control-owner #f))

;; : (-> LoopGovernor Symbol)
(def (loop-governor-execution-owner governor)
  (loop-governor-slot governor 'execution-owner #f))

;; : (-> LoopGovernor Alist)
(def (loop-governor-metadata governor)
  (loop-governor-slot governor 'metadata '()))

;;; State field lookup exposes the runtime snapshot key as a first-class policy
;;; value so downstream contracts can rename it without changing predicates.
;; : (-> LoopGovernor Symbol)
(def (loop-governor-state-field governor)
  (loop-governor-alist-ref (loop-governor-state-key governor) 'field 'acting_on))

;;; Budget limit is the only local budget behavior in this owner.
;;; Counting attempts and spending tokens remains runtime-owned state.
;; : (-> LoopGovernor Integer)
(def (loop-governor-budget-limit governor)
  (loop-governor-alist-ref (loop-governor-aggregate-budget governor)
                           'max-actionable
                           1))

;;; Pattern action keys come from descriptor metadata when present.
;;; Falling back to the pattern name keeps report-only examples inspectable.
;; : (-> LoopPatternDescriptor ActionKey)
(def (loop-governor-pattern-action-key descriptor)
  (loop-governor-alist-ref (loop-pattern-metadata descriptor)
                           'acting_on
                           (loop-pattern-name descriptor)))

;;; Runtime state snapshots use the governor state field by convention.
;;; Missing or empty values mean no active ownership claim.
;; : (-> LoopGovernor Alist MaybeActionKey)
(def (loop-governor-state-action-key governor state)
  (loop-governor-alist-ref state
                           (loop-governor-state-field governor)
                           #f))

;; : (-> ActionKey [ActionKey] Boolean)
(def (loop-governor-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else
    (loop-governor-member? value (cdr values)))))

;; : (-> Predicate [Value] [Value])
(def (loop-governor-filter predicate values)
  (cond
   ((null? values) '())
   ((predicate (car values))
    (cons (car values)
          (loop-governor-filter predicate (cdr values))))
   (else
    (loop-governor-filter predicate (cdr values)))))

;; : (-> Nat [Value] [Value])
(def (loop-governor-take-at-most limit values)
  (cond
   ((<= limit 0) '())
   ((null? values) '())
   (else
    (cons (car values)
          (loop-governor-take-at-most (- limit 1) (cdr values))))))

;;; Denylist checks both action keys and pattern names so policy authors can
;;; block a target scope or a named loop with the same slot.
;; : (-> LoopGovernor LoopPatternDescriptor Boolean)
(def (loop-governor-pattern-denied? governor descriptor)
  (let (denylist (loop-governor-shared-denylist governor))
    (or (loop-governor-member? (loop-governor-pattern-action-key descriptor)
                               denylist)
        (loop-governor-member? (loop-pattern-name descriptor)
                               denylist))))

;;; Collision checks compare descriptor action keys with runtime-supplied state
;;; facts. The check never claims the target or edits the state snapshot.
;; : (-> LoopGovernor [Alist] LoopPatternDescriptor Boolean)
(def (loop-governor-pattern-conflicted? governor states descriptor)
  (let (action-key (loop-governor-pattern-action-key descriptor))
    (and action-key
         (loop-governor-member?
          action-key
          (loop-governor-filter
           (lambda (state-action-key)
             state-action-key)
           (map (lambda (state)
                  (loop-governor-state-action-key governor state))
                states))))))

;;; Denied projection is kept separate from collision projection so doctors can
;;; explain policy blocks and state conflicts independently.
;; : (-> LoopGovernor [LoopPatternDescriptor])
(def (loop-governor-denied-patterns governor)
  (let (valid-governor (validate-loop-governor governor))
    (loop-governor-filter
     (lambda (descriptor)
       (loop-governor-pattern-denied? valid-governor descriptor))
     (loop-strategy-actionable-patterns
      (loop-governor-strategy valid-governor)))))

;;; Conflict projection consumes runtime state facts as an argument.
;;; Callers can test state behavior without starting a scheduler.
;; : (-> LoopGovernor [Alist] [LoopPatternDescriptor])
(def (loop-governor-conflicting-patterns governor states)
  (let (valid-governor (validate-loop-governor governor))
    (loop-governor-filter
     (lambda (descriptor)
       (loop-governor-pattern-conflicted? valid-governor states descriptor))
     (loop-strategy-actionable-patterns
      (loop-governor-strategy valid-governor)))))

;;; Open patterns are recommendations after static denylist and state conflict
;;; checks, then clipped by the aggregate max-actionable budget.
;; : (-> LoopGovernor [Alist] [LoopPatternDescriptor])
(def (loop-governor-open-patterns governor states)
  (let (valid-governor (validate-loop-governor governor))
    (loop-governor-take-at-most
     (loop-governor-budget-limit valid-governor)
     (loop-governor-filter
      (lambda (descriptor)
        (and (not (loop-governor-pattern-denied? valid-governor descriptor))
             (not (loop-governor-pattern-conflicted? valid-governor
                                                     states
                                                     descriptor))))
      (loop-strategy-actionable-patterns
       (loop-governor-strategy valid-governor))))))

;; : (-> Symbol LoopPatternDescriptor ActionKey Alist)
(def (loop-governor-inbox-item reason descriptor action-key)
  (list (cons 'reason reason)
        (cons 'pattern (loop-pattern-name descriptor))
        (cons 'acting_on action-key)))

;;; Human inbox items describe blocked recommendations as structured data.
;;; The inbox target is a later runtime or UI concern.
;; : (-> LoopGovernor [Alist] [Alist])
(def (loop-governor-human-inbox-items governor states)
  (let (valid-governor (validate-loop-governor governor))
    (append
     (map (lambda (descriptor)
            (loop-governor-inbox-item
             'shared-denylist
             descriptor
             (loop-governor-pattern-action-key descriptor)))
          (loop-governor-denied-patterns valid-governor))
     (map (lambda (descriptor)
            (loop-governor-inbox-item
             'acting-on-conflict
             descriptor
             (loop-governor-pattern-action-key descriptor)))
          (loop-governor-conflicting-patterns valid-governor states)))))

;;; Required errors use the same alist shape as strategy validation.
;;; That keeps governor findings composable with existing doctor output.
;; : (-> Symbol FieldValue [ValidationError])
(def (loop-governor-required-field-error field value)
  (if value
    '()
    (list (list (cons 'field field)
                (cons 'code 'required)))))

;; : (-> [Value] [ValidationError])
(def (loop-governor-node-list-validation-errors nodes)
  (cond
   ((null? nodes) '())
   ((loop-governor-node? (car nodes))
    (loop-governor-node-list-validation-errors (cdr nodes)))
   (else
    (cons (list (cons 'field 'agent-judge-nodes)
                (cons 'code 'not-loop-governor-node)
                (cons 'value (car nodes)))
          (loop-governor-node-list-validation-errors (cdr nodes))))))

;;; Validation folds strategy-plan errors under the governor boundary.
;;; Runtime state remains outside validation because it changes per handoff.
;; : (-> LoopGovernor [ValidationError])
(def (loop-governor-validation-errors governor)
  (if (loop-governor? governor)
    (append
     (loop-governor-required-field-error 'name (loop-governor-name governor))
     (if (loop-strategy-plan? (loop-governor-strategy governor))
       (let (strategy-errors
             (loop-strategy-validation-errors
              (loop-governor-strategy governor)))
         (if (null? strategy-errors)
           '()
           (list (list (cons 'field 'strategy)
                       (cons 'code 'invalid-strategy)
                       (cons 'errors strategy-errors)))))
       (list (list (cons 'field 'strategy)
                   (cons 'code 'not-loop-strategy-plan))))
     (if (symbol? (loop-governor-state-field governor))
       '()
       (list (list (cons 'field 'state-key)
                   (cons 'code 'field-not-symbol)
                   (cons 'value (loop-governor-state-field governor)))))
     (if (integer? (loop-governor-budget-limit governor))
       '()
       (list (list (cons 'field 'aggregate-budget)
                   (cons 'code 'max-actionable-not-integer)
                   (cons 'value (loop-governor-budget-limit governor)))))
     (if (list? (loop-governor-agent-judges governor))
       '()
       (list (list (cons 'field 'agent-judges)
                   (cons 'code 'not-list)
                   (cons 'value (loop-governor-agent-judges governor)))))
     (if (list? (loop-governor-agent-judge-nodes governor))
       (loop-governor-node-list-validation-errors
        (loop-governor-agent-judge-nodes governor))
       (list (list (cons 'field 'agent-judge-nodes)
                   (cons 'code 'not-list)
                   (cons 'value (loop-governor-agent-judge-nodes governor))))))
    (list '((field . governor) (code . not-loop-governor)))))

;;; Validation is the only gate before governor contracts leave Scheme.
;;; Failures stay typed so callers never parse policy strings.
;; : (-> LoopGovernor LoopGovernor)
(def (validate-loop-governor governor)
  (let (errors (loop-governor-validation-errors governor))
    (if (null? errors)
      governor
      (raise-control-plane-failure
       'loop-governor
       'invalid-loop-governor
       "invalid loop governor"
       (list (cons 'errors errors))))))

;;; Pattern-name projection is the compact contract summary for Marlin and
;;; doctor output. Full descriptor contracts remain in the nested strategy.
;; : (-> [LoopPatternDescriptor] [Symbol])
(def (loop-governor-pattern-names descriptors)
  (map loop-pattern-name descriptors))

;;; Contract projection is the governor handoff surface for Marlin.
;;; It includes state-derived facts but performs no runtime transition.
;; : (-> LoopGovernor [Alist] Alist)
(def (loop-governor->contract governor states)
  (let* ((valid-governor (validate-loop-governor governor))
         (strategy (loop-governor-strategy valid-governor))
         (open-patterns (loop-governor-open-patterns valid-governor states))
         (conflicting-patterns
          (loop-governor-conflicting-patterns valid-governor states))
         (denied-patterns
          (loop-governor-denied-patterns valid-governor)))
    (list (cons 'schema +loop-governor-schema+)
          (cons 'kind 'loop-governor)
          (cons 'name (loop-governor-name valid-governor))
          (cons 'strategy (loop-strategy-plan->contract strategy))
          (cons 'state-key (loop-governor-state-key valid-governor))
          (cons 'collision-policy
                (loop-governor-collision-policy valid-governor))
          (cons 'aggregate-budget
                (loop-governor-aggregate-budget valid-governor))
          (cons 'agent-judges
                (loop-governor-agent-judges valid-governor))
          (cons 'agent-judge-nodes
                (loop-governor-node-contracts
                 (loop-governor-agent-judge-nodes valid-governor)))
          (cons 'shared-denylist
                (loop-governor-shared-denylist valid-governor))
          (cons 'open-patterns
                (loop-governor-pattern-names open-patterns))
          (cons 'conflicting-patterns
                (loop-governor-pattern-names conflicting-patterns))
          (cons 'denied-patterns
                (loop-governor-pattern-names denied-patterns))
          (cons 'human-inbox-items
                (loop-governor-human-inbox-items valid-governor states))
          (cons 'human-inbox (loop-governor-human-inbox valid-governor))
          (cons 'handoff (loop-governor-handoff valid-governor))
          (cons 'runtime-boundary
                '((local-execution . validation-only)
                  (agent-governance . loop-governor)
                  (human-intervention . human-audit-loop)
                  (production-execution . marlin-agent-core)))
          (cons 'control-owner
                (loop-governor-control-owner valid-governor))
          (cons 'execution-owner
                (loop-governor-execution-owner valid-governor))
          (cons 'metadata (loop-governor-metadata valid-governor)))))
