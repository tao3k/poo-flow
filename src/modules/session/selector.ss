;;; -*- Gerbil -*-
;;; Boundary: report-only session selector receipts.
;;; Invariant: selector receipts describe routing intent only; Scheme never
;;; scores candidates, calls a model, dispatches workflows, or mutates sessions.

(import (only-in :clan/poo/object .ref object? object<-alist)
        :poo-flow/src/modules/session/objects)

(export poo-flow-session-selector-candidate
        poo-flow-session-selector-candidate?
        poo-flow-session-selector-candidate-id
        poo-flow-session-selector-candidate-kind
        poo-flow-session-selector-candidate-target-ref
        poo-flow-session-selector-receipt
        poo-flow-session-selector-receipt?
        poo-flow-session-selector-receipt-selector-id
        poo-flow-session-selector-receipt-candidate-ids
        poo-flow-session-selector-receipt-selection-state
        poo-flow-session-selector-receipt-selected-candidate-ref
        poo-flow-session-selector-receipt->alist)

;; : [Symbol]
(def +poo-flow-session-selector-candidate-kinds+
  '(workflow transform agent-param))

;; : (-> Symbol Boolean)
(def (poo-flow-session-selector-candidate-kind? value)
  (and (symbol? value)
       (if (member value +poo-flow-session-selector-candidate-kinds+)
         #t
         #f)))

;; : (-> Symbol Symbol Symbol String [Symbol] [Alist] PooSessionSelectorCandidate)
(def (poo-flow-session-selector-candidate candidate-id
                                          candidate-kind
                                          target-ref
                                          description
                                          required-receipt-fields
                                          . maybe-metadata)
  (poo-flow-session-require "session selector candidate id must be a symbol"
                            (symbol? candidate-id)
                            candidate-id)
  (poo-flow-session-require
   "session selector candidate kind must be workflow, transform, or agent-param"
   (poo-flow-session-selector-candidate-kind? candidate-kind)
   candidate-kind)
  (poo-flow-session-require "session selector target ref must be a symbol"
                            (symbol? target-ref)
                            target-ref)
  (poo-flow-session-require "session selector candidate description must be a string"
                            (string? description)
                            description)
  (poo-flow-session-require
   "session selector required receipt fields must be symbols"
   (poo-flow-session-every? symbol? required-receipt-fields)
   required-receipt-fields)
  (list
   (cons 'kind 'poo-flow.session.selector-candidate)
   (cons 'schema 'poo-flow.modules.session.selector-candidate.v1)
   (cons 'candidate-id candidate-id)
   (cons 'candidate-kind candidate-kind)
   (cons 'target-ref target-ref)
   (cons 'description description)
   (cons 'required-receipt-fields required-receipt-fields)
   (cons 'runtime-owner "marlin-agent-core")
   (cons 'runtime-executed #f)
   (cons 'metadata (if (null? maybe-metadata)
                     '()
                     (car maybe-metadata)))))

;; : (-> Any Boolean)
(def (poo-flow-session-selector-candidate? value)
  (and (list? value)
       (eq? (poo-flow-session-alist-ref value 'kind #f)
            'poo-flow.session.selector-candidate)))

;; : (-> PooSessionSelectorCandidate Symbol)
(def (poo-flow-session-selector-candidate-id candidate)
  (poo-flow-session-alist-ref candidate 'candidate-id #f))

;; : (-> PooSessionSelectorCandidate Symbol)
(def (poo-flow-session-selector-candidate-kind candidate)
  (poo-flow-session-alist-ref candidate 'candidate-kind #f))

;; : (-> PooSessionSelectorCandidate Symbol)
(def (poo-flow-session-selector-candidate-target-ref candidate)
  (poo-flow-session-alist-ref candidate 'target-ref #f))

;; : (-> [PooSessionSelectorCandidate] [Symbol])
(def (poo-flow-session-selector-candidate-ids candidates)
  (map poo-flow-session-selector-candidate-id candidates))

;; : (-> Symbol [PooSessionSelectorCandidate] [Symbol])
(def (poo-flow-session-selector-candidates-by-kind candidate-kind candidates)
  (cond
   ((null? candidates) '())
   ((eq? (poo-flow-session-selector-candidate-kind (car candidates))
         candidate-kind)
    (cons (poo-flow-session-selector-candidate-id (car candidates))
          (poo-flow-session-selector-candidates-by-kind
           candidate-kind
           (cdr candidates))))
   (else
    (poo-flow-session-selector-candidates-by-kind
     candidate-kind
     (cdr candidates)))))

;; : (-> Symbol Symbol Symbol Symbol [PooSessionSelectorCandidate] Alist Symbol [Alist] PooSessionSelectorReceipt)
(def (poo-flow-session-selector-receipt selector-id
                                        project-id
                                        root-session-ref
                                        input-session-ref
                                        candidates
                                        selection-policy
                                        fallback-ref
                                        . maybe-metadata)
  (poo-flow-session-require "session selector id must be a symbol"
                            (symbol? selector-id)
                            selector-id)
  (poo-flow-session-require "session selector project id must be a symbol"
                            (symbol? project-id)
                            project-id)
  (poo-flow-session-require "session selector root ref must be a symbol"
                            (symbol? root-session-ref)
                            root-session-ref)
  (poo-flow-session-require "session selector input ref must be a symbol"
                            (symbol? input-session-ref)
                            input-session-ref)
  (poo-flow-session-require "session selector candidates must be candidate rows"
                            (poo-flow-session-every?
                             poo-flow-session-selector-candidate?
                             candidates)
                            candidates)
  (poo-flow-session-require "session selector policy must be an alist"
                            (list? selection-policy)
                            selection-policy)
  (poo-flow-session-require "session selector fallback ref must be a symbol"
                            (symbol? fallback-ref)
                            fallback-ref)
  (object<-alist
   (list
    (cons 'kind 'poo-flow.session.selector-receipt)
    (cons 'schema 'poo-flow.modules.session.selector-receipt.v1)
    (cons 'selector-id selector-id)
    (cons 'project-id project-id)
    (cons 'root-session-ref root-session-ref)
    (cons 'input-session-ref input-session-ref)
    (cons 'candidate-count (length candidates))
    (cons 'candidate-ids
          (poo-flow-session-selector-candidate-ids candidates))
    (cons 'workflow-candidate-ids
          (poo-flow-session-selector-candidates-by-kind
           'workflow
           candidates))
    (cons 'transform-candidate-ids
          (poo-flow-session-selector-candidates-by-kind
           'transform
           candidates))
    (cons 'agent-param-candidate-ids
          (poo-flow-session-selector-candidates-by-kind
           'agent-param
           candidates))
    (cons 'candidates candidates)
    (cons 'selection-policy selection-policy)
    (cons 'fallback-ref fallback-ref)
    (cons 'selection-state 'pending)
    (cons 'selected-candidate-ref #f)
    (cons 'pending-selected-result
          (list (cons 'state 'pending)
                (cons 'runtime-owner "marlin-agent-core")
                (cons 'runtime-executed #f)))
    (cons 'handoff-required #t)
    (cons 'runtime-owner "marlin-agent-core")
    (cons 'runtime-executed #f)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata))))))

;; : (-> POOObject Boolean)
(def (poo-flow-session-selector-receipt? value)
  (and (object? value)
       (eq? (.ref value 'kind)
            'poo-flow.session.selector-receipt)))

;; : (-> PooSessionSelectorReceipt Symbol)
(def (poo-flow-session-selector-receipt-selector-id receipt)
  (.ref receipt 'selector-id))

;; : (-> PooSessionSelectorReceipt [Symbol])
(def (poo-flow-session-selector-receipt-candidate-ids receipt)
  (.ref receipt 'candidate-ids))

;; : (-> PooSessionSelectorReceipt Symbol)
(def (poo-flow-session-selector-receipt-selection-state receipt)
  (.ref receipt 'selection-state))

;; : (-> PooSessionSelectorReceipt MaybeSymbol)
(def (poo-flow-session-selector-receipt-selected-candidate-ref receipt)
  (.ref receipt 'selected-candidate-ref))

;; : (-> PooSessionSelectorReceipt Alist)
(def (poo-flow-session-selector-receipt->alist receipt)
  (poo-flow-session-require "session selector projection requires a receipt"
                            (poo-flow-session-selector-receipt? receipt)
                            receipt)
  (list
   (cons 'kind (.ref receipt 'kind))
   (cons 'schema (.ref receipt 'schema))
   (cons 'selector-id (.ref receipt 'selector-id))
   (cons 'project-id (.ref receipt 'project-id))
   (cons 'root-session-ref (.ref receipt 'root-session-ref))
   (cons 'input-session-ref (.ref receipt 'input-session-ref))
   (cons 'candidate-count (.ref receipt 'candidate-count))
   (cons 'candidate-ids (.ref receipt 'candidate-ids))
   (cons 'workflow-candidate-ids (.ref receipt 'workflow-candidate-ids))
   (cons 'transform-candidate-ids (.ref receipt 'transform-candidate-ids))
   (cons 'agent-param-candidate-ids
         (.ref receipt 'agent-param-candidate-ids))
   (cons 'selection-policy (.ref receipt 'selection-policy))
   (cons 'fallback-ref (.ref receipt 'fallback-ref))
   (cons 'selection-state (.ref receipt 'selection-state))
   (cons 'selected-candidate-ref (.ref receipt 'selected-candidate-ref))
   (cons 'pending-selected-result (.ref receipt 'pending-selected-result))
   (cons 'handoff-required (.ref receipt 'handoff-required))
   (cons 'runtime-owner (.ref receipt 'runtime-owner))
   (cons 'runtime-executed (.ref receipt 'runtime-executed))
   (cons 'metadata (.ref receipt 'metadata))))
