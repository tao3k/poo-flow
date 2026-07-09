;;; -*- Gerbil -*-
;;; Observability: object-specific predicates and reusable contract declarations.

(import (only-in "../utilities/contracts.ss"
                 poo-flow-contract-alist?
                 poo-flow-contract-list-of?
                 poo-flow-contract-require!
                 poo-flow-contract-check-slot!)
        (only-in "../utilities/contract-syntax.ss"
                 defcontract-family))

(export +poo-flow-observability-diagnostic-slot-contracts+
        +poo-flow-observability-receipt-slot-contracts+
        +poo-flow-observability-diagnostic-type-contract+
        +poo-flow-observability-receipt-type-contract+
        poo-flow-observability-alist?
        poo-flow-observability-list-of?
        poo-flow-observability-source-ref?
        poo-flow-observability-severity?
        poo-flow-observability-boundary-ref?
        poo-flow-observability-validator-ref?
        poo-flow-observability-graph-node-ref?
        poo-flow-observability-graph-edge-ref?
        poo-flow-observability-reason?
        poo-flow-observability-message?
        poo-flow-observability-repair-target?
        poo-flow-observability-graph-shape?
        poo-flow-observability-repair-shape?
        poo-flow-observability-readiness-shape?
        poo-flow-observability-require!
        poo-flow-observability-check-slot!
        poo-flow-observability-require-diagnostic-slots!
        poo-flow-observability-require-receipt-slots!)

;; poo-flow-observability-alist?
;;   : (-> PooFlowValue Boolean)
;;   | doc m%
;;       Recognize observability metadata alists by delegating to utilities.
;;       # Examples
;;       (poo-flow-observability-alist? '((kind . graph) (valid? . #t)))
;;       # Result
;;       #t for proper association lists; #f otherwise.
;;     %
(def (poo-flow-observability-alist? value)
  (poo-flow-contract-alist? value))

;; poo-flow-observability-list-of?
;;   : (-> (-> PooFlowValue Boolean) [PooFlowValue] Boolean)
;;   | doc m%
;;       Recognize a proper observability list whose elements satisfy a predicate.
;;       # Examples
;;       (poo-flow-observability-list-of? symbol? '(a b c))
;;       # Result
;;       #t when the input is a proper list and every item passes.
;;     %
(def (poo-flow-observability-list-of? predicate values)
  (poo-flow-contract-list-of? predicate values))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-source-ref? value)
  (or (symbol? value)
      (string? value)
      (poo-flow-observability-alist? value)))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-severity? value)
  (and (symbol? value)
       (member value '(debug info warning error fatal))
       #t))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-boundary-ref? value)
  (symbol? value))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-validator-ref? value)
  (symbol? value))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-graph-node-ref? value)
  (or (not value)
      (symbol? value)
      (string? value)
      (poo-flow-observability-alist? value)))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-graph-edge-ref? value)
  (or (not value)
      (symbol? value)
      (string? value)
      (pair? value)
      (poo-flow-observability-alist? value)))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-reason? value)
  (symbol? value))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-message? value)
  (string? value))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-repair-target? value)
  (or (not value)
      (symbol? value)
      (string? value)
      (poo-flow-observability-alist? value)))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-graph-shape? value)
  (poo-flow-observability-alist? value))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-repair-shape? value)
  (and (poo-flow-observability-alist? value)
       (assq 'target-layer value)
       (assq 'repair-target value)
       #t))

;; : (-> PooFlowValue Boolean)
(def (poo-flow-observability-readiness-shape? value)
  (and (poo-flow-observability-alist? value)
       (assq 'state value)
       (assq 'valid? value)
       #t))

(defcontract-family
  +poo-flow-observability-diagnostic-slot-contracts+
  +poo-flow-observability-diagnostic-type-contract+
  'observability/diagnostic
  'observability
  'PooFlowObservabilityDiagnostic
  '((boundary . observability) (projection . diagnostic))
  ((+poo-flow-observability-diagnostic-severity-contract+
    'observability.diagnostic/severity
    'severity
    'Symbol
    'poo-flow-observability-severity?
    poo-flow-observability-severity?
    #t
    '())
   (+poo-flow-observability-diagnostic-boundary-contract+
    'observability.diagnostic/boundary
    'boundary
    'Symbol
    'poo-flow-observability-boundary-ref?
    poo-flow-observability-boundary-ref?
    #t
    '())
   (+poo-flow-observability-diagnostic-validator-contract+
    'observability.diagnostic/validator
    'validator
    'Symbol
    'poo-flow-observability-validator-ref?
    poo-flow-observability-validator-ref?
    #t
    '())
   (+poo-flow-observability-diagnostic-node-contract+
    'observability.diagnostic/node
    'node
    'PooFlowGraphNodeRef
    'poo-flow-observability-graph-node-ref?
    poo-flow-observability-graph-node-ref?
    #t
    '())
   (+poo-flow-observability-diagnostic-edge-contract+
    'observability.diagnostic/edge
    'edge
    'PooFlowGraphEdgeRef
    'poo-flow-observability-graph-edge-ref?
    poo-flow-observability-graph-edge-ref?
    #t
    '())
   (+poo-flow-observability-diagnostic-reason-contract+
    'observability.diagnostic/reason
    'reason
    'Symbol
    'poo-flow-observability-reason?
    poo-flow-observability-reason?
    #t
    '())
   (+poo-flow-observability-diagnostic-message-contract+
    'observability.diagnostic/message
    'message
    'String
    'poo-flow-observability-message?
    poo-flow-observability-message?
    #t
    '())
   (+poo-flow-observability-diagnostic-repair-target-contract+
    'observability.diagnostic/repair-target
    'repair-target
    'PooFlowRepairTarget
    'poo-flow-observability-repair-target?
    poo-flow-observability-repair-target?
    #t
    '())
   (+poo-flow-observability-diagnostic-artifacts-contract+
    'observability.diagnostic/artifacts
    'artifacts
    'Alist
    'poo-flow-observability-alist?
    poo-flow-observability-alist?
    #t
    '())))

(defcontract-family
  +poo-flow-observability-receipt-slot-contracts+
  +poo-flow-observability-receipt-type-contract+
  'observability/receipt
  'observability
  'PooFlowObservabilityReceipt
  '((boundary . observability) (projection . agent-feedback))
  ((+poo-flow-observability-receipt-schema-contract+
    'observability.receipt/schema
    'schema
    'String
    'string?
    string?
    #t
    '())
   (+poo-flow-observability-receipt-source-contract+
    'observability.receipt/source
    'source
    'PooFlowSourceRef
    'poo-flow-observability-source-ref?
    poo-flow-observability-source-ref?
    #t
    '())
   (+poo-flow-observability-receipt-graph-contract+
    'observability.receipt/graph
    'graph
    'Alist
    'poo-flow-observability-graph-shape?
    poo-flow-observability-graph-shape?
    #t
    '())
   (+poo-flow-observability-receipt-repair-contract+
    'observability.receipt/repair
    'repair
    'Alist
    'poo-flow-observability-repair-shape?
    poo-flow-observability-repair-shape?
    #t
    '())
   (+poo-flow-observability-receipt-readiness-contract+
    'observability.receipt/readiness
    'readiness
    'Alist
    'poo-flow-observability-readiness-shape?
    poo-flow-observability-readiness-shape?
    #t
    '())
   (+poo-flow-observability-receipt-artifacts-contract+
    'observability.receipt/artifacts
    'artifacts
    'Alist
    'poo-flow-observability-alist?
    poo-flow-observability-alist?
    #t
    '())))

;; poo-flow-observability-require!
;;   : (-> Symbol (-> PooFlowValue Boolean) PooFlowValue PooFlowValue)
;;   | doc m%
;;       Delegate low-level predicate enforcement to utilities.
;;       # Examples
;;       (poo-flow-observability-require! 'receipt.schema string? schema)
;;       # Result
;;       The original value when valid; raises a contract error when invalid.
;;     %
(def (poo-flow-observability-require! label predicate value)
  (poo-flow-contract-require! label predicate value))

;; poo-flow-observability-check-slot!
;;   : (-> PooFlowSlotContract PooFlowValue PooFlowValue)
;;   | doc m%
;;       Execute one observability slot contract through utilities.
;;       # Examples
;;       (poo-flow-observability-check-slot! slot-contract value)
;;       # Result
;;       The original value when valid; raises with the slot contract key when invalid.
;;     %
(def (poo-flow-observability-check-slot! contract value)
  (poo-flow-contract-check-slot! contract value))

;; poo-flow-observability-require-diagnostic-slots!
;;   : (-> Symbol Symbol Symbol PooFlowGraphNodeRef PooFlowGraphEdgeRef Symbol String PooFlowRepairTarget [Alist] Boolean)
;;   | doc m%
;;       Enforce diagnostic slot contracts generated by =defcontract-family=.
;;       # Examples
;;       (poo-flow-observability-require-diagnostic-slots!
;;        'error 'contract 'validator 'node #f 'reason "message" 'author '())
;;       # Result
;;       #t when every diagnostic slot satisfies its generated contract.
;;     %
(def (poo-flow-observability-require-diagnostic-slots! severity boundary validator node edge reason message repair-target artifacts)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-diagnostic-severity-contract+ severity)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-diagnostic-boundary-contract+ boundary)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-diagnostic-validator-contract+ validator)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-diagnostic-node-contract+ node)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-diagnostic-edge-contract+ edge)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-diagnostic-reason-contract+ reason)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-diagnostic-message-contract+ message)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-diagnostic-repair-target-contract+ repair-target)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-diagnostic-artifacts-contract+ artifacts)
  #t)

;; poo-flow-observability-require-receipt-slots!
;;   : (-> String PooFlowSourceRef Alist [PooFlowObservabilityDiagnostic] (-> PooFlowValue Boolean) Alist Alist [Alist] Boolean)
;;   | doc m%
;;       Enforce receipt slot contracts generated by =defcontract-family=.
;;       The diagnostic predicate comes from objects.ss to avoid a module cycle.
;;       # Examples
;;       (poo-flow-observability-require-receipt-slots!
;;        schema source graph diagnostics diagnostic? repair readiness artifacts)
;;       # Result
;;       #t when the receipt shape is legal.
;;     %
(def (poo-flow-observability-require-receipt-slots! schema source graph diagnostics diagnostic? repair readiness artifacts)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-receipt-schema-contract+ schema)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-receipt-source-contract+ source)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-receipt-graph-contract+ graph)
  (poo-flow-observability-require!
   'observability.receipt/diagnostics
   (lambda (value)
     (poo-flow-observability-list-of? diagnostic? value))
   diagnostics)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-receipt-repair-contract+ repair)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-receipt-readiness-contract+ readiness)
  (poo-flow-observability-check-slot!
   +poo-flow-observability-receipt-artifacts-contract+ artifacts)
  #t)
