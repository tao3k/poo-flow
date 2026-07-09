;;; -*- Gerbil -*-
;;; Boundary: effective session policy validation receipts.
;;; Invariant: validation inspects composed POO policy objects and bounded
;;; attempt rows; it does not execute tools, hooks, communication, or runtime IO.

(import (only-in :std/srfi/1 fold)
        (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/modules/session/communication
                 poo-flow-session-communication-channel-receipt?
                 poo-flow-session-communication-channel-receipt->alist
                 poo-flow-session-communication-receipt?
                 poo-flow-session-communication-receipt->alist)
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy
        :poo-flow/src/modules/session/policy-syntax
        :poo-flow/src/modules/session/receipt-syntax)

(export poo-flow-session-policy-tool-attempt
        poo-flow-session-policy-tool-attempt?
        poo-flow-session-policy-tool-attempt-id
        poo-flow-session-policy-tool-attempt-trigger-ref
        poo-flow-session-policy-tool-attempt-tool-ref
        poo-flow-session-policy-tool-attempt-action
        poo-flow-session-policy-validation-receipt
        poo-flow-session-policy-validation-receipt?
        poo-flow-session-policy-validation-receipt-validation-id
        poo-flow-session-policy-validation-receipt-effective-model-ref
        poo-flow-session-policy-validation-receipt-effective-prompt-session-ref
        poo-flow-session-policy-validation-receipt-effective-prompt-chunk-refs
        poo-flow-session-policy-validation-receipt-effective-isolation-mode
        poo-flow-session-policy-validation-receipt-effective-sandbox-profile-ref
        poo-flow-session-policy-validation-receipt-tool-catalog-ref
        poo-flow-session-policy-validation-receipt-tool-catalog-valid?
        poo-flow-session-policy-validation-receipt-tool-catalog-policy-tool-refs
        poo-flow-session-policy-validation-receipt-tool-catalog-resolved-tool-refs
        poo-flow-session-policy-validation-receipt-tool-catalog-unresolved-tool-refs
        poo-flow-session-policy-validation-receipt-tool-catalog-allowed-attempt-tool-refs
        poo-flow-session-policy-validation-receipt-tool-catalog-unresolved-attempt-tool-refs
        poo-flow-session-policy-validation-receipt-memory-catalog-ref
        poo-flow-session-policy-validation-receipt-memory-catalog-valid?
        poo-flow-session-policy-validation-receipt-memory-catalog-resolved-store-refs
        poo-flow-session-policy-validation-receipt-memory-catalog-unresolved-store-refs
        poo-flow-session-policy-validation-receipt-allowed-communication-channel-receipts
        poo-flow-session-policy-validation-receipt-denied-communication-channel-receipts
        poo-flow-session-policy-validation-receipt-allowed-communication-receipts
        poo-flow-session-policy-validation-receipt-denied-communication-receipts
        poo-flow-session-policy-validation-receipt-valid?
        poo-flow-session-policy-validation-receipt-diagnostic-count
        poo-flow-session-policy-validation-receipt-diagnostics
        poo-flow-session-policy-validation-receipt-runtime-executed?
        poo-flow-session-policy-validation-receipt->alist
        poo-flow-session-policy-validation-receipts->alists)

;; : (-> POOObject Symbol Object Object)
(def (poo-flow-session-validation-slot policy key default)
  (with-catch
   (lambda (_failure) default)
   (lambda ()
     (.ref policy key))))

;; : (-> Alist Symbol Object Object)
(def (poo-flow-session-validation-alist-ref row key default)
  (poo-flow-session-alist-ref row key default))

;; : (-> Datum Symbol Object Object)
(def (poo-flow-session-validation-row-ref row key default)
  (if (list? row)
    (poo-flow-session-validation-alist-ref row key default)
    (poo-flow-session-validation-slot row key default)))

;;; Boundary: policy-validation field rows preserve receipt slot names for
;;; session policy diagnostics.
;; poo-flow-session-policy-validation-field-rows
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expands session policy validation fields into diagnostic receipt rows.
;;   # Examples
;;   ```scheme
;;   (poo-flow-session-policy-validation-field-rows (valid? #t))
;;   ;; => ((valid? . #t))
;;   ```
(defrules poo-flow-session-policy-validation-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

;; : (-> Datum List Boolean)
(def (poo-flow-session-validation-member? value values)
  (if (member value values) #t #f))

;; : (forall (a) (-> (List a) (List a) (List a)))
(def (poo-flow-session-validation-reverse-onto values tail)
  (if (null? values)
    tail
    (poo-flow-session-validation-reverse-onto
     (cdr values)
     (cons (car values) tail))))

;; : (-> Datum List Boolean)
(def (poo-flow-session-validation-granted? value values)
  (or (poo-flow-session-validation-member? value values)
      (poo-flow-session-validation-member? '* values)))

;; : (-> Procedure List List List SessionValidationPartition)
(def (poo-flow-session-validation-partition/rev predicate
                                                   values
                                                   accepted-rev
                                                   rejected-rev)
  (cond
   ((null? values) (list accepted-rev rejected-rev))
   ((predicate (car values))
    (poo-flow-session-validation-partition/rev
     predicate
     (cdr values)
     (cons (car values) accepted-rev)
     rejected-rev))
   (else
    (poo-flow-session-validation-partition/rev
     predicate
     (cdr values)
     accepted-rev
     (cons (car values) rejected-rev)))))

;; : (-> Procedure List SessionValidationPartition)
(def (poo-flow-session-validation-partition predicate values)
  (let* ((partition
          (poo-flow-session-validation-partition/rev
           predicate
           values
           '()
           '()))
         (accepted-values-rev (car partition))
         (rejected-values-rev (cadr partition)))
    (list (reverse accepted-values-rev)
          (reverse rejected-values-rev))))

;; : (forall (a) (-> (List a) (List a) (List a)))
(def (poo-flow-session-reverse-onto values tail)
  (foldl cons tail values))

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol [Alist] PooSessionToolAttempt)
(def (poo-flow-session-policy-tool-attempt attempt-id
                                          trigger-ref
                                          tool-ref
                                          action
                                          resource-ref
                                          principal-ref
                                          . maybe-metadata)
  (poo-flow-session-require "session policy attempt id must be a symbol"
                            (symbol? attempt-id)
                            attempt-id)
  (poo-flow-session-require "session policy attempt trigger must be a symbol"
                            (symbol? trigger-ref)
                            trigger-ref)
  (poo-flow-session-require "session policy attempt tool must be a symbol"
                            (symbol? tool-ref)
                            tool-ref)
  (poo-flow-session-require "session policy attempt action must be a symbol"
                            (symbol? action)
                            action)
  (poo-flow-session-require "session policy attempt resource must be a symbol"
                            (symbol? resource-ref)
                            resource-ref)
  (poo-flow-session-require "session policy attempt principal must be a symbol"
                            (symbol? principal-ref)
                            principal-ref)
  (poo-flow-session-policy-validation-field-rows
   (kind 'poo-flow.session.policy.tool-attempt)
   (schema 'poo-flow.modules.session.policy.tool-attempt.v1)
   (attempt-id attempt-id)
   (trigger-ref trigger-ref)
   (tool-ref tool-ref)
   (action action)
   (resource-ref resource-ref)
   (principal-ref principal-ref)
   (metadata (if (null? maybe-metadata)
               '()
               (car maybe-metadata)))
   (runtime-executed #f)))

;; : (-> Datum Boolean)
(def (poo-flow-session-policy-tool-attempt? value)
  (and (list? value)
       (eq? (poo-flow-session-validation-alist-ref value 'kind #f)
            'poo-flow.session.policy.tool-attempt)))

;;; Generated alist accessors for stable session policy tool attempts.
(defpoo-session-alist-accessors
  poo-flow-session-validation-alist-ref
  (poo-flow-session-policy-tool-attempt-id attempt-id #f)
  (poo-flow-session-policy-tool-attempt-trigger-ref trigger-ref #f)
  (poo-flow-session-policy-tool-attempt-tool-ref tool-ref #f)
  (poo-flow-session-policy-tool-attempt-action action #f)
  (poo-flow-session-policy-tool-attempt-resource-ref resource-ref #f)
  (poo-flow-session-policy-tool-attempt-principal-ref principal-ref #f))

;; : (-> Symbol Symbol Datum Alist)
(def (poo-flow-session-policy-diagnostic code scope-ref detail)
  (poo-flow-session-policy-validation-field-rows
   (kind 'poo-flow.session.policy.diagnostic)
   (schema 'poo-flow.modules.session.policy.diagnostic.v1)
   (code code)
   (scope-ref scope-ref)
   (detail detail)
   (severity 'error)
   (runtime-executed #f)))

;; : (-> PooSessionPolicy Symbol Object)
(def (poo-flow-session-policy-slot-value policy key default)
  (poo-flow-session-validation-slot policy key default))

;; : (-> PooSessionPolicy Symbol Object)
(def (poo-flow-session-policy-nested-slot policy key default)
  (let (slots (poo-flow-session-validation-slot policy 'policy-slots '()))
    (poo-flow-session-validation-alist-ref slots key default)))

;; : (-> PooSessionPolicy [Symbol])
(def (poo-flow-session-policy-context-allowed policy)
  (poo-flow-session-policy-nested-slot policy 'allowed-session-refs '()))

;; : (-> PooSessionPolicy [Symbol])
(def (poo-flow-session-policy-history-allowed policy)
  (poo-flow-session-policy-nested-slot policy 'allowed-records '()))

;; : (-> PooSessionPolicy [Symbol])
(def (poo-flow-session-policy-channel-allowed policy)
  (poo-flow-session-policy-nested-slot policy 'channel-refs '()))

;; : (-> PooSessionPolicy [Symbol])
(def (poo-flow-session-policy-communication-targets policy)
  (poo-flow-session-policy-nested-slot policy 'target-session-refs '()))

;; : (-> PooSessionPolicy [Symbol])
(def (poo-flow-session-policy-resource-capabilities policy)
  (poo-flow-session-policy-nested-slot policy 'capability-refs '()))

;; : (-> PooSessionPolicy Object)
(def (poo-flow-session-policy-resource-accounting-owner policy)
  (poo-flow-session-policy-nested-slot policy 'accounting-owner #f))

;; : (-> PooSessionPolicy [Alist])
(def (poo-flow-session-policy-resource-grants policy)
  (poo-flow-session-policy-slot-value policy 'resource-grants '()))

;; : (-> PooSessionPolicy Symbol)
(def (poo-flow-session-policy-isolation-mode policy)
  (poo-flow-session-policy-nested-slot policy 'mode #f))

;; : (-> PooSessionPolicy Symbol)
(def (poo-flow-session-policy-isolation-sibling-context policy)
  (poo-flow-session-policy-nested-slot policy 'sibling-context 'denied))

;; : (-> PooSessionPolicy Symbol)
(def (poo-flow-session-policy-isolation-parent-write policy)
  (poo-flow-session-policy-nested-slot policy 'parent-write 'denied))

;; : (-> PooSessionPolicy Symbol)
(def (poo-flow-session-policy-isolation-peer-communication policy)
  (poo-flow-session-policy-nested-slot policy 'peer-communication 'denied))

;; : (-> PooSessionPolicy Symbol)
(def (poo-flow-session-policy-sandbox-profile-ref policy)
  (poo-flow-session-policy-nested-slot policy 'profile-ref #f))

;; : (-> PooSessionPolicy Symbol)
(def (poo-flow-session-policy-sandbox-inheritance-mode policy)
  (poo-flow-session-policy-nested-slot policy 'inheritance-mode #f))

;; : (-> PooSessionPolicy Symbol)
(def (poo-flow-session-policy-sandbox-sharing-mode policy)
  (poo-flow-session-policy-nested-slot policy 'sharing-mode #f))

;; : (-> PooSessionPolicy Boolean)
(def (poo-flow-session-policy-sibling-context-allowed? isolation-policy)
  (let (sibling-context
        (poo-flow-session-policy-isolation-sibling-context isolation-policy))
    (or (eq? sibling-context 'allow)
        (eq? sibling-context 'allowed)
        (eq? sibling-context 'read)
        (eq? sibling-context 'shared)
        (eq? sibling-context '*))))

;; : (-> [Symbol] [Symbol] PooSessionPolicy [Symbol])
(def (poo-flow-session-policy-denied-sibling-context-refs requested-refs
                                                           sibling-refs
                                                           isolation-policy)
  (cond
   ((poo-flow-session-policy-sibling-context-allowed? isolation-policy) '())
   ((null? requested-refs) '())
   ((poo-flow-session-validation-member? (car requested-refs) sibling-refs)
    (cons (car requested-refs)
          (poo-flow-session-policy-denied-sibling-context-refs
           (cdr requested-refs)
           sibling-refs
           isolation-policy)))
   (else
    (poo-flow-session-policy-denied-sibling-context-refs
     (cdr requested-refs)
     sibling-refs
     isolation-policy))))

;; : (-> Alist Boolean)
(def (poo-flow-session-resource-grant-accounted? grant)
  (let (payload (if (and (pair? grant) (list? (cdr grant)))
                  (cdr grant)
                  grant))
    (if (and (list? payload) (assoc 'accounting payload))
      #t
      #f)))

;; : (-> PooSessionPolicy Boolean)
(def (poo-flow-session-resource-policy-accounted? policy)
  (let (resource-grants (poo-flow-session-policy-resource-grants policy))
    (or (null? resource-grants)
        (symbol? (poo-flow-session-policy-resource-accounting-owner policy))
        (poo-flow-session-every?
         poo-flow-session-resource-grant-accounted?
         resource-grants))))

;; : (-> [Symbol] [Symbol] SessionValidationPartition)
(def (poo-flow-session-policy-partition-refs requested allowed)
  (poo-flow-session-validation-partition
   (lambda (value)
     (poo-flow-session-validation-granted? value allowed))
   requested))

;; : (-> Alist [PooSessionCommunicationReceiptOrRow])
(def (poo-flow-session-policy-communication-receipts metadata)
  (poo-flow-session-validation-alist-ref metadata 'communication-receipts '()))

;; : (-> Alist [PooSessionCommunicationChannelReceiptOrRow])
(def (poo-flow-session-policy-communication-channel-receipts metadata)
  (poo-flow-session-validation-alist-ref
   metadata
   'communication-channel-receipts
   '()))

;; : (-> PooSessionCommunicationChannelReceiptOrRow Alist)
(def (poo-flow-session-policy-communication-channel-receipt-row receipt)
  (cond
   ((poo-flow-session-communication-channel-receipt? receipt)
    (poo-flow-session-communication-channel-receipt->alist receipt))
   ((list? receipt) receipt)
   (else
    (list (cons 'kind 'poo-flow.session.communication-channel-receipt.invalid)
          (cons 'value receipt)))))

;; : (-> [PooSessionCommunicationChannelReceiptOrRow] [Alist])
(def (poo-flow-session-policy-communication-channel-receipt-rows receipts)
  (map poo-flow-session-policy-communication-channel-receipt-row receipts))

;; : (-> PooSessionCommunicationReceiptOrRow Alist)
(def (poo-flow-session-policy-communication-receipt-row receipt)
  (cond
   ((poo-flow-session-communication-receipt? receipt)
    (poo-flow-session-communication-receipt->alist receipt))
   ((list? receipt) receipt)
   (else
    (list (cons 'kind 'poo-flow.session.communication-receipt.invalid)
          (cons 'value receipt)))))

;; : (-> [PooSessionCommunicationReceiptOrRow] [Alist])
(def (poo-flow-session-policy-communication-receipt-rows receipts)
  (map poo-flow-session-policy-communication-receipt-row receipts))

;; : (-> Alist Symbol)
(def (poo-flow-session-policy-communication-receipt-channel row)
  (poo-flow-session-validation-row-ref row 'channel-id #f))

;; : (-> Alist Symbol)
(def (poo-flow-session-policy-communication-channel-receipt-channel row)
  (poo-flow-session-validation-row-ref row 'channel-id #f))

;; : (-> Alist Symbol)
(def (poo-flow-session-policy-communication-receipt-target row)
  (poo-flow-session-validation-row-ref row 'target-session-id #f))

;; : (-> Alist Symbol)
(def (poo-flow-session-policy-communication-channel-receipt-target row)
  (poo-flow-session-validation-row-ref row 'target-session-id #f))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-receipt-channel-allowed?
      policy
      row)
  (poo-flow-session-validation-granted?
   (poo-flow-session-policy-communication-receipt-channel row)
   (poo-flow-session-policy-channel-allowed policy)))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-channel-receipt-channel-allowed?
      policy
      row)
  (poo-flow-session-validation-granted?
   (poo-flow-session-policy-communication-channel-receipt-channel row)
   (poo-flow-session-policy-channel-allowed policy)))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-receipt-target-allowed?
      policy
      row)
  (poo-flow-session-validation-granted?
   (poo-flow-session-policy-communication-receipt-target row)
   (poo-flow-session-policy-communication-targets policy)))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-channel-receipt-target-allowed?
      policy
      row)
  (poo-flow-session-validation-granted?
   (poo-flow-session-policy-communication-channel-receipt-target row)
   (poo-flow-session-policy-communication-targets policy)))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-receipt-allowed? policy row)
  (and (poo-flow-session-policy-communication-receipt-channel-allowed?
        policy
        row)
       (poo-flow-session-policy-communication-receipt-target-allowed?
        policy
        row)))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-channel-receipt-allowed?
      policy
      row)
  (and (poo-flow-session-policy-communication-channel-receipt-channel-allowed?
        policy
        row)
       (poo-flow-session-policy-communication-channel-receipt-target-allowed?
        policy
        row)))

;; : (-> PooSessionPolicy PooSessionToolAttempt Boolean)
(def (poo-flow-session-agent-tool-attempt-allowed? policy attempt)
  (poo-flow-session-tool-permission-policy-allows?
   policy
   (poo-flow-session-policy-tool-attempt-tool-ref attempt)
   (poo-flow-session-policy-tool-attempt-action attempt)))

;; : (-> PooSessionPolicy PooSessionToolAttempt Boolean)
(def (poo-flow-session-hook-tool-attempt-allowed? policy attempt)
  (poo-flow-session-hook-tool-permission-policy-allows?
   policy
   (poo-flow-session-policy-tool-attempt-trigger-ref attempt)
   (poo-flow-session-policy-tool-attempt-tool-ref attempt)
   (poo-flow-session-policy-tool-attempt-action attempt)))

;; : (-> Symbol PooSessionToolAttempt Alist)
(def (poo-flow-session-tool-attempt-diagnostic code attempt)
  (poo-flow-session-policy-diagnostic
   code
   (poo-flow-session-policy-tool-attempt-principal-ref attempt)
   (list (cons 'attempt-id
               (poo-flow-session-policy-tool-attempt-id attempt))
         (cons 'trigger-ref
               (poo-flow-session-policy-tool-attempt-trigger-ref attempt))
         (cons 'tool-ref
               (poo-flow-session-policy-tool-attempt-tool-ref attempt))
         (cons 'action
               (poo-flow-session-policy-tool-attempt-action attempt))
         (cons 'resource-ref
               (poo-flow-session-policy-tool-attempt-resource-ref attempt)))))

;; : (-> Alist MaybeToolCatalogValidationRow)
(def (poo-flow-session-tool-catalog-validation metadata)
  (poo-flow-session-validation-alist-ref metadata 'tool-catalog-validation #f))

;; : (-> MaybeToolCatalogValidationRow Boolean)
(def (poo-flow-session-tool-catalog-validation-present? validation-row)
  (if validation-row #t #f))

;; : (-> MaybeToolCatalogValidationRow Symbol Object)
(def (poo-flow-session-tool-catalog-validation-ref validation-row key default)
  (if (poo-flow-session-tool-catalog-validation-present? validation-row)
    (poo-flow-session-validation-row-ref validation-row key default)
    default))

;; : (-> [PooSessionToolAttempt] [Symbol] [Symbol])
(def (poo-flow-session-policy-attempt-tool-refs/rev attempts refs-rev)
  (cond
   ((null? attempts) refs-rev)
   (else
    (let (tool-ref
          (poo-flow-session-policy-tool-attempt-tool-ref (car attempts)))
      (poo-flow-session-policy-attempt-tool-refs/rev
       (cdr attempts)
       (if (member tool-ref refs-rev)
         refs-rev
         (cons tool-ref refs-rev)))))))

;; : (-> [PooSessionToolAttempt] [PooSessionToolAttempt] [Symbol])
(def (poo-flow-session-policy-attempt-tool-refs agent-attempts
                                                hook-attempts)
  (reverse
   (poo-flow-session-policy-attempt-tool-refs/rev
    hook-attempts
    (poo-flow-session-policy-attempt-tool-refs/rev agent-attempts '()))))

;; : (-> MaybeToolCatalogValidationRow [Symbol] SessionValidationPartition)
(def (poo-flow-session-policy-catalog-attempt-ref-partition
      tool-catalog-validation
      attempt-tool-refs)
  (if (poo-flow-session-tool-catalog-validation-present?
       tool-catalog-validation)
    (poo-flow-session-policy-partition-refs
     attempt-tool-refs
     (poo-flow-session-tool-catalog-validation-ref
      tool-catalog-validation
      'resolved-tool-refs
      '()))
    (list '() '())))

;; : (-> Alist MaybeMemoryCatalogValidationRow)
(def (poo-flow-session-memory-catalog-validation metadata)
  (poo-flow-session-validation-alist-ref metadata 'memory-catalog-validation #f))

;; : (-> MaybeMemoryCatalogValidationRow Boolean)
(def (poo-flow-session-memory-catalog-validation-present? validation-row)
  (if validation-row #t #f))

;; : (-> MaybeMemoryCatalogValidationRow Symbol Object)
(def (poo-flow-session-memory-catalog-validation-ref validation-row key default)
  (if (poo-flow-session-memory-catalog-validation-present? validation-row)
    (poo-flow-session-validation-row-ref validation-row key default)
    default))

;; : (-> Symbol Symbol [Symbol] [Alist] [Alist])
(def (poo-flow-session-denied-ref-diagnostics/rev code
                                                   scope-ref
                                                   refs
                                                   diagnostics-rev)
  (fold
   (lambda (ref diagnostics)
     (cons (poo-flow-session-policy-diagnostic
            code
            scope-ref
            (list (cons 'ref ref)))
           diagnostics))
   diagnostics-rev
   refs))

;; : (-> Symbol [PooSessionToolAttempt] [Alist] [Alist])
(def (poo-flow-session-tool-attempt-diagnostics/rev code
                                                     attempts
                                                     diagnostics-rev)
  (fold
   (lambda (attempt diagnostics)
     (cons (poo-flow-session-tool-attempt-diagnostic code attempt)
           diagnostics))
   diagnostics-rev
   attempts))

;; : (-> Symbol Symbol Alist Alist)
(def (poo-flow-session-communication-receipt-diagnostic code
                                                        scope-ref
                                                        row)
  (poo-flow-session-policy-diagnostic
   code
   scope-ref
   (list (cons 'relation-kind
               (poo-flow-session-validation-row-ref row 'relation-kind #f))
         (cons 'source-session-id
               (poo-flow-session-validation-row-ref row
                                                    'source-session-id
                                                    #f))
         (cons 'target-session-id
               (poo-flow-session-validation-row-ref row
                                                    'target-session-id
                                                    #f))
         (cons 'channel-id
               (poo-flow-session-validation-row-ref row 'channel-id #f))
         (cons 'message-kind
               (poo-flow-session-validation-row-ref row 'message-kind #f)))))

;; : (-> Symbol Symbol Alist Alist)
(def (poo-flow-session-communication-channel-receipt-diagnostic code
                                                                scope-ref
                                                                row)
  (poo-flow-session-policy-diagnostic
   code
   scope-ref
   (list (cons 'relation-kind
               (poo-flow-session-validation-row-ref row 'relation-kind #f))
         (cons 'source-session-id
               (poo-flow-session-validation-row-ref row
                                                    'source-session-id
                                                    #f))
         (cons 'target-session-id
               (poo-flow-session-validation-row-ref row
                                                    'target-session-id
                                                    #f))
         (cons 'channel-id
               (poo-flow-session-validation-row-ref row 'channel-id #f)))))

;; : (-> Symbol PooSessionPolicy [Alist] [Alist] [Alist])
(def (poo-flow-session-communication-channel-receipt-diagnostics/rev
      scope-ref
      policy
      rows
      diagnostics-rev)
  (fold
   (lambda (row diagnostics)
     (if (poo-flow-session-policy-communication-channel-receipt-allowed?
          policy
          row)
       diagnostics
       (cons (poo-flow-session-communication-channel-receipt-diagnostic
              'communication-channel-receipt-not-granted
              scope-ref
              row)
             diagnostics)))
   diagnostics-rev
   rows))

;; : (-> Symbol PooSessionPolicy [Alist] [Alist] [Alist])
(def (poo-flow-session-communication-channel-diagnostics/rev scope-ref
                                                             policy
                                                             rows
                                                             diagnostics-rev)
  (fold
   (lambda (row diagnostics)
     (if (poo-flow-session-policy-communication-receipt-channel-allowed?
          policy
          row)
       diagnostics
       (cons (poo-flow-session-communication-receipt-diagnostic
              'communication-receipt-channel-not-granted
              scope-ref
              row)
             diagnostics)))
   diagnostics-rev
   rows))

;; : (-> Symbol PooSessionPolicy [Alist] [Alist] [Alist])
(def (poo-flow-session-communication-target-diagnostics/rev scope-ref
                                                            policy
                                                            rows
                                                            diagnostics-rev)
  (fold
   (lambda (row diagnostics)
     (if (poo-flow-session-policy-communication-receipt-target-allowed?
          policy
          row)
       diagnostics
       (cons (poo-flow-session-communication-receipt-diagnostic
              'communication-receipt-target-not-granted
              scope-ref
              row)
             diagnostics)))
   diagnostics-rev
   rows))

;; : (-> PooSessionPolicy [PooSessionToolAttempt] [Alist] [Alist])
(def (poo-flow-session-hook-inheritance-diagnostics/rev agent-tool-policy
                                                        denied-hook-attempts
                                                        diagnostics-rev)
  (fold
   (lambda (attempt diagnostics)
     (if (poo-flow-session-agent-tool-attempt-allowed?
          agent-tool-policy
          attempt)
       (cons (poo-flow-session-tool-attempt-diagnostic
              'hook-tool-agent-permission-not-inherited
              attempt)
             diagnostics)
       diagnostics))
   diagnostics-rev
   denied-hook-attempts))

;; : PooSessionPolicyValidationReceiptRecordStruct
(defstruct poo-flow-session-policy-validation-receipt-record
  (validation-id
   scope-ref
   valid?
   effective-model-ref
   effective-prompt-session-ref
   effective-prompt-chunk-refs
   effective-isolation-mode
   isolation-sibling-context
   isolation-parent-write
   isolation-peer-communication
   effective-sandbox-profile-ref
   sandbox-inheritance-mode
   sandbox-sharing-mode
   allowed-context-refs
   denied-context-refs
   allowed-history-records
   denied-history-records
   allowed-communication-channels
   denied-communication-channels
   allowed-communication-channel-receipts
   denied-communication-channel-receipts
   allowed-communication-receipts
   denied-communication-receipts
   allowed-resource-refs
   denied-resource-refs
   allowed-agent-tool-attempts
   denied-agent-tool-attempts
   allowed-hook-tool-attempts
   denied-hook-tool-attempts
   tool-catalog-validation-id
   tool-catalog-ref
   tool-catalog-valid?
   tool-catalog-policy-tool-refs
   tool-catalog-resolved-tool-refs
   tool-catalog-unresolved-tool-refs
   tool-catalog-sandbox-required-tool-refs
   tool-catalog-action-mismatch-grants
   tool-catalog-allowed-attempt-tool-refs
   tool-catalog-unresolved-attempt-tool-refs
   memory-catalog-validation-id
   memory-catalog-ref
   memory-catalog-valid?
   memory-catalog-store-count
   memory-catalog-store-refs
   memory-catalog-intent-count
   memory-catalog-intent-store-refs
   memory-catalog-resolved-store-refs
   memory-catalog-unresolved-store-refs
   shared-resource-grants
   diagnostic-count
   diagnostics
   runtime-owner
   runtime-executed?
   metadata)
  transparent: #t)

;;; Boundary: session policy validation receipts aggregate lineage, selector,
;;; resource, capability, memory, compression, and tool policy checks.
;; : (-> Symbol Symbol PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy [Symbol] [Symbol] [Symbol] [Symbol] [PooSessionToolAttempt] [PooSessionToolAttempt] [Alist] PooSessionPolicyValidationReceipt)
(def (poo-flow-session-policy-validation-receipt validation-id
                                                scope-ref
                                                model-policy
                                                prompt-policy
                                                isolation-policy
                                                sandbox-policy
                                                context-policy
                                                history-policy
                                                communication-policy
                                                sharing-policy
                                                resource-policy
                                                agent-tool-policy
                                                hook-tool-policy
                                                requested-context-refs
                                                requested-history-records
                                                requested-channel-refs
                                                requested-resource-refs
                                                agent-tool-attempts
                                                hook-tool-attempts
                                                . maybe-metadata)
  (poo-flow-session-require "session policy validation id must be a symbol"
                            (symbol? validation-id)
                            validation-id)
  (poo-flow-session-require "session policy validation scope must be a symbol"
                            (symbol? scope-ref)
                            scope-ref)
  (poo-flow-session-require "session policy validation model policy required"
                            (poo-flow-session-policy? model-policy)
                            model-policy)
  (poo-flow-session-require "session policy validation prompt policy required"
                            (poo-flow-session-policy? prompt-policy)
                            prompt-policy)
  (poo-flow-session-require "session policy validation isolation policy required"
                            (poo-flow-session-policy? isolation-policy)
                            isolation-policy)
  (poo-flow-session-require "session policy validation sandbox policy required"
                            (poo-flow-session-policy? sandbox-policy)
                            sandbox-policy)
  (poo-flow-session-require "session policy validation context policy required"
                            (poo-flow-session-policy? context-policy)
                            context-policy)
  (poo-flow-session-require "session policy validation history policy required"
                            (poo-flow-session-policy? history-policy)
                            history-policy)
  (poo-flow-session-require "session policy validation communication policy required"
                            (poo-flow-session-policy? communication-policy)
                            communication-policy)
  (poo-flow-session-require "session policy validation sharing policy required"
                            (poo-flow-session-policy? sharing-policy)
                            sharing-policy)
  (poo-flow-session-require "session policy validation resource policy required"
                            (poo-flow-session-policy? resource-policy)
                            resource-policy)
  (poo-flow-session-require "session policy validation agent tool policy required"
                            (poo-flow-session-policy? agent-tool-policy)
                            agent-tool-policy)
  (poo-flow-session-require "session policy validation hook tool policy required"
                            (poo-flow-session-policy? hook-tool-policy)
                            hook-tool-policy)
  (poo-flow-session-require "session policy validation agent attempts must be attempts"
                            (poo-flow-session-every?
                             poo-flow-session-policy-tool-attempt?
                             agent-tool-attempts)
                            agent-tool-attempts)
  (poo-flow-session-require "session policy validation hook attempts must be attempts"
                            (poo-flow-session-every?
                             poo-flow-session-policy-tool-attempt?
                             hook-tool-attempts)
                            hook-tool-attempts)
  (let* ((context-ref-partition
          (poo-flow-session-policy-partition-refs
           requested-context-refs
           (poo-flow-session-policy-context-allowed context-policy)))
         (allowed-context-refs (car context-ref-partition))
         (denied-context-refs (cadr context-ref-partition))
         (history-record-partition
          (poo-flow-session-policy-partition-refs
           requested-history-records
           (poo-flow-session-policy-history-allowed history-policy)))
         (allowed-history-records (car history-record-partition))
         (denied-history-records (cadr history-record-partition))
         (communication-channel-partition
          (poo-flow-session-policy-partition-refs
           requested-channel-refs
           (poo-flow-session-policy-channel-allowed communication-policy)))
         (allowed-communication-channels
          (car communication-channel-partition))
         (denied-communication-channels
          (cadr communication-channel-partition))
         (resource-ref-partition
          (poo-flow-session-policy-partition-refs
           requested-resource-refs
           (poo-flow-session-policy-resource-capabilities resource-policy)))
         (allowed-resource-refs (car resource-ref-partition))
         (denied-resource-refs (cadr resource-ref-partition))
         (agent-tool-attempt-partition
          (poo-flow-session-validation-partition
           (lambda (attempt)
             (poo-flow-session-agent-tool-attempt-allowed?
              agent-tool-policy
              attempt))
           agent-tool-attempts))
         (allowed-agent-tool-attempts
          (car agent-tool-attempt-partition))
         (denied-agent-tool-attempts
          (cadr agent-tool-attempt-partition))
         (hook-tool-attempt-partition
          (poo-flow-session-validation-partition
           (lambda (attempt)
             (poo-flow-session-hook-tool-attempt-allowed?
              hook-tool-policy
              attempt))
           hook-tool-attempts))
         (allowed-hook-tool-attempts
          (car hook-tool-attempt-partition))
         (denied-hook-tool-attempts
          (cadr hook-tool-attempt-partition))
         (metadata
          (if (null? maybe-metadata)
            '()
            (car maybe-metadata)))
         (communication-channel-receipt-rows
          (poo-flow-session-policy-communication-channel-receipt-rows
           (poo-flow-session-policy-communication-channel-receipts metadata)))
         (communication-channel-receipt-partition
          (poo-flow-session-validation-partition
           (lambda (row)
             (poo-flow-session-policy-communication-channel-receipt-allowed?
              communication-policy
              row))
           communication-channel-receipt-rows))
         (allowed-communication-channel-receipts
          (car communication-channel-receipt-partition))
         (denied-communication-channel-receipts
          (cadr communication-channel-receipt-partition))
         (communication-receipt-rows
          (poo-flow-session-policy-communication-receipt-rows
           (poo-flow-session-policy-communication-receipts metadata)))
         (communication-receipt-partition
          (poo-flow-session-validation-partition
           (lambda (row)
             (poo-flow-session-policy-communication-receipt-allowed?
              communication-policy
              row))
           communication-receipt-rows))
         (allowed-communication-receipts
          (car communication-receipt-partition))
         (denied-communication-receipts
          (cadr communication-receipt-partition))
         (tool-catalog-validation
          (poo-flow-session-tool-catalog-validation metadata))
         (tool-catalog-diagnostics
          (poo-flow-session-tool-catalog-validation-ref
           tool-catalog-validation
           'diagnostics
           '()))
         (allowed-attempt-tool-refs
          (poo-flow-session-policy-attempt-tool-refs
           allowed-agent-tool-attempts
           allowed-hook-tool-attempts))
         (catalog-attempt-ref-partition
          (poo-flow-session-policy-catalog-attempt-ref-partition
           tool-catalog-validation
           allowed-attempt-tool-refs))
         (tool-catalog-allowed-attempt-tool-refs
          (car catalog-attempt-ref-partition))
         (tool-catalog-unresolved-attempt-tool-refs
          (cadr catalog-attempt-ref-partition))
         (memory-catalog-validation
          (poo-flow-session-memory-catalog-validation metadata))
         (memory-catalog-diagnostics
          (poo-flow-session-memory-catalog-validation-ref
           memory-catalog-validation
           'diagnostics
           '()))
         (sibling-session-refs
          (poo-flow-session-validation-alist-ref
           metadata
           'sibling-session-refs
           '()))
         (denied-sibling-context-refs
          (poo-flow-session-policy-denied-sibling-context-refs
           requested-context-refs
           sibling-session-refs
           isolation-policy))
         (diagnostics
          (let* ((diagnostics0
                  (poo-flow-session-denied-ref-diagnostics/rev
                   'context-session-not-granted
                   scope-ref
                   denied-context-refs
                   '()))
                 (diagnostics1
                  (poo-flow-session-denied-ref-diagnostics/rev
                   'history-record-not-granted
                   scope-ref
                   denied-history-records
                   diagnostics0))
                 (diagnostics2
                  (poo-flow-session-denied-ref-diagnostics/rev
                   'communication-channel-not-granted
                   scope-ref
                   denied-communication-channels
                   diagnostics1))
                 (diagnostics2channel
                  (poo-flow-session-communication-channel-receipt-diagnostics/rev
                   scope-ref
                   communication-policy
                   communication-channel-receipt-rows
                   diagnostics2))
                 (diagnostics2a
                  (poo-flow-session-communication-channel-diagnostics/rev
                   scope-ref
                   communication-policy
                   communication-receipt-rows
                   diagnostics2channel))
                 (diagnostics2b
                  (poo-flow-session-communication-target-diagnostics/rev
                   scope-ref
                   communication-policy
                   communication-receipt-rows
                   diagnostics2a))
                 (diagnostics3
                  (poo-flow-session-denied-ref-diagnostics/rev
                   'resource-capability-not-granted
                   scope-ref
                   denied-resource-refs
                   diagnostics2b))
                 (diagnostics4
                  (poo-flow-session-tool-attempt-diagnostics/rev
                   'agent-tool-attempt-not-granted
                   denied-agent-tool-attempts
                   diagnostics3))
                 (diagnostics5
                  (poo-flow-session-tool-attempt-diagnostics/rev
                   'hook-tool-attempt-not-granted
                   denied-hook-tool-attempts
                   diagnostics4))
                 (diagnostics6
                  (poo-flow-session-hook-inheritance-diagnostics/rev
                   agent-tool-policy
                   denied-hook-tool-attempts
                   diagnostics5))
                 (diagnostics7
                  (poo-flow-session-denied-ref-diagnostics/rev
                   'sibling-context-not-granted
                   scope-ref
                   denied-sibling-context-refs
                   diagnostics6))
                 (diagnostics8
                  (if (poo-flow-session-resource-policy-accounted?
                       sharing-policy)
                    diagnostics7
                    (cons (poo-flow-session-policy-diagnostic
                           'resource-sharing-missing-accounting-owner
                           scope-ref
                           (poo-flow-session-policy-resource-grants
                            sharing-policy))
                          diagnostics7)))
                 (diagnostics9
                  (poo-flow-session-validation-reverse-onto
                   tool-catalog-diagnostics
                   diagnostics8))
                 (diagnostics9a
                  (poo-flow-session-denied-ref-diagnostics/rev
                   'tool-attempt-not-in-catalog
                   scope-ref
                   tool-catalog-unresolved-attempt-tool-refs
                   diagnostics9))
                 (diagnostics10
                  (poo-flow-session-validation-reverse-onto
                   memory-catalog-diagnostics
                   diagnostics9a)))
            (reverse diagnostics10))))
    (make-poo-flow-session-policy-validation-receipt-record
     validation-id
     scope-ref
     (null? diagnostics)
     (poo-flow-session-policy-slot-value model-policy 'model-ref #f)
     (poo-flow-session-policy-slot-value
      prompt-policy
      'prompt-session-ref
      #f)
     (poo-flow-session-policy-slot-value
      prompt-policy
      'prompt-chunk-refs
      '())
     (poo-flow-session-policy-isolation-mode isolation-policy)
     (poo-flow-session-policy-isolation-sibling-context isolation-policy)
     (poo-flow-session-policy-isolation-parent-write isolation-policy)
     (poo-flow-session-policy-isolation-peer-communication isolation-policy)
     (poo-flow-session-policy-sandbox-profile-ref sandbox-policy)
     (poo-flow-session-policy-sandbox-inheritance-mode sandbox-policy)
     (poo-flow-session-policy-sandbox-sharing-mode sandbox-policy)
     allowed-context-refs
     denied-context-refs
     allowed-history-records
     denied-history-records
     allowed-communication-channels
     denied-communication-channels
     allowed-communication-channel-receipts
     denied-communication-channel-receipts
     allowed-communication-receipts
     denied-communication-receipts
     allowed-resource-refs
     denied-resource-refs
     allowed-agent-tool-attempts
     denied-agent-tool-attempts
     allowed-hook-tool-attempts
     denied-hook-tool-attempts
     (poo-flow-session-tool-catalog-validation-ref
      tool-catalog-validation
      'validation-id
      #f)
     (poo-flow-session-tool-catalog-validation-ref
      tool-catalog-validation
      'catalog-ref
      #f)
     (poo-flow-session-tool-catalog-validation-ref
      tool-catalog-validation
      'valid?
      #f)
     (poo-flow-session-tool-catalog-validation-ref
      tool-catalog-validation
      'policy-tool-refs
      '())
     (poo-flow-session-tool-catalog-validation-ref
      tool-catalog-validation
      'resolved-tool-refs
      '())
     (poo-flow-session-tool-catalog-validation-ref
      tool-catalog-validation
      'unresolved-tool-refs
      '())
     (poo-flow-session-tool-catalog-validation-ref
      tool-catalog-validation
      'sandbox-required-tool-refs
      '())
     (poo-flow-session-tool-catalog-validation-ref
      tool-catalog-validation
      'action-mismatch-grants
      '())
     tool-catalog-allowed-attempt-tool-refs
     tool-catalog-unresolved-attempt-tool-refs
     (poo-flow-session-memory-catalog-validation-ref
      memory-catalog-validation
      'validation-id
      #f)
     (poo-flow-session-memory-catalog-validation-ref
      memory-catalog-validation
      'catalog-ref
      #f)
     (poo-flow-session-memory-catalog-validation-ref
      memory-catalog-validation
      'valid?
      #f)
     (poo-flow-session-memory-catalog-validation-ref
      memory-catalog-validation
      'catalog-store-count
      0)
     (poo-flow-session-memory-catalog-validation-ref
      memory-catalog-validation
      'catalog-store-refs
      '())
     (poo-flow-session-memory-catalog-validation-ref
      memory-catalog-validation
      'intent-count
      0)
     (poo-flow-session-memory-catalog-validation-ref
      memory-catalog-validation
      'intent-store-refs
      '())
     (poo-flow-session-memory-catalog-validation-ref
      memory-catalog-validation
      'resolved-store-refs
      '())
     (poo-flow-session-memory-catalog-validation-ref
      memory-catalog-validation
      'unresolved-store-refs
      '())
     (poo-flow-session-policy-resource-grants sharing-policy)
     (length diagnostics)
     diagnostics
     "marlin-agent-core"
     #f
     metadata)))

;; : (-> Datum Boolean)
(def (poo-flow-session-policy-validation-receipt? value)
  (poo-flow-session-policy-validation-receipt-record? value))

;;; Keep these as named definitions so policy reports attach diagnostics to
;;; stable runtime bindings rather than a top-level accessor macro call.
;; : (-> PooSessionPolicyValidationReceipt Symbol)
(def (poo-flow-session-policy-validation-receipt-validation-id receipt)
  (poo-flow-session-policy-validation-receipt-record-validation-id receipt))

;; : (-> PooSessionPolicyValidationReceipt Object)
(def (poo-flow-session-policy-validation-receipt-effective-model-ref receipt)
  (poo-flow-session-policy-validation-receipt-record-effective-model-ref
   receipt))

;; : (-> PooSessionPolicyValidationReceipt Object)
(def (poo-flow-session-policy-validation-receipt-effective-prompt-session-ref
      receipt)
  (poo-flow-session-policy-validation-receipt-record-effective-prompt-session-ref
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Symbol])
(def (poo-flow-session-policy-validation-receipt-effective-prompt-chunk-refs
      receipt)
  (poo-flow-session-policy-validation-receipt-record-effective-prompt-chunk-refs
   receipt))

;; : (-> PooSessionPolicyValidationReceipt Object)
(def (poo-flow-session-policy-validation-receipt-effective-isolation-mode
      receipt)
  (poo-flow-session-policy-validation-receipt-record-effective-isolation-mode
   receipt))

;; : (-> PooSessionPolicyValidationReceipt Object)
(def (poo-flow-session-policy-validation-receipt-effective-sandbox-profile-ref
      receipt)
  (poo-flow-session-policy-validation-receipt-record-effective-sandbox-profile-ref
   receipt))

;; : (-> PooSessionPolicyValidationReceipt Object)
(def (poo-flow-session-policy-validation-receipt-tool-catalog-ref receipt)
  (poo-flow-session-policy-validation-receipt-record-tool-catalog-ref receipt))

;; : (-> PooSessionPolicyValidationReceipt Boolean)
(def (poo-flow-session-policy-validation-receipt-tool-catalog-valid? receipt)
  (poo-flow-session-policy-validation-receipt-record-tool-catalog-valid?
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Symbol])
(def (poo-flow-session-policy-validation-receipt-tool-catalog-policy-tool-refs
      receipt)
  (poo-flow-session-policy-validation-receipt-record-tool-catalog-policy-tool-refs
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Symbol])
(def (poo-flow-session-policy-validation-receipt-tool-catalog-resolved-tool-refs
      receipt)
  (poo-flow-session-policy-validation-receipt-record-tool-catalog-resolved-tool-refs
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Symbol])
(def (poo-flow-session-policy-validation-receipt-tool-catalog-unresolved-tool-refs
      receipt)
  (poo-flow-session-policy-validation-receipt-record-tool-catalog-unresolved-tool-refs
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Symbol])
(def (poo-flow-session-policy-validation-receipt-tool-catalog-allowed-attempt-tool-refs
      receipt)
  (poo-flow-session-policy-validation-receipt-record-tool-catalog-allowed-attempt-tool-refs
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Symbol])
(def (poo-flow-session-policy-validation-receipt-tool-catalog-unresolved-attempt-tool-refs
      receipt)
  (poo-flow-session-policy-validation-receipt-record-tool-catalog-unresolved-attempt-tool-refs
   receipt))

;; : (-> PooSessionPolicyValidationReceipt Object)
(def (poo-flow-session-policy-validation-receipt-memory-catalog-ref receipt)
  (poo-flow-session-policy-validation-receipt-record-memory-catalog-ref
   receipt))

;; : (-> PooSessionPolicyValidationReceipt Boolean)
(def (poo-flow-session-policy-validation-receipt-memory-catalog-valid? receipt)
  (poo-flow-session-policy-validation-receipt-record-memory-catalog-valid?
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Symbol])
(def (poo-flow-session-policy-validation-receipt-memory-catalog-resolved-store-refs
      receipt)
  (poo-flow-session-policy-validation-receipt-record-memory-catalog-resolved-store-refs
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Symbol])
(def (poo-flow-session-policy-validation-receipt-memory-catalog-unresolved-store-refs
      receipt)
  (poo-flow-session-policy-validation-receipt-record-memory-catalog-unresolved-store-refs
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Alist])
(def (poo-flow-session-policy-validation-receipt-allowed-communication-channel-receipts
      receipt)
  (poo-flow-session-policy-validation-receipt-record-allowed-communication-channel-receipts
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Alist])
(def (poo-flow-session-policy-validation-receipt-denied-communication-channel-receipts
      receipt)
  (poo-flow-session-policy-validation-receipt-record-denied-communication-channel-receipts
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Alist])
(def (poo-flow-session-policy-validation-receipt-allowed-communication-receipts
      receipt)
  (poo-flow-session-policy-validation-receipt-record-allowed-communication-receipts
   receipt))

;; : (-> PooSessionPolicyValidationReceipt [Alist])
(def (poo-flow-session-policy-validation-receipt-denied-communication-receipts
      receipt)
  (poo-flow-session-policy-validation-receipt-record-denied-communication-receipts
   receipt))

;; : (-> PooSessionPolicyValidationReceipt Boolean)
(def (poo-flow-session-policy-validation-receipt-valid? receipt)
  (poo-flow-session-policy-validation-receipt-record-valid? receipt))

;; : (-> PooSessionPolicyValidationReceipt Integer)
(def (poo-flow-session-policy-validation-receipt-diagnostic-count receipt)
  (poo-flow-session-policy-validation-receipt-record-diagnostic-count receipt))

;; : (-> PooSessionPolicyValidationReceipt [Alist])
(def (poo-flow-session-policy-validation-receipt-diagnostics receipt)
  (poo-flow-session-policy-validation-receipt-record-diagnostics receipt))

;; : (-> PooSessionPolicyValidationReceipt Boolean)
(def (poo-flow-session-policy-validation-receipt-runtime-executed? receipt)
  (poo-flow-session-policy-validation-receipt-record-runtime-executed? receipt))

;; : (-> PooSessionPolicyValidationReceipt Alist)
(defpoo-session-receipt-projection
  poo-flow-session-policy-validation-receipt->alist
  (receipt)
  (require poo-flow-session-require
           "session policy validation projection requires a receipt"
           (poo-flow-session-policy-validation-receipt? receipt)
           receipt)
  (bindings ())
  (fields
   (('kind 'poo-flow.session.policy-validation-receipt)
    ('schema 'poo-flow.modules.session.policy-validation-receipt.v1)
    ('validation-id
     (poo-flow-session-policy-validation-receipt-record-validation-id
      receipt))
    ('scope-ref
     (poo-flow-session-policy-validation-receipt-record-scope-ref
      receipt))
    ('valid?
     (poo-flow-session-policy-validation-receipt-valid? receipt))
    ('effective-model-ref
     (poo-flow-session-policy-validation-receipt-effective-model-ref
      receipt))
    ('effective-prompt-session-ref
     (poo-flow-session-policy-validation-receipt-effective-prompt-session-ref
      receipt))
    ('effective-prompt-chunk-refs
     (poo-flow-session-policy-validation-receipt-effective-prompt-chunk-refs
      receipt))
    ('effective-isolation-mode
     (poo-flow-session-policy-validation-receipt-effective-isolation-mode
      receipt))
    ('isolation-sibling-context
     (poo-flow-session-policy-validation-receipt-record-isolation-sibling-context
      receipt))
    ('isolation-parent-write
     (poo-flow-session-policy-validation-receipt-record-isolation-parent-write
      receipt))
    ('isolation-peer-communication
     (poo-flow-session-policy-validation-receipt-record-isolation-peer-communication
      receipt))
    ('effective-sandbox-profile-ref
     (poo-flow-session-policy-validation-receipt-effective-sandbox-profile-ref
      receipt))
    ('sandbox-inheritance-mode
     (poo-flow-session-policy-validation-receipt-record-sandbox-inheritance-mode
      receipt))
    ('sandbox-sharing-mode
     (poo-flow-session-policy-validation-receipt-record-sandbox-sharing-mode
      receipt))
    ('allowed-context-refs
     (poo-flow-session-policy-validation-receipt-record-allowed-context-refs
      receipt))
    ('denied-context-refs
     (poo-flow-session-policy-validation-receipt-record-denied-context-refs
      receipt))
    ('allowed-history-records
     (poo-flow-session-policy-validation-receipt-record-allowed-history-records
      receipt))
    ('denied-history-records
     (poo-flow-session-policy-validation-receipt-record-denied-history-records
      receipt))
    ('allowed-communication-channels
     (poo-flow-session-policy-validation-receipt-record-allowed-communication-channels
      receipt))
    ('denied-communication-channels
     (poo-flow-session-policy-validation-receipt-record-denied-communication-channels
      receipt))
    ('allowed-communication-channel-receipts
     (poo-flow-session-policy-validation-receipt-allowed-communication-channel-receipts
      receipt))
    ('denied-communication-channel-receipts
     (poo-flow-session-policy-validation-receipt-denied-communication-channel-receipts
      receipt))
    ('allowed-communication-receipts
     (poo-flow-session-policy-validation-receipt-allowed-communication-receipts
      receipt))
    ('denied-communication-receipts
     (poo-flow-session-policy-validation-receipt-denied-communication-receipts
      receipt))
    ('allowed-resource-refs
     (poo-flow-session-policy-validation-receipt-record-allowed-resource-refs
      receipt))
    ('denied-resource-refs
     (poo-flow-session-policy-validation-receipt-record-denied-resource-refs
      receipt))
    ('allowed-agent-tool-attempts
     (poo-flow-session-policy-validation-receipt-record-allowed-agent-tool-attempts
      receipt))
    ('denied-agent-tool-attempts
     (poo-flow-session-policy-validation-receipt-record-denied-agent-tool-attempts
      receipt))
    ('allowed-hook-tool-attempts
     (poo-flow-session-policy-validation-receipt-record-allowed-hook-tool-attempts
      receipt))
    ('denied-hook-tool-attempts
     (poo-flow-session-policy-validation-receipt-record-denied-hook-tool-attempts
      receipt))
    ('tool-catalog-validation-id
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-validation-id
      receipt))
    ('tool-catalog-ref
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-ref
      receipt))
    ('tool-catalog-valid?
     (poo-flow-session-policy-validation-receipt-tool-catalog-valid?
      receipt))
    ('tool-catalog-policy-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-policy-tool-refs
      receipt))
    ('tool-catalog-resolved-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-resolved-tool-refs
      receipt))
    ('tool-catalog-unresolved-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-unresolved-tool-refs
      receipt))
    ('tool-catalog-sandbox-required-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-sandbox-required-tool-refs
      receipt))
    ('tool-catalog-action-mismatch-grants
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-action-mismatch-grants
      receipt))
    ('tool-catalog-allowed-attempt-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-allowed-attempt-tool-refs
      receipt))
    ('tool-catalog-unresolved-attempt-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-unresolved-attempt-tool-refs
      receipt))
    ('memory-catalog-validation-id
     (poo-flow-session-policy-validation-receipt-record-memory-catalog-validation-id
      receipt))
    ('memory-catalog-ref
     (poo-flow-session-policy-validation-receipt-memory-catalog-ref receipt))
    ('memory-catalog-valid?
     (poo-flow-session-policy-validation-receipt-memory-catalog-valid?
      receipt))
    ('memory-catalog-store-count
     (poo-flow-session-policy-validation-receipt-record-memory-catalog-store-count
      receipt))
    ('memory-catalog-store-refs
     (poo-flow-session-policy-validation-receipt-record-memory-catalog-store-refs
      receipt))
    ('memory-catalog-intent-count
     (poo-flow-session-policy-validation-receipt-record-memory-catalog-intent-count
      receipt))
    ('memory-catalog-intent-store-refs
     (poo-flow-session-policy-validation-receipt-record-memory-catalog-intent-store-refs
      receipt))
    ('memory-catalog-resolved-store-refs
     (poo-flow-session-policy-validation-receipt-memory-catalog-resolved-store-refs
      receipt))
    ('memory-catalog-unresolved-store-refs
     (poo-flow-session-policy-validation-receipt-memory-catalog-unresolved-store-refs
      receipt))
    ('shared-resource-grants
     (poo-flow-session-policy-validation-receipt-record-shared-resource-grants
      receipt))
    ('diagnostic-count
     (poo-flow-session-policy-validation-receipt-diagnostic-count receipt))
    ('diagnostics
     (poo-flow-session-policy-validation-receipt-diagnostics receipt))
    ('runtime-owner
     (poo-flow-session-policy-validation-receipt-record-runtime-owner
      receipt))
    ('runtime-executed
     (poo-flow-session-policy-validation-receipt-runtime-executed?
      receipt))
    ('metadata
     (poo-flow-session-policy-validation-receipt-record-metadata receipt)))))

;; : (-> [PooSessionPolicyValidationReceipt] [Alist])
(defpoo-session-receipt-projection-batch
  poo-flow-session-policy-validation-receipts->alists (receipts)
  (projector poo-flow-session-policy-validation-receipt->alist)
  (error-message "session policy validation projection requires a list"))
