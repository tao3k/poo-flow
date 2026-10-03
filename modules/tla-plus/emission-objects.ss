;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        (only-in "emission-types.ss" PooFlowTlaTemporalEmission PooFlowTlaBehaviorEmission))
(export poo-flow-tla-temporal-emission-value poo-flow-tla-behavior-emission-value)
(def (poo-flow-tla-temporal-emission-value model-value query-value data check config)
  (validate PooFlowTlaTemporalEmission
    (.o kind: 'poo-flow.tla-plus.temporal-emission
        model: model-value query: query-value
        model-digest: (.ref model-value 'semantic-digest)
        data-source: data check-source: check config-source: config
        semantic-subset: 'poo-flow.tla-plus.literal-hypothesis-family.v2
        model-checking?: #f)))
(def (poo-flow-tla-behavior-emission-value model-value property-value data check config)
  (validate PooFlowTlaBehaviorEmission
    (.o kind: 'poo-flow.tla-plus.behavior-emission
        model: model-value property: property-value model-digest: (.ref model-value 'semantic-digest)
        data-source: data check-source: check config-source: config
        semantic-subset: 'poo-flow.tla-plus.logical-step-behavior.v1 model-checking?: #f)))
