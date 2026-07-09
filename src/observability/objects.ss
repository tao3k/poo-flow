;;; -*- Gerbil -*-
;;; Observability: POO Flow feedback evidence object protocol.
;;; Invariant: diagnostics and receipts are Scheme-side evidence products;
;;; runtime manifests and proof rows are projections, not semantic owners.

(import (only-in :clan/poo/object .def .ref object?)
        (only-in "./types.ss"
                 poo-flow-observability-require-diagnostic-slots!
                 poo-flow-observability-require-receipt-slots!))

(export poo-flow-observability-event-prototype
        poo-flow-observability-span-prototype
        poo-flow-observability-diagnostic-prototype
        poo-flow-observability-receipt-prototype
        poo-flow-observability-projection-prototype
        +poo-flow-observability-object-families+
        poo-flow-observability-family?
        poo-flow-observability-prototype?
        poo-flow-observability-prototype-id
        poo-flow-observability-prototype->alist
        make-poo-flow-observability-diagnostic
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
        make-poo-flow-observability-receipt
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

;; poo-flow-observability-diagnostic
;;   : (-> Symbol Symbol Symbol Symbol PooFlowGraphNodeRef PooFlowGraphEdgeRef Symbol String PooFlowRepairTarget [Alist] PooFlowObservabilityDiagnostic)
;;   | doc m%
;;       Fixed diagnostic evidence row. It carries validator ownership, graph
;;       position, rejection reason, and the highest legal repair target.
;;     %
(defstruct poo-flow-observability-diagnostic
  (family
   severity
   boundary
   validator
   node
   edge
   reason
   message
   repair-target
   artifacts)
  transparent: #t)

;; : (-> Symbol Symbol Symbol PooFlowGraphNodeRef PooFlowGraphEdgeRef Symbol String PooFlowRepairTarget [Alist] PooFlowObservabilityDiagnostic)
(def (poo-flow-observability-diagnostic-record severity boundary validator node edge reason message repair-target . maybe-artifacts)
  (let (artifacts (if (null? maybe-artifacts) '() (car maybe-artifacts)))
    (poo-flow-observability-require-diagnostic-slots!
     severity
     boundary
     validator
     node
     edge
     reason
     message
     repair-target
     artifacts)
    (make-poo-flow-observability-diagnostic
     'observability/diagnostic
     severity
     boundary
     validator
     node
     edge
     reason
     message
     repair-target
     artifacts)))

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

;; poo-flow-observability-receipt
;;   : (-> Symbol String PooFlowSourceRef Alist [PooFlowObservabilityDiagnostic] Alist Alist [Alist] PooFlowObservabilityReceipt)
;;   | doc m%
;;       Agent-facing feedback packet. The stable top level is graph,
;;       diagnostics, repair, and readiness; proof and manifest details remain
;;       drill-down artifacts.
;;     %
(defstruct poo-flow-observability-receipt
  (family
   schema
   source
   graph
   diagnostics
   repair
   readiness
   artifacts)
  transparent: #t)

;; : (-> String PooFlowSourceRef Alist [PooFlowObservabilityDiagnostic] Alist Alist [Alist] PooFlowObservabilityReceipt)
(def (poo-flow-observability-receipt-record schema source graph diagnostics repair readiness . maybe-artifacts)
  (let (artifacts (if (null? maybe-artifacts) '() (car maybe-artifacts)))
    (poo-flow-observability-require-receipt-slots!
     schema
     source
     graph
     diagnostics
     poo-flow-observability-diagnostic?
     repair
     readiness
     artifacts)
    (make-poo-flow-observability-receipt
     'observability/receipt
     schema
     source
     graph
     diagnostics
     repair
     readiness
     artifacts)))

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
