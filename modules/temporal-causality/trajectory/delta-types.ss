;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every)
        (only-in :poo-flow/modules/temporal-causality/trajectory/types
                 poo-flow-temporal-trajectory-series?))
(export PooFlowTemporalTrajectoryDelta poo-flow-temporal-trajectory-delta?)

(def (text? value) (and (string? value) (> (string-length value) 0)))
(def (coordinates? value)
  (and (list? value)
       (every (lambda (item) (and (exact-integer? item) (>= item 0))) value)))
(def (delta-shape? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind identity semantic-digest previous-series revised-series
                     previous-series-digest revised-series-digest
                     previous-cut-digest revised-cut-digest
                     previous-projection-digest revised-projection-digest
                     added-coordinates removed-coordinates changed-coordinates
                     status))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.trajectory-delta)
       (every text? (map (lambda (slot) (.ref value slot))
                         '(identity semantic-digest previous-series-digest
                           revised-series-digest previous-cut-digest
                           revised-cut-digest previous-projection-digest
                           revised-projection-digest)))
       (poo-flow-temporal-trajectory-series? (.ref value 'previous-series))
       (poo-flow-temporal-trajectory-series? (.ref value 'revised-series))
       (every coordinates?
              (list (.ref value 'added-coordinates)
                    (.ref value 'removed-coordinates)
                    (.ref value 'changed-coordinates)))
       (memq (.ref value 'status)
             '(unchanged identity-only scope-change sample-change
                         sample-and-scope-change))))
(define-type (PooFlowTemporalTrajectoryDelta @ Type.)
  .element?: delta-shape?)
(def (poo-flow-temporal-trajectory-delta? value)
  (element? PooFlowTemporalTrajectoryDelta value))
