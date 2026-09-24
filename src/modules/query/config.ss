;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; One POO entry object exposes the canonical Query surface.
(import (only-in :clan/poo/object .o)
        (only-in "objects.ss"
                 PooFlowQuery. PooFlowQueryElementSpace.
                 PooFlowSchemeQueryLanguage. PooFlowGqlQueryLanguage.
                 PooFlowQueryResultContract.)
        (only-in "funs.ss" poo-flow-query-admit))

(export PooFlowQueryModule.)

(def PooFlowQueryModule.
  (.o kind: 'poo-flow.query.module
      identity: 'poo-flow/modules/query
      query: PooFlowQuery.
      languages:
      (.o scheme: PooFlowSchemeQueryLanguage.
          gql: PooFlowGqlQueryLanguage.)
      element-space: PooFlowQueryElementSpace.
      result-contract: PooFlowQueryResultContract.
      .admit-query: poo-flow-query-admit))
