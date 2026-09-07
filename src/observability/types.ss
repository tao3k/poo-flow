;;; -*- Gerbil -*-
;;; Boundary: native POO type and contract descriptors for observability.
;;; Invariant: validation dispatches through gerbil-poo descriptors; contract
;;; evidence is projected only after the semantic decision has been made.

(import :gerbil/gambit
        (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :clan/poo/mop define-type element? validate)
        (only-in "../module-system/types.ss"
                 PooFlowContract.
                 poo-flow-classification-evidence
                 poo-flow-contract-admit))

(export PooFlowObservabilityDiagnosticContract
        PooFlowObservabilityReceiptContract
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
        poo-flow-observability-diagnostic-contract-evidence
        poo-flow-observability-receipt-contract-evidence
        poo-flow-observability-diagnostic-contract?
        poo-flow-observability-receipt-contract?
        poo-flow-observability-require-diagnostic!
        poo-flow-observability-require-receipt!)

(def (poo-flow-observability-alist? value)
  (and (list? value) (andmap pair? value)))

(def (poo-flow-observability-list-of? predicate values)
  (and (list? values) (andmap predicate values)))

(def (poo-flow-observability-source-ref? value)
  (or (symbol? value) (string? value) (poo-flow-observability-alist? value)))

(def (poo-flow-observability-severity? value)
  (and (symbol? value)
       (if (member value '(debug info warning error fatal)) #t #f)))

(def (poo-flow-observability-boundary-ref? value) (symbol? value))
(def (poo-flow-observability-validator-ref? value) (symbol? value))

(def (poo-flow-observability-graph-node-ref? value)
  (or (not value) (symbol? value) (string? value)
      (poo-flow-observability-alist? value)))

(def (poo-flow-observability-graph-edge-ref? value)
  (or (not value) (symbol? value) (string? value) (pair? value)
      (poo-flow-observability-alist? value)))

(def (poo-flow-observability-reason? value) (symbol? value))
(def (poo-flow-observability-message? value) (string? value))

(def (poo-flow-observability-repair-target? value)
  (or (not value) (symbol? value) (string? value)
      (poo-flow-observability-alist? value)))

(def (poo-flow-observability-graph-shape? value)
  (poo-flow-observability-alist? value))

(def (poo-flow-observability-repair-shape? value)
  (and (poo-flow-observability-alist? value)
       (assq 'target-layer value) (assq 'repair-target value) #t))

(def (poo-flow-observability-readiness-shape? value)
  (and (poo-flow-observability-alist? value)
       (assq 'state value) (assq 'valid? value) #t))

(def (poo-flow-observability-object-slots? candidate slots)
  (and (object? candidate)
       (andmap (lambda (slot) (.slot? candidate slot)) slots)))

(def (poo-flow-observability-obligation-failure contract-identity-value
                                                  slot-value expected-value)
  (.o kind: 'poo-flow.contract.obligation-failure
      contract-identity: contract-identity-value
      slot: slot-value
      expected: expected-value))

(def (poo-flow-observability-check-obligation candidate contract-identity
                                                slot predicate expected)
  (if (predicate (.ref candidate slot))
    '()
    (list (poo-flow-observability-obligation-failure
           contract-identity slot expected))))

(def +poo-flow-observability-diagnostic-slots+
  '(family severity boundary validator node edge reason message repair-target artifacts))

(def +poo-flow-observability-receipt-slots+
  '(family schema source graph diagnostics repair readiness artifacts))

(def (poo-flow-observability-classification identity slots candidate context)
  (let (accepted? (poo-flow-observability-object-slots? candidate slots))
    (poo-flow-classification-evidence
     identity candidate accepted?
     (if accepted? '()
         (list (poo-flow-observability-obligation-failure
                identity 'object-shape 'POOObject)))
     context)))

(def (poo-flow-observability-diagnostic-classify candidate context)
  (poo-flow-observability-classification
   'observability/diagnostic
   +poo-flow-observability-diagnostic-slots+
   candidate context))

(def (poo-flow-observability-diagnostic-obligations candidate _context)
  (append
   (poo-flow-observability-check-obligation candidate 'observability/diagnostic
    'family (lambda (value) (eq? value 'observability/diagnostic)) 'observability/diagnostic)
   (poo-flow-observability-check-obligation candidate 'observability/diagnostic
    'severity poo-flow-observability-severity? 'ObservabilitySeverity)
   (poo-flow-observability-check-obligation candidate 'observability/diagnostic
    'boundary poo-flow-observability-boundary-ref? 'Symbol)
   (poo-flow-observability-check-obligation candidate 'observability/diagnostic
    'validator poo-flow-observability-validator-ref? 'Symbol)
   (poo-flow-observability-check-obligation candidate 'observability/diagnostic
    'node poo-flow-observability-graph-node-ref? 'GraphNodeRef)
   (poo-flow-observability-check-obligation candidate 'observability/diagnostic
    'edge poo-flow-observability-graph-edge-ref? 'GraphEdgeRef)
   (poo-flow-observability-check-obligation candidate 'observability/diagnostic
    'reason poo-flow-observability-reason? 'Symbol)
   (poo-flow-observability-check-obligation candidate 'observability/diagnostic
    'message poo-flow-observability-message? 'String)
   (poo-flow-observability-check-obligation candidate 'observability/diagnostic
    'repair-target poo-flow-observability-repair-target? 'RepairTarget)
   (poo-flow-observability-check-obligation candidate 'observability/diagnostic
    'artifacts poo-flow-observability-alist? 'Alist)))

;;; Diagnostic contract: classification fixes the kind while obligations validate every diagnostic field.
(define-type (PooFlowObservabilityDiagnosticContract @ PooFlowContract.)
  identity: 'observability/diagnostic
  .classify: poo-flow-observability-diagnostic-classify
  .obligations: poo-flow-observability-diagnostic-obligations)

(def (poo-flow-observability-diagnostic-contract? candidate)
  (element? PooFlowObservabilityDiagnosticContract candidate))

(def (poo-flow-observability-diagnostic-contract-evidence candidate)
  (poo-flow-contract-admit
   PooFlowObservabilityDiagnosticContract candidate 'observability))

(def (poo-flow-observability-diagnostic-list? value)
  (poo-flow-observability-list-of?
   poo-flow-observability-diagnostic-contract? value))

(def (poo-flow-observability-receipt-classify candidate context)
  (poo-flow-observability-classification
   'observability/receipt
   +poo-flow-observability-receipt-slots+
   candidate context))

(def (poo-flow-observability-receipt-obligations candidate _context)
  (append
   (poo-flow-observability-check-obligation candidate 'observability/receipt
    'family (lambda (value) (eq? value 'observability/receipt)) 'observability/receipt)
   (poo-flow-observability-check-obligation candidate 'observability/receipt
    'schema string? 'String)
   (poo-flow-observability-check-obligation candidate 'observability/receipt
    'source poo-flow-observability-source-ref? 'SourceRef)
   (poo-flow-observability-check-obligation candidate 'observability/receipt
    'graph poo-flow-observability-graph-shape? 'GraphProjection)
   (poo-flow-observability-check-obligation candidate 'observability/receipt
    'diagnostics poo-flow-observability-diagnostic-list? 'DiagnosticList)
   (poo-flow-observability-check-obligation candidate 'observability/receipt
    'repair poo-flow-observability-repair-shape? 'RepairProjection)
   (poo-flow-observability-check-obligation candidate 'observability/receipt
    'readiness poo-flow-observability-readiness-shape? 'ReadinessProjection)
   (poo-flow-observability-check-obligation candidate 'observability/receipt
    'artifacts poo-flow-observability-alist? 'Alist)))

;;; Receipt contract: admission requires graph, diagnostic, repair, readiness, and artifact projections.
(define-type (PooFlowObservabilityReceiptContract @ PooFlowContract.)
  identity: 'observability/receipt
  .classify: poo-flow-observability-receipt-classify
  .obligations: poo-flow-observability-receipt-obligations)

(def (poo-flow-observability-receipt-contract? candidate)
  (element? PooFlowObservabilityReceiptContract candidate))

(def (poo-flow-observability-receipt-contract-evidence candidate)
  (poo-flow-contract-admit
   PooFlowObservabilityReceiptContract candidate 'observability))

(def (poo-flow-observability-require-diagnostic! candidate)
  (validate PooFlowObservabilityDiagnosticContract candidate))

(def (poo-flow-observability-require-receipt! candidate)
  (validate PooFlowObservabilityReceiptContract candidate))
