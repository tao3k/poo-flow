;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o) (only-in :clan/poo/mop validate) "budget-types.ss")
(export poo-flow-temporal-duration-budget poo-flow-temporal-duration-budget-value)
(def (poo-flow-temporal-duration-budget-value id capacity remaining grants)
  (validate PooFlowTemporalDurationBudget
    (.o kind: 'temporal/duration-budget identity: id capacity-ms: capacity remaining-ms: remaining allocations: grants action-authorized?: #f)))
(def (poo-flow-temporal-duration-budget id capacity)
  (poo-flow-temporal-duration-budget-value id capacity capacity '()))
