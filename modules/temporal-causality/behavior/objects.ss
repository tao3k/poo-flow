;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o) (only-in :clan/poo/mop validate) "types.ss")
(export poo-flow-temporal-state-variable poo-flow-temporal-condition
        poo-flow-temporal-assignment poo-flow-temporal-mechanism poo-flow-temporal-intervention
        poo-flow-temporal-property poo-flow-temporal-behavior-query
        poo-flow-temporal-behavior-model-value poo-flow-temporal-behavior-receipt-value)
(def (poo-flow-temporal-state-variable id domain-value initial-value)
  (validate PooFlowTemporalStateVariable
    (.o kind: 'temporal/state-variable identity: id domain: domain-value initial: initial-value)))
(def (poo-flow-temporal-condition id variable-value datum)
  (validate PooFlowTemporalCondition (.o kind: 'temporal/condition identity: id variable: variable-value value: datum)))
(def (poo-flow-temporal-assignment id variable-value datum)
  (validate PooFlowTemporalAssignment (.o kind: 'temporal/assignment identity: id variable: variable-value value: datum)))
(def (poo-flow-temporal-mechanism id guards-value assignments-value assumption-value)
  (validate PooFlowTemporalMechanism
    (.o kind: 'temporal/mechanism identity: id guards: guards-value assignments: assignments-value assumption: assumption-value)))
(def (poo-flow-temporal-intervention id onset-value assignments-value protected assumption-value)
  (validate PooFlowTemporalIntervention
    (.o kind: 'temporal/intervention identity: id onset: onset-value assignments: assignments-value
        protected-variables: protected assumption: assumption-value)))
(def (poo-flow-temporal-property id question-value conditions-value deadline-value)
  (validate PooFlowTemporalProperty
    (.o kind: 'temporal/property identity: id question: question-value conditions: conditions-value deadline: deadline-value)))
(def (poo-flow-temporal-behavior-query id property-value limit node-limit: (node-limit-value 10000))
  (validate PooFlowTemporalBehaviorQuery
    (.o kind: 'temporal/behavior-query identity: id property: property-value world-limit: limit node-limit: node-limit-value)))
(def (poo-flow-temporal-behavior-model-value id variables-value mechanisms-value interventions-value horizon-value digest)
  (validate PooFlowTemporalBehaviorModel
    (.o kind: 'temporal/behavior-model identity: id variables: variables-value mechanisms: mechanisms-value
        interventions: interventions-value horizon: horizon-value semantic-digest: digest)))
(def (poo-flow-temporal-behavior-receipt-value id digest property-value query-value class-value count exhausted witness-value counterexample-value frontier-value)
  (validate PooFlowTemporalBehaviorReceipt
    (.o kind: 'temporal/behavior-receipt identity: id model-digest: digest property: property-value query: query-value
        classification: class-value explored-worlds: count exhausted?: exhausted
        witness: witness-value counterexample: counterexample-value frontier: frontier-value
        fairness: 'none actual-causation?: #f)))
