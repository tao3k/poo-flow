(import (only-in :clan/poo/object .o .ref))

(export poo-flow-tool-call-plan
        poo-flow-tool-call-runtime-receipt
        poo-flow-tool-call-plan-proof-facts
        poo-flow-tool-call-runtime-proof-facts
        poo-flow-tool-call-plan-valid?
        poo-flow-tool-call-receipt-matches-plan?
        poo-flow-tool-call-trace-covers?
        poo-flow-tool-call-output-authorizes-policy?
        poo-flow-tool-call-fact-ref)

(def (poo-flow-list-contains? xs x)
  (if (member x xs) #t #f))

(def (poo-flow-list-subset? xs ys)
  (let loop ((rest xs))
    (cond
     ((null? rest) #t)
     ((poo-flow-list-contains? ys (car rest))
      (loop (cdr rest)))
     (else #f))))

(def (poo-flow-truthy? value)
  (and value #t))

(def (poo-flow-tool-call-entry entry-key entry-value)
  (.o (kind 'poo-flow-tool-call-entry)
      (key entry-key)
      (value entry-value)))

(def (poo-flow-tool-call-entry-index entries)
  (let loop ((rest entries) (index '()))
    (if (null? rest)
      (reverse index)
      (let ((entry (car rest)))
        (loop (cdr rest)
              (cons (cons (.ref entry 'key)
                          (.ref entry 'value))
                    index))))))

(def (poo-flow-tool-call-index-ref object key)
  (let ((pair (assq key (.ref object 'index))))
    (and pair (cdr pair))))

(def (poo-flow-tool-call-plan plan-name
                              owner-session
                              tool
                              schema-keys
                              required-keys
                              permission
                              sandbox-scope
                              cooldown
                              result-contract
                              runtime-binding
                              trace-obligations)
  (let* ((plan-entry-list
          (list (poo-flow-tool-call-entry 'owner-session owner-session)
                (poo-flow-tool-call-entry 'tool tool)
                (poo-flow-tool-call-entry 'schema-keys schema-keys)
                (poo-flow-tool-call-entry 'required-keys required-keys)
                (poo-flow-tool-call-entry 'permission permission)
                (poo-flow-tool-call-entry 'sandbox-scope sandbox-scope)
                (poo-flow-tool-call-entry 'cooldown cooldown)
                (poo-flow-tool-call-entry 'result-contract result-contract)
                (poo-flow-tool-call-entry 'runtime-binding runtime-binding)
                (poo-flow-tool-call-entry 'trace-obligations trace-obligations)))
         (plan-index-cache
          (poo-flow-tool-call-entry-index plan-entry-list)))
    (.o (kind 'poo-flow-tool-call-plan)
        (name plan-name)
        (entries plan-entry-list)
        (index plan-index-cache))))

(def (poo-flow-tool-call-runtime-receipt receipt-name
                                        owner-session
                                        tool
                                        argument-keys
                                        permission-granted?
                                        sandbox-contained?
                                        arguments-valid?
                                        cooldown-satisfied?
                                        result-accepted?
                                        runtime-binding
                                        trace
                                        output-authorizes-policy?
                                        status)
  (let* ((receipt-entry-list
          (list (poo-flow-tool-call-entry 'owner-session owner-session)
                (poo-flow-tool-call-entry 'tool tool)
                (poo-flow-tool-call-entry 'argument-keys argument-keys)
                (poo-flow-tool-call-entry 'permission-granted? permission-granted?)
                (poo-flow-tool-call-entry 'sandbox-contained? sandbox-contained?)
                (poo-flow-tool-call-entry 'arguments-valid? arguments-valid?)
                (poo-flow-tool-call-entry 'cooldown-satisfied? cooldown-satisfied?)
                (poo-flow-tool-call-entry 'result-accepted? result-accepted?)
                (poo-flow-tool-call-entry 'runtime-binding runtime-binding)
                (poo-flow-tool-call-entry 'trace trace)
                (poo-flow-tool-call-entry 'output-authorizes-policy?
                                          output-authorizes-policy?)
                (poo-flow-tool-call-entry 'status status)))
         (receipt-index-cache
          (poo-flow-tool-call-entry-index receipt-entry-list)))
    (.o (kind 'poo-flow-tool-call-runtime-receipt)
        (name receipt-name)
        (entries receipt-entry-list)
        (index receipt-index-cache))))

(def (poo-flow-tool-call-plan-valid? plan)
  (let ((owner-session (poo-flow-tool-call-index-ref plan 'owner-session))
        (tool (poo-flow-tool-call-index-ref plan 'tool))
        (schema-keys (poo-flow-tool-call-index-ref plan 'schema-keys))
        (required-keys (poo-flow-tool-call-index-ref plan 'required-keys))
        (permission (poo-flow-tool-call-index-ref plan 'permission))
        (sandbox-scope (poo-flow-tool-call-index-ref plan 'sandbox-scope))
        (cooldown (poo-flow-tool-call-index-ref plan 'cooldown))
        (result-contract (poo-flow-tool-call-index-ref plan 'result-contract))
        (runtime-binding (poo-flow-tool-call-index-ref plan 'runtime-binding)))
    (and (poo-flow-truthy? owner-session)
         (poo-flow-truthy? tool)
         (poo-flow-list-subset? required-keys schema-keys)
         (poo-flow-truthy? permission)
         (poo-flow-truthy? sandbox-scope)
         (poo-flow-truthy? cooldown)
         (poo-flow-truthy? result-contract)
         (poo-flow-truthy? runtime-binding))))

(def (poo-flow-tool-call-arguments-match-plan? plan receipt)
  (let ((argument-keys (poo-flow-tool-call-index-ref receipt 'argument-keys))
        (schema-keys (poo-flow-tool-call-index-ref plan 'schema-keys))
        (required-keys (poo-flow-tool-call-index-ref plan 'required-keys)))
    (and (poo-flow-list-subset? required-keys argument-keys)
         (poo-flow-list-subset? argument-keys schema-keys))))

(def (poo-flow-tool-call-trace-covers? plan receipt)
  (poo-flow-list-subset? (poo-flow-tool-call-index-ref plan 'trace-obligations)
                         (poo-flow-tool-call-index-ref receipt 'trace)))

(def (poo-flow-tool-call-output-authorizes-policy? receipt)
  (if (poo-flow-tool-call-index-ref receipt 'output-authorizes-policy?) #t #f))

(def (poo-flow-tool-call-receipt-matches-plan? plan receipt)
  (let ((plan-owner-session
         (poo-flow-tool-call-index-ref plan 'owner-session))
        (plan-tool
         (poo-flow-tool-call-index-ref plan 'tool))
        (plan-runtime-binding
         (poo-flow-tool-call-index-ref plan 'runtime-binding))
        (receipt-owner-session
         (poo-flow-tool-call-index-ref receipt 'owner-session))
        (receipt-tool
         (poo-flow-tool-call-index-ref receipt 'tool))
        (receipt-runtime-binding
         (poo-flow-tool-call-index-ref receipt 'runtime-binding))
        (permission-granted?
         (poo-flow-tool-call-index-ref receipt 'permission-granted?))
        (sandbox-contained?
         (poo-flow-tool-call-index-ref receipt 'sandbox-contained?))
        (arguments-valid?
         (poo-flow-tool-call-index-ref receipt 'arguments-valid?))
        (cooldown-satisfied?
         (poo-flow-tool-call-index-ref receipt 'cooldown-satisfied?))
        (result-accepted?
         (poo-flow-tool-call-index-ref receipt 'result-accepted?))
        (status
         (poo-flow-tool-call-index-ref receipt 'status)))
    (and (equal? plan-owner-session receipt-owner-session)
         (equal? plan-tool receipt-tool)
         (equal? plan-runtime-binding receipt-runtime-binding)
         (poo-flow-tool-call-arguments-match-plan? plan receipt)
         permission-granted?
         sandbox-contained?
         arguments-valid?
         cooldown-satisfied?
         result-accepted?
         (not (poo-flow-tool-call-output-authorizes-policy? receipt))
         (poo-flow-tool-call-trace-covers? plan receipt)
         (equal? status 'completed))))

(def (poo-flow-tool-call-fact-set fact-set-name fact-entry-list)
  (.o (kind 'poo-flow-tool-call-fact-set)
      (name fact-set-name)
      (entries fact-entry-list)
      (index (poo-flow-tool-call-entry-index fact-entry-list))))

(def (poo-flow-tool-call-fact-ref facts key)
  (poo-flow-tool-call-index-ref facts key))

(def (poo-flow-tool-call-plan-proof-facts plan)
  (let ((owner-session (poo-flow-tool-call-index-ref plan 'owner-session))
        (tool (poo-flow-tool-call-index-ref plan 'tool))
        (schema-keys (poo-flow-tool-call-index-ref plan 'schema-keys))
        (required-keys (poo-flow-tool-call-index-ref plan 'required-keys))
        (permission (poo-flow-tool-call-index-ref plan 'permission))
        (sandbox-scope (poo-flow-tool-call-index-ref plan 'sandbox-scope))
        (cooldown (poo-flow-tool-call-index-ref plan 'cooldown))
        (result-contract (poo-flow-tool-call-index-ref plan 'result-contract))
        (runtime-binding (poo-flow-tool-call-index-ref plan 'runtime-binding))
        (trace-obligations
         (poo-flow-tool-call-index-ref plan 'trace-obligations)))
    (poo-flow-tool-call-fact-set
     'poo-flow.tool-calling.control
     (list
      (poo-flow-tool-call-entry 'source 'poo-flow.tool-calling.control)
      (poo-flow-tool-call-entry 'tool-request-has-owner-session
                                (poo-flow-truthy? owner-session))
      (poo-flow-tool-call-entry 'declared-tool
                                (poo-flow-truthy? tool))
      (poo-flow-tool-call-entry 'tool-arguments-match-schema
                                (poo-flow-list-subset? required-keys
                                                       schema-keys))
      (poo-flow-tool-call-entry 'tool-permission-before-call
                                (poo-flow-truthy? permission))
      (poo-flow-tool-call-entry 'tool-scope-contained
                                (poo-flow-truthy? sandbox-scope))
      (poo-flow-tool-call-entry 'cooldown-before-retry
                                (poo-flow-truthy? cooldown))
      (poo-flow-tool-call-entry 'tool-result-before-downstream-step
                                (poo-flow-truthy? result-contract))
      (poo-flow-tool-call-entry 'runtime-binding-matches-tool-contract
                                (poo-flow-truthy? runtime-binding))
      (poo-flow-tool-call-entry 'trace-obligations-declared
                                (poo-flow-truthy? trace-obligations))
      (poo-flow-tool-call-entry 'plan-valid
                                (and (poo-flow-truthy? owner-session)
                                     (poo-flow-truthy? tool)
                                     (poo-flow-list-subset? required-keys
                                                            schema-keys)
                                     (poo-flow-truthy? permission)
                                     (poo-flow-truthy? sandbox-scope)
                                     (poo-flow-truthy? cooldown)
                                     (poo-flow-truthy? result-contract)
                                     (poo-flow-truthy? runtime-binding)))))))

(def (poo-flow-tool-call-runtime-proof-facts plan receipt)
  (let ((plan-owner-session
         (poo-flow-tool-call-index-ref plan 'owner-session))
        (plan-runtime-binding
         (poo-flow-tool-call-index-ref plan 'runtime-binding))
        (receipt-owner-session
         (poo-flow-tool-call-index-ref receipt 'owner-session))
        (receipt-runtime-binding
         (poo-flow-tool-call-index-ref receipt 'runtime-binding))
        (permission-granted?
         (poo-flow-tool-call-index-ref receipt 'permission-granted?))
        (sandbox-contained?
         (poo-flow-tool-call-index-ref receipt 'sandbox-contained?))
        (arguments-valid?
         (poo-flow-tool-call-index-ref receipt 'arguments-valid?))
        (cooldown-satisfied?
         (poo-flow-tool-call-index-ref receipt 'cooldown-satisfied?))
        (result-accepted?
         (poo-flow-tool-call-index-ref receipt 'result-accepted?)))
    (poo-flow-tool-call-fact-set
     'poo-flow.tool-calling.control.runtime
     (list
      (poo-flow-tool-call-entry 'source 'poo-flow.tool-calling.control.runtime)
      (poo-flow-tool-call-entry 'tool-request-has-owner-session
                                (equal? plan-owner-session
                                        receipt-owner-session))
      (poo-flow-tool-call-entry 'tool-arguments-match-schema
                                (poo-flow-tool-call-arguments-match-plan?
                                 plan receipt))
      (poo-flow-tool-call-entry 'tool-permission-before-call
                                permission-granted?)
      (poo-flow-tool-call-entry 'tool-scope-contained
                                sandbox-contained?)
      (poo-flow-tool-call-entry 'validate-arguments-before-runtime
                                arguments-valid?)
      (poo-flow-tool-call-entry 'tool-output-cannot-authorize-policy
                                (not (poo-flow-tool-call-output-authorizes-policy?
                                      receipt)))
      (poo-flow-tool-call-entry 'cooldown-before-retry
                                cooldown-satisfied?)
      (poo-flow-tool-call-entry 'tool-result-before-downstream-step
                                result-accepted?)
      (poo-flow-tool-call-entry 'runtime-binding-matches-tool-contract
                                (equal? plan-runtime-binding
                                        receipt-runtime-binding))
      (poo-flow-tool-call-entry 'runtime-receipt-matches-tool-plan
                                (poo-flow-tool-call-receipt-matches-plan?
                                 plan receipt))
      (poo-flow-tool-call-entry 'trace-covers-tool-request-call-result
                                (poo-flow-tool-call-trace-covers?
                                 plan receipt))))))
