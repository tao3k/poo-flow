;;; -*- Gerbil -*-
;;; Boundary: loop strategies compose policy descriptors into inert handoff data.
;;; Invariant: local execution here is harness-only validation, never production runtime.

(import (only-in :clan/poo/object .o .mix object?)
        :core/roles
        :core/failure
        :loops/descriptor)

(export +loop-strategy-plan-schema+
        +loop-local-validation-default+
        +loop-runtime-handoff-default+
        loop-strategy-engine-role
        loop-prioritization-role
        loop-local-validation-role
        loop-runtime-handoff-role
        loop-strategy-plan-prototype
        make-loop-strategy-plan
        loop-strategy-plan?
        loop-strategy-slot
        loop-strategy-name
        loop-strategy-patterns
        loop-strategy-selection
        loop-strategy-level-ceiling
        loop-strategy-local-validation
        loop-strategy-handoff
        loop-strategy-metadata
        loop-strategy-control-owner
        loop-strategy-execution-owner
        loop-strategy-local-validation-harness-only?
        loop-pattern-within-ceiling?
        loop-pattern-prioritized-before?
        loop-strategy-selected-patterns
        loop-strategy-actionable-patterns
        loop-strategy-human-gated-patterns
        loop-strategy-next-pattern
        loop-strategy-validation-errors
        validate-loop-strategy-plan
        loop-strategy-plan->contract)

;;; Boundary: schema id is the stable contract name exported to Marlin.
;; Symbol <- Unit
(def +loop-strategy-plan-schema+ 'poo-flow.loop-strategy-plan.v1)

;;; Boundary: local validation defaults keep repository execution harness-only.
;;; Intent: tests and probes may run locally without claiming production loop ownership.
;; Alist <- Unit
(def +loop-local-validation-default+
  '((mode . harness-only)
    (purpose . (test validation stability performance))
    (allow-effects . #f)
    (checks . (contract smoke replay benchmark))))

;;; Boundary: handoff defaults document the production owner for loop execution.
;;; Intent: Scheme should not allocate timers, worktrees, or connector IO here.
;; Alist <- Unit
(def +loop-runtime-handoff-default+
  '((target . marlin-agent-core)
    (transport . scheme-abi)
    (contract . poo-flow.loop-pattern.v1)))

;;; Boundary: engine role marks this file as policy composition, not execution.
;;; Boundary: root strategy role identifies Scheme as the policy owner while
;;; leaving the effect-capable loop runtime to the handoff contract.
;; Role <- Unit
(def loop-strategy-engine-role
  (.o (:: @ strategy-role)
      (name 'loop-strategy-engine)
      (kind 'loop-control)
      (responsibility 'multi-loop-policy-composition)
      (runtime-owner 'gerbil)
      (loop-capability 'strategy-composition)))

;;; Boundary: prioritization role owns ordering policy for selected patterns.
;;; Boundary: prioritization is a policy role so repository defaults can later
;;; override ranking without changing the strategy-plan constructor.
;; Role <- Unit
(def loop-prioritization-role
  (.o (:: @ loop-strategy-engine-role)
      (name 'loop-prioritization)
      (kind 'loop-policy)
      (responsibility 'priority-and-autonomy-ordering)
      (loop-policy-slot 'prioritization)))

;;; Boundary: local validation role keeps repository checks harness-only.
;;; Boundary: local validation is a role because tests need a first-class slot
;;; that explicitly forbids production effects in this package.
;; Role <- Unit
(def loop-local-validation-role
  (.o (:: @ loop-strategy-engine-role)
      (name 'loop-local-validation)
      (kind 'loop-policy)
      (responsibility 'harness-only-validation)
      (loop-policy-slot 'local-validation)))

;;; Boundary: runtime handoff role names Marlin as the execution owner.
;;; Boundary: runtime handoff is a role so Marlin ownership is inherited by the
;;; composed plan instead of repeated in ad hoc projection code.
;; Role <- Unit
(def loop-runtime-handoff-role
  (.o (:: @ loop-strategy-engine-role)
      (name 'loop-runtime-handoff)
      (kind 'loop-boundary)
      (responsibility 'marlin-runtime-contract-projection)
      (loop-policy-slot 'handoff)))

;;; Boundary: plan slots are policy data for selecting loop descriptors.
;;; Intent: C3/POO composes strategy roles before Marlin receives a contract.
;; LoopStrategyPlanPrototype <- Unit
(def loop-strategy-plan-prototype
  (.mix slots: (role-constant-slots
                (list (cons 'schema +loop-strategy-plan-schema+)
                      (cons 'kind 'loop-strategy-plan)
                      (cons 'name #f)
                      (cons 'patterns '())
                      (cons 'selection 'priority-first)
                      (cons 'level-ceiling 'l2)
                      (cons 'local-validation +loop-local-validation-default+)
                      (cons 'handoff +loop-runtime-handoff-default+)
                      (cons 'control-owner 'gerbil)
                      (cons 'execution-owner 'marlin-agent-core)
                      (cons 'metadata '())))
        loop-runtime-handoff-role
        loop-local-validation-role
        loop-prioritization-role
        loop-strategy-engine-role))

;;; Boundary: constructor receives descriptors and strategy-policy overrides.
;;; Runtime handles, timers, connector clients, and worktrees stay out of scope.
;; LoopStrategyPlan <- Symbol [LoopPatternDescriptor] [Alist]
(def (make-loop-strategy-plan name patterns . maybe-overrides)
  (.mix slots: (role-constant-slots
                (append
                 (list (cons 'name name)
                       (cons 'patterns patterns))
                 (if (null? maybe-overrides) '() (car maybe-overrides))))
        loop-strategy-plan-prototype))

;;; Boundary: predicate accepts C3-composed strategy objects by kind slot.
;; Boolean <- LoopStrategyPlanCandidate
(def (loop-strategy-plan? plan)
  (and (object? plan)
       (eq? (loop-strategy-slot plan 'kind #f)
            'loop-strategy-plan)))

;;; Boundary: slot access keeps strategy plans record-like and policy-owned.
;; LoopStrategySlotValue <- LoopStrategyPlan Symbol LoopStrategySlotValue
(def (loop-strategy-slot plan slot default)
  (role-slot/default plan slot default))

;;; Boundary: alist policy lookup is used only for local validation metadata.
;;; Alist lookup stays local to the strategy module so runtime-boundary policy
;;; checks do not depend on descriptor-internal helpers.
;; AlistValue <- Alist Symbol AlistValue
(def (loop-strategy-alist-ref alist key default)
  (cond
   ((assoc key alist) => cdr)
   (else default)))

;;; Boundary: name is the stable handle used in projected contracts.
;; Symbol <- LoopStrategyPlan
(def (loop-strategy-name plan)
  (loop-strategy-slot plan 'name #f))

;;; Boundary: patterns stay descriptor data until a Marlin handoff consumes them.
;; [LoopPatternDescriptor] <- LoopStrategyPlan
(def (loop-strategy-patterns plan)
  (loop-strategy-slot plan 'patterns '()))

;;; Boundary: selection names the ordering policy without executing it.
;; Symbol <- LoopStrategyPlan
(def (loop-strategy-selection plan)
  (loop-strategy-slot plan 'selection #f))

;;; Boundary: autonomy ceiling filters patterns before any runtime handoff.
;; Symbol <- LoopStrategyPlan
(def (loop-strategy-level-ceiling plan)
  (loop-strategy-slot plan 'level-ceiling #f))

;;; Boundary: local validation metadata describes harness checks only.
;; Alist <- LoopStrategyPlan
(def (loop-strategy-local-validation plan)
  (loop-strategy-slot plan 'local-validation '()))

;;; Boundary: handoff metadata describes the downstream runtime contract.
;; Alist <- LoopStrategyPlan
(def (loop-strategy-handoff plan)
  (loop-strategy-slot plan 'handoff '()))

;;; Boundary: metadata is descriptive and never scheduler state.
;; Alist <- LoopStrategyPlan
(def (loop-strategy-metadata plan)
  (loop-strategy-slot plan 'metadata '()))

;;; Boundary: control owner stays Gerbil for descriptor policy composition.
;; Symbol <- LoopStrategyPlan
(def (loop-strategy-control-owner plan)
  (loop-strategy-slot plan 'control-owner #f))

;;; Boundary: execution owner remains external to this Scheme strategy surface.
;; Symbol <- LoopStrategyPlan
(def (loop-strategy-execution-owner plan)
  (loop-strategy-slot plan 'execution-owner #f))

;;; This predicate is the enforcement point for the local/runtime split: tests
;;; may project contracts locally, but any effect-capable loop must be rejected.
;;; Boundary: this predicate prevents tests from becoming production execution.
;; Boolean <- LoopStrategyPlan
(def (loop-strategy-local-validation-harness-only? plan)
  (let (policy (loop-strategy-local-validation plan))
    (and (eq? (loop-strategy-alist-ref policy 'mode #f) 'harness-only)
         (eq? (loop-strategy-alist-ref policy 'allow-effects #t) #f))))

;;; Autonomy ceilings are policy gates, not scheduler readiness checks. They
;;; keep future L3 patterns out of current L1/L2 contract projections.
;;; Boundary: ceiling checks reject unknown autonomy levels instead of guessing.
;; Boolean <- LoopPatternDescriptor Symbol
(def (loop-pattern-within-ceiling? descriptor ceiling)
  (and (loop-pattern-level? ceiling)
       (loop-pattern-level? (loop-pattern-level descriptor))
       (loop-pattern-level<=? (loop-pattern-level descriptor) ceiling)))

;;; Boundary: priority comparison is policy ordering, not scheduler readiness.
;;; Intent: equal priority keeps the more capable autonomy level first because it has more gates.
;; Boolean <- LoopPatternDescriptor LoopPatternDescriptor
(def (loop-pattern-prioritized-before? left right)
  (let ((left-priority (loop-pattern-priority left))
        (right-priority (loop-pattern-priority right)))
    (cond
     ((< left-priority right-priority) #t)
     ((> left-priority right-priority) #f)
     (else
      (> (loop-pattern-level-rank (loop-pattern-level left))
         (loop-pattern-level-rank (loop-pattern-level right)))))))

;;; Strategy helpers keep filtering explicit so policy predicates remain visible
;;; to tests and harness diagnostics.
;; [Value] <- Predicate [Value]
(def (loop-filter predicate values)
  (cond
   ((null? values) '())
   ((predicate (car values))
    (cons (car values)
          (loop-filter predicate (cdr values))))
   (else
    (loop-filter predicate (cdr values)))))

;;; Boundary: insert keeps the sorted prefix stable for equal-priority descriptors.
;;; Insert preserves the already-ranked prefix and is intentionally small:
;;; priority comparison is isolated in =loop-pattern-prioritized-before?=.
;; [LoopPatternDescriptor] <- LoopPatternDescriptor [LoopPatternDescriptor]
(def (loop-insert-pattern descriptor sorted)
  (cond
   ((null? sorted) (list descriptor))
   ((loop-pattern-prioritized-before? descriptor (car sorted))
    (cons descriptor sorted))
   (else
    (cons (car sorted)
          (loop-insert-pattern descriptor (cdr sorted))))))

;;; Strategy selection uses a pure insertion fold so ordering is deterministic
;;; without mutating descriptors or carrying runtime scheduler state.
;; [LoopPatternDescriptor] <- [LoopPatternDescriptor]
(def (loop-sort-patterns descriptors)
  (foldr (lambda (descriptor sorted)
           (loop-insert-pattern descriptor sorted))
         '()
         descriptors))

;;; Boundary: selected patterns are validated, filtered by autonomy ceiling, and sorted.
;;; Selected patterns are the complete pre-runtime candidate set after static
;;; level gating and priority ranking.
;;; Marlin still decides actual execution from the handoff contract.
;; [LoopPatternDescriptor] <- LoopStrategyPlan
(def (loop-strategy-selected-patterns plan)
  (let* ((valid-plan (validate-loop-strategy-plan plan))
         (ceiling (loop-strategy-level-ceiling valid-plan)))
    (loop-sort-patterns
     (loop-filter
      (lambda (descriptor)
        (loop-pattern-within-ceiling? descriptor ceiling))
      (loop-strategy-patterns valid-plan)))))

;;; Actionable patterns exclude L1 report-only loops so strategy plans can show
;;; advisory loops and write-capable loops in separate contract fields.
;;; Boundary: actionable patterns are selected first, then filtered by runtime readiness.
;; [LoopPatternDescriptor] <- LoopStrategyPlan
(def (loop-strategy-actionable-patterns plan)
  (loop-filter loop-pattern-actionable?
               (loop-strategy-selected-patterns plan)))

;;; Human-gated projection is a doctor/checker surface: it exposes why a loop
;;; needs review without starting the loop or contacting the external system.
;;; Boundary: human gate filters remain explicit data checks.
;; [LoopPatternDescriptor] <- LoopStrategyPlan Symbol
(def (loop-strategy-human-gated-patterns plan gate)
  (loop-filter
   (lambda (descriptor)
     (loop-pattern-human-gate-required? descriptor gate))
   (loop-strategy-selected-patterns plan)))

;;; The next pattern is a policy recommendation for the runtime handoff. It is
;;; deliberately not a wake-up decision and does not mutate loop state.
;;; Boundary: next-pattern is a projection, not a scheduler side effect.
;; MaybeLoopPatternDescriptor <- LoopStrategyPlan
(def (loop-strategy-next-pattern plan)
  (let (patterns (loop-strategy-actionable-patterns plan))
    (if (null? patterns)
      #f
      (car patterns))))

;;; Required-field errors use the same alist shape as nested descriptor errors
;;; so downstream presentation can concatenate findings without translation.
;;; Boundary: required-field errors use structured details for doctor output.
;; [ValidationError] <- Symbol FieldValue
(def (loop-strategy-required-field-error field value)
  (if value
    '()
    (list (list (cons 'field field)
                (cons 'code 'required)))))

;;; Pattern validation nests descriptor findings under the strategy index so a
;;; downstream doctor can point at the bad loop entry without parsing strings.
;; [ValidationError] <- [LoopPatternDescriptor] Nat
(def (loop-strategy-pattern-validation-errors descriptors index)
  (cond
   ((null? descriptors) '())
   (else
    (let (errors (loop-pattern-validation-errors (car descriptors)))
      (append
       (if (null? errors)
         '()
         (list (list (cons 'field 'patterns)
                     (cons 'index index)
                     (cons 'code 'invalid-pattern)
                     (cons 'errors errors))))
       (loop-strategy-pattern-validation-errors (cdr descriptors)
                                                (+ index 1)))))))

;;; Boundary: validation errors are structured data so doctor surfaces stay typed.
;;; The aggregate validator keeps local policy mistakes in one alist payload:
;;; shape errors, autonomy ceiling errors, harness violations, and child
;;; descriptor failures all become doctor-friendly data before any handoff.
;; [ValidationError] <- LoopStrategyPlan
(def (loop-strategy-validation-errors plan)
  (if (loop-strategy-plan? plan)
    (append
     (loop-strategy-required-field-error 'name (loop-strategy-name plan))
     (if (list? (loop-strategy-patterns plan))
       '()
       (list (list (cons 'field 'patterns)
                   (cons 'code 'not-list)
                   (cons 'value (loop-strategy-patterns plan)))))
     (if (loop-pattern-level? (loop-strategy-level-ceiling plan))
       '()
       (list (list (cons 'field 'level-ceiling)
                   (cons 'code 'unsupported-level)
                   (cons 'value (loop-strategy-level-ceiling plan)))))
     (if (loop-strategy-local-validation-harness-only? plan)
       '()
       (list (list (cons 'field 'local-validation)
                   (cons 'code 'local-execution-must-be-harness-only)
                   (cons 'value (loop-strategy-local-validation plan)))))
     (loop-strategy-pattern-validation-errors
      (if (list? (loop-strategy-patterns plan))
        (loop-strategy-patterns plan)
        '())
      0))
    (list '((field . plan) (code . not-loop-strategy-plan)))))

;;; Boundary: validation is the gate before any strategy projection leaves this owner.
;;; Validation raises the same typed failure shape used by the rest of the
;;; control plane, so test harnesses do not parse ad hoc strategy errors.
;; LoopStrategyPlan <- LoopStrategyPlan
(def (validate-loop-strategy-plan plan)
  (let (errors (loop-strategy-validation-errors plan))
    (if (null? errors)
      plan
      (raise-control-plane-failure
       'loop-strategy
       'invalid-loop-strategy-plan
       "invalid loop strategy plan"
       (list (cons 'errors errors))))))

;;; Name projection is the compact user-facing summary for selected patterns.
;; [Symbol] <- [LoopPatternDescriptor]
(def (loop-pattern-names descriptors)
  (map loop-pattern-name descriptors))

;;; Boundary: projection is the only local "execution" outcome.
;;; Invariant: contract data can be tested locally, but Marlin owns the run.
;; Alist <- LoopStrategyPlan
(def (loop-strategy-plan->contract plan)
  (let* ((valid-plan (validate-loop-strategy-plan plan))
         (selected-patterns (loop-strategy-selected-patterns valid-plan))
         (actionable-patterns (loop-strategy-actionable-patterns valid-plan))
         (next-pattern (if (null? actionable-patterns)
                         #f
                         (car actionable-patterns))))
    (list (cons 'schema +loop-strategy-plan-schema+)
          (cons 'kind 'loop-strategy-plan)
          (cons 'name (loop-strategy-name valid-plan))
          (cons 'selection (loop-strategy-selection valid-plan))
          (cons 'level-ceiling (loop-strategy-level-ceiling valid-plan))
          (cons 'pattern-count (length (loop-strategy-patterns valid-plan)))
          (cons 'selected-patterns
                (map loop-pattern-descriptor->contract selected-patterns))
          (cons 'actionable-patterns
                (loop-pattern-names actionable-patterns))
          (cons 'next-pattern
                (if next-pattern (loop-pattern-name next-pattern) #f))
          (cons 'local-validation
                (loop-strategy-local-validation valid-plan))
          (cons 'handoff (loop-strategy-handoff valid-plan))
          (cons 'runtime-boundary
                '((local-execution . validation-only)
                  (production-execution . marlin-agent-core)))
          (cons 'control-owner (loop-strategy-control-owner valid-plan))
          (cons 'execution-owner (loop-strategy-execution-owner valid-plan))
          (cons 'metadata (loop-strategy-metadata valid-plan)))))
