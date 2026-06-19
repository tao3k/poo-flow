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

;; : (-> Unit Symbol)
(def +loop-pattern-schema+ 'poo-flow.loop-pattern.v1)

;; : (-> Unit [Symbol])
(def +loop-levels+ '(l1 l2 l2+ l3))

;; : (-> Unit [Symbol])
(def +loop-policy-roles+
  '(safety budget level checker maker state schedule purpose observability connector skill isolation))

;; : (-> Unit [Symbol])
(def +loop-default-human-gates+
  '(security authentication authorization payments pii infrastructure dependency-upgrade large-change repeated-failure))

;; : (-> Unit Role)
(def loop-agent-role
  (.o (:: @ control-plane-role)
      (name 'loop-agent)
      (kind 'loop-control)
      (responsibility 'loop-policy-composition)
      (runtime-owner 'gerbil)
      (loop-capability 'policy-composition)))

;; : (-> Unit Role)
(def loop-purpose-role
  (.o (:: @ loop-agent-role)
      (name 'loop-purpose)
      (kind 'loop-policy)
      (responsibility 'goal-and-scope)
      (loop-policy-slot 'purpose)))

;; : (-> Unit Role)
(def loop-level-role
  (.o (:: @ loop-agent-role)
      (name 'loop-level)
      (kind 'loop-policy)
      (responsibility 'autonomy-level-gates)
      (loop-policy-slot 'level)))

;; : (-> Unit Role)
(def loop-schedule-role
  (.o (:: @ loop-agent-role)
      (name 'loop-schedule)
      (kind 'loop-policy)
      (responsibility 'wake-up-policy)
      (loop-policy-slot 'schedule)))

;; : (-> Unit Role)
(def loop-state-role
  (.o (:: @ loop-agent-role)
      (name 'loop-state)
      (kind 'loop-policy)
      (responsibility 'durable-state-contract)
      (loop-policy-slot 'state)))

;; : (-> Unit Role)
(def loop-budget-role
  (.o (:: @ loop-agent-role)
      (name 'loop-budget)
      (kind 'loop-policy)
      (responsibility 'cost-and-attempt-gates)
      (loop-policy-slot 'budget)))

;; : (-> Unit Role)
(def loop-isolation-role
  (.o (:: @ loop-agent-role)
      (name 'loop-isolation)
      (kind 'loop-policy)
      (responsibility 'worktree-and-session-isolation)
      (loop-policy-slot 'isolation)))

;; : (-> Unit Role)
(def loop-skill-role
  (.o (:: @ loop-agent-role)
      (name 'loop-skill)
      (kind 'loop-policy)
      (responsibility 'intent-memory)
      (loop-policy-slot 'skills)))

;; : (-> Unit Role)
(def loop-connector-role
  (.o (:: @ loop-agent-role)
      (name 'loop-connector)
      (kind 'loop-policy)
      (responsibility 'external-surface-scopes)
      (loop-policy-slot 'connectors)))

;; : (-> Unit Role)
(def loop-maker-role
  (.o (:: @ loop-agent-role)
      (name 'loop-maker)
      (kind 'loop-policy)
      (responsibility 'action-agent)
      (loop-policy-slot 'maker)))

;; : (-> Unit Role)
(def loop-checker-role
  (.o (:: @ loop-agent-role)
      (name 'loop-checker)
      (kind 'loop-policy)
      (responsibility 'verification-agent)
      (loop-policy-slot 'checker)))

;; : (-> Unit Role)
(def loop-safety-role
  (.o (:: @ loop-agent-role)
      (name 'loop-safety)
      (kind 'loop-policy)
      (responsibility 'human-gates-and-denylists)
      (loop-policy-slot 'safety)))

;; : (-> Unit Role)
(def loop-observability-role
  (.o (:: @ loop-agent-role)
      (name 'loop-observability)
      (kind 'loop-policy)
      (responsibility 'run-receipts-and-metrics)
      (loop-policy-slot 'observability)))

;;; Boundary: default loop pattern slots are inert policy data.
;;; Intent: C3/POO composition ranks policy defaults before Marlin executes.
;; : (-> Unit LoopPatternDescriptorPrototype)
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
;; : (-> Symbol String [Alist] LoopPatternDescriptor)
(def (make-loop-pattern-descriptor name goal . maybe-overrides)
  (.mix slots: (role-constant-slots
                (append
                 (list (cons 'name name)
                       (cons 'goal goal))
                 (if (null? maybe-overrides) '() (car maybe-overrides))))
        loop-pattern-descriptor-prototype))

;; : (-> LoopPatternDescriptorCandidate Boolean)
(def (loop-pattern-descriptor? descriptor)
  (and (object? descriptor)
       (eq? (loop-pattern-descriptor-slot descriptor 'kind #f)
            'loop-pattern)))

;; : (-> LoopPatternDescriptor Symbol LoopSlotValue LoopSlotValue)
(def (loop-pattern-descriptor-slot descriptor slot default)
  (role-slot/default descriptor slot default))

;; : (-> Alist Symbol AlistValue AlistValue)
(def (loop-alist-ref alist key default)
  (cond
   ((assoc key alist) => cdr)
   (else default)))

;; : (-> LoopPatternDescriptor Symbol)
(def (loop-pattern-name descriptor)
  (loop-pattern-descriptor-slot descriptor 'name #f))

;; : (-> LoopPatternDescriptor String)
(def (loop-pattern-goal descriptor)
  (loop-pattern-descriptor-slot descriptor 'goal #f))

;; : (-> LoopPatternDescriptor Symbol)
(def (loop-pattern-level descriptor)
  (loop-pattern-descriptor-slot descriptor 'level #f))

;; : (-> LoopPatternDescriptor Integer)
(def (loop-pattern-priority descriptor)
  (loop-pattern-descriptor-slot descriptor 'priority #f))

;; : (-> LoopPatternDescriptor [Value])
(def (loop-pattern-watched-scope descriptor)
  (loop-pattern-descriptor-slot descriptor 'watched-scope '()))

;; : (-> LoopPatternDescriptor [Value])
(def (loop-pattern-non-goals descriptor)
  (loop-pattern-descriptor-slot descriptor 'non-goals '()))

;; : (-> LoopPatternDescriptor Alist)
(def (loop-pattern-schedule descriptor)
  (loop-pattern-descriptor-slot descriptor 'schedule '()))

;; : (-> LoopPatternDescriptor Alist)
(def (loop-pattern-state descriptor)
  (loop-pattern-descriptor-slot descriptor 'state '()))

;; : (-> LoopPatternDescriptor Alist)
(def (loop-pattern-budget descriptor)
  (loop-pattern-descriptor-slot descriptor 'budget '()))

;; : (-> LoopPatternDescriptor Alist)
(def (loop-pattern-isolation descriptor)
  (loop-pattern-descriptor-slot descriptor 'isolation '()))

;; : (-> LoopPatternDescriptor [Value])
(def (loop-pattern-skills descriptor)
  (loop-pattern-descriptor-slot descriptor 'skills '()))

;; : (-> LoopPatternDescriptor [Value])
(def (loop-pattern-connectors descriptor)
  (loop-pattern-descriptor-slot descriptor 'connectors '()))

;; : (-> LoopPatternDescriptor Alist)
(def (loop-pattern-maker descriptor)
  (loop-pattern-descriptor-slot descriptor 'maker '()))

;; : (-> LoopPatternDescriptor Alist)
(def (loop-pattern-checker descriptor)
  (loop-pattern-descriptor-slot descriptor 'checker '()))

;; : (-> LoopPatternDescriptor Alist)
(def (loop-pattern-safety descriptor)
  (loop-pattern-descriptor-slot descriptor 'safety '()))

;; : (-> LoopPatternDescriptor Alist)
(def (loop-pattern-observability descriptor)
  (loop-pattern-descriptor-slot descriptor 'observability '()))

;; : (-> LoopPatternDescriptor [Symbol])
(def (loop-pattern-policy-order descriptor)
  (loop-pattern-descriptor-slot descriptor 'policy-order '()))

;; : (-> LoopPatternDescriptor Symbol)
(def (loop-pattern-control-owner descriptor)
  (loop-pattern-descriptor-slot descriptor 'control-owner #f))

;; : (-> LoopPatternDescriptor Symbol)
(def (loop-pattern-execution-owner descriptor)
  (loop-pattern-descriptor-slot descriptor 'execution-owner #f))

;; : (-> LoopPatternDescriptor Alist)
(def (loop-pattern-metadata descriptor)
  (loop-pattern-descriptor-slot descriptor 'metadata '()))

;; : (-> Symbol Boolean)
(def (loop-pattern-level? level)
  (and (memq level +loop-levels+) #t))

;; : (-> Symbol Nat)
(def (loop-pattern-level-rank level)
  (case level
    ((l1) 1)
    ((l2) 2)
    ((l2+) 3)
    ((l3) 4)
    (else 0)))

;; : (-> Symbol Symbol Boolean)
(def (loop-pattern-level<=? lower upper)
  (<= (loop-pattern-level-rank lower)
      (loop-pattern-level-rank upper)))

;; : (-> LoopPatternDescriptor Boolean)
(def (loop-pattern-report-only? descriptor)
  (eq? (loop-pattern-level descriptor) 'l1))

;; : (-> LoopPatternDescriptor Boolean)
(def (loop-pattern-actionable? descriptor)
  (and (loop-pattern-level? (loop-pattern-level descriptor))
       (not (loop-pattern-report-only? descriptor))))

;; : (-> LoopPatternDescriptor [Symbol])
(def (loop-pattern-safety-human-gates descriptor)
  (loop-alist-ref (loop-pattern-safety descriptor) 'human-gates '()))

;; : (-> LoopPatternDescriptor Symbol Boolean)
(def (loop-pattern-human-gate-required? descriptor gate)
  (and (memq gate (loop-pattern-safety-human-gates descriptor)) #t))

;; : (-> Symbol FieldValue [ValidationError])
(def (loop-required-field-error field value)
  (if value
    '()
    (list (list (cons 'field field)
                (cons 'code 'required)))))

;; : (-> LoopPatternDescriptor [ValidationError])
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

;; : (-> LoopPatternDescriptor LoopPatternDescriptor)
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
;; : (-> LoopPatternDescriptor Alist)
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
