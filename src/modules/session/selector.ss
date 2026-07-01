;;; -*- Gerbil -*-
;;; Boundary: report-only session selector receipts.
;;; Invariant: selector receipts describe routing intent only; Scheme never
;;; scores candidates, calls a model, dispatches workflows, or mutates sessions.

(import (only-in :clan/poo/object .ref object? object<-alist)
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/receipt-syntax)

(export poo-flow-session-selector-candidate
        poo-flow-session-selector-candidate?
        poo-flow-session-selector-candidate-id
        poo-flow-session-selector-candidate-kind
        poo-flow-session-selector-candidate-target-ref
        poo-flow-session-selector-candidate->alist
        poo-flow-session-selector-candidates->alists
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

;; : (-> POOObject Symbol Value Value)
(def (poo-flow-session-selector-slot object key default)
  (with-catch
   (lambda (_failure) default)
   (lambda ()
     (.ref object key))))

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
  (object<-alist
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
                      (car maybe-metadata))))))

;; : (-> POOObject Boolean)
(def (poo-flow-session-selector-candidate? value)
  (and (object? value)
       (eq? (poo-flow-session-selector-slot value 'kind #f)
            'poo-flow.session.selector-candidate)))

;; : (-> PooSessionSelectorCandidate Symbol)
(def (poo-flow-session-selector-candidate-id candidate)
  (.ref candidate 'candidate-id))

;; : (-> PooSessionSelectorCandidate Symbol)
(def (poo-flow-session-selector-candidate-kind candidate)
  (.ref candidate 'candidate-kind))

;; : (-> PooSessionSelectorCandidate Symbol)
(def (poo-flow-session-selector-candidate-target-ref candidate)
  (.ref candidate 'target-ref))

;; : (-> PooSessionSelectorCandidate Alist)
(defpoo-session-receipt-projection
  poo-flow-session-selector-candidate->alist
  (candidate)
  (require poo-flow-session-require
           "session selector candidate projection requires a candidate"
           (poo-flow-session-selector-candidate? candidate)
           candidate)
  (bindings ())
  (fields
   (('kind (.ref candidate 'kind))
    ('schema (.ref candidate 'schema))
    ('candidate-id (.ref candidate 'candidate-id))
    ('candidate-kind (.ref candidate 'candidate-kind))
    ('target-ref (.ref candidate 'target-ref))
    ('description (.ref candidate 'description))
    ('required-receipt-fields (.ref candidate 'required-receipt-fields))
    ('runtime-owner (.ref candidate 'runtime-owner))
    ('runtime-executed (.ref candidate 'runtime-executed))
    ('metadata (.ref candidate 'metadata)))))

;; : (-> [PooSessionSelectorCandidate] [Alist])
(defpoo-session-receipt-projection-batch
  poo-flow-session-selector-candidates->alists
  (candidates)
  (projector poo-flow-session-selector-candidate->alist)
  (error-message "session selector candidate projection requires a list"))

;; : (-> [PooSessionSelectorCandidate] Alist)
(def (poo-flow-session-selector-candidate-summary candidates)
  (let loop ((remaining-candidates candidates)
             (candidate-count 0)
             (candidate-ids-rev '())
             (workflow-candidate-ids-rev '())
             (transform-candidate-ids-rev '())
             (agent-param-candidate-ids-rev '()))
    (cond
     ((null? remaining-candidates)
      (list
       (cons 'candidate-count candidate-count)
       (cons 'candidate-ids (reverse candidate-ids-rev))
       (cons 'workflow-candidate-ids
             (reverse workflow-candidate-ids-rev))
       (cons 'transform-candidate-ids
             (reverse transform-candidate-ids-rev))
       (cons 'agent-param-candidate-ids
             (reverse agent-param-candidate-ids-rev))))
     (else
      (let* ((candidate (car remaining-candidates))
             (candidate-id
              (poo-flow-session-selector-candidate-id candidate))
             (candidate-kind
              (poo-flow-session-selector-candidate-kind candidate))
             (next-candidates (cdr remaining-candidates))
             (next-count (+ candidate-count 1))
             (next-candidate-ids
              (cons candidate-id candidate-ids-rev)))
        (cond
         ((eq? candidate-kind 'workflow)
          (loop next-candidates
                next-count
                next-candidate-ids
                (cons candidate-id workflow-candidate-ids-rev)
                transform-candidate-ids-rev
                agent-param-candidate-ids-rev))
         ((eq? candidate-kind 'transform)
          (loop next-candidates
                next-count
                next-candidate-ids
                workflow-candidate-ids-rev
                (cons candidate-id transform-candidate-ids-rev)
                agent-param-candidate-ids-rev))
         (else
          (loop next-candidates
                next-count
                next-candidate-ids
                workflow-candidate-ids-rev
                transform-candidate-ids-rev
                (cons candidate-id
                      agent-param-candidate-ids-rev)))))))))

;; : PooSessionSelectorReceiptRecord
(defstruct poo-flow-session-selector-receipt-record
  (selector-id
   project-id
   root-session-ref
   input-session-ref
   candidate-count
   candidate-ids
   workflow-candidate-ids
   transform-candidate-ids
   agent-param-candidate-ids
   candidates
   selection-policy
   fallback-ref
   selection-state
   selected-candidate-ref
   pending-selected-result
   handoff-required
   runtime-owner
   runtime-executed
   metadata)
  transparent: #t)

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
  (let* ((candidate-summary
          (poo-flow-session-selector-candidate-summary candidates))
         (candidate-count
          (poo-flow-session-alist-ref
           candidate-summary
           'candidate-count
           0))
         (candidate-ids
          (poo-flow-session-alist-ref
           candidate-summary
           'candidate-ids
           '()))
         (workflow-candidate-ids
          (poo-flow-session-alist-ref
           candidate-summary
           'workflow-candidate-ids
           '()))
         (transform-candidate-ids
          (poo-flow-session-alist-ref
           candidate-summary
           'transform-candidate-ids
           '()))
         (agent-param-candidate-ids
          (poo-flow-session-alist-ref
           candidate-summary
           'agent-param-candidate-ids
           '())))
    (make-poo-flow-session-selector-receipt-record
     selector-id
     project-id
     root-session-ref
     input-session-ref
     candidate-count
     candidate-ids
     workflow-candidate-ids
     transform-candidate-ids
     agent-param-candidate-ids
     candidates
     selection-policy
     fallback-ref
     'pending
     #f
     (list (cons 'state 'pending)
           (cons 'runtime-owner "marlin-agent-core")
           (cons 'runtime-executed #f))
     #t
     "marlin-agent-core"
     #f
     (if (null? maybe-metadata)
       '()
       (car maybe-metadata)))))

;; : (-> Any Boolean)
(def (poo-flow-session-selector-receipt? value)
  (poo-flow-session-selector-receipt-record? value))

;; : (-> PooSessionSelectorReceipt Symbol)
(def (poo-flow-session-selector-receipt-selector-id receipt)
  (poo-flow-session-selector-receipt-record-selector-id receipt))

;; : (-> PooSessionSelectorReceipt [Symbol])
(def (poo-flow-session-selector-receipt-candidate-ids receipt)
  (poo-flow-session-selector-receipt-record-candidate-ids receipt))

;; : (-> PooSessionSelectorReceipt Symbol)
(def (poo-flow-session-selector-receipt-selection-state receipt)
  (poo-flow-session-selector-receipt-record-selection-state receipt))

;; : (-> PooSessionSelectorReceipt MaybeSymbol)
(def (poo-flow-session-selector-receipt-selected-candidate-ref receipt)
  (poo-flow-session-selector-receipt-record-selected-candidate-ref receipt))

;; : (-> PooSessionSelectorReceipt Alist)
(defpoo-session-receipt-projection
  poo-flow-session-selector-receipt->alist
  (receipt)
  (require poo-flow-session-require
           "session selector projection requires a receipt"
           (poo-flow-session-selector-receipt? receipt)
           receipt)
  (bindings ())
  (fields
   (('kind 'poo-flow.session.selector-receipt)
    ('schema 'poo-flow.modules.session.selector-receipt.v1)
    ('selector-id
     (poo-flow-session-selector-receipt-record-selector-id receipt))
    ('project-id
     (poo-flow-session-selector-receipt-record-project-id receipt))
    ('root-session-ref
     (poo-flow-session-selector-receipt-record-root-session-ref
      receipt))
    ('input-session-ref
     (poo-flow-session-selector-receipt-record-input-session-ref
      receipt))
    ('candidate-count
     (poo-flow-session-selector-receipt-record-candidate-count receipt))
    ('candidate-ids
     (poo-flow-session-selector-receipt-candidate-ids receipt))
    ('workflow-candidate-ids
     (poo-flow-session-selector-receipt-record-workflow-candidate-ids
      receipt))
    ('transform-candidate-ids
     (poo-flow-session-selector-receipt-record-transform-candidate-ids
      receipt))
    ('agent-param-candidate-ids
     (poo-flow-session-selector-receipt-record-agent-param-candidate-ids
      receipt))
    ('candidates
     (poo-flow-session-selector-candidates->alists
      (poo-flow-session-selector-receipt-record-candidates receipt)))
    ('selection-policy
     (poo-flow-session-selector-receipt-record-selection-policy receipt))
    ('fallback-ref
     (poo-flow-session-selector-receipt-record-fallback-ref receipt))
    ('selection-state
     (poo-flow-session-selector-receipt-selection-state receipt))
    ('selected-candidate-ref
     (poo-flow-session-selector-receipt-selected-candidate-ref receipt))
    ('pending-selected-result
     (poo-flow-session-selector-receipt-record-pending-selected-result
      receipt))
    ('handoff-required
     (poo-flow-session-selector-receipt-record-handoff-required receipt))
    ('runtime-owner
     (poo-flow-session-selector-receipt-record-runtime-owner receipt))
    ('runtime-executed
     (poo-flow-session-selector-receipt-record-runtime-executed receipt))
    ('metadata
     (poo-flow-session-selector-receipt-record-metadata receipt)))))
