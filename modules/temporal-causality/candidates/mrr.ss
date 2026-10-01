;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Project MRR's native typed result admission into an incomplete candidate.
;;; A native admission receipt does not establish result completeness.
(import (only-in :clan/poo/object .ref)
        (only-in :poo-flow/modules/query/types
                 poo-flow-source-query-receipt?)
        (only-in :poo-flow/modules/query/providers/mrr/config.ss
                 MrrGqlQueryProvider)
        (only-in :poo-flow/modules/query/providers/mrr/result-funs.ss
                 poo-flow-mrr-result-admission-projection-replay)
        (only-in "funs.ss" poo-flow-candidate-receipt)
        (only-in "gql.ss" poo-flow-gql-candidate-receipt))
(export poo-flow-mrr-projected-candidate-receipt)

(def (poo-flow-mrr-projected-candidate-receipt
      id candidate scope query element-space source-receipt projection)
  (unless (poo-flow-source-query-receipt? source-receipt)
    (error "invalid MRR source query receipt"))
  (let* ((gql-receipt
          (poo-flow-gql-candidate-receipt
           id candidate scope query element-space MrrGqlQueryProvider
           source-receipt))
         (projection
          (poo-flow-mrr-result-admission-projection-replay projection query)))
    (unless (and (equal? (.ref scope 'evidence-cut-digest)
                         (.ref projection 'snapshot-digest))
                 (= (.ref scope 'generation)
                    (.ref projection 'generation))
                 (eq? (.ref source-receipt 'provider-identity) 'mrr)
                 (equal? (.ref source-receipt 'result-digest)
                         (.ref projection 'result-digest))
                 (= (.ref source-receipt 'result-count)
                    (.ref projection 'result-count)))
      (error "MRR result admission does not match candidate cut and Query"))
    (poo-flow-candidate-receipt
     id candidate scope 'gql
     (.ref gql-receipt 'request-digest)
     (.ref projection 'semantic-digest)
     (.ref projection 'result-digest)
     (.ref projection 'result-count)
     #f)))
