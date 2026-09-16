;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO-native causal-trajectory and structural-analysis values.
(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        (only-in :poo-flow/src/modules/temporal-causality/types
                 poo-flow-relation-trajectory-witness-kind
                 poo-flow-structural-impact-receipt-kind
                 poo-flow-temporal-observation-kind
                 poo-flow-causal-event-kind
                 poo-flow-causal-event-graph-kind
                 poo-flow-causal-trajectory-contract-kind
                 poo-flow-causal-trajectory-assessment-kind
                 poo-flow-causal-cut-kind
                 poo-flow-temporal-classification-receipt-kind
                 PooFlowRelationTrajectoryWitness
                 PooFlowStructuralImpactReceipt
                 PooFlowTemporalObservation
                 PooFlowCausalEvent
                 PooFlowCausalEventGraph
                 PooFlowCausalTrajectoryContract
                 PooFlowCausalTrajectoryAssessment
                 PooFlowCausalCut
                 PooFlowTemporalClassificationReceipt))

(export poo-flow-relation-trajectory-witness
        poo-flow-structural-impact-receipt
        poo-flow-temporal-observation
        poo-flow-causal-event
        poo-flow-causal-event-graph-value
        poo-flow-causal-trajectory-contract
        poo-flow-causal-trajectory-assessment
        poo-flow-causal-cut-value
        poo-flow-temporal-classification-receipt)

(def (poo-flow-relation-trajectory-witness
      target-node-id-value node-path-value relation-path-value)
  (validate
   PooFlowRelationTrajectoryWitness
   (.o kind: poo-flow-relation-trajectory-witness-kind
       target-node-id: target-node-id-value
       node-path: node-path-value
       relation-path: relation-path-value)))

(def (poo-flow-structural-impact-receipt
      status-value graph-id-value changed-node-ids-value direction-value
      selected-relations-value affected-node-ids-value trajectories-value
      unresolved-edges-value)
  (validate
   PooFlowStructuralImpactReceipt
   (.o kind: poo-flow-structural-impact-receipt-kind
       status: status-value
       scope: 'structural-snapshot
       graph-id: graph-id-value
       changed-node-ids: changed-node-ids-value
       direction: direction-value
       selected-relations: selected-relations-value
       affected-node-ids: affected-node-ids-value
       relation-trajectories: trajectories-value
       unresolved-edges: unresolved-edges-value
       temporal-impact-assessed?: #f
       release-authorized?: #f
       runtime-executed?: #f)))

(def (poo-flow-temporal-observation
      identity-value clock-role-value logical-position-value
      provenance-identity-value)
  (validate
   PooFlowTemporalObservation
   (.o kind: poo-flow-temporal-observation-kind
       identity: identity-value
       clock-role: clock-role-value
       logical-position: logical-position-value
       provenance-identity: provenance-identity-value
       immutable?: #t
       runtime-executed?: #f)))

(def (poo-flow-causal-event
      identity-value subject-value event-kind-value observation-value
      payload-identity-value causal-parent-identities-value modality-value
      committed-value)
  (validate
   PooFlowCausalEvent
   (.o kind: poo-flow-causal-event-kind
       identity: identity-value
       subject: subject-value
       event-kind: event-kind-value
       observation: observation-value
       payload-identity: payload-identity-value
       causal-parent-identities: causal-parent-identities-value
       modality: modality-value
       committed?: committed-value
       runtime-executed?: #f)))

(def (poo-flow-causal-event-graph-value
      identity-value subject-value events-value event-index-value
      missing-parent-identities-value temporal-order-violations-value)
  (validate
   PooFlowCausalEventGraph
   (.o kind: poo-flow-causal-event-graph-kind
       identity: identity-value
       subject: subject-value
       events: events-value
       event-index: event-index-value
       missing-parent-identities: missing-parent-identities-value
       temporal-order-violations: temporal-order-violations-value
       complete?: (and (null? missing-parent-identities-value)
                       (null? temporal-order-violations-value))
       runtime-executed?: #f)))

(def (poo-flow-causal-trajectory-contract
      identity-value trigger-event-id-value intended-event-ids-value
      error-event-paths-value intended-impact-event-ids-value
      error-impact-event-ids-value)
  (validate
   PooFlowCausalTrajectoryContract
   (.o kind: poo-flow-causal-trajectory-contract-kind
       identity: identity-value
       trigger-event-id: trigger-event-id-value
       intended-event-ids: intended-event-ids-value
       error-event-paths: error-event-paths-value
       intended-impact-event-ids: intended-impact-event-ids-value
       error-impact-event-ids: error-impact-event-ids-value)))

(def (poo-flow-causal-trajectory-assessment
      status-value contract-value event-graph-value diagnostics-value)
  (validate
   PooFlowCausalTrajectoryAssessment
   (.o kind: poo-flow-causal-trajectory-assessment-kind
       status: status-value
       accepted?: (eq? status-value 'causal-trajectory-admitted)
       contract-identity: (.ref contract-value 'identity)
       event-graph-identity: (.ref event-graph-value 'identity)
       diagnostics: diagnostics-value
       intended-event-ids: (.ref contract-value 'intended-event-ids)
       error-event-paths: (.ref contract-value 'error-event-paths)
       intended-impact-event-ids:
       (.ref contract-value 'intended-impact-event-ids)
       error-impact-event-ids: (.ref contract-value 'error-impact-event-ids)
       assurance-closed?: #f
       release-authorized?: #f
       runtime-executed?: #f)))

(def (poo-flow-causal-cut-value
      identity-value event-graph-identity-value subject-value
      events-value event-index-value
      missing-parent-identities-value temporal-order-violations-value
      as-of-position-value)
  (validate
   PooFlowCausalCut
   (.o kind: poo-flow-causal-cut-kind
       identity: identity-value
       event-graph-identity: event-graph-identity-value
       subject: subject-value
       events: events-value
       event-index: event-index-value
       missing-parent-identities: missing-parent-identities-value
       temporal-order-violations: temporal-order-violations-value
       complete?: (and (null? missing-parent-identities-value)
                       (null? temporal-order-violations-value))
       as-of-position: as-of-position-value
       runtime-executed?: #f)))

(def (poo-flow-temporal-classification-receipt
      status-value event-graph-identity-value cut-identity-value
      trigger-event-id-value
      as-of-position-value horizon-value past-event-ids-value
      current-event-ids-value future-event-ids-value
      hypothesized-event-ids-value
      counterfactual-event-ids-value outside-horizon-event-ids-value
      unknown-frontier-value trajectories-value structural-impact-value)
  (validate
   PooFlowTemporalClassificationReceipt
   (.o kind: poo-flow-temporal-classification-receipt-kind
       status: status-value
       event-graph-identity: event-graph-identity-value
       cut-identity: cut-identity-value
       trigger-event-id: trigger-event-id-value
       as-of-position: as-of-position-value
       horizon: horizon-value
       past-event-ids: past-event-ids-value
       current-event-ids: current-event-ids-value
       future-event-ids: future-event-ids-value
       hypothesized-event-ids: hypothesized-event-ids-value
       counterfactual-event-ids: counterfactual-event-ids-value
       outside-horizon-event-ids: outside-horizon-event-ids-value
       unknown-frontier: unknown-frontier-value
       relation-trajectories: trajectories-value
       structural-impact: structural-impact-value
       assurance-closed?: #f
       release-authorized?: #f
       runtime-executed?: #f)))
