;;; -*- Gerbil -*-
;;; Boundary: loop-agent descriptors are policy composition data.
;;; Invariant: scheduling, persistence, and execution stay in marlin-agent-core.

(import (only-in :clan/poo/object .o .mix object?)
        :core/roles
        :core/failure)

(export +loop-pattern-schema+
        +loop-levels+
        +loop-policy-roles+
        +loop-default-human-gates+
        loop-agent-role
        loop-purpose-role
        loop-level-role
        loop-schedule-role
        loop-state-role
        loop-budget-role
        loop-isolation-role
        loop-skill-role
        loop-connector-role
        loop-maker-role
        loop-checker-role
        loop-safety-role
        loop-observability-role
        loop-pattern-descriptor-prototype
        make-loop-pattern-descriptor
        loop-pattern-descriptor?
        loop-pattern-descriptor-slot
        loop-pattern-name
        loop-pattern-goal
        loop-pattern-level
        loop-pattern-priority
        loop-pattern-watched-scope
        loop-pattern-non-goals
        loop-pattern-schedule
        loop-pattern-state
        loop-pattern-budget
        loop-pattern-isolation
        loop-pattern-skills
        loop-pattern-connectors
        loop-pattern-maker
        loop-pattern-checker
        loop-pattern-safety
        loop-pattern-observability
        loop-pattern-policy-order
        loop-pattern-control-owner
        loop-pattern-execution-owner
        loop-pattern-metadata
        loop-pattern-level?
        loop-pattern-level-rank
        loop-pattern-level<=?
        loop-pattern-report-only?
        loop-pattern-actionable?
        loop-pattern-safety-human-gates
        loop-pattern-human-gate-required?
        loop-pattern-validation-errors
        validate-loop-pattern-descriptor
        loop-pattern-descriptor->contract)

;; Symbol <- Unit
(def +loop-pattern-schema+ 'poo-flow.loop-pattern.v1)

;; [Symbol] <- Unit
(def +loop-levels+ '(l1 l2 l2+ l3))

;; [Symbol] <- Unit
(def +loop-policy-roles+
  '(safety budget level checker maker state schedule purpose observability connector skill isolation))

;; [Symbol] <- Unit
(def +loop-default-human-gates+
  '(security authentication authorization payments pii infrastructure dependency-upgrade large-change repeated-failure))

;; Role <- Unit
(def loop-agent-role
  (.o (:: @ control-plane-role)
      (name 'loop-agent)
      (kind 'loop-control)
      (responsibility 'loop-policy-composition)
      (runtime-owner 'gerbil)
      (loop-capability 'policy-composition)))

;; Role <- Unit
(def loop-purpose-role
  (.o (:: @ loop-agent-role)
      (name 'loop-purpose)
      (kind 'loop-policy)
      (responsibility 'goal-and-scope)
      (loop-policy-slot 'purpose)))

;; Role <- Unit
(def loop-level-role
  (.o (:: @ loop-agent-role)
      (name 'loop-level)
      (kind 'loop-policy)
      (responsibility 'autonomy-level-gates)
      (loop-policy-slot 'level)))

;; Role <- Unit
(def loop-schedule-role
  (.o (:: @ loop-agent-role)
      (name 'loop-schedule)
      (kind 'loop-policy)
      (responsibility 'wake-up-policy)
      (loop-policy-slot 'schedule)))

;; Role <- Unit
(def loop-state-role
  (.o (:: @ loop-agent-role)
      (name 'loop-state)
      (kind 'loop-policy)
      (responsibility 'durable-state-contract)
      (loop-policy-slot 'state)))

;; Role <- Unit
(def loop-budget-role
  (.o (:: @ loop-agent-role)
      (name 'loop-budget)
      (kind 'loop-policy)
      (responsibility 'cost-and-attempt-gates)
      (loop-policy-slot 'budget)))

;; Role <- Unit
(def loop-isolation-role
  (.o (:: @ loop-agent-role)
      (name 'loop-isolation)
      (kind 'loop-policy)
      (responsibility 'worktree-and-session-isolation)
      (loop-policy-slot 'isolation)))

;; Role <- Unit
(def loop-skill-role
  (.o (:: @ loop-agent-role)
      (name 'loop-skill)
      (kind 'loop-policy)
      (responsibility 'intent-memory)
      (loop-policy-slot 'skills)))

;; Role <- Unit
(def loop-connector-role
  (.o (:: @ loop-agent-role)
      (name 'loop-connector)
      (kind 'loop-policy)
      (responsibility 'external-surface-scopes)
      (loop-policy-slot 'connectors)))

;; Role <- Unit
(def loop-maker-role
  (.o (:: @ loop-agent-role)
      (name 'loop-maker)
      (kind 'loop-policy)
      (responsibility 'action-agent)
      (loop-policy-slot 'maker)))

;; Role <- Unit
(def loop-checker-role
  (.o (:: @ loop-agent-role)
      (name 'loop-checker)
      (kind 'loop-policy)
      (responsibility 'verification-agent)
      (loop-policy-slot 'checker)))

;; Role <- Unit
(def loop-safety-role
  (.o (:: @ loop-agent-role)
      (name 'loop-safety)
      (kind 'loop-policy)
      (responsibility 'human-gates-and-denylists)
      (loop-policy-slot 'safety)))

;; Role <- Unit
(def loop-observability-role
  (.o (:: @ loop-agent-role)
      (name 'loop-observability)
      (kind 'loop-policy)
      (responsibility 'run-receipts-and-metrics)
      (loop-policy-slot 'observability)))

;;; Boundary: default loop pattern slots are inert policy data.
;;; Intent: C3/POO composition ranks policy defaults before Marlin executes.
;; LoopPatternDescriptorPrototype <- Unit
(def loop-pattern-descriptor-prototype
  (.mix slots: (role-constant-slots
                (list (cons 'schema +loop-pattern-schema+)
                      (cons 'kind 'loop-pattern)
                      (cons 'name #f)
                      (cons 'goal #f)
                      (cons 'level 'l1)
                      (cons 'priority 50)
                      (cons 'watched-scope '())
                      (cons 'non-goals '())
                      (cons 'schedule '((mode . manual)))
                      (cons 'state '((store . file) (path . "STATE.md")))
                      (cons 'budget '((max-attempts . 1)))
                      (cons 'isolation '((mode . none)))
                      (cons 'skills '())
                      (cons 'connectors '())
                      (cons 'maker '((enabled . #f)))
                      (cons 'checker '((required . #t)))
                      (cons 'safety
                            (list (cons 'human-gates +loop-default-human-gates+)
                                  (cons 'denylist '())
                                  (cons 'auto-merge #f)))
                      (cons 'observability '((run-log . "loop-run-log.md")))
                      (cons 'policy-order +loop-policy-roles+)
                      (cons 'control-owner 'gerbil)
                      (cons 'execution-owner 'marlin-agent-core)
                      (cons 'metadata '())))
        loop-safety-role
        loop-budget-role
        loop-level-role
        loop-checker-role
        loop-maker-role
        loop-state-role
        loop-schedule-role
        loop-purpose-role
        loop-observability-role
        loop-connector-role
        loop-skill-role
        loop-isolation-role
        loop-agent-role))

;;; Boundary: constructor accepts only descriptor-policy overrides.
;;; Runtime commands, timers, and connector handles belong to marlin-agent-core.
;; LoopPatternDescriptor <- Symbol String [Alist]
(def (make-loop-pattern-descriptor name goal . maybe-overrides)
  (.mix slots: (role-constant-slots
                (append
                 (list (cons 'name name)
                       (cons 'goal goal))
                 (if (null? maybe-overrides) '() (car maybe-overrides))))
        loop-pattern-descriptor-prototype))

;; Boolean <- LoopPatternDescriptorCandidate
(def (loop-pattern-descriptor? descriptor)
  (and (object? descriptor)
       (eq? (loop-pattern-descriptor-slot descriptor 'kind #f)
            'loop-pattern)))

;; LoopSlotValue <- LoopPatternDescriptor Symbol LoopSlotValue
(def (loop-pattern-descriptor-slot descriptor slot default)
  (role-slot/default descriptor slot default))

;; AlistValue <- Alist Symbol AlistValue
(def (loop-alist-ref alist key default)
  (cond
   ((assoc key alist) => cdr)
   (else default)))

;; Symbol <- LoopPatternDescriptor
(def (loop-pattern-name descriptor)
  (loop-pattern-descriptor-slot descriptor 'name #f))

;; String <- LoopPatternDescriptor
(def (loop-pattern-goal descriptor)
  (loop-pattern-descriptor-slot descriptor 'goal #f))

;; Symbol <- LoopPatternDescriptor
(def (loop-pattern-level descriptor)
  (loop-pattern-descriptor-slot descriptor 'level #f))

;; Integer <- LoopPatternDescriptor
(def (loop-pattern-priority descriptor)
  (loop-pattern-descriptor-slot descriptor 'priority #f))

;; [Value] <- LoopPatternDescriptor
(def (loop-pattern-watched-scope descriptor)
  (loop-pattern-descriptor-slot descriptor 'watched-scope '()))

;; [Value] <- LoopPatternDescriptor
(def (loop-pattern-non-goals descriptor)
  (loop-pattern-descriptor-slot descriptor 'non-goals '()))

;; Alist <- LoopPatternDescriptor
(def (loop-pattern-schedule descriptor)
  (loop-pattern-descriptor-slot descriptor 'schedule '()))

;; Alist <- LoopPatternDescriptor
(def (loop-pattern-state descriptor)
  (loop-pattern-descriptor-slot descriptor 'state '()))

;; Alist <- LoopPatternDescriptor
(def (loop-pattern-budget descriptor)
  (loop-pattern-descriptor-slot descriptor 'budget '()))

;; Alist <- LoopPatternDescriptor
(def (loop-pattern-isolation descriptor)
  (loop-pattern-descriptor-slot descriptor 'isolation '()))

;; [Value] <- LoopPatternDescriptor
(def (loop-pattern-skills descriptor)
  (loop-pattern-descriptor-slot descriptor 'skills '()))

;; [Value] <- LoopPatternDescriptor
(def (loop-pattern-connectors descriptor)
  (loop-pattern-descriptor-slot descriptor 'connectors '()))

;; Alist <- LoopPatternDescriptor
(def (loop-pattern-maker descriptor)
  (loop-pattern-descriptor-slot descriptor 'maker '()))

;; Alist <- LoopPatternDescriptor
(def (loop-pattern-checker descriptor)
  (loop-pattern-descriptor-slot descriptor 'checker '()))

;; Alist <- LoopPatternDescriptor
(def (loop-pattern-safety descriptor)
  (loop-pattern-descriptor-slot descriptor 'safety '()))

;; Alist <- LoopPatternDescriptor
(def (loop-pattern-observability descriptor)
  (loop-pattern-descriptor-slot descriptor 'observability '()))

;; [Symbol] <- LoopPatternDescriptor
(def (loop-pattern-policy-order descriptor)
  (loop-pattern-descriptor-slot descriptor 'policy-order '()))

;; Symbol <- LoopPatternDescriptor
(def (loop-pattern-control-owner descriptor)
  (loop-pattern-descriptor-slot descriptor 'control-owner #f))

;; Symbol <- LoopPatternDescriptor
(def (loop-pattern-execution-owner descriptor)
  (loop-pattern-descriptor-slot descriptor 'execution-owner #f))

;; Alist <- LoopPatternDescriptor
(def (loop-pattern-metadata descriptor)
  (loop-pattern-descriptor-slot descriptor 'metadata '()))

;; Boolean <- Symbol
(def (loop-pattern-level? level)
  (and (memq level +loop-levels+) #t))

;; Nat <- Symbol
(def (loop-pattern-level-rank level)
  (case level
    ((l1) 1)
    ((l2) 2)
    ((l2+) 3)
    ((l3) 4)
    (else 0)))

;; Boolean <- Symbol Symbol
(def (loop-pattern-level<=? lower upper)
  (<= (loop-pattern-level-rank lower)
      (loop-pattern-level-rank upper)))

;; Boolean <- LoopPatternDescriptor
(def (loop-pattern-report-only? descriptor)
  (eq? (loop-pattern-level descriptor) 'l1))

;; Boolean <- LoopPatternDescriptor
(def (loop-pattern-actionable? descriptor)
  (and (loop-pattern-level? (loop-pattern-level descriptor))
       (not (loop-pattern-report-only? descriptor))))

;; [Symbol] <- LoopPatternDescriptor
(def (loop-pattern-safety-human-gates descriptor)
  (loop-alist-ref (loop-pattern-safety descriptor) 'human-gates '()))

;; Boolean <- LoopPatternDescriptor Symbol
(def (loop-pattern-human-gate-required? descriptor gate)
  (and (memq gate (loop-pattern-safety-human-gates descriptor)) #t))

;; [ValidationError] <- Symbol FieldValue
(def (loop-required-field-error field value)
  (if value
    '()
    (list (list (cons 'field field)
                (cons 'code 'required)))))

;; [ValidationError] <- LoopPatternDescriptor
(def (loop-pattern-validation-errors descriptor)
  (if (loop-pattern-descriptor? descriptor)
    (append
     (loop-required-field-error 'name (loop-pattern-name descriptor))
     (loop-required-field-error 'goal (loop-pattern-goal descriptor))
     (if (loop-pattern-level? (loop-pattern-level descriptor))
       '()
       (list (list (cons 'field 'level)
                   (cons 'code 'unsupported-level)
                   (cons 'value (loop-pattern-level descriptor)))))
     (if (integer? (loop-pattern-priority descriptor))
       '()
       (list (list (cons 'field 'priority)
                   (cons 'code 'not-integer)
                   (cons 'value (loop-pattern-priority descriptor)))))
     (if (list? (loop-pattern-policy-order descriptor))
       '()
       (list (list (cons 'field 'policy-order)
                   (cons 'code 'not-list)))))
    (list '((field . descriptor) (code . not-loop-pattern-descriptor)))))

;; LoopPatternDescriptor <- LoopPatternDescriptor
(def (validate-loop-pattern-descriptor descriptor)
  (let (errors (loop-pattern-validation-errors descriptor))
    (if (null? errors)
      descriptor
      (raise-control-plane-failure
       'loop-pattern
       'invalid-loop-pattern-descriptor
       "invalid loop pattern descriptor"
       (list (cons 'errors errors))))))

;;; Boundary: contract projection is inert data for Marlin.
;;; Invariant: no scheduler, connector, or worktree side effect happens here.
;; Alist <- LoopPatternDescriptor
(def (loop-pattern-descriptor->contract descriptor)
  (let (valid-descriptor (validate-loop-pattern-descriptor descriptor))
    (list (cons 'schema +loop-pattern-schema+)
          (cons 'kind 'loop-pattern)
          (cons 'name (loop-pattern-name valid-descriptor))
          (cons 'goal (loop-pattern-goal valid-descriptor))
          (cons 'level (loop-pattern-level valid-descriptor))
          (cons 'priority (loop-pattern-priority valid-descriptor))
          (cons 'watched-scope (loop-pattern-watched-scope valid-descriptor))
          (cons 'non-goals (loop-pattern-non-goals valid-descriptor))
          (cons 'schedule (loop-pattern-schedule valid-descriptor))
          (cons 'state (loop-pattern-state valid-descriptor))
          (cons 'budget (loop-pattern-budget valid-descriptor))
          (cons 'isolation (loop-pattern-isolation valid-descriptor))
          (cons 'skills (loop-pattern-skills valid-descriptor))
          (cons 'connectors (loop-pattern-connectors valid-descriptor))
          (cons 'maker (loop-pattern-maker valid-descriptor))
          (cons 'checker (loop-pattern-checker valid-descriptor))
          (cons 'safety (loop-pattern-safety valid-descriptor))
          (cons 'observability (loop-pattern-observability valid-descriptor))
          (cons 'policy-order (loop-pattern-policy-order valid-descriptor))
          (cons 'control-owner (loop-pattern-control-owner valid-descriptor))
          (cons 'execution-owner (loop-pattern-execution-owner valid-descriptor))
          (cons 'metadata (loop-pattern-metadata valid-descriptor)))))
