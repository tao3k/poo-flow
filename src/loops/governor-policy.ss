;;; -*- Gerbil -*-
;;; Boundary: governor policy projection, validation, and Marlin contract facts.
;;; Invariant: runtime snapshots are inputs; this owner never locks or mutates them.

(import :poo-flow/src/core/failure
        :poo-flow/src/loops/descriptor
        :poo-flow/src/loops/strategy
        :poo-flow/src/loops/governor-core
        (only-in :std/sugar foldl))

(export loop-governor-state-field
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
        loop-governor->contract/validated
        loop-governor->contract)

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

;;; Boundary: loop governor member predicate is the policy-visible edge for
;;; loop behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> ActionKey [ActionKey] Boolean)
(def (loop-governor-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else
    (loop-governor-member? value (cdr values)))))

;;; Boundary: loop governor value set is the policy-visible edge for loop
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [Value] HashTable)
(def (loop-governor-value-set values)
  (let (table (make-hash-table))
    (for-each
     (lambda (value)
       (hash-put! table value #t))
     values)
    table))

;; : (-> HashTable Value Boolean)
(def (loop-governor-set-member? table value)
  (and value (hash-get table value)))

;;; Boundary: loop governor filter is the policy-visible edge for loop
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Predicate [Value] [Value])
(def (loop-governor-filter predicate values)
  (cond
   ((null? values) '())
   ((predicate (car values))
    (cons (car values)
          (loop-governor-filter predicate (cdr values))))
   (else
    (loop-governor-filter predicate (cdr values)))))

;;; Boundary: loop governor take at most is the policy-visible edge for loop
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Nat [Value] [Value])
(def (loop-governor-take-at-most limit values)
  (cond
   ((<= limit 0) '())
   ((null? values) '())
   (else
    (cons (car values)
          (loop-governor-take-at-most (- limit 1) (cdr values))))))

;;; Boundary: loop governor classify patterns is the policy-visible edge for
;;; loop behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> LoopGovernor [Alist] Alist)
(def (loop-governor-classify-patterns valid-governor states)
  (let* ((strategy (loop-governor-strategy valid-governor))
         (selected-patterns
          (loop-strategy-selected-patterns/from-fields
           (loop-strategy-patterns strategy)
           (loop-strategy-level-ceiling strategy)))
         (actionable-patterns
          (loop-governor-filter loop-pattern-actionable? selected-patterns))
         (denylist (loop-governor-shared-denylist valid-governor))
         (state-action-keys
          (loop-governor-filter
           (lambda (state-action-key)
             state-action-key)
           (map (lambda (state)
                  (loop-governor-state-action-key valid-governor state))
                states)))
         (denylist-set (loop-governor-value-set denylist))
         (state-action-key-set
          (loop-governor-value-set state-action-keys))
         (budget-limit (loop-governor-budget-limit valid-governor))
         (groups
          (foldl
           (lambda (descriptor groups)
             (let* ((open (car groups))
                    (conflicting (cadr groups))
                    (denied (caddr groups))
                    (action-key
                     (loop-governor-pattern-action-key descriptor))
                    (pattern-name (loop-pattern-name descriptor))
                    (denied?
                     (or (loop-governor-set-member? denylist-set action-key)
                         (loop-governor-set-member? denylist-set pattern-name)))
                    (conflicted?
                     (and action-key
                          (loop-governor-set-member?
                           state-action-key-set
                           action-key))))
               (list
                (if (and (not denied?) (not conflicted?))
                  (cons descriptor open)
                  open)
                (if conflicted?
                  (cons descriptor conflicting)
                  conflicting)
                (if denied?
                  (cons descriptor denied)
                  denied))))
           '(() () ())
           actionable-patterns))
         (open (car groups))
         (conflicting (cadr groups))
         (denied (caddr groups)))
    (list
     (cons 'selected-patterns selected-patterns)
     (cons 'actionable-patterns actionable-patterns)
     (cons 'open-patterns
           (loop-governor-take-at-most
            budget-limit
            (reverse open)))
     (cons 'conflicting-patterns (reverse conflicting))
     (cons 'denied-patterns (reverse denied)))))

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
    (loop-governor-alist-ref
     (loop-governor-classify-patterns valid-governor '())
     'denied-patterns
     '())))

;;; Conflict projection consumes runtime state facts as an argument.
;;; Callers can test state behavior without starting a scheduler.
;; : (-> LoopGovernor [Alist] [LoopPatternDescriptor])
(def (loop-governor-conflicting-patterns governor states)
  (let (valid-governor (validate-loop-governor governor))
    (loop-governor-alist-ref
     (loop-governor-classify-patterns valid-governor states)
     'conflicting-patterns
     '())))

;;; Open patterns are recommendations after static denylist and state conflict
;;; checks, then clipped by the aggregate max-actionable budget.
;; : (-> LoopGovernor [Alist] [LoopPatternDescriptor])
(def (loop-governor-open-patterns governor states)
  (let (valid-governor (validate-loop-governor governor))
    (loop-governor-alist-ref
     (loop-governor-classify-patterns valid-governor states)
     'open-patterns
     '())))

;; : (-> Symbol LoopPatternDescriptor ActionKey Alist)
(def (loop-governor-inbox-item reason descriptor action-key)
  (list (cons 'reason reason)
        (cons 'pattern (loop-pattern-name descriptor))
        (cons 'acting_on action-key)))

;;; Human inbox items describe blocked recommendations as structured data.
;;; The inbox target is a later runtime or UI concern.
;; : (-> LoopGovernor [Alist] [Alist])
(def (loop-governor-human-inbox-items governor states)
  (let* ((valid-governor (validate-loop-governor governor))
         (classified
          (loop-governor-classify-patterns valid-governor states)))
    (loop-governor-human-inbox-items/from-patterns
     (loop-governor-alist-ref classified 'denied-patterns '())
     (loop-governor-alist-ref classified 'conflicting-patterns '()))))

;;; Boundary: loop governor human inbox items from patterns is the policy-
;;; visible edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [LoopPatternDescriptor] [LoopPatternDescriptor] [Alist])
(def (loop-governor-human-inbox-items/from-patterns denied-patterns conflicting-patterns)
  (loop-governor-human-inbox-items/tail
   denied-patterns
   'shared-denylist
   (loop-governor-human-inbox-items/tail
    conflicting-patterns
    'acting-on-conflict
    '())))

;; : (-> [LoopPatternDescriptor] Symbol [Alist] [Alist])
(def (loop-governor-human-inbox-items/tail descriptors reason tail)
  (cond
   ((null? descriptors) tail)
   (else
    (cons (loop-governor-inbox-item
           reason
           (car descriptors)
           (loop-governor-pattern-action-key (car descriptors)))
          (loop-governor-human-inbox-items/tail
           (cdr descriptors)
           reason
           tail)))))

;;; Required errors use the same alist shape as strategy validation.
;;; That keeps governor findings composable with existing doctor output.
;; : (-> Symbol FieldValue [ValidationError])
(def (loop-governor-required-field-error/tail field value tail)
  (if value
    tail
    (cons (list (cons 'field field)
                (cons 'code 'required))
          tail)))

;; : (-> Symbol FieldValue [ValidationError])
(def (loop-governor-required-field-error field value)
  (loop-governor-required-field-error/tail field value '()))

;;; Boundary: loop governor field validation error unless is the policy-visible
;;; edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> Boolean Symbol Symbol FieldValue [ValidationError])
(def (loop-governor-field-validation-error/unless/tail valid?
                                                        field
                                                        code
                                                        value
                                                        tail)
  (if valid?
    tail
    (cons (list (cons 'field field)
                (cons 'code code)
                (cons 'value value))
          tail)))

;; : (-> Boolean Symbol Symbol FieldValue [ValidationError])
(def (loop-governor-field-validation-error/unless valid? field code value)
  (loop-governor-field-validation-error/unless/tail
   valid?
   field
   code
   value
   '()))

;;; Boundary: loop governor strategy validation errors is the policy-visible
;;; edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> LoopStrategyPlan [ValidationError] [ValidationError])
(def (loop-governor-strategy-validation-errors/tail strategy tail)
  (if (loop-strategy-plan? strategy)
    (let (strategy-errors (loop-strategy-validation-errors strategy))
      (if (null? strategy-errors)
        tail
        (cons (list (cons 'field 'strategy)
                    (cons 'code 'invalid-strategy)
                    (cons 'errors strategy-errors))
              tail)))
    (cons (list (cons 'field 'strategy)
                (cons 'code 'not-loop-strategy-plan))
          tail)))

;; : (-> LoopStrategyPlan [ValidationError])
(def (loop-governor-strategy-validation-errors strategy)
  (loop-governor-strategy-validation-errors/tail strategy '()))

;;; Boundary: loop governor node list validation errors is the policy-visible
;;; edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;;; Boundary: loop governor agent judge node field errors is the policy-visible
;;; edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [LoopGovernorNode] [ValidationError])
(def (loop-governor-agent-judge-node-field-errors nodes)
  (if (list? nodes)
    (loop-governor-node-list-validation-errors nodes)
    (list (list (cons 'field 'agent-judge-nodes)
                (cons 'code 'not-list)
                (cons 'value nodes)))))

;;; Boundary: loop governor node list validation errors is the policy-visible
;;; edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
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
    (loop-governor-required-field-error/tail
     'name
     (loop-governor-name governor)
     (loop-governor-strategy-validation-errors/tail
      (loop-governor-strategy governor)
      (loop-governor-field-validation-error/unless/tail
       (symbol? (loop-governor-state-field governor))
       'state-key
       'field-not-symbol
       (loop-governor-state-field governor)
       (loop-governor-field-validation-error/unless/tail
        (integer? (loop-governor-budget-limit governor))
        'aggregate-budget
        'max-actionable-not-integer
        (loop-governor-budget-limit governor)
        (loop-governor-field-validation-error/unless/tail
         (list? (loop-governor-agent-judges governor))
         'agent-judges
         'not-list
         (loop-governor-agent-judges governor)
         (loop-governor-agent-judge-node-field-errors
          (loop-governor-agent-judge-nodes governor)))))))
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

;;; Governor contracts need strategy identity and ordered names, not 600 full
;;; descriptor contracts. Full descriptor projection stays on the strategy API.
;; : (-> LoopStrategyPlan [LoopPatternDescriptor] [LoopPatternDescriptor] Alist)
(def (loop-governor-strategy-summary strategy selected-patterns actionable-patterns)
  (let (next-pattern
        (if (null? actionable-patterns)
          #f
          (car actionable-patterns)))
    (list (cons 'schema +loop-strategy-plan-schema+)
          (cons 'kind 'loop-strategy-plan)
          (cons 'projection 'compact-governor-view)
          (cons 'name (loop-strategy-name strategy))
          (cons 'selection (loop-strategy-selection strategy))
          (cons 'level-ceiling (loop-strategy-level-ceiling strategy))
          (cons 'pattern-count (length (loop-strategy-patterns strategy)))
          (cons 'selected-patterns
                (loop-governor-pattern-names selected-patterns))
          (cons 'actionable-patterns
                (loop-governor-pattern-names actionable-patterns))
          (cons 'next-pattern
                (if next-pattern (loop-pattern-name next-pattern) #f))
          (cons 'local-validation (loop-strategy-local-validation strategy))
          (cons 'handoff (loop-strategy-handoff strategy))
          (cons 'runtime-boundary
                '((local-execution . validation-only)
                  (production-execution . marlin-agent-core)))
          (cons 'control-owner (loop-strategy-control-owner strategy))
          (cons 'execution-owner (loop-strategy-execution-owner strategy))
          (cons 'metadata (loop-strategy-metadata strategy)))))

;;; Contract projection is the governor handoff surface for Marlin.
;;; It includes state-derived facts but performs no runtime transition.
;; : (-> LoopGovernor [Alist] Alist)
(def (loop-governor->contract/validated valid-governor states)
  (let* ((strategy (loop-governor-strategy valid-governor))
         (classified
          (loop-governor-classify-patterns valid-governor states))
         (open-patterns
          (loop-governor-alist-ref classified 'open-patterns '()))
         (conflicting-patterns
          (loop-governor-alist-ref classified 'conflicting-patterns '()))
         (denied-patterns
          (loop-governor-alist-ref classified 'denied-patterns '()))
         (selected-patterns
          (loop-governor-alist-ref classified 'selected-patterns '()))
         (actionable-patterns
          (loop-governor-alist-ref classified 'actionable-patterns '()))
         (agent-judge-nodes
          (loop-governor-agent-judge-nodes valid-governor)))
    (list (cons 'schema +loop-governor-schema+)
          (cons 'kind 'loop-governor)
          (cons 'name (loop-governor-name valid-governor))
          (cons 'strategy
                (loop-governor-strategy-summary
                 strategy
                 selected-patterns
                 actionable-patterns))
          (cons 'state-key (loop-governor-state-key valid-governor))
          (cons 'collision-policy
                (loop-governor-collision-policy valid-governor))
          (cons 'aggregate-budget
                (loop-governor-aggregate-budget valid-governor))
          (cons 'agent-judges
                (loop-governor-agent-judges valid-governor))
          (cons 'agent-judge-nodes
                (loop-governor-node-contracts agent-judge-nodes))
          (cons 'shared-denylist
                (loop-governor-shared-denylist valid-governor))
          (cons 'open-patterns
                (loop-governor-pattern-names open-patterns))
          (cons 'conflicting-patterns
                (loop-governor-pattern-names conflicting-patterns))
          (cons 'denied-patterns
                (loop-governor-pattern-names denied-patterns))
          (cons 'human-inbox-items
                (loop-governor-human-inbox-items/from-patterns
                 denied-patterns
                 conflicting-patterns))
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

;; : (-> LoopGovernor [Alist] Alist)
(def (loop-governor->contract governor states)
  (loop-governor->contract/validated
   (validate-loop-governor governor)
   states))
