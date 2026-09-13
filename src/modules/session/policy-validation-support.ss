;;; -*- Gerbil -*-
;;; Boundary: shared pure helpers for session policy validation.

(import (only-in :std/srfi/1 fold)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy-syntax
        :poo-flow/src/modules/session/receipt-syntax)

(export poo-flow-session-validation-slot
        poo-flow-session-validation-alist-ref
        poo-flow-session-validation-row-ref
        poo-flow-session-policy-validation-field-rows
        poo-flow-session-validation-member?
        poo-flow-session-validation-reverse-onto
        poo-flow-session-validation-granted?
        poo-flow-session-validation-partition/rev
        poo-flow-session-validation-partition
        poo-flow-session-validation-partition-accepted
        poo-flow-session-validation-partition-rejected
        poo-flow-session-validation-partition/with-context/rev
        poo-flow-session-validation-partition/with-context
        poo-flow-session-reverse-onto
        poo-flow-session-policy-tool-attempt
        poo-flow-session-policy-tool-attempt?
        poo-flow-session-policy-tool-attempt-id
        poo-flow-session-policy-tool-attempt-trigger-ref
        poo-flow-session-policy-tool-attempt-tool-ref
        poo-flow-session-policy-tool-attempt-action
        poo-flow-session-policy-tool-attempt-resource-ref
        poo-flow-session-policy-tool-attempt-principal-ref
        poo-flow-session-policy-diagnostic
        poo-flow-session-policy-slot-value
        poo-flow-session-policy-nested-slot
        poo-flow-session-policy-context-allowed
        poo-flow-session-policy-history-allowed
        poo-flow-session-policy-channel-allowed
        poo-flow-session-policy-communication-targets
        poo-flow-session-policy-resource-capabilities
        poo-flow-session-policy-resource-accounting-owner
        poo-flow-session-policy-resource-grants
        poo-flow-session-policy-isolation-mode
        poo-flow-session-policy-isolation-sibling-context
        poo-flow-session-policy-isolation-parent-write
        poo-flow-session-policy-isolation-peer-communication
        poo-flow-session-policy-sandbox-profile-ref
        poo-flow-session-policy-sandbox-inheritance-mode
        poo-flow-session-policy-sandbox-sharing-mode
        poo-flow-session-policy-sibling-context-allowed?
        poo-flow-session-policy-denied-sibling-context-refs
        poo-flow-session-resource-grant-accounted?
        poo-flow-session-resource-policy-accounted?
        poo-flow-session-policy-partition-refs)

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

;;; Boundary: callers construct explicit field pairs; this helper preserves
;;; their order without adding a second syntax layer over ordinary values.
;; : (-> (List (Pair Symbol Object)) (List (Pair Symbol Object)))
(def (poo-flow-session-policy-validation-field-rows . rows)
  rows)

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

;;; Partition selectors centralize the internal two-list protocol so receipt
;;; assembly does not repeat shape dispatch for every policy family.
;; : (-> SessionValidationPartition List)
(def (poo-flow-session-validation-partition-accepted partition)
  (car partition))

;; : (-> SessionValidationPartition List)
(def (poo-flow-session-validation-partition-rejected partition)
  (cadr partition))

;; : (forall (c a) (-> (-> c a Boolean) c (List a) (List a) (List a) SessionValidationPartition))
;; : (-> Procedure Object List List List SessionValidationPartition)
(def (poo-flow-session-validation-partition/with-context/rev predicate
                                                                context
                                                                values
                                                                accepted-rev
                                                                rejected-rev)
  (cond
   ((null? values) (list accepted-rev rejected-rev))
   ((predicate context (car values))
    (poo-flow-session-validation-partition/with-context/rev
     predicate
     context
     (cdr values)
     (cons (car values) accepted-rev)
     rejected-rev))
   (else
    (poo-flow-session-validation-partition/with-context/rev
     predicate
     context
     (cdr values)
     accepted-rev
     (cons (car values) rejected-rev)))))

;; : (forall (c a) (-> (-> c a Boolean) c (List a) SessionValidationPartition))
;; : (-> Procedure Object List SessionValidationPartition)
(def (poo-flow-session-validation-partition/with-context predicate context values)
  (let* ((partition
          (poo-flow-session-validation-partition/with-context/rev
           predicate
           context
           values
           '()
           '()))
         (accepted-values-rev (car partition))
         (rejected-values-rev (cadr partition)))
    (list (reverse accepted-values-rev)
          (reverse rejected-values-rev))))

;; : (forall (a) (-> (List a) (List a) (List a)))
;; : (-> List List List)
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

;; : (-> Datum Boolean)
(def (poo-flow-session-policy-tool-attempt? value)
  (and (list? value)
       (eq? (poo-flow-session-validation-alist-ref value 'kind #f)
            'poo-flow.session.policy.tool-attempt)))

;; : (-> Alist MaybeSymbol)
(def (poo-flow-session-policy-tool-attempt-id attempt)
  (poo-flow-session-validation-alist-ref attempt 'attempt-id #f))

;; : (-> Alist MaybeSymbol)
(def (poo-flow-session-policy-tool-attempt-trigger-ref attempt)
  (poo-flow-session-validation-alist-ref attempt 'trigger-ref #f))

;; : (-> Alist MaybeSymbol)
(def (poo-flow-session-policy-tool-attempt-tool-ref attempt)
  (poo-flow-session-validation-alist-ref attempt 'tool-ref #f))

;; : (-> Alist MaybeSymbol)
(def (poo-flow-session-policy-tool-attempt-action attempt)
  (poo-flow-session-validation-alist-ref attempt 'action #f))

;; : (-> Alist MaybeSymbol)
(def (poo-flow-session-policy-tool-attempt-resource-ref attempt)
  (poo-flow-session-validation-alist-ref attempt 'resource-ref #f))

;; : (-> Alist MaybeSymbol)
(def (poo-flow-session-policy-tool-attempt-principal-ref attempt)
  (poo-flow-session-validation-alist-ref attempt 'principal-ref #f))

;; : (-> Symbol Symbol Datum Alist)
(def (poo-flow-session-policy-diagnostic code scope-ref detail)
  (poo-flow-session-policy-validation-field-rows
   (cons 'kind 'poo-flow.session.policy.diagnostic)
   (cons 'schema 'poo-flow.modules.session.policy.diagnostic.v1)
   (cons 'code code)
   (cons 'scope-ref scope-ref)
   (cons 'detail detail)
   (cons 'severity 'error)
   (cons 'runtime-executed #f)))

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
