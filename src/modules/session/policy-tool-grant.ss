;;; -*- Gerbil -*-
;;; Boundary: session tool grant rows, contracts, and grant matching.

(import :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy-syntax
        :poo-flow/src/modules/session/policy-core
        (only-in "../../utilities/contracts.ss"
                 poo-flow-contract-check-slot!
                 poo-flow-object-type-contract->alist)
        (only-in "../../utilities/contract-syntax.ss"
                 defcontract-family))

(export +poo-flow-session-tool-grant-slot-contracts+
        +poo-flow-session-tool-grant-type-contract+
        poo-flow-session-tool-grant
        poo-flow-session-tool-grant?
        poo-flow-session-tool-grant-type-contract->alist
        poo-flow-session-tool-grant-check-slot!
        poo-flow-session-tool-grant-require-slots!
        poo-flow-session-tool-grant-id
        poo-flow-session-tool-grant-tool-ref
        poo-flow-session-tool-grant-actions
        poo-flow-session-tool-grant-resource-refs
        poo-flow-session-tool-grant-trigger-refs
        poo-flow-session-tool-grant-allows?
        poo-flow-session-tool-grants-allow?)

;; : (-> Symbol Symbol [Symbol] [Symbol/String] [Symbol] [Alist] PooSessionToolGrant)
(def (poo-flow-session-tool-grant grant-id
                                  tool-ref
                                  actions
                                  resource-refs
                                  trigger-refs
                                  . maybe-metadata)
  (poo-flow-session-require "session tool grant id must be a symbol"
                            (symbol? grant-id)
                            grant-id)
  (poo-flow-session-require "session tool grant tool ref must be a symbol"
                            (symbol? tool-ref)
                            tool-ref)
  (poo-flow-session-require "session tool grant actions must be symbols"
                            (poo-flow-session-symbol-list? actions)
                            actions)
  (poo-flow-session-require
   "session tool grant resource refs must be symbols or strings"
   (poo-flow-session-policy-ref-list? resource-refs)
   resource-refs)
  (poo-flow-session-require "session tool grant trigger refs must be symbols"
                            (poo-flow-session-symbol-list? trigger-refs)
                            trigger-refs)
  (let (metadata (if (null? maybe-metadata) '() (car maybe-metadata)))
    (poo-flow-session-tool-grant-require-slots!
     'poo-flow.session.tool-grant
     'poo-flow.modules.session.tool-grant.v1
     grant-id
     tool-ref
     actions
     resource-refs
     trigger-refs
     metadata
     #f)
    (list
     (cons 'kind 'poo-flow.session.tool-grant)
     (cons 'schema 'poo-flow.modules.session.tool-grant.v1)
     (cons 'grant-id grant-id)
     (cons 'tool-ref tool-ref)
     (cons 'actions actions)
     (cons 'resource-refs resource-refs)
     (cons 'trigger-refs trigger-refs)
     (cons 'metadata metadata)
     (cons 'runtime-executed #f))))

;; : (-> Datum Boolean)
(def (poo-flow-session-tool-grant? value)
  (and (list? value)
       (eq? (poo-flow-session-alist-ref value 'kind #f)
            'poo-flow.session.tool-grant)))

;;; Boundary: generated tool-grant accessors keep the alist receipt API stable.
(defpoo-session-alist-accessors
  poo-flow-session-alist-ref
  (poo-flow-session-tool-grant-id grant-id #f)
  (poo-flow-session-tool-grant-tool-ref tool-ref #f)
  (poo-flow-session-tool-grant-actions actions '())
  (poo-flow-session-tool-grant-resource-refs resource-refs '())
  (poo-flow-session-tool-grant-trigger-refs trigger-refs '()))

(defcontract-family
  +poo-flow-session-tool-grant-slot-contracts+
  +poo-flow-session-tool-grant-type-contract+
  'session/tool-grant
  'session
  'PooSessionToolGrant
  '((boundary . session-policy) (runtime . marlin-agent-core))
  ((+poo-flow-session-tool-grant-kind-contract+
    'session.tool-grant/kind
    'kind
    'Symbol
    'poo-flow-session-tool-grant-kind-value?
    poo-flow-session-tool-grant-kind-value?
    #t
    '())
   (+poo-flow-session-tool-grant-schema-contract+
    'session.tool-grant/schema
    'schema
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+poo-flow-session-tool-grant-grant-id-contract+
    'session.tool-grant/grant-id
    'grant-id
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+poo-flow-session-tool-grant-tool-ref-contract+
    'session.tool-grant/tool-ref
    'tool-ref
    'Symbol
    'symbol?
    symbol?
    #t
    '())
   (+poo-flow-session-tool-grant-actions-contract+
    'session.tool-grant/actions
    'actions
    '[Symbol]
    'poo-flow-session-symbol-list?
    poo-flow-session-symbol-list?
    #t
    '())
   (+poo-flow-session-tool-grant-resource-refs-contract+
    'session.tool-grant/resource-refs
    'resource-refs
    '[Symbol/String]
    'poo-flow-session-policy-ref-list?
    poo-flow-session-policy-ref-list?
    #t
    '())
   (+poo-flow-session-tool-grant-trigger-refs-contract+
    'session.tool-grant/trigger-refs
    'trigger-refs
    '[Symbol]
    'poo-flow-session-symbol-list?
    poo-flow-session-symbol-list?
    #t
    '())
   (+poo-flow-session-tool-grant-metadata-contract+
    'session.tool-grant/metadata
    'metadata
    'Alist
    'poo-flow-session-policy-alist?
    poo-flow-session-policy-alist?
    #t
    '())
   (+poo-flow-session-tool-grant-runtime-executed-contract+
    'session.tool-grant/runtime-executed
    'runtime-executed
    'Boolean
    'poo-flow-session-policy-boolean?
    poo-flow-session-policy-boolean?
    #t
    '())))

;; poo-flow-session-tool-grant-type-contract->alist
;;   | contract: adjacent machine contract below defines the projection.
;;   | doc m%
;;       Project the structured contract for session tool grant rows.
;;       # Examples
;;       (poo-flow-session-tool-grant-type-contract->alist)
;;       # Result
;;       An alist representation suitable for policy diagnostics.
;;     %
;; : (-> Unit Alist)
(def (poo-flow-session-tool-grant-type-contract->alist)
  (poo-flow-object-type-contract->alist
   +poo-flow-session-tool-grant-type-contract+))

;; : (-> PooFlowSlotContract PooFlowValue PooFlowValue)
(def (poo-flow-session-tool-grant-check-slot! contract value)
  (poo-flow-contract-check-slot! contract value))

;; poo-flow-session-tool-grant-require-slots!
;;   | contract: adjacent machine contract below defines the tool grant gate.
;;   | doc m%
;;       Enforce generated slot contracts for one tool grant row. Tool execution
;;       remains outside Scheme; this gate only validates authorization data.
;;       # Examples
;;       (poo-flow-session-tool-grant-require-slots!
;;        'poo-flow.session.tool-grant schema grant tool actions resources triggers '() #f)
;;       # Result
;;       #t when every grant slot satisfies its contract.
;;     %
;; : (-> Symbol Symbol Symbol Symbol [Symbol] [Symbol/String] [Symbol] Alist Boolean Boolean)
(def (poo-flow-session-tool-grant-require-slots! kind
                                                 schema
                                                 grant-id
                                                 tool-ref
                                                 actions
                                                 resource-refs
                                                 trigger-refs
                                                 metadata
                                                 runtime-executed?)
  (poo-flow-session-tool-grant-check-slot!
   +poo-flow-session-tool-grant-kind-contract+
   kind)
  (poo-flow-session-tool-grant-check-slot!
   +poo-flow-session-tool-grant-schema-contract+
   schema)
  (poo-flow-session-tool-grant-check-slot!
   +poo-flow-session-tool-grant-grant-id-contract+
   grant-id)
  (poo-flow-session-tool-grant-check-slot!
   +poo-flow-session-tool-grant-tool-ref-contract+
   tool-ref)
  (poo-flow-session-tool-grant-check-slot!
   +poo-flow-session-tool-grant-actions-contract+
   actions)
  (poo-flow-session-tool-grant-check-slot!
   +poo-flow-session-tool-grant-resource-refs-contract+
   resource-refs)
  (poo-flow-session-tool-grant-check-slot!
   +poo-flow-session-tool-grant-trigger-refs-contract+
   trigger-refs)
  (poo-flow-session-tool-grant-check-slot!
   +poo-flow-session-tool-grant-metadata-contract+
   metadata)
  (poo-flow-session-tool-grant-check-slot!
   +poo-flow-session-tool-grant-runtime-executed-contract+
   runtime-executed?)
  #t)

;; : (-> PooSessionToolGrant Symbol Symbol Boolean)
(def (poo-flow-session-tool-grant-allows? grant tool-ref action)
  (and (poo-flow-session-tool-grant? grant)
       (poo-flow-session-policy-match?
        tool-ref
        (list (poo-flow-session-tool-grant-tool-ref grant)))
       (poo-flow-session-policy-match?
        action
        (poo-flow-session-tool-grant-actions grant))))

;; : (-> [PooSessionToolGrant] Symbol Symbol Boolean)
(def (poo-flow-session-tool-grants-allow? grants tool-ref action)
  (cond
   ((null? grants) #f)
   ((poo-flow-session-tool-grant-allows? (car grants) tool-ref action) #t)
   (else
    (poo-flow-session-tool-grants-allow? (cdr grants) tool-ref action))))
