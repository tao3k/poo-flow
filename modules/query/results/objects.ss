;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in "types.ss"
                 PooFlowQueryResultCell PooFlowQueryResultRow
                 PooFlowQueryResultSet))
(export PooFlowQueryResultCell. PooFlowQueryResultRow.
        PooFlowQueryResultSet.
        poo-flow-query-result-cell-value
        poo-flow-query-result-row-value
        poo-flow-query-result-set-value)

(def PooFlowQueryResultCell.
  (.o kind: 'poo-flow.query.result-cell
      semantic-digest: #f field: #f value: #f))
(def PooFlowQueryResultRow.
  (.o kind: 'poo-flow.query.result-row
      semantic-digest: #f identity: #f cells: '()))
(def PooFlowQueryResultSet.
  (.o kind: 'poo-flow.query.result-set
      identity: #f semantic-digest: #f
      query-identity: #f query-version: #f semantic-revision: #f
      result-contract-identity: #f rows: '()
      result-count: 0 result-digest: #f complete?: #f))

(def (poo-flow-query-result-cell-value digest-value field-value scalar-value)
  (validate
   PooFlowQueryResultCell
   (.o (:: @ PooFlowQueryResultCell.)
       semantic-digest: digest-value
       field: field-value value: scalar-value)))

(def (poo-flow-query-result-row-value digest-value id-value cells-value)
  (validate
   PooFlowQueryResultRow
   (.o (:: @ PooFlowQueryResultRow.)
       semantic-digest: digest-value
       identity: id-value cells: cells-value)))

(def (poo-flow-query-result-set-value
      id-value query-value version-value revision-value contract-value
      rows-value count-value digest-value complete-value)
  (validate
   PooFlowQueryResultSet
   (.o (:: @ PooFlowQueryResultSet.)
       identity: id-value semantic-digest: digest-value
       query-identity: query-value query-version: version-value
       semantic-revision: revision-value
       result-contract-identity: contract-value
       rows: rows-value result-count: count-value
       result-digest: digest-value complete?: complete-value)))
