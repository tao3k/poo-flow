;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; POO projection of the native MRR QueryResultAdmissionReceipt metadata.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop Type. define-type element?)
        (only-in :std/list/list every))
(export PooFlowMrrResultAdmissionProjection
        poo-flow-mrr-result-admission-projection?)

(def (text? value) (and (string? value) (> (string-length value) 0)))
(def (shape? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind identity semantic-digest native-schema
                     query-source-digest query-binding-digest generation
                     relation-catalog-digest entity-catalog-digest
                     snapshot-digest result-digest result-count complete?))
       (eq? (.ref value 'kind) 'poo-flow.query.mrr-result-projection)
       (every text?
              (map (lambda (slot) (.ref value slot))
                   '(identity semantic-digest native-schema
                              query-source-digest query-binding-digest
                              relation-catalog-digest entity-catalog-digest
                              snapshot-digest result-digest)))
       (exact-integer? (.ref value 'generation))
       (>= (.ref value 'generation) 0)
       (exact-integer? (.ref value 'result-count))
       (>= (.ref value 'result-count) 0)
       (eq? (.ref value 'complete?) #f)))
(define-type (PooFlowMrrResultAdmissionProjection @ Type.)
  .element?: shape?)
(def (poo-flow-mrr-result-admission-projection? value)
  (element? PooFlowMrrResultAdmissionProjection value))
