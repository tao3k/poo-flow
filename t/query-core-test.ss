;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test check test-case test-suite)
        (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        :poo-flow/src/modules/query/interface)

(export query-core-test)

(def QueryResult
  (poo-flow-query-result-contract
   'healthcare/query-result 'relation-row
   '(source target evidence) 32))

(def QuerySpace
  (poo-flow-query-element-space
   'healthcare/case-space "sha256:space-v1"
   '(case-1 profile-1 source-1) #t))

;;; Scheme is the concise host notation.  The value itself is one GQL-aligned
;;; POO AST, so inheritance and slot algebra remain available without creating
;;; a second Scheme Query language.
(def CaseProfileProgram
  (.o (:: @ PooFlowGqlQueryProgram.)
      identity: 'healthcare-case-profile-relations
      match:
      (.o (:: @ GqlQueryPath.)
          start: (.o (:: @ GqlQueryNode.) binding: 's label: 'Scenario)
          next:
          (.o (:: @ GqlQueryStep.)
              relation: 'HAS_CASE
              target: (.o (:: @ GqlQueryNode.) binding: 'c label: 'Case)
              next:
              (.o (:: @ GqlQueryStep.)
                  relation: 'HAS_EFFECTIVE_PROFILE
                  target:
                  (.o (:: @ GqlQueryNode.) binding: 'p label: 'Profile))))
      where:
      (.o (:: @ GqlQueryEquals.)
          left:
          (.o (:: @ GqlQueryProperty.) binding: 's property: 'identity)
          right:
          (.o (:: @ GqlQueryLiteral.)
              literal-kind: 'string value: "healthcare"))
      project:
      (.o (:: @ GqlQueryProjection.)
          expression:
          (.o (:: @ GqlQueryProperty.) binding: 's property: 'identity)
          next:
          (.o (:: @ GqlQueryProjection.)
              expression:
              (.o (:: @ GqlQueryProperty.) binding: 'c property: 'id)
              next:
              (.o (:: @ GqlQueryProjection.)
                  expression:
                  (.o (:: @ GqlQueryProperty.)
                      binding: 'p property: 'identity))))))

(def Query
  (validate
   PooFlowQuery
   (.o (:: @ PooFlowQuery.)
       identity: 'healthcare/case-profile-relations
       version: "1"
       semantic-revision: "sha256:space-v1"
       element-space-identity: 'healthcare/case-space
       selected-element-identities: '(case-1 profile-1)
       language: PooFlowGqlQueryLanguage.
       program: CaseProfileProgram
       result-bound: 16
       completeness-requirement: 'complete
       evidence-requirements: '(provenance-root result-digest)
       visibility-request: 'organization
       result-contract: QueryResult)))

(def query-core-test
  (test-suite
   "canonical Query core"

   (test-case "publishes one semantic language with two surfaces"
     (check (.ref PooFlowQueryModule. 'query) => PooFlowQuery.)
     (check (.ref (.ref PooFlowQueryModule. 'languages) 'gql)
            => PooFlowGqlQueryLanguage.)
     (check (.ref PooFlowGqlQueryLanguage. 'authoring-surface)
            => 'scheme-poo)
     (check (.ref PooFlowGqlQueryLanguage. 'source-surface) => 'gql)
     (check (.ref PooFlowGqlQueryLanguage. 'parser-owner)
            => 'gerbil-parser)
     (check (.ref PooFlowQueryModule. 'element-space)
            => PooFlowQueryElementSpace.)
     (check (.ref PooFlowQueryModule. 'result-contract)
            => PooFlowQueryResultContract.))

   (test-case "projects the POO AST deterministically to standard GQL"
     (check
      (poo-flow-query->gql Query)
      =>
      (string-append
       "MATCH (s:Scenario)-[:HAS_CASE]->(c:Case)-[:HAS_EFFECTIVE_PROFILE]->(p:Profile)\n"
       "WHERE s.identity = 'healthcare'\n"
       "RETURN s.identity, c.id, p.identity\n")))

   (test-case "escapes GQL string literals without transferring parser ownership"
     (let (escaped
           (.o (:: @ CaseProfileProgram)
               where:
               (.o (:: @ GqlQueryEquals.)
                   left:
                   (.o (:: @ GqlQueryProperty.)
                       binding: 's property: 'identity)
                   right:
                   (.o (:: @ GqlQueryLiteral.)
                       literal-kind: 'string value: "patient's-case"))))
       (check
        (poo-flow-query-program->gql escaped)
        =>
        (string-append
         "MATCH (s:Scenario)-[:HAS_CASE]->(c:Case)-[:HAS_EFFECTIVE_PROFILE]->(p:Profile)\n"
         "WHERE s.identity = 'patient''s-case'\n"
         "RETURN s.identity, c.id, p.identity\n"))))

   (test-case "admits a bounded read-only Query against its ElementSpace"
     (let (receipt (poo-flow-query-admit Query QuerySpace))
       (check (poo-flow-query-admission-receipt? receipt) => #t)
       (check (.ref receipt 'accepted?) => #t)
       (check (.ref receipt 'diagnostics) => '())
       (check (.ref receipt 'semantic-revision) => "sha256:space-v1")
       (check (.ref receipt 'language-identity) => 'gql)
       (check (.ref receipt 'mutation-authority?) => #f)
       (check (.ref receipt 'action-authority?) => #f)
       (check (.ref receipt 'runtime-executed?) => #f)))

   (test-case "rejects undeclared Elements without widening the space"
     (let* ((query
             (validate
              PooFlowQuery
              (.o (:: @ Query)
                  selected-element-identities: '(case-1 missing-profile))))
            (receipt (poo-flow-query-admit query QuerySpace)))
       (check (.ref receipt 'accepted?) => #f)
       (check (.ref receipt 'diagnostics)
              => '((undeclared-selected-elements (missing-profile))))
       (check (.ref receipt 'action-authority?) => #f)))

   (test-case "rejects raw GQL and arbitrary Scheme programs"
     (check
      (poo-flow-query?
       (.o (:: @ Query) program: "MATCH (n) RETURN n"))
      => #f)
     (check
      (poo-flow-query?
       (.o (:: @ Query) program: (lambda (_) #t)))
      => #f))

   (test-case "rejects revision drift and incomplete complete-space claims"
     (let* ((space
             (poo-flow-query-element-space
              'healthcare/case-space "sha256:space-v2"
              '(case-1 profile-1 source-1) #f))
            (receipt (poo-flow-query-admit Query space)))
       (check (.ref receipt 'accepted?) => #f)
       (check (map car (.ref receipt 'diagnostics))
              => '(semantic-revision-mismatch incomplete-element-space))
       (check (.ref receipt 'runtime-executed?) => #f)))))
