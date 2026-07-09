;;; -*- Gerbil -*-
;;; Boundary: tool, memory, and diagnostic catalog checks for session policy validation.

(import (only-in :std/srfi/1 fold)
        :poo-flow/src/modules/session/policy
        :poo-flow/src/modules/session/policy-validation-support
        :poo-flow/src/modules/session/policy-validation-communication)

(export poo-flow-session-agent-tool-attempt-allowed?
        poo-flow-session-hook-tool-attempt-allowed?
        poo-flow-session-tool-attempt-diagnostic
        poo-flow-session-tool-catalog-validation
        poo-flow-session-tool-catalog-validation-present?
        poo-flow-session-tool-catalog-validation-ref
        poo-flow-session-policy-attempt-tool-refs/rev
        poo-flow-session-policy-attempt-tool-refs
        poo-flow-session-policy-catalog-attempt-ref-partition
        poo-flow-session-memory-catalog-validation
        poo-flow-session-memory-catalog-validation-present?
        poo-flow-session-memory-catalog-validation-ref
        poo-flow-session-denied-ref-diagnostics/rev
        poo-flow-session-tool-attempt-diagnostics/rev
        poo-flow-session-communication-receipt-diagnostic
        poo-flow-session-communication-channel-receipt-diagnostic
        poo-flow-session-communication-channel-receipt-diagnostics/rev
        poo-flow-session-communication-channel-diagnostics/rev
        poo-flow-session-communication-target-diagnostics/rev
        poo-flow-session-hook-inheritance-diagnostics/rev)

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
