;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every))
(export PooFlowTemporalDurationBudget poo-flow-temporal-duration-budget?)
(def (budget? v)
  (and (object? v) (every (lambda (s) (.slot? v s)) '(kind identity capacity-ms remaining-ms allocations action-authorized?))
       (eq? (.ref v 'kind) 'temporal/duration-budget) (eq? (.ref v 'action-authorized?) #f)
       (string? (.ref v 'identity)) (> (string-length (.ref v 'identity)) 0)
       (exact-integer? (.ref v 'capacity-ms)) (> (.ref v 'capacity-ms) 0)
       (exact-integer? (.ref v 'remaining-ms)) (<= 0 (.ref v 'remaining-ms) (.ref v 'capacity-ms))
       (list? (.ref v 'allocations))))
(define-type (PooFlowTemporalDurationBudget @ Type.) .element?: budget?)
(def (poo-flow-temporal-duration-budget? v) (element? PooFlowTemporalDurationBudget v))
