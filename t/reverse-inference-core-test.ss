;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :std/test test-suite check check-exception)
        (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/modules/query/interface
                 PooFlowQuery. PooFlowGqlQueryProgram.
                 PooFlowSchemeGqlQueryLanguage.
                 GqlQueryNode. GqlQueryPath. GqlQueryProperty.
                 GqlQueryProjection. poo-flow-query-result-contract)
        (only-in :poo-flow/modules/reverse-inference/interface
                 PooFlowReverseInferenceCase.
                 poo-flow-inference-claim
                 poo-flow-inference-step
                 poo-flow-inference-hypothesis
                 poo-flow-reverse-inference-evaluate
                 poo-flow-inference-hypothesis-result))

(export reverse-inference-core-test)

(def ClaimProgram
  (.o (:: @ PooFlowGqlQueryProgram.)
      identity: 'reverse-inference-core-claims
      match:
      (.o (:: @ GqlQueryPath.)
          start: (.o (:: @ GqlQueryNode.)
                     binding: 'claim label: 'EvidenceClaim))
      project:
      (.o (:: @ GqlQueryProjection.)
          expression:
          (.o (:: @ GqlQueryProperty.) binding: 'claim property: 'identity)
          next:
          (.o (:: @ GqlQueryProjection.)
              expression:
              (.o (:: @ GqlQueryProperty.) binding: 'claim property: 'value)
              next:
              (.o (:: @ GqlQueryProjection.)
                  expression:
                  (.o (:: @ GqlQueryProperty.)
                      binding: 'claim property: 'evidenceSource))))))

(def ClaimQuery
  (.o (:: @ PooFlowQuery.)
      identity: 'reverse-inference-core-claims
      version: "1"
      semantic-revision: "sha256:reverse-inference-core"
      element-space-identity: 'test/reverse-inference
      selected-element-identities: '(outcome target-a target-b alternate)
      language: PooFlowSchemeGqlQueryLanguage.
      program: ClaimProgram
      result-bound: 16
      completeness-requirement: 'complete
      evidence-requirements:
      '(source-content-identity provenance-root result-digest)
      result-contract:
      (poo-flow-query-result-contract
       'test/reverse-inference-rows 'relation-row
       '(claim value evidenceSource) 16)))

(def CoreCase.
  (.o (:: @ PooFlowReverseInferenceCase.)
      query: ClaimQuery
      claims:
      (list (poo-flow-inference-claim 'outcome 'present 'source-a)
            (poo-flow-inference-claim 'target-a 'destination-1 'source-b)
            (poo-flow-inference-claim 'target-b 'destination-1 'source-c))
      steps:
      (list (poo-flow-inference-step
             'result 'candidate 'outcome 'target-a)
            (poo-flow-inference-step
             'candidate 'origin 'target-a 'target-b 'equal-value)
            (poo-flow-inference-step
             'result 'alternative 'outcome 'alternate))
      hypotheses:
      (list (poo-flow-inference-hypothesis
             'matched-source 'result 'origin
             '(outcome target-a target-b))
            (poo-flow-inference-hypothesis
             'alternative-source 'result 'alternative
             '(outcome alternate)))))

(def (result-status receipt hypothesis-id)
  (.ref (poo-flow-inference-hypothesis-result receipt hypothesis-id)
        'status))

(def reverse-inference-core-test
  (test-suite "generic reverse inference over POO evidence"
    (poo-flow-test-case "matching sources support one candidate only"
      (let (receipt (poo-flow-reverse-inference-evaluate CoreCase.))
        (check (.ref receipt 'query-executed-in-scheme?) => #t)
        (check (result-status receipt 'matched-source) => 'supported)
        (check (result-status receipt 'alternative-source)
               => 'needs-evidence)
        (check (.ref receipt 'source-authenticity-verified?) => #f)))
    (poo-flow-test-case "a conflicting source defeats the matching pair"
      (let* ((case-value
              (.o (:: @ CoreCase.)
                  claims:
                  (cons (poo-flow-inference-claim
                         'target-b 'destination-2 'source-d)
                        (.ref CoreCase. 'claims))))
             (receipt (poo-flow-reverse-inference-evaluate case-value)))
        (check (.ref receipt 'evidence-consistent?) => #f)
        (check (result-status receipt 'matched-source) => 'conflicted)
        (check (result-status receipt 'alternative-source)
               => 'needs-evidence)))
    (poo-flow-test-case "a cyclic candidate graph reaches a finite fixed point"
      (let* ((case-value
              (.o (:: @ CoreCase.)
                  steps:
                  (cons (poo-flow-inference-step
                         'origin 'result 'target-a 'target-b 'equal-value)
                        (.ref CoreCase. 'steps))))
             (receipt (poo-flow-reverse-inference-evaluate case-value)))
        (check (result-status receipt 'matched-source) => 'supported)
        (check (< (length (.ref receipt 'reachable-candidates)) 16)
               => #t)))
    (poo-flow-test-case "negative claims are rejected"
      (check-exception
       (poo-flow-reverse-inference-evaluate
        (.o (:: @ CoreCase.)
            claims: (list (poo-flow-inference-claim
                           'outcome 'absent 'source-a))))
       true))))
