;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; One POO entry object exposes the canonical Query surface.
(import (only-in :clan/poo/object .o)
        (only-in "objects.ss"
                 PooFlowQuery. PooFlowQueryElementSpace.
                 PooFlowGqlQueryLanguage.
                 PooFlowQueryResultContract.)
        (only-in "funs.ss" poo-flow-query-admit)
        (only-in "gql.ss" poo-flow-query->gql)
        (only-in "contracts.ss" poo-flow-query-bind-execution-receipt)
        (only-in "results/objects.ss"
                 PooFlowQueryResultCell. PooFlowQueryResultRow.
                 PooFlowQueryResultSet.)
        (only-in "results/funs.ss"
                 poo-flow-query-result-cell poo-flow-query-result-row
                 poo-flow-query-result-set)
        (only-in "providers/mrr/config.ss" MrrGqlQueryProvider))

(export PooFlowQueryModule.)

(def PooFlowQueryModule.
  (.o kind: 'poo-flow.query.module
      identity: 'poo-flow/modules/query
      query: PooFlowQuery.
      languages:
      (.o gql: PooFlowGqlQueryLanguage.)
      element-space: PooFlowQueryElementSpace.
      result-contract: PooFlowQueryResultContract.
      result-cell: PooFlowQueryResultCell.
      result-row: PooFlowQueryResultRow.
      result-set: PooFlowQueryResultSet.
      providers: (.o mrr: MrrGqlQueryProvider)
      .admit-query: poo-flow-query-admit
      .project-gql: poo-flow-query->gql
      .bind-execution-receipt: poo-flow-query-bind-execution-receipt
      .result-cell: poo-flow-query-result-cell
      .result-row: poo-flow-query-result-row
      .result-set: poo-flow-query-result-set))
