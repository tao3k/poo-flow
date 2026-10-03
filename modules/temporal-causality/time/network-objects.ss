;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o) (only-in :clan/poo/mop validate) "network-types.ss")
(export poo-flow-temporal-time-choice poo-flow-temporal-time-constraint poo-flow-temporal-time-network-value
        poo-flow-temporal-time-selection-value poo-flow-temporal-time-network-assessment-value)
(def (poo-flow-temporal-time-choice id values)
  (validate PooFlowTemporalTimeChoice (.o kind: 'temporal/time-choice identity: id alternatives: values)))
(def (poo-flow-temporal-time-constraint id from to allowed)
  (validate PooFlowTemporalTimeConstraint
    (.o kind: 'temporal/time-constraint identity: id left: from right: to relations: allowed)))
(def (poo-flow-temporal-time-network-value id variables rules digest)
  (validate PooFlowTemporalTimeNetwork
    (.o kind: 'temporal/time-network identity: id choices: variables constraints: rules semantic-digest: digest)))
(def (poo-flow-temporal-time-selection-value id datum)
  (.o kind: 'temporal/time-selection identity: id value: datum))
(def (poo-flow-temporal-time-network-assessment-value id model-digest-value status-value count exhaustive witness-value frontier-value unknown-count world-limit-value node-limit-value)
  (.o kind: 'temporal/time-network-assessment identity: id model-digest: model-digest-value
      status: status-value explored-assignments: count exhausted?: exhaustive witness: witness-value
      frontier: frontier-value unknown-assignments: unknown-count
      world-limit: world-limit-value node-limit: node-limit-value action-authorized?: #f))
