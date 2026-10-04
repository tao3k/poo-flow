;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in "checked-source-types.ss" PooFlowTlaCheckedSource))

(export poo-flow-tla-checked-source-value)

(def (poo-flow-tla-checked-source-value
      identity-value digest-value source-value source-set-value config-value schema-value
      contract-value tool-value version-value output-value workers-value
      generated-value distinct-value left-value depth-value)
  (validate PooFlowTlaCheckedSource
    (.o kind: 'poo-flow.tla-plus.checked-source.v2
        identity: identity-value semantic-digest: digest-value
        source-digest: source-value source-set-digest: source-set-value
        config-digest: config-value
        qualification-schema: schema-value syntax-contract: contract-value
        tool-digest: tool-value tlc-version: version-value
        output-digest: output-value workers: workers-value
        states-generated: generated-value distinct-states: distinct-value
        states-left: left-value graph-depth: depth-value
        source-checked?: #t semantic-refinement?: #f
        action-authorized?: #f)))
