;;; -*- Gerbil -*-
;;; Boundary: human audit loops project review decisions over loop facts.
;;; Invariant: this module never edits config, schedules loops, or executes runtime work.

(import (only-in :clan/poo/object .o object?)
        :poo-flow/src/core/roles
        :poo-flow/src/core/failure
        :poo-flow/src/core/object-syntax
        :poo-flow/src/core/agent-harness
        (only-in "./governor.ss"
                 loop-governor?
                 loop-governor->contract/validated
                 loop-governor-human-node-role
                 loop-governor-node->contract
                 loop-governor-validation-errors)
        (only-in "../utilities/contracts.ss"
                 poo-flow-contract-alist?
                 poo-flow-contract-list-of?
                 poo-flow-contract-check-slot!
                 poo-flow-object-type-contract->alist)
        (only-in "../utilities/contract-syntax.ss"
                 defcontract-family))

(export +loop-human-audit-schema+
        +loop-human-audit-decisions+
        +loop-human-audit-default-review-policy+
        +loop-human-audit-slot-contracts+
        +loop-human-audit-type-contract+
        loop-human-governor-node-role
        loop-human-audit-role
        loop-human-review-role
        loop-human-decision-role
        loop-human-audit-prototype
        make-loop-human-audit
        loop-human-audit?
        loop-human-audit-slot
        loop-human-audit-name
        loop-human-audit-governor
        loop-human-audit-state-facts
        loop-human-audit-decisions
        loop-human-audit-review-policy
        loop-human-audit-governor-derived?
        loop-human-audit-governance-node-kind
        loop-human-audit-human-intervention?
        loop-human-audit-control-owner
        loop-human-audit-decision-owner
        loop-human-audit-execution-owner
        loop-human-audit-metadata
        loop-human-audit-alist?
        loop-human-audit-list-of?
        loop-human-audit-decision-entry?
        loop-human-audit-decision-list?
        loop-human-audit-type-contract->alist
        loop-human-audit-check-slot!
        loop-human-audit-require-slots!
        loop-human-audit-decision?
        loop-human-audit-decision-ref
        loop-human-audit-review-items
        loop-human-audit-validation-errors
        validate-loop-human-audit
        loop-human-audit->agent-operation
        loop-human-audit->runtime-snapshot
        loop-human-audit->contract)

;;; Boundary: schema names the human audit review contract.
;; : (-> Unit Symbol)
(def +loop-human-audit-schema+ 'poo-flow.loop-human-audit.v1)

;;; Boundary: decision values are review state, not config comments.
;; : (-> Unit [Symbol])
(def +loop-human-audit-decisions+
  '(pending approved rejected escalated changes-requested))

;;; Boundary: default policy says the surface is review-only.
;; : (-> Unit Alist)
(def +loop-human-audit-default-review-policy+
  '((mode . review-loop)
    (governor-derived . #t)
    (governance-node-kind . human)
    (requires-human . #t)
    (records-decisions . #t)
    (mutates-config . #f)
    (executes-runtime . #f)))

;;; Boundary: human audit is a governor-derived node in the governance chain.
;;; It reuses POO/C3 governor policy shape while marking the node as human.
;; : (-> Unit Role)
(def loop-human-governor-node-role
  (.o (:: @ loop-governor-human-node-role)
      (name 'loop-human-governor-node)
      (kind 'loop-control)
      (responsibility 'human-node-governance)
      (runtime-owner 'gerbil)
      (loop-capability 'human-governor-node)
      (governance-node-kind 'human)
      (governance-responsibility 'human-audit)
      (human-intervention #t)))

;;; Boundary: root audit role owns true human intervention.
;;; It is a governor-derived human node, not an agent judge.
;; : (-> Unit Role)
(def loop-human-audit-role
  (.o (:: @ loop-human-governor-node-role)
      (name 'loop-human-audit)
      (kind 'loop-control)
      (responsibility 'human-intervention-loop)
      (runtime-owner 'gerbil)
      (loop-capability 'human-audit-review)))

;;; Boundary: review role projects human review items from supplied facts.
;; : (-> Unit Role)
(def loop-human-review-role
  (.o (:: @ loop-human-audit-role)
      (name 'loop-human-review)
      (kind 'loop-policy)
      (responsibility 'review-item-projection)
      (loop-policy-slot 'review-items)))

;;; Boundary: decision role records human outcomes as data.
;; : (-> Unit Role)
(def loop-human-decision-role
  (.o (:: @ loop-human-audit-role)
      (name 'loop-human-decision)
      (kind 'loop-policy)
      (responsibility 'approval-rejection-escalation)
      (loop-policy-slot 'decisions)))

;;; Prototype slots keep audit state separate from user config.
;; : (-> Unit LoopHumanAuditPrototype)
(def loop-human-audit-prototype
  (poo-core-role-object
   (slots ((schema +loop-human-audit-schema+)
           (kind 'loop-human-audit)
           (name #f)
           (governor #f)
           (governor-contract #f)
           (state-facts '())
           (decisions '())
           (review-policy +loop-human-audit-default-review-policy+)
           (governor-derived #t)
           (governance-node-kind 'human)
           (governance-responsibility 'human-audit)
           (human-intervention #t)
           (control-owner 'gerbil)
           (decision-owner 'human)
           (execution-owner 'marlin-agent-core)
           (metadata '())))
   (supers loop-human-decision-role
           loop-human-review-role
           loop-human-audit-role)))

;; : (-> Alist Alist Alist)
(def (loop-human-audit-slot-rows/tail rows tail)
  (foldr cons tail rows))

;; : (-> Symbol LoopGovernor [Alist] [Alist] Alist Alist)
(def (loop-human-audit-slot-rows name
                                 governor
                                 state-facts
                                 decisions
                                 overrides)
  (loop-human-audit-slot-rows/tail
   (list
    (cons 'name name)
    (cons 'governor governor)
    (cons 'state-facts state-facts)
    (cons 'decisions decisions))
   overrides))

;;; Constructor binds one governor view to human decisions.
;;; Decisions are alists of =(pattern . decision)=.
;; : (-> Symbol LoopGovernor [Alist] [Alist] [Alist] LoopHumanAudit)
(def (make-loop-human-audit name governor state-facts decisions . maybe-overrides)
  (poo-core-role-object
   (slot-rows
    (loop-human-audit-slot-rows
     name
     governor
     state-facts
     decisions
     (if (null? maybe-overrides) '() (car maybe-overrides))))
   (supers loop-human-audit-prototype)))

;; : (-> LoopHumanAuditCandidate Boolean)
(def (loop-human-audit? audit)
  (and (object? audit)
       (eq? (loop-human-audit-slot audit 'kind #f)
            'loop-human-audit)))

;; : (-> LoopHumanAudit Symbol Value Value)
(def (loop-human-audit-slot audit slot default)
  (role-slot/default audit slot default))

;;; Boundary: loop human audit alist ref is the policy-visible edge for loop
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Alist Symbol Value Value)
(def (loop-human-audit-alist-ref alist key default)
  (cond
   ((assoc key alist) => cdr)
   (else default)))

;; | LoopHumanAuditDecisionCandidate = Symbol
;; : (-> LoopHumanAuditDecisionCandidate (List LoopHumanAuditDecisionCandidate) Boolean)
(def (loop-human-audit-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else
    (loop-human-audit-member? value (cdr values)))))

;; loop-human-audit-alist?
;;   : (-> PooFlowValue Boolean)
;;   | doc m%
;;       Recognize proper alist values used by audit review projections.
;;       # Examples
;;       (loop-human-audit-alist? '((mode . review-loop)))
;;       # Result
;;       #t for proper association lists.
;;     %
(def (loop-human-audit-alist? value)
  (poo-flow-contract-alist? value))

;; loop-human-audit-list-of?
;;   : (-> (-> PooFlowValue Boolean) PooFlowValue Boolean)
;;   | doc m%
;;       Recognize proper human-audit lists whose elements satisfy a predicate.
;;       # Examples
;;       (loop-human-audit-list-of? symbol? '(pending approved))
;;       # Result
;;       #t when every element satisfies the supplied predicate.
;;     %
(def (loop-human-audit-list-of? predicate values)
  (poo-flow-contract-list-of? predicate values))

;; : (-> PooFlowValue Boolean)
(def (loop-human-audit-state-fact-list? value)
  (loop-human-audit-list-of? loop-human-audit-alist? value))

;; : (-> PooFlowValue Boolean)
(def (loop-human-audit-governor-contract? value)
  (or (not value)
      (loop-human-audit-alist? value)))

;; : (-> PooFlowValue Boolean)
(def (loop-human-audit-decision-entry? value)
  (and (pair? value)
       (symbol? (car value))
       (loop-human-audit-decision? (cdr value))))

;; : (-> PooFlowValue Boolean)
(def (loop-human-audit-decision-list? value)
  (loop-human-audit-list-of? loop-human-audit-decision-entry? value))

;; loop-human-audit-type-contract->alist
;;   : (-> Unit Alist)
;;   | doc m%
;;       Project the structured contract for human audit loop POO objects.
;;       # Examples
;;       (loop-human-audit-type-contract->alist)
;;       # Result
;;       An alist representation for doctor, graph explanation, and manifests.
;;     %
(def (loop-human-audit-type-contract->alist)
  (poo-flow-object-type-contract->alist +loop-human-audit-type-contract+))

;; loop-human-audit-check-slot!
;;   : (-> PooFlowSlotContract PooFlowValue PooFlowValue)
;;   | doc m%
;;       Execute one human-audit slot contract through utilities.
;;       # Examples
;;       (loop-human-audit-check-slot! +loop-human-audit-name-contract+ 'audit)
;;       # Result
;;       The original value when valid; otherwise raises a contract error.
;;     %
(def (loop-human-audit-check-slot! contract value)
  (poo-flow-contract-check-slot! contract value))

;; loop-human-audit-require-slots!
;;   : (-> Symbol LoopGovernor MaybeAlist [Alist] [Alist] Alist Boolean Symbol Boolean Symbol Symbol Symbol Alist Boolean)
;;   | doc m%
;;       Enforce generated slot contracts for the human audit loop boundary.
;;       # Examples
;;       (loop-human-audit-require-slots!
;;        'audit governor #f state-facts decisions policy #t 'human #t 'gerbil 'human 'marlin-agent-core '())
;;       # Result
;;       #t when every human audit slot satisfies its generated contract.
;;     %
(def (loop-human-audit-require-slots! name governor governor-contract state-facts decisions review-policy governor-derived governance-node-kind human-intervention control-owner decision-owner execution-owner metadata)
  (loop-human-audit-check-slot! +loop-human-audit-name-contract+ name)
  (loop-human-audit-check-slot! +loop-human-audit-governor-contract+ governor)
  (loop-human-audit-check-slot!
   +loop-human-audit-governor-contract-slot-contract+
   governor-contract)
  (loop-human-audit-check-slot!
   +loop-human-audit-state-facts-contract+
   state-facts)
  (loop-human-audit-check-slot! +loop-human-audit-decisions-contract+ decisions)
  (loop-human-audit-check-slot!
   +loop-human-audit-review-policy-contract+
   review-policy)
  (loop-human-audit-check-slot!
   +loop-human-audit-governor-derived-contract+
   governor-derived)
  (loop-human-audit-check-slot!
   +loop-human-audit-governance-node-kind-contract+
   governance-node-kind)
  (loop-human-audit-check-slot!
   +loop-human-audit-human-intervention-contract+
   human-intervention)
  (loop-human-audit-check-slot!
   +loop-human-audit-control-owner-contract+
   control-owner)
  (loop-human-audit-check-slot!
   +loop-human-audit-decision-owner-contract+
   decision-owner)
  (loop-human-audit-check-slot!
   +loop-human-audit-execution-owner-contract+
   execution-owner)
  (loop-human-audit-check-slot! +loop-human-audit-metadata-contract+ metadata)
  #t)

;;; Boundary: loop human audit filter is the policy-visible edge for loop
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Predicate [Value] [Value])
(def (loop-human-audit-filter predicate values)
  (cond
   ((null? values) '())
   ((predicate (car values))
    (cons (car values)
          (loop-human-audit-filter predicate (cdr values))))
   (else
    (loop-human-audit-filter predicate (cdr values)))))

;; : (-> LoopHumanAudit Symbol)
(def (loop-human-audit-name audit)
  (loop-human-audit-slot audit 'name #f))

;; : (-> LoopHumanAudit LoopGovernor)
(def (loop-human-audit-governor audit)
  (loop-human-audit-slot audit 'governor #f))

;; : (-> LoopHumanAudit MaybeAlist)
(def (loop-human-audit-governor-contract audit)
  (loop-human-audit-slot audit 'governor-contract #f))

;; : (-> LoopHumanAudit [Alist])
(def (loop-human-audit-state-facts audit)
  (loop-human-audit-slot audit 'state-facts '()))

;; : (-> LoopHumanAudit [Alist])
(def (loop-human-audit-decisions audit)
  (loop-human-audit-slot audit 'decisions '()))

;; : (-> LoopHumanAudit Alist)
(def (loop-human-audit-review-policy audit)
  (loop-human-audit-slot audit 'review-policy '()))

;; : (-> LoopHumanAudit Boolean)
(def (loop-human-audit-governor-derived? audit)
  (loop-human-audit-slot audit 'governor-derived #f))

;; : (-> LoopHumanAudit Symbol)
(def (loop-human-audit-governance-node-kind audit)
  (loop-human-audit-slot audit 'governance-node-kind #f))

;; : (-> LoopHumanAudit Boolean)
(def (loop-human-audit-human-intervention? audit)
  (loop-human-audit-slot audit 'human-intervention #f))

;; : (-> LoopHumanAudit Symbol)
(def (loop-human-audit-control-owner audit)
  (loop-human-audit-slot audit 'control-owner #f))

;; : (-> LoopHumanAudit Symbol)
(def (loop-human-audit-decision-owner audit)
  (loop-human-audit-slot audit 'decision-owner #f))

;; : (-> LoopHumanAudit Symbol)
(def (loop-human-audit-execution-owner audit)
  (loop-human-audit-slot audit 'execution-owner #f))

;; : (-> LoopHumanAudit Alist)
(def (loop-human-audit-metadata audit)
  (loop-human-audit-slot audit 'metadata '()))

;; : (-> Symbol Boolean)
(def (loop-human-audit-decision? decision)
  (loop-human-audit-member? decision +loop-human-audit-decisions+))

;;; Boundary: loop human audit decision ref is the policy-visible edge for loop
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> LoopHumanAudit Symbol Symbol Symbol)
(def (loop-human-audit-decision-ref audit pattern default)
  (let (found (assoc pattern (loop-human-audit-decisions audit)))
    (if found (cdr found) default)))

;; : (-> Symbol Symbol Value Symbol Alist)
(def (loop-human-audit-review-item reason pattern action-key decision)
  (list (cons 'reason reason)
        (cons 'pattern pattern)
        (cons 'acting_on action-key)
        (cons 'decision decision)))

;; : (-> LoopHumanAudit Alist Symbol Alist)
(def (loop-human-audit-inbox-item->review-item audit item)
  (let* ((pattern (loop-human-audit-alist-ref item 'pattern #f))
         (decision (loop-human-audit-decision-ref audit pattern 'pending)))
    (loop-human-audit-review-item
     (loop-human-audit-alist-ref item 'reason 'human-inbox)
     pattern
     (loop-human-audit-alist-ref item 'acting_on #f)
     decision)))

;; : (-> LoopHumanAudit Symbol Alist)
(def (loop-human-audit-open-pattern->review-item audit pattern)
  (loop-human-audit-review-item
   'actionable-pattern
   pattern
   #f
   (loop-human-audit-decision-ref audit pattern 'pending)))

;;; Review items combine actionable recommendations and blocked inbox facts.
;;; This is the human loop surface; it does not mutate config or state.
;; : (-> LoopHumanAudit [Alist])
(def (loop-human-audit-review-items audit)
  (let* ((valid-audit (validate-loop-human-audit audit))
         (governor (loop-human-audit-governor valid-audit))
         (state-facts (loop-human-audit-state-facts valid-audit))
         (contract (loop-governor->contract/validated governor state-facts)))
    (loop-human-audit-review-items/from-governor-contract
     valid-audit
     contract)))

;;; Boundary: loop human audit review items from governor contract is the
;;; policy-visible edge for loop behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> LoopHumanAudit Alist [Alist])
(def (loop-human-audit-review-items/from-governor-contract audit contract)
  (loop-human-audit-open-review-items/tail
   audit
   (loop-human-audit-alist-ref contract 'open-patterns '())
   (loop-human-audit-inbox-review-items/tail
    audit
    (loop-human-audit-alist-ref contract 'human-inbox-items '())
    '())))

;; : (-> LoopHumanAudit [Symbol] [Alist] [Alist])
(def (loop-human-audit-open-review-items/tail audit patterns tail)
  (cond
   ((null? patterns) tail)
   (else
    (cons (loop-human-audit-open-pattern->review-item audit (car patterns))
          (loop-human-audit-open-review-items/tail
           audit
           (cdr patterns)
           tail)))))

;; : (-> LoopHumanAudit [Alist] [Alist] [Alist])
(def (loop-human-audit-inbox-review-items/tail audit items tail)
  (cond
   ((null? items) tail)
   (else
    (cons (loop-human-audit-inbox-item->review-item audit (car items))
          (loop-human-audit-inbox-review-items/tail
           audit
           (cdr items)
           tail)))))

;;; Boundary: loop human audit required field error is the policy-visible edge
;;; for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> Symbol Value [ValidationError])
(def (loop-human-audit-required-field-error/tail field value tail)
  (if value
    tail
    (cons (list (cons 'field field)
                (cons 'code 'required))
          tail)))

;; : (-> Symbol Value [ValidationError])
(def (loop-human-audit-required-field-error field value)
  (loop-human-audit-required-field-error/tail field value '()))

;;; Boundary: loop human audit field validation error unless is the policy-
;;; visible edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> Boolean Symbol Symbol FieldValue [ValidationError])
(def (loop-human-audit-field-validation-error/unless/tail valid?
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
(def (loop-human-audit-field-validation-error/unless valid? field code value)
  (loop-human-audit-field-validation-error/unless/tail
   valid?
   field
   code
   value
   '()))

;;; Boundary: loop human audit governor validation errors is the policy-visible
;;; edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> LoopGovernor [ValidationError])
(def (loop-human-audit-governor-validation-errors governor)
  (if (loop-governor? governor)
    (loop-governor-validation-errors governor)
    (list (list (cons 'field 'governor)
                (cons 'code 'not-loop-governor)))))

;;; Boundary: loop human audit governor contract validation errors is the
;;; policy-visible edge for loop behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> LoopGovernor [ValidationError])
(def (loop-human-audit-governor-contract-validation-errors governor)
  (if (loop-governor? governor)
    '()
    (list (list (cons 'field 'governor)
                (cons 'code 'not-loop-governor)))))

;;; Boundary: loop human audit governor contract field validation errors is the
;;; policy-visible edge for loop behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> MaybeAlist [ValidationError])
(def (loop-human-audit-governor-contract-field-validation-errors contract)
  (if (or (not contract) (list? contract))
    '()
    (list (list (cons 'field 'governor-contract)
                (cons 'code 'not-list)
                (cons 'value contract)))))

;;; Boundary: loop human audit decision validation errors is the policy-visible
;;; edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;;; Boundary: loop human audit decisions field validation errors is the policy-
;;; visible edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [Alist] [ValidationError])
(def (loop-human-audit-decisions-field-validation-errors decisions)
  (if (list? decisions)
    (loop-human-audit-decision-validation-errors decisions)
    (list (list (cons 'field 'decisions)
                (cons 'code 'not-list)
                (cons 'value decisions)))))

;;; Boundary: loop human audit decision validation errors is the policy-visible
;;; edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [Alist] [ValidationError])
(def (loop-human-audit-decision-validation-errors decisions)
  (cond
   ((null? decisions) '())
   ((and (pair? (car decisions))
         (loop-human-audit-decision? (cdar decisions)))
    (loop-human-audit-decision-validation-errors (cdr decisions)))
   (else
    (cons (list (cons 'field 'decisions)
                (cons 'code 'unsupported-decision)
                (cons 'value (car decisions)))
          (loop-human-audit-decision-validation-errors (cdr decisions))))))

;; : (-> [ValidationError] [ValidationError] [ValidationError])
(def (loop-human-audit-errors/tail errors tail)
  (if (null? errors)
    tail
    (cons (car errors)
          (loop-human-audit-errors/tail (cdr errors) tail))))

;;; Boundary: validation keeps audit contracts typed before review projection.
;; : (-> LoopHumanAudit [ValidationError])
(def (loop-human-audit-validation-errors audit)
  (if (loop-human-audit? audit)
    (loop-human-audit-required-field-error/tail
     'name
     (loop-human-audit-name audit)
     (loop-human-audit-errors/tail
      (loop-human-audit-governor-validation-errors
       (loop-human-audit-governor audit))
      (loop-human-audit-errors/tail
       (loop-human-audit-governor-contract-field-validation-errors
        (loop-human-audit-governor-contract audit))
       (loop-human-audit-field-validation-error/unless/tail
        (list? (loop-human-audit-state-facts audit))
        'state-facts
        'not-list
        (loop-human-audit-state-facts audit)
        (loop-human-audit-decisions-field-validation-errors
         (loop-human-audit-decisions audit))))))
    (list '((field . audit) (code . not-loop-human-audit)))))

;;; Boundary: loop human audit validation errors contract facts is the policy-
;;; visible edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> LoopHumanAudit [ValidationError])
(def (loop-human-audit-validation-errors/contract-facts audit)
  (if (loop-human-audit? audit)
    (loop-human-audit-required-field-error/tail
     'name
     (loop-human-audit-name audit)
     (loop-human-audit-errors/tail
      (loop-human-audit-governor-contract-validation-errors
       (loop-human-audit-governor audit))
      (loop-human-audit-errors/tail
       (loop-human-audit-governor-contract-field-validation-errors
        (loop-human-audit-governor-contract audit))
       (loop-human-audit-field-validation-error/unless/tail
        (list? (loop-human-audit-state-facts audit))
        'state-facts
        'not-list
        (loop-human-audit-state-facts audit)
        (loop-human-audit-decisions-field-validation-errors
         (loop-human-audit-decisions audit))))))
    (list '((field . audit) (code . not-loop-human-audit)))))

;;; Boundary: validate loop human audit is the policy-visible edge for loop
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> LoopHumanAudit LoopHumanAudit)
(def (validate-loop-human-audit audit)
  (let (errors (loop-human-audit-validation-errors audit))
    (if (null? errors)
      audit
      (raise-control-plane-failure
       'loop-human-audit
       'invalid-loop-human-audit
       "invalid loop human audit"
       (list (cons 'errors errors))))))

;;; Boundary: validate loop human audit contract facts is the policy-visible
;;; edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> LoopHumanAudit LoopHumanAudit)
(def (validate-loop-human-audit/contract-facts audit)
  (let (errors (loop-human-audit-validation-errors/contract-facts audit))
    (if (null? errors)
      audit
      (raise-control-plane-failure
       'loop-human-audit
       'invalid-loop-human-audit
       "invalid loop human audit"
       (list (cons 'errors errors))))))

;;; Decision projection keeps review filtering as data-flow over the policy
;;; table, so adding a decision does not change the contract writer.
;; : (-> LoopHumanAudit Symbol [Symbol])
(def (loop-human-audit-patterns-by-decision audit decision)
  (loop-human-audit-patterns-by-decision/from-decisions
   (loop-human-audit-decisions audit)
   decision))

;; : (-> [Alist] Symbol [Symbol])
(def (loop-human-audit-patterns-by-decision/from-decisions decisions decision)
  (cond
   ((null? decisions) '())
   ((and (pair? (car decisions))
         (eq? (cdar decisions) decision))
    (cons (caar decisions)
          (loop-human-audit-patterns-by-decision/from-decisions
           (cdr decisions)
           decision)))
   (else
    (loop-human-audit-patterns-by-decision/from-decisions
     (cdr decisions)
     decision))))

;;; Boundary: loop human audit review items pending predicate is the policy-
;;; visible edge for loop behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [Alist] Boolean)
(def (loop-human-audit-review-items-pending? review-items)
  (cond
   ((null? review-items) #f)
   ((eq? (loop-human-audit-alist-ref (car review-items)
                                     'decision
                                     'pending)
         'pending)
    #t)
   (else
    (loop-human-audit-review-items-pending? (cdr review-items)))))

;;; Boundary: loop human audit operation status is the policy-visible edge for
;;; loop behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [Alist] Symbol)
(def (loop-human-audit-operation-status review-items)
  (if (loop-human-audit-review-items-pending? review-items)
    'waiting-human
    'completed))

;; : (-> LoopHumanAudit Symbol)
(def (loop-human-audit-operation-id audit)
  (string->symbol
   (string-append
    "human-audit:"
    (symbol->string (loop-human-audit-name audit)))))

;;; Human audit is projected as an agent operation so loop cases can hand the
;;; same inert object family to CLI, UI, or runtime adapters. It is still
;;; review-only data: no runtime work is submitted here.
;; : (-> LoopHumanAudit [Alist] PooFlowAgentOperation)
(def (loop-human-audit->agent-operation* audit review-items)
  (make-poo-flow-agent-operation
   (loop-human-audit-operation-id audit)
   'human-audit
   (list 'loop-human-audit (loop-human-audit-name audit))
   #f
   (list (cons 'schema +loop-human-audit-schema+)
         (cons 'review-items review-items)
         (cons 'decisions (loop-human-audit-decisions audit)))
   +loop-human-audit-schema+
   (list (cons 'target (loop-human-audit-execution-owner audit))
         (cons 'mode 'review-loop)
         (cons 'executes-runtime #f))
   (loop-human-audit-operation-status review-items)
   #f
   (list (cons 'governor-derived
               (loop-human-audit-governor-derived? audit))
         (cons 'governance-node-kind
               (loop-human-audit-governance-node-kind audit))
         (cons 'decision-owner
               (loop-human-audit-decision-owner audit)))))

;; : (-> LoopHumanAudit PooFlowAgentOperation)
(def (loop-human-audit->agent-operation audit)
  (let* ((valid-audit (validate-loop-human-audit audit))
         (review-items (loop-human-audit-review-items valid-audit)))
    (loop-human-audit->agent-operation* valid-audit review-items)))

;; : (-> LoopHumanAudit [Alist] PooFlowRuntimeSnapshot)
(def (loop-human-audit->runtime-snapshot* audit review-items)
  (make-poo-flow-runtime-snapshot
   'human-audit
   (loop-human-audit-name audit)
   (loop-human-audit-operation-status review-items)
   #f
   (list (cons 'review-count (length review-items))
         (cons 'approved-patterns
               (loop-human-audit-patterns-by-decision audit 'approved))
         (cons 'rejected-patterns
               (loop-human-audit-patterns-by-decision audit 'rejected))
         (cons 'escalated-patterns
               (loop-human-audit-patterns-by-decision audit 'escalated))
         (cons 'changed-requested-patterns
               (loop-human-audit-patterns-by-decision
                audit
                'changes-requested)))
   #f
   '((stage . loop-human-audit->runtime-snapshot)
     (runtime-executed . #f)
     (projection-only . #t))
   (list (cons 'operation-id
               (loop-human-audit-operation-id audit))
         (cons 'decision-owner
               (loop-human-audit-decision-owner audit)))))

;; : (-> LoopHumanAudit PooFlowRuntimeSnapshot)
(def (loop-human-audit->runtime-snapshot audit)
  (let* ((valid-audit (validate-loop-human-audit audit))
         (review-items (loop-human-audit-review-items valid-audit)))
    (loop-human-audit->runtime-snapshot* valid-audit review-items)))

;;; Contract projection is the human audit loop review surface.
;;; It records review state without writing config, state, or runtime effects.
;; : (-> LoopHumanAudit Alist Alist)
(def (loop-human-audit->contract/validated-governor-contract
      valid-audit
      governor-contract)
  (let* ((state-facts (loop-human-audit-state-facts valid-audit))
         (review-items
          (loop-human-audit-review-items/from-governor-contract
           valid-audit
           governor-contract))
         (agent-operation
          (loop-human-audit->agent-operation* valid-audit review-items))
         (runtime-snapshot
          (loop-human-audit->runtime-snapshot* valid-audit review-items)))
    (list (cons 'schema +loop-human-audit-schema+)
          (cons 'kind 'loop-human-audit)
          (cons 'name (loop-human-audit-name valid-audit))
          (cons 'governor-schema
                (loop-human-audit-alist-ref governor-contract 'schema #f))
          (cons 'governor governor-contract)
          (cons 'review-policy
                (loop-human-audit-review-policy valid-audit))
          (cons 'audit-boundary
                (list (cons 'governor-derived
                            (loop-human-audit-governor-derived? valid-audit))
                      (cons 'governance-node-kind
                            (loop-human-audit-governance-node-kind valid-audit))
                      (cons 'human-intervention
                            (loop-human-audit-human-intervention? valid-audit))
                      (cons 'agent-judgement-source
                            'consumed-governor-facts)))
          (cons 'audit-node
                (loop-governor-node->contract valid-audit))
          (cons 'review-items review-items)
          (cons 'review-count (length review-items))
          (cons 'agent-operation
                (poo-flow-agent-operation->alist agent-operation))
          (cons 'runtime-snapshot
                (poo-flow-runtime-snapshot->alist runtime-snapshot))
          (cons 'decisions (loop-human-audit-decisions valid-audit))
          (cons 'approved-patterns
                (loop-human-audit-patterns-by-decision valid-audit 'approved))
          (cons 'rejected-patterns
                (loop-human-audit-patterns-by-decision valid-audit 'rejected))
          (cons 'escalated-patterns
                (loop-human-audit-patterns-by-decision valid-audit 'escalated))
          (cons 'changed-requested-patterns
                (loop-human-audit-patterns-by-decision
                 valid-audit
                 'changes-requested))
          (cons 'state-facts state-facts)
          (cons 'runtime-boundary
                '((local-execution . validation-only)
                  (config-mutation . checked-interface-only)
                  (governor-inheritance . poo-c3)
                  (human-decision-state . review-loop)))
          (cons 'control-owner (loop-human-audit-control-owner valid-audit))
          (cons 'decision-owner (loop-human-audit-decision-owner valid-audit))
          (cons 'execution-owner (loop-human-audit-execution-owner valid-audit))
          (cons 'metadata (loop-human-audit-metadata valid-audit)))))

;;; Boundary: loop human audit to contract is the policy-visible edge for loop
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> LoopHumanAudit Alist)
(def (loop-human-audit->contract audit)
  (let* ((provided-governor-contract
          (loop-human-audit-governor-contract audit))
         (valid-audit
          (if provided-governor-contract
            (validate-loop-human-audit/contract-facts audit)
            (validate-loop-human-audit audit)))
         (governor (loop-human-audit-governor valid-audit))
         (state-facts (loop-human-audit-state-facts valid-audit))
         (governor-contract
          (or provided-governor-contract
              (loop-governor->contract/validated governor state-facts))))
    (loop-human-audit->contract/validated-governor-contract
     valid-audit
     governor-contract)))

(defcontract-family
  +loop-human-audit-slot-contracts+
  +loop-human-audit-type-contract+
  'loop-human-audit
  'loops
  'LoopHumanAudit
  '((boundary . loop-human-audit) (projection . human-review-loop))
  ((+loop-human-audit-name-contract+
    'loop-human-audit/name
    'name
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-human-audit-governor-contract+
    'loop-human-audit/governor
    'governor
    'LoopGovernor
    'loop-governor?
    loop-governor?
    #t
    '())
   (+loop-human-audit-governor-contract-slot-contract+
    'loop-human-audit/governor-contract
    'governor-contract
    'MaybeAlist
    'loop-human-audit-governor-contract?
    loop-human-audit-governor-contract?
    #t
    '())
   (+loop-human-audit-state-facts-contract+
    'loop-human-audit/state-facts
    'state-facts
    '[Alist]
    'loop-human-audit-state-fact-list?
    loop-human-audit-state-fact-list?
    #t
    '())
   (+loop-human-audit-decisions-contract+
    'loop-human-audit/decisions
    'decisions
    '[LoopHumanAuditDecision]
    'loop-human-audit-decision-list?
    loop-human-audit-decision-list?
    #t
    '())
   (+loop-human-audit-review-policy-contract+
    'loop-human-audit/review-policy
    'review-policy
    'Alist
    'loop-human-audit-alist?
    loop-human-audit-alist?
    #t
    '())
   (+loop-human-audit-governor-derived-contract+
    'loop-human-audit/governor-derived
    'governor-derived
    'Boolean
    'boolean?
    boolean?
    #t
    '())
   (+loop-human-audit-governance-node-kind-contract+
    'loop-human-audit/governance-node-kind
    'governance-node-kind
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-human-audit-human-intervention-contract+
    'loop-human-audit/human-intervention
    'human-intervention
    'Boolean
    'boolean?
    boolean?
    #t
    '())
   (+loop-human-audit-control-owner-contract+
    'loop-human-audit/control-owner
    'control-owner
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-human-audit-decision-owner-contract+
    'loop-human-audit/decision-owner
    'decision-owner
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-human-audit-execution-owner-contract+
    'loop-human-audit/execution-owner
    'execution-owner
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+loop-human-audit-metadata-contract+
    'loop-human-audit/metadata
    'metadata
    'Alist
    'loop-human-audit-alist?
    loop-human-audit-alist?
    #t
    '())))
