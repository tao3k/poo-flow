;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in :poo-flow/modules/temporal-causality/time/types
                 poo-flow-temporal-instant-kind
                 poo-flow-temporal-interval-kind
                 poo-flow-temporal-axes-kind
                 PooFlowTemporalInstant PooFlowTemporalInterval
                 PooFlowTemporalAxes))

(export poo-flow-temporal-instant poo-flow-temporal-interval
        poo-flow-temporal-axes)

(def (poo-flow-temporal-instant identity-value domain-value coordinate-value
                                provenance-value modality-value)
  (validate PooFlowTemporalInstant
    (.o kind: poo-flow-temporal-instant-kind
        identity: identity-value domain-identity: domain-value
        coordinate: coordinate-value
        provenance-identity: provenance-value modality: modality-value)))

(def (poo-flow-temporal-interval identity-value start-value end-value
                                 start-closed-value end-closed-value)
  (validate PooFlowTemporalInterval
    (.o kind: poo-flow-temporal-interval-kind
        identity: identity-value start: start-value end: end-value
        start-closed?: start-closed-value end-closed?: end-closed-value)))

(def (poo-flow-temporal-axes identity-value event-value ingress-value
                              processing-value)
  (validate PooFlowTemporalAxes
    (.o kind: poo-flow-temporal-axes-kind identity: identity-value
        event-instant: event-value ingress-instant: ingress-value
        processing-instant: processing-value)))
