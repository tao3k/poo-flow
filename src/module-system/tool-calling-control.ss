;;; Boundary: tool-calling control owns the policy-visible proof surface between
;;; Scheme workflow intent and runtime tool execution.
;;; Invariant: validation proof facts must stay deterministic and independent
;;; from provider transport side effects.
(import (only-in :clan/poo/object .o .ref))

(export poo-flow-tool-call-plan
        poo-flow-tool-call-runtime-receipt
        poo-flow-tool-call-fact-family
        poo-flow-tool-call-fact-family-build
        poo-flow-tool-call-fact-family-ref
        poo-flow-tool-call-runtime-validation-proof-facts
        poo-flow-tool-call-mediated-receipt
        poo-flow-tool-call-fact-ref)

;; : (-> PooObject PooObject PooObject PooObject)
(def (poo-flow-tool-call-mediated-receipt runtime token-validation
                                          token-consumption)
  (unless (.ref token-validation 'accepted?)
    (error "tool call requires an accepted AuthorizedEffectToken"))
  (unless (eq? (.ref token-consumption 'outcome) 'committed)
    (error "tool call requires a committed token consumption receipt"))
  (.o (kind 'poo-flow-tool-call-mediated-receipt)
      (runtime-receipt runtime)
      (token-id (.ref token-consumption 'token-id))
      (nonce (.ref token-consumption 'nonce))
      (semantic-root (.ref token-consumption 'semantic-root))
      (execution-root (.ref token-consumption 'execution-root))
      (durability (.ref token-consumption 'durability))
      (status 'committed)))

;; : (-> Object Boolean)
(def (poo-flow-truthy? value)
  (if value #t #f))

;; : (-> [Symbol] [Symbol] Boolean)
(def (poo-flow-list-subset? expected actual)
  (andmap (lambda (value) (memq value actual)) expected))

;; : (-> Symbol Object PooObject)
(def (poo-flow-tool-call-entry entry-key entry-value)
  (.o (kind 'poo-flow-tool-call-entry)
      (key entry-key)
      (value entry-value)))

;; : (-> [PooObject] Alist)
(def (poo-flow-tool-call-entry-index entry-list)
  (foldl
   (lambda (entry index-cache)
     (cons (cons (.ref entry 'key) (.ref entry 'value))
           index-cache))
   '()
   entry-list))

;; : (-> PooObject Symbol Object)
(def (poo-flow-tool-call-index-ref object key)
  (let ((cell (assq key (.ref object 'index))))
    (and cell (cdr cell))))

;; : (-> Symbol Symbol PooObject)
(def (poo-flow-tool-call-fact-family family-name source-tag)
  (.o (kind 'poo-flow-tool-call-fact-family)
      (name family-name)
      (source source-tag)))

;; : (-> PooObject Alist Alist)
(def (poo-flow-tool-call-fact-family-pairs family fact-pair-list)
  (let* ((family-name (.ref family 'name))
         (source-tag (.ref family 'source))
         (family-pairs
          (if (assq 'fact-family fact-pair-list)
            fact-pair-list
            (cons (cons 'fact-family family-name) fact-pair-list))))
    (if (or (not source-tag) (assq 'source family-pairs))
      family-pairs
      (cons (cons 'source source-tag) family-pairs))))

;; : (-> PooObject Alist PooObject)
(def (poo-flow-tool-call-fact-family-build family fact-pair-list)
  (let* ((pairs (poo-flow-tool-call-fact-family-pairs
                 family
                 fact-pair-list))
         (entries
          (map (lambda (fact-pair)
                 (poo-flow-tool-call-entry (car fact-pair) (cdr fact-pair)))
               pairs))
         (index-cache pairs))
    (.o (kind 'poo-flow-tool-call-fact-set)
        (family family)
        (name (.ref family 'name))
        (entries entries)
        (index index-cache))))

;; : (-> Symbol Alist PooObject)
(def (poo-flow-tool-call-fact-set fact-set-name fact-pair-list)
  (poo-flow-tool-call-fact-family-build
   (poo-flow-tool-call-fact-family fact-set-name #f)
   fact-pair-list))

;; : (-> PooObject Symbol Object)
(def (poo-flow-tool-call-fact-ref facts key)
  (poo-flow-tool-call-index-ref facts key))

;; : (-> PooObject PooObject Symbol Object)
(def (poo-flow-tool-call-fact-family-ref family facts key)
  (and (equal? (.ref family 'name)
               (poo-flow-tool-call-fact-ref facts 'fact-family))
       (poo-flow-tool-call-fact-ref facts key)))

;; : PooObject
(def +poo-flow-tool-call-runtime-validation-fact-family+
  (poo-flow-tool-call-fact-family
   'poo-flow-tool-call-runtime-validation-proof-facts
   'poo-flow.tool-calling.control.runtime))

;; : (-> Symbol Symbol Symbol [Symbol] [Symbol] Symbol Symbol Symbol Symbol Symbol [Symbol] PooObject)
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
          (list
           (poo-flow-tool-call-entry 'name plan-name)
           (poo-flow-tool-call-entry 'owner-session owner-session)
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

;; : (-> Symbol Symbol Symbol [Symbol] Boolean Boolean Boolean Boolean Boolean Symbol [Symbol] Boolean Symbol PooObject)
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
          (list
           (poo-flow-tool-call-entry 'name receipt-name)
           (poo-flow-tool-call-entry 'owner-session owner-session)
           (poo-flow-tool-call-entry 'tool tool)
           (poo-flow-tool-call-entry 'argument-keys argument-keys)
           (poo-flow-tool-call-entry 'permission-granted?
                                     permission-granted?)
           (poo-flow-tool-call-entry 'sandbox-contained?
                                     sandbox-contained?)
           (poo-flow-tool-call-entry 'arguments-valid? arguments-valid?)
           (poo-flow-tool-call-entry 'cooldown-satisfied?
                                     cooldown-satisfied?)
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

;;; Boundary: validation proof facts expose tool-call runtime decisions without
;;; calling provider execution again or mutating receipt state.
;; : (-> PooObject PooObject PooObject)
(def (poo-flow-tool-call-runtime-validation-proof-facts plan receipt)
  (let* ((plan-owner-session
          (poo-flow-tool-call-index-ref plan 'owner-session))
         (plan-tool
          (poo-flow-tool-call-index-ref plan 'tool))
         (schema-keys
          (poo-flow-tool-call-index-ref plan 'schema-keys))
         (required-keys
          (poo-flow-tool-call-index-ref plan 'required-keys))
         (permission
          (poo-flow-tool-call-index-ref plan 'permission))
         (sandbox-scope
          (poo-flow-tool-call-index-ref plan 'sandbox-scope))
         (cooldown
          (poo-flow-tool-call-index-ref plan 'cooldown))
         (result-contract
          (poo-flow-tool-call-index-ref plan 'result-contract))
         (plan-runtime-binding
          (poo-flow-tool-call-index-ref plan 'runtime-binding))
         (trace-obligations
          (poo-flow-tool-call-index-ref plan 'trace-obligations))
         (receipt-owner-session
          (poo-flow-tool-call-index-ref receipt 'owner-session))
         (receipt-tool
          (poo-flow-tool-call-index-ref receipt 'tool))
         (argument-keys
          (poo-flow-tool-call-index-ref receipt 'argument-keys))
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
         (receipt-runtime-binding
          (poo-flow-tool-call-index-ref receipt 'runtime-binding))
         (trace
          (poo-flow-tool-call-index-ref receipt 'trace))
         (output-authorizes-policy?
          (poo-flow-tool-call-index-ref receipt 'output-authorizes-policy?))
         (status
          (poo-flow-tool-call-index-ref receipt 'status))
         (owner-session? (poo-flow-truthy? plan-owner-session))
         (declared-tool? (poo-flow-truthy? plan-tool))
         (plan-arguments-match-schema?
          (poo-flow-list-subset? required-keys schema-keys))
         (permission? (poo-flow-truthy? permission))
         (scope? (poo-flow-truthy? sandbox-scope))
         (cooldown? (poo-flow-truthy? cooldown))
         (result? (poo-flow-truthy? result-contract))
         (runtime-binding? (poo-flow-truthy? plan-runtime-binding))
         (plan-valid?
          (and owner-session?
               declared-tool?
               plan-arguments-match-schema?
               permission?
               scope?
               cooldown?
               result?
               runtime-binding?))
         (same-owner-session?
          (equal? plan-owner-session receipt-owner-session))
         (same-tool?
          (equal? plan-tool receipt-tool))
         (same-runtime-binding?
          (equal? plan-runtime-binding receipt-runtime-binding))
         (arguments-match-plan?
          (and (poo-flow-list-subset? required-keys argument-keys)
               (poo-flow-list-subset? argument-keys schema-keys)))
         (trace-covers?
          (poo-flow-list-subset? trace-obligations trace))
         (output-cannot-authorize-policy?
          (not (poo-flow-truthy? output-authorizes-policy?)))
         (receipt-matches-plan?
          (and same-owner-session?
               same-tool?
               same-runtime-binding?
               arguments-match-plan?
               permission-granted?
               sandbox-contained?
               arguments-valid?
               cooldown-satisfied?
               result-accepted?
               output-cannot-authorize-policy?
               trace-covers?
               (equal? status 'completed))))
    (poo-flow-tool-call-fact-family-build
     +poo-flow-tool-call-runtime-validation-fact-family+
     (list
      (cons 'source 'poo-flow.tool-calling.control.runtime)
      (cons 'plan-valid plan-valid?)
      (cons 'tool-request-has-owner-session same-owner-session?)
      (cons 'declared-tool declared-tool?)
      (cons 'tool-arguments-match-schema arguments-match-plan?)
      (cons 'tool-permission-before-call permission-granted?)
      (cons 'tool-scope-contained sandbox-contained?)
      (cons 'validate-arguments-before-runtime arguments-valid?)
      (cons 'tool-output-cannot-authorize-policy
            output-cannot-authorize-policy?)
      (cons 'cooldown-before-retry cooldown-satisfied?)
      (cons 'tool-result-before-downstream-step result-accepted?)
      (cons 'runtime-binding-matches-tool-contract same-runtime-binding?)
      (cons 'runtime-receipt-matches-tool-plan receipt-matches-plan?)
      (cons 'trace-covers-tool-request-call-result trace-covers?)))))
