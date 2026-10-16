;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in :poo-flow/modules/temporal-causality/applicability/types
                 PooFlowTemporalFamilyApplicability))
(export poo-flow-temporal-family-applicability-value)
(def (poo-flow-temporal-family-applicability-value admission original current status-value)
  (validate PooFlowTemporalFamilyApplicability
    (.o kind: 'poo-flow.temporal-causality.family-applicability.v1
        admission-digest: admission original-source-digest: original
        current-source-digest: current status: status-value
        runtime-executed?: #f source-authenticated?: #f action-authorized?: #f)))
