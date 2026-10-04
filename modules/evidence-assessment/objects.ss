;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Public values are POO objects; Ascent tuples are private projections.
(import (only-in :clan/poo/object .o))

(export PooFlowEvidenceAssessmentCase.
        poo-flow-evidence-reference
        poo-flow-evidence-claim
        poo-flow-evidence-step
        poo-flow-evidence-hypothesis
        poo-flow-evidence-branch)

(def PooFlowEvidenceAssessmentCase.
  (.o kind: 'poo-flow.evidence-assessment.case
      claims: '()
      steps: '()
      query: #f
      hypotheses: '()
      unresolved: '()))

(def (poo-flow-evidence-reference source-id source-uri
                                            independence-group-value
                                            (content-digest-value #f))
  (.o kind: 'poo-flow.evidence-assessment.evidence-reference
      source: source-id uri: source-uri
      independence-group: independence-group-value
      content-digest: content-digest-value))

(def (poo-flow-evidence-claim claim-id claim-value claim-source
                               (evidence-reference-value #f))
  (.o kind: 'poo-flow.evidence-assessment.claim
      identity: claim-id value: claim-value source: claim-source
      evidence-reference: evidence-reference-value))

(def (poo-flow-evidence-step from-node to-node first-claim second-claim
                            (join-mode 'presence))
  (.o kind: 'poo-flow.evidence-assessment.step
      from: from-node to: to-node first: first-claim
      second: second-claim join: join-mode))

(def (poo-flow-evidence-hypothesis hypothesis-id from-node to-node
                                   required-claim-ids)
  (.o kind: 'poo-flow.evidence-assessment.hypothesis
      identity: hypothesis-id from: from-node to: to-node
      required-claims: required-claim-ids))

(def (poo-flow-evidence-branch branch-id proposed-values withheld-identities
                                (reason-value 'unspecified))
  (.o kind: 'poo-flow.evidence-assessment.branch
      identity: branch-id
      proposed-claims: proposed-values
      withheld-claims: withheld-identities
      reason: reason-value))
