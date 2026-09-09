;;; -*- Gerbil -*-
;;; Observability: POO Flow feedback evidence object protocol.
;;; Invariant: diagnostics and receipts are Scheme-side evidence products;
;;; runtime manifests and proof rows are projections, not semantic owners.

(import (only-in :clan/poo/object .def .o .ref object?)
        (only-in :clan/poo/mop .defgeneric validate)
        (only-in "../types.ss" poo-flow-contract-admit)
        (only-in "../object-family/syntax.ss" defpoo-object-family)
        "funcs.ss"
        (only-in "./types.ss"
                 PooFlowObservationIdentityContract PooFlowObservationProvenanceContract
                 PooFlowObservationContextContract PooFlowAdmissionObservationContract
                 poo-flow-observability-diagnostic-contract?
                 poo-flow-observability-receipt-contract?
                 poo-flow-observability-require-diagnostic!
                 poo-flow-observability-require-receipt!))

(export poo-flow-observability-event-prototype
        poo-flow-admission-observation-prototype
        poo-flow-observation-identity
        poo-flow-observation-provenance
        poo-flow-observation-context
        poo-flow-observe-admission-evidence
        poo-flow-observe-contract-admission
        poo-flow-observation-explain
        poo-flow-observation-summary
        poo-flow-observability-span-prototype
        poo-flow-observability-diagnostic-prototype
        poo-flow-observability-receipt-prototype
        poo-flow-observability-projection-prototype
        +poo-flow-observability-object-families+
        poo-flow-observability-family?
        poo-flow-observability-prototype?
        poo-flow-observability-prototype-id
        poo-flow-observability-prototype->alist
        poo-flow-observability-diagnostic?
        poo-flow-observability-diagnostic-family
        poo-flow-observability-diagnostic-severity
        poo-flow-observability-diagnostic-boundary
        poo-flow-observability-diagnostic-validator
        poo-flow-observability-diagnostic-node
        poo-flow-observability-diagnostic-edge
        poo-flow-observability-diagnostic-reason
        poo-flow-observability-diagnostic-message
        poo-flow-observability-diagnostic-repair-target
        poo-flow-observability-diagnostic-artifacts
        poo-flow-observability-diagnostic-record
        poo-flow-observability-diagnostic-code
        poo-flow-observability-diagnostic->alist
        poo-flow-observability-receipt?
        poo-flow-observability-receipt-family
        poo-flow-observability-receipt-schema
        poo-flow-observability-receipt-source
        poo-flow-observability-receipt-graph
        poo-flow-observability-receipt-diagnostics
        poo-flow-observability-receipt-repair
        poo-flow-observability-receipt-readiness
        poo-flow-observability-receipt-artifacts
        poo-flow-observability-receipt-record
        poo-flow-observability-receipt-valid?
        poo-flow-observability-receipt-diagnostic-codes
        poo-flow-observability-receipt-next-action
        poo-flow-observability-graph
        poo-flow-observability-repair
        poo-flow-observability-readiness
        poo-flow-observability-feedback-receipt
        poo-flow-observability-domain-next-action
        poo-flow-observability-agent-feedback
        poo-flow-observability-receipt->alist)

(def ObservationIdentity.
  (.ref PooFlowObservationIdentityContract 'proto))
(def ObservationProvenance.
  (.ref PooFlowObservationProvenanceContract 'proto))
(def ObservationContext.
  (.ref PooFlowObservationContextContract 'proto))
(def AdmissionObservation.
  (.ref PooFlowAdmissionObservationContract 'proto))

;; +poo-flow-observability-object-families+
;;   : [Symbol]
;;   | doc m%
;;       Canonical observability object families. Module-specific diagnostics
;;       extend these families instead of adding central string-only cases.
;;     %
(def +poo-flow-observability-object-families+
  '(observability/event
    observability/span
    observability/diagnostic
    observability/receipt
    observability/projection))

;; : (POOObject Symbol Symbol [Symbol] [Symbol])
(.def poo-flow-observability-event-prototype
  id: 'observability/event
  boundary: 'observability
  owns: '(atomic-evidence state-change validation-fact projection-fact)
  requires: '(source-provenance evidence-kind))

;; : (POOObject Symbol Symbol [Symbol] [Symbol])
(.def poo-flow-observability-span-prototype
  id: 'observability/span
  boundary: 'observability
  owns: '(bounded-operation graph-rebuild validator-run projection-run)
  requires: '(source-provenance start-event end-event))

;; : (POOObject Symbol Symbol [Symbol] [Symbol])
(.def poo-flow-observability-diagnostic-prototype
  id: 'observability/diagnostic
  boundary: 'observability
  owns: '(validator-owned-rejection graph-positioned-finding repair-target)
  requires: '(severity validator reason repair-target))

;; : (POOObject Symbol Symbol [Symbol] [Symbol])
(.def poo-flow-observability-receipt-prototype
  id: 'observability/receipt
  boundary: 'observability
  owns: '(agent-feedback graph-diagnostics repair-readiness drill-down-artifacts)
  requires: '(graph diagnostics repair readiness))

;; : (POOObject Symbol Symbol [Symbol] [Symbol])
(.def poo-flow-observability-projection-prototype
  id: 'observability/projection
  boundary: 'observability
  owns: '(doctor-report graph-preview proof-preview runtime-preview)
  requires: '(producer source-receipt projection-kind))

;; : (-> PooFlowObservabilityFamilyCandidate Boolean)
(def (poo-flow-observability-family? family)
  (and (symbol? family)
       (member family +poo-flow-observability-object-families+)
       #t))

;; : (-> PooFlowObservabilityPrototypeCandidate Boolean)
(def (poo-flow-observability-prototype? value)
  (and (object? value)
       (with-catch
        (lambda (_failure) #f)
        (lambda ()
          (poo-flow-observability-family? (.ref value 'id))))))

;; : (-> PooFlowObservabilityPrototype Symbol)
(def (poo-flow-observability-prototype-id prototype)
  (.ref prototype 'id))

;; : (-> PooFlowObservabilityPrototype Alist)
(def (poo-flow-observability-prototype->alist prototype)
  (list
   (cons 'id (.ref prototype 'id))
   (cons 'boundary (.ref prototype 'boundary))
   (cons 'owns (.ref prototype 'owns))
   (cons 'requires (.ref prototype 'requires))))

;; : (-> Symbol Symbol Symbol PooFlowGraphNodeRef PooFlowGraphEdgeRef Symbol String PooFlowRepairTarget [Alist] PooFlowObservabilityDiagnostic)
(def (poo-flow-observability-diagnostic-record severity boundary validator node edge reason message repair-target . maybe-artifacts)
  (let ((prototype poo-flow-observability-diagnostic-prototype)
        (severity-value severity)
        (boundary-value boundary)
        (validator-value validator)
        (node-value node)
        (edge-value edge)
        (reason-value reason)
        (message-value message)
        (repair-target-value repair-target)
        (artifacts-value (if (null? maybe-artifacts) '() (car maybe-artifacts))))
    (poo-flow-observability-require-diagnostic!
     (.o (:: @ [prototype])
         family: 'observability/diagnostic
         severity: severity-value
         boundary: boundary-value
         validator: validator-value
         node: node-value
         edge: edge-value
         reason: reason-value
         message: message-value
         repair-target: repair-target-value
         artifacts: artifacts-value))))

(def (poo-flow-observability-diagnostic? value)
  (poo-flow-observability-diagnostic-contract? value))

(defpoo-object-family
  (accessors
   (poo-flow-observability-diagnostic-family family)
   (poo-flow-observability-diagnostic-severity severity)
   (poo-flow-observability-diagnostic-boundary boundary)
   (poo-flow-observability-diagnostic-validator validator)
   (poo-flow-observability-diagnostic-node node)
   (poo-flow-observability-diagnostic-edge edge)
   (poo-flow-observability-diagnostic-reason reason)
   (poo-flow-observability-diagnostic-message message)
   (poo-flow-observability-diagnostic-repair-target repair-target)
   (poo-flow-observability-diagnostic-artifacts artifacts))
  (projections))

;; : (-> PooFlowObservabilityDiagnostic Symbol)
(def (poo-flow-observability-diagnostic-code diagnostic)
  (poo-flow-observability-diagnostic-reason diagnostic))

;; : (-> PooFlowObservabilityDiagnostic Alist)
(def (poo-flow-observability-diagnostic->alist diagnostic)
  (list
   (cons 'family (poo-flow-observability-diagnostic-family diagnostic))
   (cons 'severity (poo-flow-observability-diagnostic-severity diagnostic))
   (cons 'boundary (poo-flow-observability-diagnostic-boundary diagnostic))
   (cons 'validator (poo-flow-observability-diagnostic-validator diagnostic))
   (cons 'node (poo-flow-observability-diagnostic-node diagnostic))
   (cons 'edge (poo-flow-observability-diagnostic-edge diagnostic))
   (cons 'reason (poo-flow-observability-diagnostic-reason diagnostic))
   (cons 'message (poo-flow-observability-diagnostic-message diagnostic))
   (cons 'repair-target
         (poo-flow-observability-diagnostic-repair-target diagnostic))
   (cons 'artifacts
         (poo-flow-observability-diagnostic-artifacts diagnostic))))

;; : (-> String PooFlowSourceRef Alist [PooFlowObservabilityDiagnostic] Alist Alist [Alist] PooFlowObservabilityReceipt)
(def (poo-flow-observability-receipt-record schema source graph diagnostics repair readiness . maybe-artifacts)
  (let ((prototype poo-flow-observability-receipt-prototype)
        (schema-value schema)
        (source-value source)
        (graph-value graph)
        (diagnostics-value diagnostics)
        (repair-value repair)
        (readiness-value readiness)
        (artifacts-value (if (null? maybe-artifacts) '() (car maybe-artifacts))))
    (poo-flow-observability-require-receipt!
     (.o (:: @ [prototype])
         family: 'observability/receipt
         schema: schema-value
         source: source-value
         graph: graph-value
         diagnostics: diagnostics-value
         repair: repair-value
         readiness: readiness-value
         artifacts: artifacts-value))))

(def (poo-flow-observability-receipt? value)
  (poo-flow-observability-receipt-contract? value))

(defpoo-object-family
  (accessors
   (poo-flow-observability-receipt-family family)
   (poo-flow-observability-receipt-schema schema)
   (poo-flow-observability-receipt-source source)
   (poo-flow-observability-receipt-graph graph)
   (poo-flow-observability-receipt-diagnostics diagnostics)
   (poo-flow-observability-receipt-repair repair)
   (poo-flow-observability-receipt-readiness readiness)
   (poo-flow-observability-receipt-artifacts artifacts))
  (projections))

;; : (-> PooFlowObservabilityReceipt Boolean)
(def (poo-flow-observability-receipt-valid? receipt)
  (and (poo-flow-observability-receipt? receipt)
       (null? (poo-flow-observability-receipt-diagnostics receipt))
       (eq? (cdr (assq 'state (poo-flow-observability-receipt-readiness receipt)))
            'ready)))

;; : (-> PooFlowObservabilityReceipt [Symbol])
(def (poo-flow-observability-receipt-diagnostic-codes receipt)
  (map poo-flow-observability-diagnostic-code
       (poo-flow-observability-receipt-diagnostics receipt)))

;; : (-> PooFlowObservabilityReceipt Symbol)
(def (poo-flow-observability-receipt-next-action receipt)
  (if (poo-flow-observability-receipt-valid? receipt)
    'accept-graph
    'repair-graph))

;; : (-> Symbol PooFlowGraphSummary [Alist] Alist)
(def (poo-flow-observability-graph kind summary . maybe-metadata)
  (list
   (cons 'kind kind)
   (cons 'summary summary)
   (cons 'metadata
         (if (null? maybe-metadata) '() (car maybe-metadata)))))

;; : (-> (Or Symbol False) (Or Symbol False) [Alist] Alist)
(def (poo-flow-observability-repair target-layer repair-target . maybe-hints)
  (list
   (cons 'target-layer target-layer)
   (cons 'repair-target repair-target)
   (cons 'hints
         (if (null? maybe-hints) '() (car maybe-hints)))))

;; : (-> Symbol Boolean [Alist] Alist)
(def (poo-flow-observability-readiness state valid? . maybe-metadata)
  (list
   (cons 'state state)
   (cons 'valid? valid?)
   (cons 'metadata
         (if (null? maybe-metadata) '() (car maybe-metadata)))))

;; : (-> String PooFlowSourceRef Alist [PooFlowObservabilityDiagnostic] Alist Alist [Alist] PooFlowObservabilityReceipt)
(def (poo-flow-observability-feedback-receipt schema source graph diagnostics repair readiness . maybe-artifacts)
  (poo-flow-observability-receipt-record
   schema
   source
   graph
   diagnostics
   repair
   readiness
   (if (null? maybe-artifacts) '() (car maybe-artifacts))))

;; : (-> Boolean Symbol Symbol Symbol)
(def (poo-flow-observability-domain-next-action valid? accept-action repair-action)
  (if valid? accept-action repair-action))

;; : (-> Symbol Symbol Symbol PooFlowObservabilityReceipt Alist)
(def (poo-flow-observability-agent-feedback kind accept-action repair-action receipt)
  (cons
   (cons 'kind kind)
   (cons
    (cons 'next-action
          (poo-flow-observability-domain-next-action
           (poo-flow-observability-receipt-valid? receipt)
           accept-action
           repair-action))
    (poo-flow-observability-receipt->alist receipt))))

;; : (forall (a) (-> PooFlowObservabilityReceipt (List (Pair Symbol a))))
;; : (-> PooFlowObservabilityReceipt Alist)
(def (poo-flow-observability-receipt->alist receipt)
  (list
   (cons 'family (poo-flow-observability-receipt-family receipt))
   (cons 'schema (poo-flow-observability-receipt-schema receipt))
   (cons 'source (poo-flow-observability-receipt-source receipt))
   (cons 'graph (poo-flow-observability-receipt-graph receipt))
   (cons 'diagnostics
         (map poo-flow-observability-diagnostic->alist
              (poo-flow-observability-receipt-diagnostics receipt)))
   (cons 'diagnostic-codes
         (poo-flow-observability-receipt-diagnostic-codes receipt))
   (cons 'repair (poo-flow-observability-receipt-repair receipt))
   (cons 'readiness (poo-flow-observability-receipt-readiness receipt))
   (cons 'next-action
         (poo-flow-observability-receipt-next-action receipt))
   (cons 'artifacts (poo-flow-observability-receipt-artifacts receipt))))

;;; Boundary: native framework behavior is resolved by upstream slots,
;;; not the legacy metadata-family catalog or an event-kind switch.
(.defgeneric (poo-flow-observation-explain observation) slot: .explain)
;;; Boundary: summary dispatch shares the same native observation receiver contract.
(.defgeneric (poo-flow-observation-summary observation) slot: .summary)

(def poo-flow-admission-observation-prototype
  (.o (:: self AdmissionObservation.)
      (.explain (poo-flow-observation-admission-explanation self))
      (.summary (poo-flow-observation-admission-summary self))))

(def (poo-flow-observation-identity namespace-value name-value revision-value)
  (validate PooFlowObservationIdentityContract
    (.o (:: @ ObservationIdentity.)
        namespace: namespace-value name: name-value revision: revision-value)))

(def (poo-flow-observation-provenance producer-value provider-value phase-value)
  (validate PooFlowObservationProvenanceContract
    (.o (:: @ ObservationProvenance.)
        producer: producer-value provider: provider-value phase: phase-value)))

;;; Identity/provenance are supplied explicitly by the producer. They provide
;;; correlation, not a cryptographic assertion of producer authority.
(def (poo-flow-observation-context identity-value source-value generation-value
                                   causes-value provenance-value
                                   detail-budget: (budget-value 256))
  (validate PooFlowObservationContextContract
    (.o (:: @ ObservationContext.)
        identity: identity-value source: source-value generation: generation-value
        causes: causes-value provenance: provenance-value detail-budget: budget-value)))

(def (poo-flow-observe-admission-evidence context receipt)
  (let ((facts-value (poo-flow-observation-admission-facts receipt context))
        (identity-value (.ref context 'identity))
        (source-value (.ref context 'source))
        (generation-value (.ref context 'generation))
        (causes-value (.ref context 'causes))
        (provenance-value (.ref context 'provenance)))
    (validate PooFlowAdmissionObservationContract
      (.o (:: @ poo-flow-admission-observation-prototype)
          identity: identity-value source: source-value generation: generation-value
          causes: causes-value provenance: provenance-value
          disclosure: 'internal evidence: facts-value))))

(def (poo-flow-observe-contract-admission context contract candidate
                                         evaluation-context: (evaluation-context #f))
  ;; Validate observation metadata before evaluating the subject exactly once.
  (validate PooFlowObservationContextContract context)
  (poo-flow-observe-admission-evidence
   context (poo-flow-contract-admit contract candidate evaluation-context)))
