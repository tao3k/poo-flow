;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in :poo-flow/modules/temporal-causality/trajectory/types
                 PooFlowTemporalTrajectorySample
                 PooFlowTemporalTrajectorySeries))
(export poo-flow-temporal-trajectory-sample
        poo-flow-temporal-trajectory-series-value)

(def (poo-flow-temporal-trajectory-sample instant-value outcome-value)
  (validate PooFlowTemporalTrajectorySample
    (.o kind: 'poo-flow.temporal-causality.trajectory-sample
        instant: instant-value outcome: outcome-value)))

(def (poo-flow-temporal-trajectory-series-value
      identity-value digest-value subject-value scenario-value outcome-value
      unit-value cut-value projection-value domain-value modality-value
      samples-value)
  (validate PooFlowTemporalTrajectorySeries
    (.o kind: 'poo-flow.temporal-causality.trajectory-series
        identity: identity-value semantic-digest: digest-value
        subject-identity: subject-value scenario-identity: scenario-value
        outcome-identity: outcome-value unit-identity: unit-value
        source-cut-digest: cut-value source-projection-digest: projection-value
        time-domain-identity: domain-value modality: modality-value
        samples: samples-value)))
