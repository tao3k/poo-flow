;;; -*- Gerbil -*-
;;; Owner: dynamic agent-sandbox profile candidates live here.
;;; Boundary:
;;; - Candidates, patches, promotion requests, and receipts are inert data.
;;; - Runtime promote/apply/link stays behind Marlin or backend runtimes.
;;; Import contract: backend modules override POO descriptor slots, not this data shape.
;;; Policy evidence: tests validate contracts without invoking nono or CubeSandbox.

(import (only-in :clan/poo/object .@ .mix object?)
        :poo-flow/src/core/api
        :poo-flow/src/modules/agent-sandbox/alist
        :poo-flow/src/modules/agent-sandbox/profile)

(export +agent-sandbox-profile-candidate-schema+
        +agent-sandbox-profile-candidate-patch-schema+
        +agent-sandbox-profile-promotion-request-schema+
        +agent-sandbox-profile-promotion-receipt-schema+
        +agent-sandbox-profile-candidate-choice-actions+
        defagent-sandbox-profile-candidate-contract
        agent-sandbox-profile-candidate
        agent-sandbox-profile-candidate-choice
        agent-sandbox-profile-candidate-descriptor-prototype
        make-agent-sandbox-profile-candidate-descriptor
        agent-sandbox-profile-candidate-descriptor?
        agent-sandbox-profile-candidate-descriptor-name
        agent-sandbox-profile-candidate-descriptor-backend-kind
        agent-sandbox-profile-candidate-descriptor-source
        agent-sandbox-profile-candidate-descriptor-metadata
        agent-sandbox-profile-candidate-descriptor-validator
        agent-sandbox-profile-candidate-descriptor-patch-projector
        agent-sandbox-profile-candidate-descriptor-promotion-projector
        agent-sandbox-profile-candidate-descriptor->candidate
        make-agent-sandbox-profile-candidate-choice
        make-agent-sandbox-profile-candidate
        agent-sandbox-profile-candidate?
        agent-sandbox-profile-candidate-choice?
        agent-sandbox-profile-candidate-patch?
        agent-sandbox-profile-promotion-request?
        agent-sandbox-profile-candidate-validation-errors
        agent-sandbox-validate-profile-candidate
        agent-sandbox-profile-promotion-request-validation-errors
        agent-sandbox-validate-profile-promotion-request
        agent-sandbox-profile-candidate-ref
        agent-sandbox-profile-candidate-backend-kind
        agent-sandbox-profile-candidate-source
        agent-sandbox-profile-candidate-profile-ref
        agent-sandbox-profile-candidate-command
        agent-sandbox-profile-candidate-observations
        agent-sandbox-profile-candidate-choices
        agent-sandbox-profile-candidate-metadata
        agent-sandbox-profile-candidate->patch
        agent-sandbox-profile-candidate->nono-promote-request
        agent-sandbox-profile-promotion-receipt)

;; : (-> Unit Symbol)
(def +agent-sandbox-profile-candidate-schema+
  'poo-flow.agent-sandbox-profile-candidate.v1)

;; : (-> Unit Symbol)
(def +agent-sandbox-profile-candidate-patch-schema+
  'poo-flow.agent-sandbox-profile-candidate-patch.v1)

;; : (-> Unit Symbol)
(def +agent-sandbox-profile-promotion-request-schema+
  'poo-flow.agent-sandbox-profile-promotion-request.v1)

;; : (-> Unit Symbol)
(def +agent-sandbox-profile-promotion-receipt-schema+
  'poo-flow.agent-sandbox-profile-promotion-receipt.v1)

;; : (-> Unit [Symbol])
(def +agent-sandbox-profile-candidate-choice-actions+
  '(grant suppress skip))

;;; Contract declarations are macro-owned so new backends can declare required
;;; fields once and reuse the same validation function shape as core profiles.
;; : (-> CandidateContractSyntax CandidateContractDefinition)
(defrules defagent-sandbox-profile-candidate-contract ()
  ((_ name (field predicate) ...)
   (def name
     (list (cons 'field predicate) ...))))

;; : (-> Value Boolean)
(def (agent-sandbox-profile-candidate-present? value)
  (and value #t))

;; : (-> Value Boolean)
(def (agent-sandbox-profile-candidate-schema? value)
  (eq? value +agent-sandbox-profile-candidate-schema+))

;; : (-> Value Boolean)
(def (agent-sandbox-profile-candidate-patch-schema? value)
  (eq? value +agent-sandbox-profile-candidate-patch-schema+))

;; : (-> Value Boolean)
(def (agent-sandbox-profile-promotion-request-schema? value)
  (eq? value +agent-sandbox-profile-promotion-request-schema+))

;; : (-> Value Boolean)
(def (agent-sandbox-profile-candidate-choice-action? value)
  (or (eq? value 'grant)
      (eq? value 'suppress)
      (eq? value 'skip)))

;; : (-> Value Boolean)
(def (agent-sandbox-profile-candidate-choice? choice)
  (and (list? choice)
       (agent-sandbox-profile-candidate-choice-action?
        (agent-sandbox-alist-ref choice 'action #f))
       (agent-sandbox-profile-candidate-present?
        (agent-sandbox-alist-ref choice 'section #f))
       (agent-sandbox-profile-candidate-present?
        (agent-sandbox-alist-ref choice 'value #f))))

;; : (-> [ProfileCandidateChoice] Boolean)
(def (agent-sandbox-profile-candidate-choice-list-tail? choices)
  (cond
   ((null? choices) #t)
   ((not (pair? choices)) #f)
   ((agent-sandbox-profile-candidate-choice? (car choices))
    (agent-sandbox-profile-candidate-choice-list-tail? (cdr choices)))
   (else #f)))

;; : (-> Value Boolean)
(def (agent-sandbox-profile-candidate-choice-list? choices)
  (and (pair? choices)
       (agent-sandbox-profile-candidate-choice-list-tail? choices)))

(defagent-sandbox-profile-candidate-contract
  +agent-sandbox-profile-candidate-required-fields+
  (backend-kind agent-sandbox-profile-candidate-present?)
  (source agent-sandbox-profile-candidate-present?)
  (choices agent-sandbox-profile-candidate-choice-list?))

;;; Syntax sugar produces data only. Runtime validation remains in the ordinary
;;; constructors so macro users and function users share the same contract gate.
;; : (-> ProfileCandidateSyntax ProfileCandidate)
(defrules agent-sandbox-profile-candidate ()
  ((_ backend-kind source choices (field value) ...)
   (make-agent-sandbox-profile-candidate
    backend-kind
    source
    choices
    (list (cons 'field value) ...))))

;; : (-> ProfileCandidateChoiceSyntax ProfileCandidateChoice)
(defrules agent-sandbox-profile-candidate-choice ()
  ((_ action (field value) ...)
   (make-agent-sandbox-profile-candidate-choice
    'action
    (list (cons 'field value) ...))))

;; : (-> ProfileCandidateChoiceAction Alist ProfileCandidateChoice)
(def (make-agent-sandbox-profile-candidate-choice action fields)
  (let (choice (cons (cons 'action action)
                     (if fields fields '())))
    (if (agent-sandbox-profile-candidate-choice? choice)
      choice
      (raise-control-plane-failure
       'agent-sandbox
       'invalid-agent-sandbox-profile-candidate-choice
       "invalid agent sandbox profile candidate choice"
       (list (cons 'choice choice))))))

;; : (-> ProfileCandidate ProfileCandidate)
(def (agent-sandbox-profile-candidate-validator candidate)
  (agent-sandbox-validate-profile-candidate candidate))

;; : (-> ProfileCandidate ProfileCandidatePatch)
(def (agent-sandbox-profile-candidate-default-patch-projector candidate)
  (let* ((valid-candidate (agent-sandbox-validate-profile-candidate candidate))
         (choices (agent-sandbox-profile-candidate-choices valid-candidate)))
    (list (cons 'schema +agent-sandbox-profile-candidate-patch-schema+)
          (cons 'backend-kind
                (agent-sandbox-profile-candidate-backend-kind valid-candidate))
          (cons 'source
                (agent-sandbox-profile-candidate-source valid-candidate))
          (cons 'profile-ref
                (agent-sandbox-profile-candidate-profile-ref valid-candidate))
          (cons 'command
                (agent-sandbox-profile-candidate-command valid-candidate))
          (cons 'observations
                (agent-sandbox-profile-candidate-observations valid-candidate))
          (cons 'grants
                (agent-sandbox-profile-candidate-choices-with-action
                 choices 'grant))
          (cons 'suppressions
                (agent-sandbox-profile-candidate-choices-with-action
                 choices 'suppress))
          (cons 'skipped
                (agent-sandbox-profile-candidate-choices-with-action
                 choices 'skip))
          (cons 'validation-errors '())
          (cons 'metadata
                (agent-sandbox-profile-candidate-metadata valid-candidate)))))

;; : (-> ProfileCandidate Alist ProfilePromotionRequest)
(def (agent-sandbox-profile-candidate-default-promotion-projector candidate
                                                                  options)
  (agent-sandbox-profile-candidate->nono-promote-request candidate options))

;;; Profile candidate descriptors are POO extension points. Backend modules may
;;; override validator/projector slots without changing the public data contract.
;; : (-> Unit AgentSandboxProfileCandidateDescriptorPrototype)
(def agent-sandbox-profile-candidate-descriptor-prototype
  (.mix slots: (role-constant-slots
                (list (cons 'name 'agent-sandbox-profile-candidate)
                      (cons 'backend-kind #f)
                      (cons 'source #f)
                      (cons 'metadata '())
                      (cons 'validator
                            agent-sandbox-profile-candidate-validator)
                      (cons 'patch-projector
                            agent-sandbox-profile-candidate-default-patch-projector)
                      (cons 'promotion-projector
                            agent-sandbox-profile-candidate-default-promotion-projector)))
        execution-policy-role))

;; : (-> Symbol Symbol Symbol [Alist] AgentSandboxProfileCandidateDescriptor)
(def (make-agent-sandbox-profile-candidate-descriptor name
                                                      backend-kind
                                                      source
                                                      . maybe-overrides)
  (.mix slots: (role-constant-slots
                (append
                 (list (cons 'name name)
                       (cons 'backend-kind backend-kind)
                       (cons 'source source)
                       (cons 'metadata '()))
                 (if (null? maybe-overrides) '() (car maybe-overrides))))
        agent-sandbox-profile-candidate-descriptor-prototype))

;; : (-> Value Boolean)
(def (agent-sandbox-profile-candidate-descriptor? descriptor)
  (object? descriptor))

;; : (-> AgentSandboxProfileCandidateDescriptor Symbol)
(def (agent-sandbox-profile-candidate-descriptor-name descriptor)
  (.@ descriptor name))

;; : (-> AgentSandboxProfileCandidateDescriptor Symbol)
(def (agent-sandbox-profile-candidate-descriptor-backend-kind descriptor)
  (.@ descriptor backend-kind))

;; : (-> AgentSandboxProfileCandidateDescriptor Symbol)
(def (agent-sandbox-profile-candidate-descriptor-source descriptor)
  (.@ descriptor source))

;; : (-> AgentSandboxProfileCandidateDescriptor Alist)
(def (agent-sandbox-profile-candidate-descriptor-metadata descriptor)
  (.@ descriptor metadata))

;; : (-> AgentSandboxProfileCandidateDescriptor Procedure)
(def (agent-sandbox-profile-candidate-descriptor-validator descriptor)
  (.@ descriptor validator))

;; : (-> AgentSandboxProfileCandidateDescriptor Procedure)
(def (agent-sandbox-profile-candidate-descriptor-patch-projector descriptor)
  (.@ descriptor patch-projector))

;; : (-> AgentSandboxProfileCandidateDescriptor Procedure)
(def (agent-sandbox-profile-candidate-descriptor-promotion-projector descriptor)
  (.@ descriptor promotion-projector))

;; : (-> Alist Alist Alist)
(def (agent-sandbox-profile-candidate-descriptor-options options metadata)
  (agent-sandbox-merge-alists
   (list (cons 'metadata
               (agent-sandbox-merge-alists
                (agent-sandbox-option options 'metadata '())
                metadata)))
   options))

;; : (-> AgentSandboxProfileCandidateDescriptor [ProfileCandidateChoice] [Alist] ProfileCandidate)
(def (agent-sandbox-profile-candidate-descriptor->candidate descriptor
                                                            choices
                                                            . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (candidate
          (make-agent-sandbox-profile-candidate
           (agent-sandbox-profile-candidate-descriptor-backend-kind descriptor)
           (agent-sandbox-profile-candidate-descriptor-source descriptor)
           choices
           (agent-sandbox-profile-candidate-descriptor-options
            options
            (agent-sandbox-profile-candidate-descriptor-metadata
             descriptor)))))
    ((agent-sandbox-profile-candidate-descriptor-validator descriptor)
     candidate)))

;; : (-> Symbol Symbol [ProfileCandidateChoice] [Alist] ProfileCandidate)
(def (make-agent-sandbox-profile-candidate backend-kind
                                           source
                                           choices
                                           . maybe-options)
  (let ((options (if (null? maybe-options) '() (car maybe-options))))
    (agent-sandbox-validate-profile-candidate
     (list (cons 'schema +agent-sandbox-profile-candidate-schema+)
           (cons 'backend-kind backend-kind)
           (cons 'source source)
           (cons 'profile-ref
                 (agent-sandbox-option options 'profile-ref #f))
           (cons 'command
                 (agent-sandbox-option options 'command #f))
           (cons 'observations
                 (agent-sandbox-option options 'observations '()))
           (cons 'choices choices)
           (cons 'metadata
                 (agent-sandbox-option options 'metadata '()))))))

;; : (-> Value Boolean)
(def (agent-sandbox-profile-candidate? value)
  (and (list? value)
       (agent-sandbox-profile-candidate-schema?
        (agent-sandbox-alist-ref value 'schema #f))))

;; : (-> Value Boolean)
(def (agent-sandbox-profile-candidate-patch? value)
  (and (list? value)
       (agent-sandbox-profile-candidate-patch-schema?
        (agent-sandbox-alist-ref value 'schema #f))))

;; : (-> Value Boolean)
(def (agent-sandbox-profile-promotion-request? value)
  (and (list? value)
       (agent-sandbox-profile-promotion-request-schema?
        (agent-sandbox-alist-ref value 'schema #f))))

(defagent-sandbox-profile-candidate-contract
  +agent-sandbox-profile-promotion-request-required-fields+
  (backend-kind agent-sandbox-profile-candidate-present?)
  (mode agent-sandbox-profile-candidate-present?)
  (patch agent-sandbox-profile-candidate-patch?))

;; : (-> ProfileCandidateChoice Value Boolean)
(def (agent-sandbox-profile-candidate-choice-action-is? choice action)
  (eq? (agent-sandbox-alist-ref choice 'action #f) action))

;; : (-> [ProfileCandidateChoice] Symbol [ProfileCandidateChoice])
(def (agent-sandbox-profile-candidate-choices-with-action choices action)
  (cond
   ((null? choices) '())
   ((not (pair? choices)) '())
   ((agent-sandbox-profile-candidate-choice-action-is? (car choices) action)
    (cons (car choices)
          (agent-sandbox-profile-candidate-choices-with-action
           (cdr choices) action)))
   (else
    (agent-sandbox-profile-candidate-choices-with-action
     (cdr choices) action))))

;; : (-> [ProfileCandidateChoice] Fixnum [ValidationError])
(def (agent-sandbox-profile-candidate-choice-errors choices index)
  (cond
   ((null? choices) '())
   ((not (pair? choices))
    (list (list (cons 'field 'choices)
                (cons 'code 'improper-choice-list)
                (cons 'index index)
                (cons 'value choices))))
   ((agent-sandbox-profile-candidate-choice? (car choices))
    (agent-sandbox-profile-candidate-choice-errors
     (cdr choices) (+ index 1)))
   (else
    (cons (list (cons 'field 'choices)
                (cons 'code 'invalid-choice)
                (cons 'index index)
                (cons 'choice (car choices)))
          (agent-sandbox-profile-candidate-choice-errors
           (cdr choices) (+ index 1))))))

;; : (-> ProfileCandidate [ValidationError])
(def (agent-sandbox-profile-candidate-validation-errors candidate)
  (append
   (if (agent-sandbox-profile-candidate-schema?
        (agent-sandbox-alist-ref candidate 'schema #f))
     '()
     (list '((field . schema) (code . schema-mismatch))))
   (agent-sandbox-required-field-errors
    candidate
    +agent-sandbox-profile-candidate-required-fields+)
   (agent-sandbox-profile-candidate-choice-errors
    (agent-sandbox-alist-ref candidate 'choices '())
    0)))

;; : (-> ProfileCandidate ProfileCandidate)
(def (agent-sandbox-validate-profile-candidate candidate)
  (let (errors (agent-sandbox-profile-candidate-validation-errors candidate))
    (if (null? errors)
      candidate
      (raise-control-plane-failure
       'agent-sandbox
       'invalid-agent-sandbox-profile-candidate
       "invalid agent sandbox profile candidate"
       (list (cons 'errors errors)
             (cons 'candidate candidate))))))

;; : (-> ProfilePromotionRequest [ValidationError])
(def (agent-sandbox-profile-promotion-request-validation-errors request)
  (append
   (if (agent-sandbox-profile-promotion-request-schema?
        (agent-sandbox-alist-ref request 'schema #f))
     '()
     (list '((field . schema) (code . schema-mismatch))))
   (agent-sandbox-required-field-errors
    request
    +agent-sandbox-profile-promotion-request-required-fields+)))

;; : (-> ProfilePromotionRequest ProfilePromotionRequest)
(def (agent-sandbox-validate-profile-promotion-request request)
  (let (errors (agent-sandbox-profile-promotion-request-validation-errors request))
    (if (null? errors)
      request
      (raise-control-plane-failure
       'agent-sandbox
       'invalid-agent-sandbox-profile-promotion-request
       "invalid agent sandbox profile promotion request"
       (list (cons 'errors errors)
             (cons 'request request))))))

;; : (-> ProfileCandidate Symbol Value Value)
(def (agent-sandbox-profile-candidate-ref candidate key default)
  (agent-sandbox-alist-ref candidate key default))

;; : (-> ProfileCandidate Symbol)
(def (agent-sandbox-profile-candidate-backend-kind candidate)
  (agent-sandbox-profile-candidate-ref candidate 'backend-kind #f))

;; : (-> ProfileCandidate Symbol)
(def (agent-sandbox-profile-candidate-source candidate)
  (agent-sandbox-profile-candidate-ref candidate 'source #f))

;; : (-> ProfileCandidate Value)
(def (agent-sandbox-profile-candidate-profile-ref candidate)
  (agent-sandbox-profile-candidate-ref candidate 'profile-ref #f))

;; : (-> ProfileCandidate Value)
(def (agent-sandbox-profile-candidate-command candidate)
  (agent-sandbox-profile-candidate-ref candidate 'command #f))

;; : (-> ProfileCandidate [Observation])
(def (agent-sandbox-profile-candidate-observations candidate)
  (agent-sandbox-profile-candidate-ref candidate 'observations '()))

;; : (-> ProfileCandidate [ProfileCandidateChoice])
(def (agent-sandbox-profile-candidate-choices candidate)
  (agent-sandbox-profile-candidate-ref candidate 'choices '()))

;; : (-> ProfileCandidate Alist)
(def (agent-sandbox-profile-candidate-metadata candidate)
  (agent-sandbox-profile-candidate-ref candidate 'metadata '()))

;; : (-> ProfileCandidate [AgentSandboxProfileCandidateDescriptor] ProfileCandidatePatch)
(def (agent-sandbox-profile-candidate->patch candidate . maybe-descriptor)
  (if (null? maybe-descriptor)
    (agent-sandbox-profile-candidate-default-patch-projector candidate)
    ((agent-sandbox-profile-candidate-descriptor-patch-projector
      (car maybe-descriptor))
     candidate)))

;; : (-> Value Value)
(def (agent-sandbox-profile-candidate-command-arg value)
  (cond
   ((not value) #f)
   ((string? value) value)
   ((symbol? value) (symbol->string value))
   (else value)))

;; : (-> Symbol Value [String])
(def (agent-sandbox-profile-candidate-nono-promote-argv mode draft-ref)
  (let ((draft-args
         (if draft-ref
           (list (agent-sandbox-profile-candidate-command-arg draft-ref))
           '())))
    (cond
     ((eq? mode 'diff)
      (append '("nono" "profile" "promote" "--diff") draft-args))
     ((eq? mode 'apply)
      (append '("nono" "profile" "promote" "--yes") draft-args))
     (else
      (append '("nono" "profile" "promote") draft-args)))))

;; : (-> ProfileCandidate [Alist] ProfilePromotionRequest)
(def (agent-sandbox-profile-candidate->nono-promote-request candidate
                                                            . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (valid-candidate (agent-sandbox-validate-profile-candidate candidate))
         (backend-kind
          (agent-sandbox-profile-candidate-backend-kind valid-candidate))
         (mode (agent-sandbox-option options 'mode 'diff))
         (profile-ref
          (agent-sandbox-option
           options
           'profile-ref
           (agent-sandbox-profile-candidate-profile-ref valid-candidate)))
         (draft-ref (agent-sandbox-option options 'draft-ref profile-ref))
         (patch (agent-sandbox-profile-candidate->patch valid-candidate))
         (request
          (list (cons 'schema
                      +agent-sandbox-profile-promotion-request-schema+)
                (cons 'backend-kind backend-kind)
                (cons 'mode mode)
                (cons 'profile-ref profile-ref)
                (cons 'draft-ref draft-ref)
                (cons 'argv
                      (agent-sandbox-profile-candidate-nono-promote-argv
                       mode draft-ref))
                (cons 'patch patch)
                (cons 'runtime-executed #f)
                (cons 'metadata
                      (agent-sandbox-option options 'metadata '())))))
    (if (eq? backend-kind 'nono)
      (agent-sandbox-validate-profile-promotion-request request)
      (raise-control-plane-failure
       'agent-sandbox
       'invalid-agent-sandbox-profile-promotion-request
       "nono promotion request requires a nono profile candidate"
       (list (cons 'backend-kind backend-kind)
             (cons 'candidate valid-candidate))))))

;; : (-> Boolean Symbol ProfilePromotionRequest [Alist] ProfilePromotionReceipt)
(def (agent-sandbox-profile-promotion-receipt ok?
                                              status
                                              request
                                              . maybe-options)
  (let ((options (if (null? maybe-options) '() (car maybe-options)))
        (valid-request
         (agent-sandbox-validate-profile-promotion-request request)))
    (list (cons 'schema +agent-sandbox-profile-promotion-receipt-schema+)
          (cons 'ok? ok?)
          (cons 'status status)
          (cons 'backend-kind
                (agent-sandbox-alist-ref valid-request 'backend-kind #f))
          (cons 'mode
                (agent-sandbox-alist-ref valid-request 'mode #f))
          (cons 'profile-ref
                (agent-sandbox-alist-ref valid-request 'profile-ref #f))
          (cons 'draft-ref
                (agent-sandbox-alist-ref valid-request 'draft-ref #f))
          (cons 'applied?
                (agent-sandbox-option options 'applied? #f))
          (cons 'runtime-executed
                (agent-sandbox-option options 'runtime-executed #f))
          (cons 'request valid-request)
          (cons 'output
                (agent-sandbox-option options 'output #f))
          (cons 'metadata
                (agent-sandbox-option options 'metadata '())))))
