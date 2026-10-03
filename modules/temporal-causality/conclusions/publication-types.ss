;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every))
(export PooFlowTemporalPublication poo-flow-temporal-publication?)
(def (shape? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind subject scope predecessor revision proof policy generation
                     cut projection journal model nonce operation expected-version
                     expires-unix wire-payload action-authorized? runtime-executed?))
       (eq? (.ref value 'kind) 'poo-flow.temporal.publish.v1)
       (every string?
              (map (lambda (slot) (.ref value slot))
                   '(subject scope predecessor revision proof policy generation
                             cut projection journal model nonce operation wire-payload)))
       (every (lambda (n) (and (exact-integer? n) (>= n 0) (< n (expt 2 63))))
              (list (.ref value 'expected-version) (.ref value 'expires-unix)))
       (member (.ref value 'operation) '("assert" "correct" "retract"))
       (eq? (.ref value 'action-authorized?) #f)
       (eq? (.ref value 'runtime-executed?) #f)))
(define-type (PooFlowTemporalPublication @ Type.) .element?: shape?)
(def (poo-flow-temporal-publication? value) (element? PooFlowTemporalPublication value))
