;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in :poo-flow/modules/temporal-causality/time/uncertainty-types
                 poo-flow-temporal-bounded-observation-kind
                 poo-flow-temporal-duration-assessment-kind
                 PooFlowTemporalBoundedObservation
                 PooFlowTemporalDurationAssessment))

(export poo-flow-temporal-bounded-observation-value
        poo-flow-temporal-duration-assessment-value)

(def (poo-flow-temporal-bounded-observation-value
      identity-value digest-value role-value source-value earliest-value
      latest-value precision-value acquisition-value receipt-value
      attestation-value attempt-value schema-value)
  (validate PooFlowTemporalBoundedObservation
    (.o kind: poo-flow-temporal-bounded-observation-kind
        identity: identity-value semantic-digest: digest-value
        clock-role: role-value source-identity: source-value
        earliest: earliest-value latest: latest-value
        precision: precision-value acquisition-instant: acquisition-value
        receipt-identity: receipt-value attestation-identity: attestation-value
        attempt-identity: attempt-value schema-identity: schema-value)))

(def (poo-flow-temporal-duration-assessment-value
      identity-value digest-value status-value start-value end-value
      domain-value minimum-value maximum-value)
  (validate PooFlowTemporalDurationAssessment
    (.o kind: poo-flow-temporal-duration-assessment-kind
        identity: identity-value semantic-digest: digest-value
        status: status-value start-observation-digest: start-value
        end-observation-digest: end-value domain-identity: domain-value
        minimum: minimum-value maximum: maximum-value)))
