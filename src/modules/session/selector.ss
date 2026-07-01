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
        poo-flow-session-selector-receipt-valid?
        poo-flow-session-selector-receipt-diagnostic-count
        poo-flow-session-selector-receipt-diagnostics
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

;; : (-> Alist Symbol Value Value)
(def (poo-flow-session-selector-policy-ref policy key default)
  (poo-flow-session-alist-ref policy key default))

;; : (-> List List List)
(def (poo-flow-session-selector-rows/tail rows tail)
  (let loop ((remaining-rows rows)
             (rows-rev '()))
    (if (null? remaining-rows)
      (let restore ((remaining-rev rows-rev)
                    (result tail))
        (if (null? remaining-rev)
          result
          (restore (cdr remaining-rev)
                   (cons (car remaining-rev) result))))
      (loop (cdr remaining-rows)
            (cons (car remaining-rows) rows-rev)))))

(defrules poo-flow-session-selector-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

;; : (-> Symbol Symbol Alist)
(def (poo-flow-session-selector-diagnostic code selector-id detail)
  (poo-flow-session-selector-field-rows
   (kind 'poo-flow.session.selector.diagnostic)
   (schema 'poo-flow.modules.session.selector.diagnostic.v1)
   (code code)
   (selector-id selector-id)
   (detail detail)
   (severity 'error)
   (runtime-executed #f)))

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

;; : (-> Symbol Symbol)
(def (poo-flow-session-selector-target-policy-key candidate-kind)
  (cond
   ((eq? candidate-kind 'workflow) 'workflow-target-refs)
   ((eq? candidate-kind 'transform) 'transform-target-refs)
   (else 'agent-param-target-refs)))

;; : (-> Alist PooSessionSelectorCandidate MaybeSymbolList)
(def (poo-flow-session-selector-candidate-known-targets selection-policy
                                                        candidate)
  (poo-flow-session-selector-policy-ref
   selection-policy
   (poo-flow-session-selector-target-policy-key
    (poo-flow-session-selector-candidate-kind candidate))
   #f))

;; : (-> Alist PooSessionSelectorCandidate Boolean)
(def (poo-flow-session-selector-candidate-resolved? selection-policy
                                                    candidate)
  (let (known-targets
        (poo-flow-session-selector-candidate-known-targets
         selection-policy
         candidate))
    (or (not known-targets)
        (if (member (poo-flow-session-selector-candidate-target-ref
                     candidate)
                    known-targets)
          #t
          #f))))

;; : (-> Symbol PooSessionSelectorCandidate Alist)
(def (poo-flow-session-selector-candidate-diagnostic selector-id candidate)
  (poo-flow-session-selector-diagnostic
   'selector-candidate-target-not-declared
   selector-id
   (poo-flow-session-selector-field-rows
    (candidate-id
     (poo-flow-session-selector-candidate-id candidate))
    (candidate-kind
     (poo-flow-session-selector-candidate-kind candidate))
    (target-ref
     (poo-flow-session-selector-candidate-target-ref candidate)))))

;; : (-> Symbol [PooSessionSelectorCandidate] Alist [Symbol] [Symbol] [Alist] Alist)
(def (poo-flow-session-selector-resolution/rev selector-id
                                                candidates
                                                selection-policy
                                                resolved-ids-rev
                                                unresolved-ids-rev
                                                diagnostics-rev)
  (cond
   ((null? candidates)
    (list (cons 'resolved-candidate-ids (reverse resolved-ids-rev))
          (cons 'unresolved-candidate-ids (reverse unresolved-ids-rev))
          (cons 'diagnostics (reverse diagnostics-rev))))
   ((poo-flow-session-selector-candidate-resolved?
     selection-policy
     (car candidates))
    (poo-flow-session-selector-resolution/rev
     selector-id
     (cdr candidates)
     selection-policy
     (cons (poo-flow-session-selector-candidate-id (car candidates))
           resolved-ids-rev)
     unresolved-ids-rev
     diagnostics-rev))
   (else
    (poo-flow-session-selector-resolution/rev
     selector-id
     (cdr candidates)
     selection-policy
     resolved-ids-rev
     (cons (poo-flow-session-selector-candidate-id (car candidates))
           unresolved-ids-rev)
     (cons (poo-flow-session-selector-candidate-diagnostic
            selector-id
            (car candidates))
           diagnostics-rev)))))

;; : (-> Symbol [PooSessionSelectorCandidate] Alist Alist)
(def (poo-flow-session-selector-resolution selector-id
                                           candidates
                                           selection-policy)
  (poo-flow-session-selector-resolution/rev selector-id
                                            candidates
                                            selection-policy
                                            '()
                                            '()
                                            '()))

;; : (-> Symbol [Symbol] Alist Boolean)
(def (poo-flow-session-selector-fallback-resolved? fallback-ref
                                                   candidate-ids
                                                   selection-policy)
  (or (if (member fallback-ref candidate-ids) #t #f)
      (let (external-fallback-refs
            (poo-flow-session-selector-policy-ref
             selection-policy
             'external-fallback-refs
             #f))
        (or (not external-fallback-refs)
            (if (member fallback-ref external-fallback-refs) #t #f)))))

;; : (-> Symbol Symbol Alist)
(def (poo-flow-session-selector-fallback-diagnostic selector-id
                                                    fallback-ref)
  (poo-flow-session-selector-diagnostic
   'selector-fallback-not-declared
   selector-id
   (poo-flow-session-selector-field-rows
    (fallback-ref fallback-ref))))

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
   fallback-resolved?
   resolved-candidate-ids
   unresolved-candidate-ids
   selection-state
   selected-candidate-ref
   pending-selected-result
   valid?
   diagnostic-count
   diagnostics
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
           '()))
         (resolution
          (poo-flow-session-selector-resolution selector-id
                                                candidates
                                                selection-policy))
         (resolved-candidate-ids
          (poo-flow-session-alist-ref
           resolution
           'resolved-candidate-ids
           '()))
         (unresolved-candidate-ids
          (poo-flow-session-alist-ref
           resolution
           'unresolved-candidate-ids
           '()))
         (fallback-resolved?
          (poo-flow-session-selector-fallback-resolved?
           fallback-ref
           candidate-ids
           selection-policy))
         (diagnostics0
          (poo-flow-session-alist-ref resolution 'diagnostics '()))
         (diagnostics
          (if fallback-resolved?
            diagnostics0
            (poo-flow-session-selector-rows/tail
             diagnostics0
             (list
              (poo-flow-session-selector-fallback-diagnostic
               selector-id
               fallback-ref))))))
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
     fallback-resolved?
     resolved-candidate-ids
     unresolved-candidate-ids
     'pending
     #f
     (poo-flow-session-selector-field-rows
      (state 'pending)
      (runtime-owner "marlin-agent-core")
      (runtime-executed #f))
     (null? diagnostics)
     (length diagnostics)
     diagnostics
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

;; : (-> PooSessionSelectorReceipt Boolean)
(def (poo-flow-session-selector-receipt-valid? receipt)
  (poo-flow-session-selector-receipt-record-valid? receipt))

;; : (-> PooSessionSelectorReceipt Integer)
(def (poo-flow-session-selector-receipt-diagnostic-count receipt)
  (poo-flow-session-selector-receipt-record-diagnostic-count receipt))

;; : (-> PooSessionSelectorReceipt [Alist])
(def (poo-flow-session-selector-receipt-diagnostics receipt)
  (poo-flow-session-selector-receipt-record-diagnostics receipt))

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
    ('fallback-resolved?
     (poo-flow-session-selector-receipt-record-fallback-resolved? receipt))
    ('resolved-candidate-ids
     (poo-flow-session-selector-receipt-record-resolved-candidate-ids
      receipt))
    ('unresolved-candidate-ids
     (poo-flow-session-selector-receipt-record-unresolved-candidate-ids
      receipt))
    ('selection-state
     (poo-flow-session-selector-receipt-selection-state receipt))
    ('selected-candidate-ref
     (poo-flow-session-selector-receipt-selected-candidate-ref receipt))
    ('pending-selected-result
     (poo-flow-session-selector-receipt-record-pending-selected-result
      receipt))
    ('valid?
     (poo-flow-session-selector-receipt-valid? receipt))
    ('diagnostic-count
     (poo-flow-session-selector-receipt-diagnostic-count receipt))
    ('diagnostics
     (poo-flow-session-selector-receipt-diagnostics receipt))
    ('handoff-required
     (poo-flow-session-selector-receipt-record-handoff-required receipt))
    ('runtime-owner
     (poo-flow-session-selector-receipt-record-runtime-owner receipt))
    ('runtime-executed
     (poo-flow-session-selector-receipt-record-runtime-executed receipt))
    ('metadata
     (poo-flow-session-selector-receipt-record-metadata receipt)))))
