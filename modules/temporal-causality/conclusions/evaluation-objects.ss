;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o) (only-in :clan/poo/mop validate) "evaluation-types.ss")
(export poo-flow-temporal-evaluation-value)
(def (poo-flow-temporal-evaluation-value id profile-value model-value query-value model-digest-value query-digest-value
      statement-digest-value subject-value scope-value cut-value projection-value policy-value generation-value
      classification-value exhausted-value admitted-value)
  (validate PooFlowTemporalEvaluation
    (.o kind: 'temporal/evaluation identity: id profile: profile-value model: model-value query: query-value
        model-digest: model-digest-value query-digest: query-digest-value statement-digest: statement-digest-value
        subject: subject-value scope: scope-value cut: cut-value projection: projection-value
        policy: policy-value generation: generation-value classification: classification-value
        exhausted?: exhausted-value admitted?: admitted-value action-authorized?: #f)))
