;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every)
        (only-in :poo-flow/modules/temporal-causality/impact/types
                 poo-flow-temporal-impact-contrast?))
(export PooFlowTemporalImpactRefresh poo-flow-temporal-impact-refresh?)

(def (text? value) (and (string? value) (> (string-length value) 0)))
(def (refresh-shape? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind identity semantic-digest previous-contrast
                     revised-contrast left-delta-digest right-delta-digest
                     revised-left-series-digest revised-right-series-digest
                     action reason causal-impact-admitted?
                     runtime-executed?))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.impact-refresh)
       (every text? (map (lambda (slot) (.ref value slot))
                         '(identity semantic-digest left-delta-digest
                           right-delta-digest revised-left-series-digest
                           revised-right-series-digest)))
       (poo-flow-temporal-impact-contrast? (.ref value 'previous-contrast))
       (or (not (.ref value 'revised-contrast))
           (poo-flow-temporal-impact-contrast? (.ref value 'revised-contrast)))
       (memq (.ref value 'action) '(reused recomputed blocked))
       (memq (.ref value 'reason)
             '(unchanged source-version scope-mismatch grid-mismatch))
       (eq? (.ref value 'causal-impact-admitted?) #f)
       (eq? (.ref value 'runtime-executed?) #f)))
(define-type (PooFlowTemporalImpactRefresh @ Type.)
  .element?: refresh-shape?)
(def (poo-flow-temporal-impact-refresh? value)
  (element? PooFlowTemporalImpactRefresh value))
