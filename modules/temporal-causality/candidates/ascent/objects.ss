;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o .ref) (only-in :clan/poo/mop validate) "types.ss")
(export poo-flow-ascent-request-value poo-flow-ascent-execution-value poo-flow-ascent-admission-value)
(def (poo-flow-ascent-request-value id-value digest-value profile-value pin-value scope-value model-value query-value source-value binding-value iterations-value derived-value output-value work-value nodes-value)
 (validate PooFlowAscentCandidateRequest
  (.o kind: 'temporal/ascent-request identity: id-value semantic-digest: digest-value profile: profile-value provider-pin: pin-value
      scope: scope-value model: model-value query: query-value source-identity: source-value binding-digest: binding-value
      iterations: iterations-value derived-limit: derived-value output-limit: output-value proof-work: work-value proof-nodes: nodes-value)))
(def (poo-flow-ascent-execution-value request-digest-value native-value)
 (validate PooFlowAscentCandidateExecution
  (.o kind: 'temporal/ascent-execution request-digest: request-digest-value native-receipt: native-value)))
(def (poo-flow-ascent-admission-value exchange-value source-verified-value evaluation-value)
 (validate PooFlowAscentCandidateAdmission
  (.o kind: 'temporal/ascent-admission exchange: exchange-value source-verified?: source-verified-value
      evaluation: evaluation-value admitted?: (and source-verified-value evaluation-value (.ref evaluation-value 'admitted?)))))
