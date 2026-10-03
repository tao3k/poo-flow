;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in "publication-types.ss" PooFlowTemporalPublication))
(export poo-flow-temporal-publication-value)
(def (poo-flow-temporal-publication-value subject-value scope-value predecessor-value
      revision-value proof-value policy-value generation-value cut-value projection-value
      journal-value model-value nonce-value operation-value version-value expiry-value payload-value)
  (validate PooFlowTemporalPublication
    (.o kind: 'poo-flow.temporal.publish.v1
        subject: subject-value scope: scope-value predecessor: predecessor-value
        revision: revision-value proof: proof-value policy: policy-value
        generation: generation-value cut: cut-value projection: projection-value
        journal: journal-value model: model-value nonce: nonce-value operation: operation-value
        expected-version: version-value expires-unix: expiry-value wire-payload: payload-value
        action-authorized?: #f runtime-executed?: #f)))
