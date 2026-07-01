;;; -*- Gerbil -*-
;;; Boundary: effective session policy validation receipts.
;;; Invariant: validation inspects composed POO policy objects and bounded
;;; attempt rows; it does not execute tools, hooks, communication, or runtime IO.

(import (only-in :clan/poo/object .ref)
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
        poo-flow-session-policy-validation-receipt-tool-catalog-valid?
        poo-flow-session-policy-validation-receipt-valid?
        poo-flow-session-policy-validation-receipt-diagnostic-count
        poo-flow-session-policy-validation-receipt-diagnostics
        poo-flow-session-policy-validation-receipt-runtime-executed?
        poo-flow-session-policy-validation-receipt->alist
        poo-flow-session-policy-validation-receipts->alists)

;; : (-> POOObject Symbol Value Value)
(def (poo-flow-session-validation-slot policy key default)
  (with-catch
   (lambda (_failure) default)
   (lambda ()
     (.ref policy key))))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-session-validation-alist-ref row key default)
  (poo-flow-session-alist-ref row key default))

;; : (-> Any Symbol Value Value)
(def (poo-flow-session-validation-row-ref row key default)
  (if (list? row)
    (poo-flow-session-validation-alist-ref row key default)
    (poo-flow-session-validation-slot row key default)))

;; : (-> Any [Any] Boolean)
(def (poo-flow-session-validation-member? value values)
  (if (member value values) #t #f))

;; : (forall (a) (-> (List a) (List a) (List a)))
(def (poo-flow-session-validation-reverse-onto values tail)
  (if (null? values)
    tail
    (poo-flow-session-validation-reverse-onto
     (cdr values)
     (cons (car values) tail))))

;; : (-> Any [Any] Boolean)
(def (poo-flow-session-validation-granted? value values)
  (or (poo-flow-session-validation-member? value values)
      (poo-flow-session-validation-member? '* values)))

;; : (-> Procedure [Any] [Any] [Any] ([Any] [Any]))
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

;; : (-> Procedure [Any] ([Any] [Any]))
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

;; : (-> [Any] [Any] [Any])
(def (poo-flow-session-reverse-onto values tail)
  (let loop ((remaining-values values)
             (result tail))
    (if (null? remaining-values)
      result
      (loop (cdr remaining-values)
            (cons (car remaining-values) result)))))

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
  (list
   (cons 'kind 'poo-flow.session.policy.tool-attempt)
   (cons 'schema 'poo-flow.modules.session.policy.tool-attempt.v1)
   (cons 'attempt-id attempt-id)
   (cons 'trigger-ref trigger-ref)
   (cons 'tool-ref tool-ref)
   (cons 'action action)
   (cons 'resource-ref resource-ref)
   (cons 'principal-ref principal-ref)
   (cons 'metadata (if (null? maybe-metadata)
                     '()
                     (car maybe-metadata)))
   (cons 'runtime-executed #f)))

;; : (-> Any Boolean)
(def (poo-flow-session-policy-tool-attempt? value)
  (and (list? value)
       (eq? (poo-flow-session-validation-alist-ref value 'kind #f)
            'poo-flow.session.policy.tool-attempt)))

;; : PooSessionToolAttempt -> Value accessors
(defpoo-session-alist-accessors
  poo-flow-session-validation-alist-ref
  (poo-flow-session-policy-tool-attempt-id attempt-id #f)
  (poo-flow-session-policy-tool-attempt-trigger-ref trigger-ref #f)
  (poo-flow-session-policy-tool-attempt-tool-ref tool-ref #f)
  (poo-flow-session-policy-tool-attempt-action action #f)
  (poo-flow-session-policy-tool-attempt-resource-ref resource-ref #f)
  (poo-flow-session-policy-tool-attempt-principal-ref principal-ref #f))

;; : (-> Symbol Symbol Any Alist)
(def (poo-flow-session-policy-diagnostic code scope-ref detail)
  (list (cons 'kind 'poo-flow.session.policy.diagnostic)
        (cons 'schema 'poo-flow.modules.session.policy.diagnostic.v1)
        (cons 'code code)
        (cons 'scope-ref scope-ref)
        (cons 'detail detail)
        (cons 'severity 'error)
        (cons 'runtime-executed #f)))

;; : (-> PooSessionPolicy Symbol Value)
(def (poo-flow-session-policy-slot-value policy key default)
  (poo-flow-session-validation-slot policy key default))

;; : (-> PooSessionPolicy Symbol Value)
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
(def (poo-flow-session-policy-resource-capabilities policy)
  (poo-flow-session-policy-nested-slot policy 'capability-refs '()))

;; : (-> PooSessionPolicy Value)
(def (poo-flow-session-policy-resource-accounting-owner policy)
  (poo-flow-session-policy-nested-slot policy 'accounting-owner #f))

;; : (-> PooSessionPolicy [Alist])
(def (poo-flow-session-policy-resource-grants policy)
  (poo-flow-session-policy-slot-value policy 'resource-grants '()))

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

;; : (-> [Symbol] [Symbol] ([Symbol] [Symbol]))
(def (poo-flow-session-policy-partition-refs requested allowed)
  (poo-flow-session-validation-partition
   (lambda (value)
     (poo-flow-session-validation-granted? value allowed))
   requested))

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

;; : (-> MaybeToolCatalogValidationRow Symbol Value)
(def (poo-flow-session-tool-catalog-validation-ref validation-row key default)
  (if (poo-flow-session-tool-catalog-validation-present? validation-row)
    (poo-flow-session-validation-row-ref validation-row key default)
    default))

;; : (-> Symbol Symbol [Symbol] [Alist] [Alist])
(def (poo-flow-session-denied-ref-diagnostics/rev code
                                                   scope-ref
                                                   refs
                                                   diagnostics-rev)
  (cond
   ((null? refs) diagnostics-rev)
   (else
    (poo-flow-session-denied-ref-diagnostics/rev
     code
     scope-ref
     (cdr refs)
     (cons (poo-flow-session-policy-diagnostic
            code
            scope-ref
            (list (cons 'ref (car refs))))
           diagnostics-rev)))))

;; : (-> Symbol [PooSessionToolAttempt] [Alist] [Alist])
(def (poo-flow-session-tool-attempt-diagnostics/rev code
                                                     attempts
                                                     diagnostics-rev)
  (cond
   ((null? attempts) diagnostics-rev)
   (else
    (poo-flow-session-tool-attempt-diagnostics/rev
     code
     (cdr attempts)
     (cons (poo-flow-session-tool-attempt-diagnostic code (car attempts))
           diagnostics-rev)))))

;; : (-> PooSessionPolicy [PooSessionToolAttempt] [Alist] [Alist])
(def (poo-flow-session-hook-inheritance-diagnostics/rev agent-tool-policy
                                                        denied-hook-attempts
                                                        diagnostics-rev)
  (cond
   ((null? denied-hook-attempts) diagnostics-rev)
   (else
    (let (attempt (car denied-hook-attempts))
      (if (poo-flow-session-agent-tool-attempt-allowed?
           agent-tool-policy
           attempt)
        (poo-flow-session-hook-inheritance-diagnostics/rev
         agent-tool-policy
         (cdr denied-hook-attempts)
         (cons (poo-flow-session-tool-attempt-diagnostic
                'hook-tool-agent-permission-not-inherited
                attempt)
               diagnostics-rev))
        (poo-flow-session-hook-inheritance-diagnostics/rev
         agent-tool-policy
         (cdr denied-hook-attempts)
         diagnostics-rev))))))

;; : PooSessionPolicyValidationReceiptRecord
(defstruct poo-flow-session-policy-validation-receipt-record
  (validation-id
   scope-ref
   valid?
   effective-model-ref
   effective-prompt-session-ref
   effective-prompt-chunk-refs
   allowed-context-refs
   denied-context-refs
   allowed-history-records
   denied-history-records
   allowed-communication-channels
   denied-communication-channels
   allowed-resource-refs
   denied-resource-refs
   allowed-agent-tool-attempts
   denied-agent-tool-attempts
   allowed-hook-tool-attempts
   denied-hook-tool-attempts
   tool-catalog-validation-id
   tool-catalog-ref
   tool-catalog-valid?
   tool-catalog-resolved-tool-refs
   tool-catalog-unresolved-tool-refs
   tool-catalog-sandbox-required-tool-refs
   tool-catalog-action-mismatch-grants
   shared-resource-grants
   diagnostic-count
   diagnostics
   runtime-owner
   runtime-executed?
   metadata)
  transparent: #t)

;; : (-> Symbol Symbol PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy PooSessionPolicy [Symbol] [Symbol] [Symbol] [Symbol] [PooSessionToolAttempt] [PooSessionToolAttempt] [Alist] PooSessionPolicyValidationReceipt)
(def (poo-flow-session-policy-validation-receipt validation-id
                                                scope-ref
                                                model-policy
                                                prompt-policy
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
         (tool-catalog-validation
          (poo-flow-session-tool-catalog-validation metadata))
         (tool-catalog-diagnostics
          (poo-flow-session-tool-catalog-validation-ref
           tool-catalog-validation
           'diagnostics
           '()))
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
                 (diagnostics3
                  (poo-flow-session-denied-ref-diagnostics/rev
                   'resource-capability-not-granted
                   scope-ref
                   denied-resource-refs
                   diagnostics2))
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
                  (if (poo-flow-session-resource-policy-accounted?
                       sharing-policy)
                    diagnostics6
                    (cons (poo-flow-session-policy-diagnostic
                           'resource-sharing-missing-accounting-owner
                           scope-ref
                           (poo-flow-session-policy-resource-grants
                            sharing-policy))
                          diagnostics6)))
                 (diagnostics8
                  (poo-flow-session-validation-reverse-onto
                   tool-catalog-diagnostics
                   diagnostics7)))
            (reverse diagnostics8))))
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
     allowed-context-refs
     denied-context-refs
     allowed-history-records
     denied-history-records
     allowed-communication-channels
     denied-communication-channels
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
     (poo-flow-session-policy-resource-grants sharing-policy)
     (length diagnostics)
     diagnostics
     "marlin-agent-core"
     #f
     metadata)))

;; : (-> Any Boolean)
(def (poo-flow-session-policy-validation-receipt? value)
  (poo-flow-session-policy-validation-receipt-record? value))

;; : PooSessionPolicyValidationReceipt -> Value accessors
(defpoo-session-record-accessors
  (poo-flow-session-policy-validation-receipt-validation-id
   poo-flow-session-policy-validation-receipt-record-validation-id)
  (poo-flow-session-policy-validation-receipt-effective-model-ref
   poo-flow-session-policy-validation-receipt-record-effective-model-ref)
  (poo-flow-session-policy-validation-receipt-effective-prompt-session-ref
   poo-flow-session-policy-validation-receipt-record-effective-prompt-session-ref)
  (poo-flow-session-policy-validation-receipt-effective-prompt-chunk-refs
   poo-flow-session-policy-validation-receipt-record-effective-prompt-chunk-refs)
  (poo-flow-session-policy-validation-receipt-tool-catalog-valid?
   poo-flow-session-policy-validation-receipt-record-tool-catalog-valid?)
  (poo-flow-session-policy-validation-receipt-valid?
   poo-flow-session-policy-validation-receipt-record-valid?)
  (poo-flow-session-policy-validation-receipt-diagnostic-count
   poo-flow-session-policy-validation-receipt-record-diagnostic-count)
  (poo-flow-session-policy-validation-receipt-diagnostics
   poo-flow-session-policy-validation-receipt-record-diagnostics)
  (poo-flow-session-policy-validation-receipt-runtime-executed?
   poo-flow-session-policy-validation-receipt-record-runtime-executed?))

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
