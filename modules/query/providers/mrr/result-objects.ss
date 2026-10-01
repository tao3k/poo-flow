;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in "result-types.ss" PooFlowMrrResultAdmissionProjection))
(export PooFlowMrrResultAdmissionProjection.
        poo-flow-mrr-result-admission-projection-value)

(def PooFlowMrrResultAdmissionProjection.
  (.o kind: 'poo-flow.query.mrr-result-projection
      identity: #f semantic-digest: #f native-schema: #f
      query-source-digest: #f query-binding-digest: #f generation: #f
      relation-catalog-digest: #f entity-catalog-digest: #f
      snapshot-digest: #f result-digest: #f result-count: #f
      complete?: #f))

(def (poo-flow-mrr-result-admission-projection-value
      id-value digest-value schema-value source-value binding-value
      generation-value relation-value entity-value snapshot-value
      result-value count-value)
  (validate
   PooFlowMrrResultAdmissionProjection
   (.o (:: @ PooFlowMrrResultAdmissionProjection.)
       identity: id-value semantic-digest: digest-value
       native-schema: schema-value
       query-source-digest: source-value
       query-binding-digest: binding-value generation: generation-value
       relation-catalog-digest: relation-value
       entity-catalog-digest: entity-value
       snapshot-digest: snapshot-value
       result-digest: result-value result-count: count-value
       complete?: #f)))
