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

;; : (-> LoopGovernor [Alist] Alist)
(def (loop-governor-classify-patterns valid-governor states)
  (let* ((groups
          (foldl
           (lambda (descriptor groups)
             (let* ((open (car groups))
                    (conflicting (cadr groups))
                    (denied (caddr groups))
                    (denied?
                     (loop-governor-pattern-denied? valid-governor descriptor))
                    (conflicted?
                     (loop-governor-pattern-conflicted?
                      valid-governor
                      states
                      descriptor)))
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
           (loop-strategy-actionable-patterns
            (loop-governor-strategy valid-governor))))
         (open (car groups))
         (conflicting (cadr groups))
         (denied (caddr groups)))
    (list
     (cons 'open-patterns
           (loop-governor-take-at-most
            (loop-governor-budget-limit valid-governor)
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

;; : (-> [LoopPatternDescriptor] [LoopPatternDescriptor] [Alist])
(def (loop-governor-human-inbox-items/from-patterns denied-patterns conflicting-patterns)
  (append
   (map (lambda (descriptor)
          (loop-governor-inbox-item
           'shared-denylist
           descriptor
           (loop-governor-pattern-action-key descriptor)))
        denied-patterns)
   (map (lambda (descriptor)
          (loop-governor-inbox-item
           'acting-on-conflict
           descriptor
           (loop-governor-pattern-action-key descriptor)))
        conflicting-patterns)))

;;; Required errors use the same alist shape as strategy validation.
;;; That keeps governor findings composable with existing doctor output.
;; : (-> Symbol FieldValue [ValidationError])
(def (loop-governor-required-field-error field value)
  (if value
    '()
    (list (list (cons 'field field)
                (cons 'code 'required)))))

;; : (-> Boolean Symbol Symbol FieldValue [ValidationError])
(def (loop-governor-field-validation-error/unless valid? field code value)
  (if valid?
    '()
    (list (list (cons 'field field)
                (cons 'code code)
                (cons 'value value)))))

;; : (-> LoopStrategyPlan [ValidationError])
(def (loop-governor-strategy-validation-errors strategy)
  (if (loop-strategy-plan? strategy)
    (let (strategy-errors (loop-strategy-validation-errors strategy))
      (if (null? strategy-errors)
        '()
        (list (list (cons 'field 'strategy)
                    (cons 'code 'invalid-strategy)
                    (cons 'errors strategy-errors)))))
    (list (list (cons 'field 'strategy)
                (cons 'code 'not-loop-strategy-plan)))))

;; : (-> [LoopGovernorNode] [ValidationError])
(def (loop-governor-agent-judge-node-field-errors nodes)
  (if (list? nodes)
    (loop-governor-node-list-validation-errors nodes)
    (list (list (cons 'field 'agent-judge-nodes)
                (cons 'code 'not-list)
                (cons 'value nodes)))))

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
     (loop-governor-strategy-validation-errors
      (loop-governor-strategy governor))
     (loop-governor-field-validation-error/unless
      (symbol? (loop-governor-state-field governor))
      'state-key
      'field-not-symbol
      (loop-governor-state-field governor))
     (loop-governor-field-validation-error/unless
      (integer? (loop-governor-budget-limit governor))
      'aggregate-budget
      'max-actionable-not-integer
      (loop-governor-budget-limit governor))
     (loop-governor-field-validation-error/unless
      (list? (loop-governor-agent-judges governor))
      'agent-judges
      'not-list
      (loop-governor-agent-judges governor))
     (loop-governor-agent-judge-node-field-errors
      (loop-governor-agent-judge-nodes governor)))
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
         (classified
          (loop-governor-classify-patterns valid-governor states))
         (open-patterns
          (loop-governor-alist-ref classified 'open-patterns '()))
         (conflicting-patterns
          (loop-governor-alist-ref classified 'conflicting-patterns '()))
         (denied-patterns
          (loop-governor-alist-ref classified 'denied-patterns '()))
         (agent-judge-nodes
          (loop-governor-agent-judge-nodes valid-governor)))
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
