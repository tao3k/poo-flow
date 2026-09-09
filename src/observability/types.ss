;;; -*- Gerbil -*-
;;; Boundary: native POO type and contract descriptors for observability.
;;; Invariant: validation dispatches through gerbil-poo descriptors; contract
;;; evidence is projected only after the semantic decision has been made.

(import :gerbil/gambit
        (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :clan/poo/mop define-type element? validate)
        (only-in :std/sugar cut)
        (only-in "../module-system/types.ss"
                 PooFlowContract.
                 PooFlowNativeObjectContract.
                 poo-flow-classification-evidence
                 poo-flow-contract-admit))

(export PooFlowObservabilityDiagnosticContract
        PooFlowObservationIdentityContract
        PooFlowObservationProvenanceContract
        PooFlowObservationContextContract
        PooFlowObservationFailureContract
        PooFlowObservationFactsContract
        PooFlowAdmissionObservationFactsContract
        PooFlowObservationContract
        PooFlowAdmissionObservationContract
        PooFlowObservationSummaryContract
        PooFlowAuthoringObservationContract
        PooFlowDebugCallPolicyContract
        PooFlowDebugCallReceiptContract
        PooFlowDebugSlotPolicyContract
        PooFlowDebugSlotReceiptContract
        PooFlowDebugMemoryPolicyContract
        PooFlowDebugMemorySampleContract
        PooFlowDebugMemoryReceiptContract
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

;;; Framework foundation: explicit native prototypes, independent of legacy
;;; feedback receipts and strict module-system presentation structs.
(def (poo-flow-observation-scalar-classify identity predicate candidate context)
  (let (accepted? (predicate candidate))
    (poo-flow-classification-evidence identity candidate accepted?
      (if accepted? '() '(invalid-observation-field)) context)))

;;; Invariant: symbolic observation fields remain closed over Scheme symbols.
(define-type (ObservationSymbol @ PooFlowContract.)
  identity: 'observation/symbol
  .classify: (cut poo-flow-observation-scalar-classify
                  'observation/symbol symbol? <> <>))

;;; Invariant: boolean observation fields reject truthy non-boolean values.
(define-type (ObservationBoolean @ PooFlowContract.)
  identity: 'observation/boolean
  .classify: (cut poo-flow-observation-scalar-classify
                  'observation/boolean boolean? <> <>))

(def (poo-flow-observation-natural? value)
  (and (exact-integer? value) (>= value 0)))

;;; Invariant: counts and budgets are exact nonnegative integers.
(define-type (ObservationNatural @ PooFlowContract.)
  identity: 'observation/natural
  .classify: (cut poo-flow-observation-scalar-classify
                  'observation/natural poo-flow-observation-natural? <> <>))

;;; Boundary: observable identities bind namespace, name, and revision together.
(define-type (PooFlowObservationIdentityContract @ PooFlowNativeObjectContract.)
  identity: 'observation/identity
  proto: (.o)
  responsibilities: (.o namespace: ObservationSymbol name: ObservationSymbol
                        revision: ObservationSymbol))

(def (poo-flow-observation-identities? value)
  (poo-flow-observability-list-of?
   (cut element? PooFlowObservationIdentityContract <>) value))

;;; Invariant: causal identity lists contain only admitted native identity objects.
(define-type (ObservationIdentities @ PooFlowContract.)
  identity: 'observation/identities
  .classify: (cut poo-flow-observation-scalar-classify
                  'observation/identities poo-flow-observation-identities? <> <>))

;;; Boundary: provenance records producer, provider, and phase without asserting authority.
(define-type (PooFlowObservationProvenanceContract @ PooFlowNativeObjectContract.)
  identity: 'observation/provenance
  proto: (.o)
  responsibilities: (.o producer: PooFlowObservationIdentityContract
                        provider: PooFlowObservationIdentityContract phase: ObservationSymbol))

;;; Invariant: context keeps identity lineage and its bounded disclosure budget in one value.
(define-type (PooFlowObservationContextContract @ PooFlowNativeObjectContract.)
  identity: 'observation/context
  proto: (.o)
  responsibilities: (.o identity: PooFlowObservationIdentityContract
                        source: PooFlowObservationIdentityContract
                        generation: PooFlowObservationIdentityContract
                        causes: ObservationIdentities
                        provenance: PooFlowObservationProvenanceContract
                        detail-budget: ObservationNatural))

(def (poo-flow-observation-path? value)
  (poo-flow-observability-list-of? symbol? value))

;;; Invariant: failure paths are structural symbol lists, not presentation strings.
(define-type (ObservationPath @ PooFlowContract.)
  identity: 'observation/path
  .classify: (cut poo-flow-observation-scalar-classify
                  'observation/path poo-flow-observation-path? <> <>))

(def (poo-flow-observation-slot-edge? value)
  (and (pair? value)
       (symbol? (car value))
       (symbol? (cdr value))))

(def (poo-flow-observation-slot-path? value)
  (poo-flow-observability-list-of?
   poo-flow-observation-slot-edge? value))

;;; Invariant: a slot path identifies each edge by receiver and slot symbols.
;;; Equal slot names on distinct guarded receivers are not recursive aliases.
(define-type (ObservationSlotPath @ PooFlowContract.)
  identity: 'observation/slot-path
  .classify: (cut poo-flow-observation-scalar-classify
                  'observation/slot-path
                  poo-flow-observation-slot-path? <> <>))

;;; Boundary: each failure binds its structural path to a contract and stable code.
(define-type (PooFlowObservationFailureContract @ PooFlowNativeObjectContract.)
  identity: 'observation/failure
  proto: (.o)
  responsibilities: (.o path: ObservationPath contract: ObservationSymbol code: ObservationSymbol))

(def (poo-flow-observation-failures? value)
  (poo-flow-observability-list-of?
   (cut element? PooFlowObservationFailureContract <>) value))

;;; Invariant: failure collections contain only admitted failure objects.
(define-type (ObservationFailures @ PooFlowContract.)
  identity: 'observation/failures
  .classify: (cut poo-flow-observation-scalar-classify
                  'observation/failures poo-flow-observation-failures? <> <>))

;;; Boundary: this empty responsibility base is the native extension point for fact families.
(define-type (PooFlowObservationFactsContract @ PooFlowNativeObjectContract.)
  identity: 'observation/facts
  proto: (.o)
  responsibilities: (.o))

(def PooFlowObservationFacts.
  (.ref PooFlowObservationFactsContract 'proto))

(def (poo-flow-admission-facts-obligations value _context)
  (if (and (eq? (.ref value 'accepted?)
                (and (.ref value 'classification-accepted?)
                     (zero? (.ref value 'obligation-count))))
           (or (not (.ref value 'accepted?)) (null? (.ref value 'failures)))
           (or (not (.ref value 'detail-complete?))
               (and (> (.ref value 'inspected-count) 0)
                    (or (.ref value 'accepted?) (pair? (.ref value 'failures)))))
           (>= (.ref value 'inspected-count) (length (.ref value 'failures))))
    '() '(inconsistent-admission-observation)))

;;; Invariant: admission facts must reconcile their decision, counts, and bounded failures.
(define-type (PooFlowAdmissionObservationFactsContract @ PooFlowObservationFactsContract)
  identity: 'observation/admission-facts
  proto: (.o (:: @ PooFlowObservationFacts.))
  responsibilities: (.o contract: ObservationSymbol accepted?: ObservationBoolean
                        classification-accepted?: ObservationBoolean
                        obligation-count: ObservationNatural
                        failures: ObservationFailures detail-complete?: ObservationBoolean
                        inspected-count: ObservationNatural)
  .obligations: poo-flow-admission-facts-obligations)

(def (poo-flow-observation-internal? value) (eq? value 'internal))
;;; Invariant: the initial framework admits only internal disclosure.
(define-type (ObservationDisclosure @ PooFlowContract.)
  identity: 'observation/disclosure
  .classify: (cut poo-flow-observation-scalar-classify
                  'observation/disclosure poo-flow-observation-internal? <> <>))

;;; Boundary: the event contract binds lineage, disclosure, and native evidence responsibilities.
(define-type (PooFlowObservationContract @ PooFlowNativeObjectContract.)
  identity: 'observation/event
  proto: (.o)
  responsibilities: (.o identity: PooFlowObservationIdentityContract
                        source: PooFlowObservationIdentityContract
                        generation: PooFlowObservationIdentityContract
                        causes: ObservationIdentities provenance: PooFlowObservationProvenanceContract
                        disclosure: ObservationDisclosure evidence: PooFlowObservationFactsContract))

(def PooFlowObservation.
  (.ref PooFlowObservationContract 'proto))

;;; Invariant: admission events refine the generic evidence slot with admission facts.
(define-type (PooFlowAdmissionObservationContract @ PooFlowObservationContract)
  identity: 'observation/admission-event
  proto: (.o (:: @ PooFlowObservation.))
  responsibilities: (.o (:: @ (.ref PooFlowObservationContract 'responsibilities))
                        evidence: PooFlowAdmissionObservationFactsContract))

;;; Boundary: only bounded aggregate scalars enter the default development renderer.
(define-type (PooFlowObservationSummaryContract @ PooFlowNativeObjectContract.)
  identity: 'observation/summary
  proto: (.o)
  responsibilities: (.o accepted?: ObservationBoolean detail-complete?: ObservationBoolean
                        failure-count: ObservationNatural inspected-count: ObservationNatural))

;;; Authoring observations are structural advice, not executed runtime facts.
;;; Their fixed phase and rejection polarity prevent a style diagnostic from
;;; being promoted into evidence that a Module or operation actually ran.
(def (poo-flow-authoring-observation-obligations observation _context)
  (if (and (eq? (.ref observation 'form) '.o)
           (eq? (.ref observation 'phase) 'object-construction)
           (eq? (.ref observation 'status) 'inline-prototype-lookup)
           (eq? (.ref observation 'code)
                'poo-prototype-lookup-inside-composition)
           (eq? (.ref observation 'recommendation)
                'bind-prototype-once-before-repeated-construction)
           (not (.ref observation 'accepted?))
           (not (.ref observation 'runtime-executed?)))
    '()
    '(inconsistent-authoring-observation)))

;;; Boundary: source inspection retains only symbolic owner and repair facts.
;;; It never retains the source datum, expanded syntax, object, or slot value.
(define-type (PooFlowAuthoringObservationContract @ PooFlowNativeObjectContract.)
  identity: 'observation/poo-authoring
  proto: (.o)
  responsibilities: (.o scope: ObservationSymbol
                        owner: ObservationSymbol
                        form: ObservationSymbol
                        phase: ObservationSymbol
                        status: ObservationSymbol
                        code: ObservationSymbol
                        recommendation: ObservationSymbol
                        accepted?: ObservationBoolean
                        runtime-executed?: ObservationBoolean)
  .obligations: poo-flow-authoring-observation-obligations)

;;; Boundary: traced calls carry an explicit depth budget.  The policy is a
;;; native POO value rather than an ambient global tracer setting.
(define-type (PooFlowDebugCallPolicyContract @ PooFlowNativeObjectContract.)
  identity: 'observation/debug-call-policy
  proto: (.o)
  responsibilities: (.o label: ObservationSymbol
                        maximum-depth: ObservationNatural))

;;; Boundary: call tracing retains only structural identities and categories.
;;; Arguments, results, receivers, and exceptions never enter this receipt.
(define-type (PooFlowDebugCallReceiptContract @ PooFlowNativeObjectContract.)
  identity: 'observation/debug-call-receipt
  proto: (.o)
  responsibilities: (.o policy: PooFlowDebugCallPolicyContract
                        call: ObservationSymbol
                        depth: ObservationNatural
                        active-path: ObservationPath
                        operator-kind: ObservationSymbol
                        outcome: ObservationSymbol
                        accepted?: ObservationBoolean
                        reason: ObservationSymbol))

;;; Boundary: lazy slot resolution has its own depth budget.  It is separate
;;; from the call policy because resolving a slot may precede procedure lookup.
;;; Invariant: the budget is positive.  A zero budget would misreport every
;;; first slot lookup as a runtime depth anomaly instead of policy rejection.
(def (poo-flow-debug-slot-policy-obligations policy _context)
  (if (> (.ref policy 'maximum-depth) 0)
    '()
    '(non-positive-maximum-slot-depth)))

;;; Boundary: this Contract owns debug-slot admission configuration only.
;;; A separate call policy cannot silently widen or disable its slot budget.
(define-type (PooFlowDebugSlotPolicyContract @ PooFlowNativeObjectContract.)
  identity: 'observation/debug-slot-policy
  proto: (.o)
  responsibilities: (.o label: ObservationSymbol
                        maximum-depth: ObservationNatural)
  .obligations: poo-flow-debug-slot-policy-obligations)

;;; Forged slot receipts cannot turn a cycle, excessive depth, or raised
;;; resolver into an accepted observation.  Depth always equals the bounded
;;; active path retained by the receipt.
(def (poo-flow-debug-slot-receipt-obligations receipt _context)
  (let* ((policy (.ref receipt 'policy))
         (receiver (.ref receipt 'receiver))
         (slot (.ref receipt 'slot))
         (edge (cons receiver slot))
         (depth (.ref receipt 'depth))
         (path (.ref receipt 'active-path))
         (outcome (.ref receipt 'outcome)))
    (let-values (((expected-accepted? expected-reason valid-boundary?)
                  (case outcome
                    ((admitted)
                     (values #t 'slot-resolution-admitted
                             (and (not (member edge path))
                                  (< depth (.ref policy 'maximum-depth)))))
                    ((resolved)
                     (values #t 'slot-resolved
                             (and (not (member edge path))
                                  (< depth (.ref policy 'maximum-depth)))))
                    ((raised)
                     (values #f 'slot-resolution-raised
                             (and (not (member edge path))
                                  (< depth (.ref policy 'maximum-depth)))))
                    ((rejected-cycle)
                     (values #f 'recursive-slot-resolution
                             (and (member edge path) #t)))
                    ((rejected-depth)
                     (values #f 'maximum-slot-depth-exceeded
                             (and (not (member edge path))
                                  (>= depth (.ref policy 'maximum-depth)))))
                    (else (values #f 'invalid-slot-outcome #f)))))
      (if (and (= depth (length path))
               valid-boundary?
               (eq? (.ref receipt 'accepted?) expected-accepted?)
               (eq? (.ref receipt 'reason) expected-reason))
        '()
        '(inconsistent-debug-slot-receipt)))))

;;; Boundary: slot receipts retain receiver/slot symbols and an active symbol
;;; path only.  The object, computed value, and original exception stay out.
(define-type (PooFlowDebugSlotReceiptContract @ PooFlowNativeObjectContract.)
  identity: 'observation/debug-slot-receipt
  proto: (.o)
  responsibilities: (.o policy: PooFlowDebugSlotPolicyContract
                        receiver: ObservationSymbol
                        slot: ObservationSymbol
                        depth: ObservationNatural
                        active-path: ObservationSlotPath
                        outcome: ObservationSymbol
                        accepted?: ObservationBoolean
                        reason: ObservationSymbol)
  .obligations: poo-flow-debug-slot-receipt-obligations)

;;; Boundary: a debug memory policy is an explicit POO value. The process
;;; launcher owns the independent Gambit heap ceiling used before this module
;;; can be loaded.
(define-type (PooFlowDebugMemoryPolicyContract @ PooFlowNativeObjectContract.)
  identity: 'observation/debug-memory-policy
  proto: (.o)
  responsibilities: (.o label: ObservationSymbol
                        heap-limit-bytes: ObservationNatural
                        live-growth-limit-bytes: ObservationNatural
                        sample-interval-milliseconds: ObservationNatural
                        collect-before-sample?: ObservationBoolean
                        fail-closed?: ObservationBoolean))

;;; Boundary: a sample projects Gerbil runtime counters into a native POO
;;; value; it never retains heap objects or exposes the runtime statistics row.
(define-type (PooFlowDebugMemorySampleContract @ PooFlowNativeObjectContract.)
  identity: 'observation/debug-memory-sample
  proto: (.o)
  responsibilities: (.o phase: ObservationSymbol
                        heap-size-bytes: ObservationNatural
                        allocated-bytes: ObservationNatural
                        live-bytes: ObservationNatural
                        movable-bytes: ObservationNatural
                        still-bytes: ObservationNatural))

(def (poo-flow-debug-memory-receipt-obligations receipt _context)
  (let* ((policy (.ref receipt 'policy))
         (after (.ref receipt 'after))
         (heap-exceeded?
          (> (.ref after 'heap-size-bytes)
             (.ref policy 'heap-limit-bytes)))
         (growth-exceeded?
          (> (.ref receipt 'live-growth-bytes)
             (.ref policy 'live-growth-limit-bytes)))
         (expected-reason
          (cond (heap-exceeded? 'heap-limit-exceeded)
                (growth-exceeded? 'live-growth-limit-exceeded)
                (else 'within-budget)))
         (expected-accepted?
          (and (not heap-exceeded?) (not growth-exceeded?))))
    (if (and (eq? (.ref receipt 'reason) expected-reason)
             (eq? (.ref receipt 'accepted?) expected-accepted?))
      '()
      '(inconsistent-debug-memory-receipt))))

;;; Invariant: a receipt binds one policy to two samples and a derived verdict.
;;; Negative deltas are normalized to zero by the pure constructor.
(define-type (PooFlowDebugMemoryReceiptContract @ PooFlowNativeObjectContract.)
  identity: 'observation/debug-memory-receipt
  proto: (.o)
  responsibilities: (.o phase: ObservationSymbol
                        policy: PooFlowDebugMemoryPolicyContract
                        before: PooFlowDebugMemorySampleContract
                        after: PooFlowDebugMemorySampleContract
                        heap-growth-bytes: ObservationNatural
                        live-growth-bytes: ObservationNatural
                        accepted?: ObservationBoolean
                        reason: ObservationSymbol)
  .obligations: poo-flow-debug-memory-receipt-obligations)
