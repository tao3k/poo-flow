;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: domain-neutral temporal-causality analysis contracts.
;;; Invariant: structural reachability is never temporal proof or authority.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/srfi/1 every)
        (only-in :poo-flow/src/graph/types poo-flow-graph-id?))

(export poo-flow-relation-trajectory-witness-kind
        poo-flow-structural-impact-receipt-kind
        poo-flow-temporal-observation-kind
        poo-flow-causal-event-kind
        poo-flow-causal-event-graph-kind
        poo-flow-causal-cut-kind
        poo-flow-temporal-classification-receipt-kind
        PooFlowRelationTrajectoryWitness
        PooFlowStructuralImpactReceipt
        PooFlowTemporalObservation
        PooFlowCausalEvent
        PooFlowCausalEventGraph
        PooFlowCausalCut
        PooFlowTemporalClassificationReceipt
        poo-flow-relation-trajectory-witness?
        poo-flow-structural-impact-receipt?
        poo-flow-temporal-observation?
        poo-flow-causal-event?
        poo-flow-causal-event-graph?
        poo-flow-causal-cut?
        poo-flow-temporal-classification-receipt?)

(def poo-flow-relation-trajectory-witness-kind
  'poo-flow.temporal-causality.relation-trajectory-witness)

(def poo-flow-structural-impact-receipt-kind
  'poo-flow.temporal-causality.structural-impact-receipt)

(def poo-flow-temporal-observation-kind
  'poo-flow.temporal-causality.temporal-observation)

(def poo-flow-causal-event-kind
  'poo-flow.temporal-causality.causal-event)

(def poo-flow-causal-event-graph-kind
  'poo-flow.temporal-causality.causal-event-graph)

(def poo-flow-causal-cut-kind
  'poo-flow.temporal-causality.causal-cut)

(def poo-flow-temporal-classification-receipt-kind
  'poo-flow.temporal-causality.temporal-classification-receipt)

(def (temporal-causality-has-slots? value slots)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot)) slots)))

(def (relation-trajectory-witness-shape? value)
  (and (temporal-causality-has-slots?
        value '(kind target-node-id node-path relation-path))
       (eq? (.ref value 'kind) poo-flow-relation-trajectory-witness-kind)
       (poo-flow-graph-id? (.ref value 'target-node-id))
       (list? (.ref value 'node-path))
       (pair? (.ref value 'node-path))
       (every poo-flow-graph-id? (.ref value 'node-path))
       (equal? (.ref value 'target-node-id)
               (car (reverse (.ref value 'node-path))))
       (list? (.ref value 'relation-path))
       (every symbol? (.ref value 'relation-path))
       (= (length (.ref value 'relation-path))
          (- (length (.ref value 'node-path)) 1))))

(define-type (PooFlowRelationTrajectoryWitness @ Type.)
  .element?: relation-trajectory-witness-shape?)

(def (poo-flow-relation-trajectory-witness? value)
  (element? PooFlowRelationTrajectoryWitness value))

(def (structural-impact-receipt-shape? value)
  (and (temporal-causality-has-slots?
        value
        '(kind status scope graph-id changed-node-ids direction
               selected-relations affected-node-ids relation-trajectories
               unresolved-edges temporal-impact-assessed?
               release-authorized? runtime-executed?))
       (eq? (.ref value 'kind) poo-flow-structural-impact-receipt-kind)
       (memq (.ref value 'status)
             '(snapshot-scoped-impact partial-impact invalid-inventory))
       (eq? (.ref value 'scope) 'structural-snapshot)
       (poo-flow-graph-id? (.ref value 'graph-id))
       (list? (.ref value 'changed-node-ids))
       (pair? (.ref value 'changed-node-ids))
       (every poo-flow-graph-id? (.ref value 'changed-node-ids))
       (memq (.ref value 'direction) '(dependents dependencies))
       (list? (.ref value 'selected-relations))
       (pair? (.ref value 'selected-relations))
       (every symbol? (.ref value 'selected-relations))
       (list? (.ref value 'affected-node-ids))
       (every poo-flow-graph-id? (.ref value 'affected-node-ids))
       (list? (.ref value 'relation-trajectories))
       (every poo-flow-relation-trajectory-witness?
              (.ref value 'relation-trajectories))
       (list? (.ref value 'unresolved-edges))
       (eq? (.ref value 'temporal-impact-assessed?) #f)
       (eq? (.ref value 'release-authorized?) #f)
       (eq? (.ref value 'runtime-executed?) #f)))

(define-type (PooFlowStructuralImpactReceipt @ Type.)
  .element?: structural-impact-receipt-shape?)

(def (poo-flow-structural-impact-receipt? value)
  (element? PooFlowStructuralImpactReceipt value))

(def (temporal-causality-text? value)
  (and (string? value) (> (string-length value) 0)))

(def (temporal-causality-position? value)
  (and (exact-integer? value) (>= value 0)))

(def (temporal-causality-unique? values)
  (let (seen (make-hash-table))
    (every
     (lambda (value)
       (if (hash-get seen value)
         #f
         (begin (hash-put! seen value #t) #t)))
     values)))

(def (temporal-observation-shape? value)
  (and (temporal-causality-has-slots?
        value
        '(kind identity clock-role logical-position provenance-identity
               immutable? runtime-executed?))
       (eq? (.ref value 'kind) poo-flow-temporal-observation-kind)
       (temporal-causality-text? (.ref value 'identity))
       (memq (.ref value 'clock-role)
             '(wall-clock monotonic logical-version authoritative-service))
       (temporal-causality-position? (.ref value 'logical-position))
       (temporal-causality-text? (.ref value 'provenance-identity))
       (eq? (.ref value 'immutable?) #t)
       (eq? (.ref value 'runtime-executed?) #f)))

(define-type (PooFlowTemporalObservation @ Type.)
  .element?: temporal-observation-shape?)

(def (poo-flow-temporal-observation? value)
  (element? PooFlowTemporalObservation value))

(def (causal-event-shape? value)
  (and (temporal-causality-has-slots?
        value
        '(kind identity subject event-kind observation payload-identity
               causal-parent-identities modality committed?
               runtime-executed?))
       (eq? (.ref value 'kind) poo-flow-causal-event-kind)
       (temporal-causality-text? (.ref value 'identity))
       (temporal-causality-text? (.ref value 'subject))
       (symbol? (.ref value 'event-kind))
       (poo-flow-temporal-observation? (.ref value 'observation))
       (temporal-causality-text? (.ref value 'payload-identity))
       (list? (.ref value 'causal-parent-identities))
       (every temporal-causality-text?
              (.ref value 'causal-parent-identities))
       (temporal-causality-unique?
        (.ref value 'causal-parent-identities))
       (memq (.ref value 'modality)
             '(observed declared derived hypothesized counterfactual))
       (boolean? (.ref value 'committed?))
       (if (eq? (.ref value 'modality) 'observed)
         (.ref value 'committed?)
         #t)
       (if (memq (.ref value 'modality) '(hypothesized counterfactual))
         (not (.ref value 'committed?))
         #t)
       (eq? (.ref value 'runtime-executed?) #f)))

(define-type (PooFlowCausalEvent @ Type.)
  .element?: causal-event-shape?)

(def (poo-flow-causal-event? value)
  (element? PooFlowCausalEvent value))

(def (causal-event-inventory-shape? value expected-kind extra-slots)
  (and (temporal-causality-has-slots?
        value
        (append
         '(kind identity subject events event-index missing-parent-identities
                temporal-order-violations complete? runtime-executed?)
         extra-slots))
       (eq? (.ref value 'kind) expected-kind)
       (temporal-causality-text? (.ref value 'identity))
       (temporal-causality-text? (.ref value 'subject))
       (list? (.ref value 'events))
       (pair? (.ref value 'events))
       (every poo-flow-causal-event? (.ref value 'events))
       (every (lambda (event)
                (equal? (.ref event 'subject) (.ref value 'subject)))
              (.ref value 'events))
       (temporal-causality-unique?
        (map (lambda (event) (.ref event 'identity))
             (.ref value 'events)))
       (hash-table? (.ref value 'event-index))
       (every
        (lambda (event)
          (eq? (hash-get (.ref value 'event-index)
                         (.ref event 'identity))
               event))
        (.ref value 'events))
       (list? (.ref value 'missing-parent-identities))
       (every temporal-causality-text?
              (.ref value 'missing-parent-identities))
       (list? (.ref value 'temporal-order-violations))
       (every
        (lambda (violation)
          (and (list? violation)
               (= (length violation) 2)
               (every temporal-causality-text? violation)))
        (.ref value 'temporal-order-violations))
       (boolean? (.ref value 'complete?))
       (eq? (.ref value 'complete?)
            (and (null? (.ref value 'missing-parent-identities))
                 (null? (.ref value 'temporal-order-violations))))
       (eq? (.ref value 'runtime-executed?) #f)))

(def (causal-event-graph-shape? value)
  (causal-event-inventory-shape?
   value poo-flow-causal-event-graph-kind '()))

(define-type (PooFlowCausalEventGraph @ Type.)
  .element?: causal-event-graph-shape?)

(def (poo-flow-causal-event-graph? value)
  (element? PooFlowCausalEventGraph value))

(def (causal-cut-shape? value)
  (and (causal-event-inventory-shape?
        value poo-flow-causal-cut-kind
        '(event-graph-identity as-of-position))
       (temporal-causality-text? (.ref value 'event-graph-identity))
       (temporal-causality-position? (.ref value 'as-of-position))
       (every
        (lambda (event)
          (and (.ref event 'committed?)
               (<= (.ref (.ref event 'observation) 'logical-position)
                   (.ref value 'as-of-position))))
        (.ref value 'events))))

(define-type (PooFlowCausalCut @ Type.)
  .element?: causal-cut-shape?)

(def (poo-flow-causal-cut? value)
  (element? PooFlowCausalCut value))

(def (temporal-classification-receipt-shape? value)
  (and (temporal-causality-has-slots?
        value
        '(kind status event-graph-identity cut-identity trigger-event-id
               as-of-position horizon
               past-event-ids current-event-ids future-event-ids
               hypothesized-event-ids counterfactual-event-ids
               outside-horizon-event-ids
               unknown-frontier relation-trajectories structural-impact
               assurance-closed? release-authorized? runtime-executed?))
       (eq? (.ref value 'kind)
            poo-flow-temporal-classification-receipt-kind)
       (memq (.ref value 'status)
             '(bounded-temporal-classification
               partial-temporal-classification invalid-causal-cut))
       (every temporal-causality-text?
              (list (.ref value 'event-graph-identity)
                    (.ref value 'cut-identity)
                    (.ref value 'trigger-event-id)))
       (temporal-causality-position? (.ref value 'as-of-position))
       (temporal-causality-position? (.ref value 'horizon))
       (>= (.ref value 'horizon) (.ref value 'as-of-position))
       (every (lambda (slot)
                (let (ids (.ref value slot))
                  (and (list? ids) (every temporal-causality-text? ids))))
              '(past-event-ids current-event-ids future-event-ids
                hypothesized-event-ids counterfactual-event-ids
                outside-horizon-event-ids
                unknown-frontier))
       (temporal-causality-unique?
        (apply append
               (map (lambda (slot) (.ref value slot))
                    '(past-event-ids current-event-ids future-event-ids
                      hypothesized-event-ids counterfactual-event-ids
                      outside-horizon-event-ids
                      unknown-frontier))))
       (list? (.ref value 'relation-trajectories))
       (every poo-flow-relation-trajectory-witness?
              (.ref value 'relation-trajectories))
       (poo-flow-structural-impact-receipt?
        (.ref value 'structural-impact))
       (eq? (.ref value 'assurance-closed?) #f)
       (eq? (.ref value 'release-authorized?) #f)
       (eq? (.ref value 'runtime-executed?) #f)))

(define-type (PooFlowTemporalClassificationReceipt @ Type.)
  .element?: temporal-classification-receipt-shape?)

(def (poo-flow-temporal-classification-receipt? value)
  (element? PooFlowTemporalClassificationReceipt value))
