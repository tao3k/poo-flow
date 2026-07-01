;;; -*- Gerbil -*-
;;; Boundary: effective session policy validation receipts.
;;; Invariant: validation inspects composed POO policy objects and bounded
;;; attempt rows; it does not execute tools, hooks, communication, or runtime IO.

(import (only-in :clan/poo/object .ref object? object<-alist)
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy
        :poo-flow/src/modules/session/policy-syntax)

(export poo-flow-session-policy-tool-attempt
        poo-flow-session-policy-tool-attempt?
        poo-flow-session-policy-tool-attempt-id
        poo-flow-session-policy-tool-attempt-trigger-ref
        poo-flow-session-policy-tool-attempt-tool-ref
        poo-flow-session-policy-tool-attempt-action
        poo-flow-session-policy-validation-receipt
        poo-flow-session-policy-validation-receipt?
        poo-flow-session-policy-validation-receipt-valid?
        poo-flow-session-policy-validation-receipt-diagnostics
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

;; : (-> Any [Any] Boolean)
(def (poo-flow-session-validation-member? value values)
  (if (member value values) #t #f))

;; : (-> Any [Any] Boolean)
(def (poo-flow-session-validation-granted? value values)
  (or (poo-flow-session-validation-member? value values)
      (poo-flow-session-validation-member? '* values)))

;; : (-> Procedure [Any] ([Any] [Any]))
(def (poo-flow-session-validation-partition predicate values)
  (cond
   ((null? values) (list '() '()))
   (else
    (let* ((value (car values))
           (tail-partition
            (poo-flow-session-validation-partition predicate (cdr values)))
           (accepted-values (car tail-partition))
           (rejected-values (cadr tail-partition)))
      (if (predicate value)
        (list (cons value accepted-values) rejected-values)
        (list accepted-values (cons value rejected-values)))))))

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

;; : (-> PooSessionPolicy PooSessionPolicy [PooSessionToolAttempt] [Alist] [Alist])
(def (poo-flow-session-hook-inheritance-diagnostics/rev agent-tool-policy
                                                        hook-tool-policy
                                                        hook-attempts
                                                        diagnostics-rev)
  (cond
   ((null? hook-attempts) diagnostics-rev)
   (else
    (let (attempt (car hook-attempts))
      (if (and (not (poo-flow-session-hook-tool-attempt-allowed?
                     hook-tool-policy
                     attempt))
               (poo-flow-session-agent-tool-attempt-allowed?
                agent-tool-policy
                attempt))
        (poo-flow-session-hook-inheritance-diagnostics/rev
         agent-tool-policy
         hook-tool-policy
         (cdr hook-attempts)
         (cons (poo-flow-session-tool-attempt-diagnostic
                'hook-tool-agent-permission-not-inherited
                attempt)
               diagnostics-rev))
        (poo-flow-session-hook-inheritance-diagnostics/rev
         agent-tool-policy
         hook-tool-policy
         (cdr hook-attempts)
         diagnostics-rev))))))

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
                   hook-tool-policy
                   hook-tool-attempts
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
                          diagnostics6))))
            (reverse diagnostics7))))
    (object<-alist
     (list
      (cons 'kind 'poo-flow.session.policy-validation-receipt)
      (cons 'schema 'poo-flow.modules.session.policy-validation-receipt.v1)
      (cons 'validation-id validation-id)
      (cons 'scope-ref scope-ref)
      (cons 'valid? (null? diagnostics))
      (cons 'effective-model-ref
            (poo-flow-session-policy-slot-value model-policy 'model-ref #f))
      (cons 'effective-prompt-session-ref
            (poo-flow-session-policy-slot-value
             prompt-policy
             'prompt-session-ref
             #f))
      (cons 'effective-prompt-chunk-refs
            (poo-flow-session-policy-slot-value
             prompt-policy
             'prompt-chunk-refs
             '()))
      (cons 'allowed-context-refs allowed-context-refs)
      (cons 'denied-context-refs denied-context-refs)
      (cons 'allowed-history-records allowed-history-records)
      (cons 'denied-history-records denied-history-records)
      (cons 'allowed-communication-channels
            allowed-communication-channels)
      (cons 'denied-communication-channels
            denied-communication-channels)
      (cons 'allowed-resource-refs allowed-resource-refs)
      (cons 'denied-resource-refs denied-resource-refs)
      (cons 'allowed-agent-tool-attempts allowed-agent-tool-attempts)
      (cons 'denied-agent-tool-attempts denied-agent-tool-attempts)
      (cons 'allowed-hook-tool-attempts allowed-hook-tool-attempts)
      (cons 'denied-hook-tool-attempts denied-hook-tool-attempts)
      (cons 'shared-resource-grants
            (poo-flow-session-policy-resource-grants sharing-policy))
      (cons 'diagnostic-count (length diagnostics))
      (cons 'diagnostics diagnostics)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f)
      (cons 'metadata (if (null? maybe-metadata)
                        '()
                        (car maybe-metadata)))))))

;; : (-> POOObject Boolean)
(def (poo-flow-session-policy-validation-receipt? value)
  (and (object? value)
       (eq? (.ref value 'kind)
            'poo-flow.session.policy-validation-receipt)))

;; : PooSessionPolicyValidationReceipt -> Value accessors
(defpoo-session-object-accessors
  .ref
  (poo-flow-session-policy-validation-receipt-valid? valid?)
  (poo-flow-session-policy-validation-receipt-diagnostics diagnostics))

;; : (-> PooSessionPolicyValidationReceipt Alist)
(defpoo-session-object-projection
  poo-flow-session-policy-validation-receipt->alist
  (receipt)
  (require poo-flow-session-require
           "session policy validation projection requires a receipt"
           poo-flow-session-policy-validation-receipt?)
  (object-reader .ref)
  (rows
   (slot kind)
   (slot schema)
   (slot validation-id)
   (slot scope-ref)
   (slot valid?)
   (slot effective-model-ref)
   (slot effective-prompt-session-ref)
   (slot effective-prompt-chunk-refs)
   (slot allowed-context-refs)
   (slot denied-context-refs)
   (slot allowed-history-records)
   (slot denied-history-records)
   (slot allowed-communication-channels)
   (slot denied-communication-channels)
   (slot allowed-resource-refs)
   (slot denied-resource-refs)
   (slot allowed-agent-tool-attempts)
   (slot denied-agent-tool-attempts)
   (slot allowed-hook-tool-attempts)
   (slot denied-hook-tool-attempts)
   (slot shared-resource-grants)
   (slot diagnostic-count)
   (slot diagnostics)
   (slot runtime-owner)
   (slot runtime-executed)
   (slot metadata)))

;; : (-> [PooSessionPolicyValidationReceipt] [Alist])
(defpoo-session-object-projection-batch
  poo-flow-session-policy-validation-receipts->alists (receipts)
  (projector poo-flow-session-policy-validation-receipt->alist)
  (error-message "session policy validation projection requires a list"))
