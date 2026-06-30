;;; -*- Gerbil -*-
;;; Boundary: effective session policy validation receipts.
;;; Invariant: validation inspects composed POO policy objects and bounded
;;; attempt rows; it does not execute tools, hooks, communication, or runtime IO.

(import (only-in :clan/poo/object .ref object? object<-alist)
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy)

(export poo-flow-session-policy-tool-attempt
        poo-flow-session-policy-tool-attempt?
        poo-flow-session-policy-tool-attempt-id
        poo-flow-session-policy-tool-attempt-trigger-ref
        poo-flow-session-policy-tool-attempt-tool-ref
        poo-flow-session-policy-tool-attempt-action
        poo-flow-session-policy-validation-receipt
        poo-flow-session-policy-validation-receipt?
        poo-flow-session-policy-validation-receipt-valid?
        poo-flow-session-policy-validation-receipt-diagnostics)

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

;; : (-> Procedure [Any] [Any])
(def (poo-flow-session-validation-filter predicate values)
  (cond
   ((null? values) '())
   ((predicate (car values))
    (cons (car values)
          (poo-flow-session-validation-filter predicate (cdr values))))
   (else
    (poo-flow-session-validation-filter predicate (cdr values)))))

;; : (-> Procedure [Any] [Any])
(def (poo-flow-session-validation-remove predicate values)
  (poo-flow-session-validation-filter
   (lambda (value) (not (predicate value)))
   values))

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

;; : (-> PooSessionToolAttempt Symbol)
(def (poo-flow-session-policy-tool-attempt-id attempt)
  (poo-flow-session-validation-alist-ref attempt 'attempt-id #f))

;; : (-> PooSessionToolAttempt Symbol)
(def (poo-flow-session-policy-tool-attempt-trigger-ref attempt)
  (poo-flow-session-validation-alist-ref attempt 'trigger-ref #f))

;; : (-> PooSessionToolAttempt Symbol)
(def (poo-flow-session-policy-tool-attempt-tool-ref attempt)
  (poo-flow-session-validation-alist-ref attempt 'tool-ref #f))

;; : (-> PooSessionToolAttempt Symbol)
(def (poo-flow-session-policy-tool-attempt-action attempt)
  (poo-flow-session-validation-alist-ref attempt 'action #f))

;; : (-> PooSessionToolAttempt Symbol)
(def (poo-flow-session-policy-tool-attempt-resource-ref attempt)
  (poo-flow-session-validation-alist-ref attempt 'resource-ref #f))

;; : (-> PooSessionToolAttempt Symbol)
(def (poo-flow-session-policy-tool-attempt-principal-ref attempt)
  (poo-flow-session-validation-alist-ref attempt 'principal-ref #f))

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

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-session-policy-allowed-refs requested allowed)
  (poo-flow-session-validation-filter
   (lambda (value)
     (poo-flow-session-validation-granted? value allowed))
   requested))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-session-policy-denied-refs requested allowed)
  (poo-flow-session-validation-remove
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

;; : (-> Symbol Symbol [Symbol] [Alist])
(def (poo-flow-session-denied-ref-diagnostics code scope-ref refs)
  (map (lambda (ref)
         (poo-flow-session-policy-diagnostic
          code
          scope-ref
          (list (cons 'ref ref))))
       refs))

;; : (-> PooSessionPolicy PooSessionPolicy [PooSessionToolAttempt] [Alist])
(def (poo-flow-session-hook-inheritance-diagnostics agent-tool-policy
                                                    hook-tool-policy
                                                    hook-attempts)
  (apply append
         (map (lambda (attempt)
                (if (and (not (poo-flow-session-hook-tool-attempt-allowed?
                               hook-tool-policy
                               attempt))
                         (poo-flow-session-agent-tool-attempt-allowed?
                          agent-tool-policy
                          attempt))
                  (list (poo-flow-session-tool-attempt-diagnostic
                         'hook-tool-agent-permission-not-inherited
                         attempt))
                  '()))
              hook-attempts)))

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
  (let* ((allowed-context-refs
          (poo-flow-session-policy-allowed-refs
           requested-context-refs
           (poo-flow-session-policy-context-allowed context-policy)))
         (denied-context-refs
          (poo-flow-session-policy-denied-refs
           requested-context-refs
           (poo-flow-session-policy-context-allowed context-policy)))
         (allowed-history-records
          (poo-flow-session-policy-allowed-refs
           requested-history-records
           (poo-flow-session-policy-history-allowed history-policy)))
         (denied-history-records
          (poo-flow-session-policy-denied-refs
           requested-history-records
           (poo-flow-session-policy-history-allowed history-policy)))
         (allowed-communication-channels
          (poo-flow-session-policy-allowed-refs
           requested-channel-refs
           (poo-flow-session-policy-channel-allowed communication-policy)))
         (denied-communication-channels
          (poo-flow-session-policy-denied-refs
           requested-channel-refs
           (poo-flow-session-policy-channel-allowed communication-policy)))
         (allowed-resource-refs
          (poo-flow-session-policy-allowed-refs
           requested-resource-refs
           (poo-flow-session-policy-resource-capabilities resource-policy)))
         (denied-resource-refs
          (poo-flow-session-policy-denied-refs
           requested-resource-refs
           (poo-flow-session-policy-resource-capabilities resource-policy)))
         (allowed-agent-tool-attempts
          (poo-flow-session-validation-filter
           (lambda (attempt)
             (poo-flow-session-agent-tool-attempt-allowed?
              agent-tool-policy
              attempt))
           agent-tool-attempts))
         (denied-agent-tool-attempts
          (poo-flow-session-validation-remove
           (lambda (attempt)
             (poo-flow-session-agent-tool-attempt-allowed?
              agent-tool-policy
              attempt))
           agent-tool-attempts))
         (allowed-hook-tool-attempts
          (poo-flow-session-validation-filter
           (lambda (attempt)
             (poo-flow-session-hook-tool-attempt-allowed?
              hook-tool-policy
              attempt))
           hook-tool-attempts))
         (denied-hook-tool-attempts
          (poo-flow-session-validation-remove
           (lambda (attempt)
             (poo-flow-session-hook-tool-attempt-allowed?
              hook-tool-policy
              attempt))
           hook-tool-attempts))
         (diagnostics
          (append
           (poo-flow-session-denied-ref-diagnostics
            'context-session-not-granted
            scope-ref
            denied-context-refs)
           (poo-flow-session-denied-ref-diagnostics
            'history-record-not-granted
            scope-ref
            denied-history-records)
           (poo-flow-session-denied-ref-diagnostics
            'communication-channel-not-granted
            scope-ref
            denied-communication-channels)
           (poo-flow-session-denied-ref-diagnostics
            'resource-capability-not-granted
            scope-ref
            denied-resource-refs)
           (map (lambda (attempt)
                  (poo-flow-session-tool-attempt-diagnostic
                   'agent-tool-attempt-not-granted
                   attempt))
                denied-agent-tool-attempts)
           (map (lambda (attempt)
                  (poo-flow-session-tool-attempt-diagnostic
                   'hook-tool-attempt-not-granted
                   attempt))
                denied-hook-tool-attempts)
           (poo-flow-session-hook-inheritance-diagnostics
            agent-tool-policy
            hook-tool-policy
            hook-tool-attempts)
           (if (poo-flow-session-resource-policy-accounted? sharing-policy)
             '()
             (list (poo-flow-session-policy-diagnostic
                    'resource-sharing-missing-accounting-owner
                    scope-ref
                    (poo-flow-session-policy-resource-grants
                     sharing-policy)))))))
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

;; : (-> PooSessionPolicyValidationReceipt Boolean)
(def (poo-flow-session-policy-validation-receipt-valid? receipt)
  (.ref receipt 'valid?))

;; : (-> PooSessionPolicyValidationReceipt [Alist])
(def (poo-flow-session-policy-validation-receipt-diagnostics receipt)
  (.ref receipt 'diagnostics))
