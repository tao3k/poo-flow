;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Public values are POO objects; Ascent tuples are private projections.
(import (only-in :clan/poo/object .o))

(export PooFlowReverseInferenceCase.
        poo-flow-inference-evidence-reference
        poo-flow-inference-claim
        poo-flow-inference-step
        poo-flow-inference-hypothesis
        poo-flow-inference-branch)

(def PooFlowReverseInferenceCase.
  (.o kind: 'poo-flow.reverse-inference.case
      claims: '()
      steps: '()
      query: #f
      hypotheses: '()
      unresolved: '()))

(def (poo-flow-inference-evidence-reference source-id source-uri
                                            independence-group-value
                                            (content-digest-value #f))
  (.o kind: 'poo-flow.reverse-inference.evidence-reference
      source: source-id uri: source-uri
      independence-group: independence-group-value
      content-digest: content-digest-value))

(def (poo-flow-inference-claim claim-id claim-value claim-source
                               (evidence-reference-value #f))
  (.o kind: 'poo-flow.reverse-inference.claim
      identity: claim-id value: claim-value source: claim-source
      evidence-reference: evidence-reference-value))

(def (poo-flow-inference-step from-node to-node first-claim second-claim
                            (join-mode 'presence))
  (.o kind: 'poo-flow.reverse-inference.step
      from: from-node to: to-node first: first-claim
      second: second-claim join: join-mode))

(def (poo-flow-inference-hypothesis hypothesis-id from-node to-node
                                   required-claim-ids)
  (.o kind: 'poo-flow.reverse-inference.hypothesis
      identity: hypothesis-id from: from-node to: to-node
      required-claims: required-claim-ids))

(def (poo-flow-inference-branch branch-id proposed-values withheld-identities
                                (reason-value 'unspecified))
  (.o kind: 'poo-flow.reverse-inference.branch
      identity: branch-id
      proposed-claims: proposed-values
      withheld-claims: withheld-identities
      reason: reason-value))
