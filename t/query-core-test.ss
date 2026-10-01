;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :core/observability/testing-case poo-flow-test-case)
         (only-in :std/test check check-exception test-suite)
        (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        :poo-flow/modules/query/interface
        (only-in :poo-flow/modules/temporal-causality/candidates/interface
                 poo-flow-candidate-scope poo-flow-candidate-exchange
                 poo-flow-candidate-check
                 poo-flow-gql-candidate-receipt
                 poo-flow-gql-candidate-row-check
                 poo-flow-mrr-projected-candidate-receipt))

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

(def (test-sha256 character)
  (string-append "sha256:" (make-string 64 character)))

(def query-core-test
  (test-suite
   "canonical Query core"

   (poo-flow-test-case "publishes one semantic language with two surfaces"
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
            => PooFlowQueryResultContract.)
     (check (.ref PooFlowQueryModule. 'result-cell)
            => PooFlowQueryResultCell.)
     (check (.ref PooFlowQueryModule. 'result-row)
            => PooFlowQueryResultRow.)
     (check (.ref PooFlowQueryModule. 'result-set)
            => PooFlowQueryResultSet.))

   (poo-flow-test-case "projects the POO AST deterministically to standard GQL"
     (check
      (poo-flow-query->gql Query)
      =>
      (string-append
       "MATCH (s:Scenario)-[:HAS_CASE]->(c:Case)-[:HAS_EFFECTIVE_PROFILE]->(p:Profile)\n"
       "WHERE s.identity = 'healthcare'\n"
       "RETURN s.identity, c.id, p.identity\n")))

   (poo-flow-test-case "escapes GQL string literals without transferring parser ownership"
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

   (poo-flow-test-case "admits a bounded read-only Query against its ElementSpace"
     (let (receipt (poo-flow-query-admit Query QuerySpace))
       (check (poo-flow-query-admission-receipt? receipt) => #t)
       (check (.ref receipt 'accepted?) => #t)
       (check (.ref receipt 'diagnostics) => '())
       (check (.ref receipt 'semantic-revision) => "sha256:space-v1")
       (check (.ref receipt 'language-identity) => 'gql)
       (check (.ref receipt 'mutation-authority?) => #f)
       (check (.ref receipt 'action-authority?) => #f)
       (check (.ref receipt 'runtime-executed?) => #f)))

   (poo-flow-test-case "binds an admitted MRR candidate through Provider x Query dispatch"
     (let* ((admission (poo-flow-query-admit Query QuerySpace))
            (candidate
             (poo-flow-query-execution-candidate
              'mrr
              'healthcare/case-profile-relations
              "1"
              "sha256:space-v1"
              (poo-flow-query-source-content-identity Query)
              'gerbil-parser
              "sha256:provenance-v1"
              "sha256:result-v1"
              3
              #t))
            (receipt
             (poo-flow-query-bind-execution-receipt
              MrrGqlQueryProvider Query admission candidate)))
       (check (poo-flow-source-query-receipt? receipt) => #t)
       (check (.ref receipt 'admitted?) => #t)
       (check (.ref receipt 'diagnostics) => '())
       (check (.ref receipt 'provider-identity) => 'mrr)
       (check (.ref receipt 'result-contract-identity)
              => 'healthcare/query-result)
       (check (.ref receipt 'runtime-executed?) => #t)
       (check (.ref receipt 'mutation-authority?) => #f)
       (check (.ref receipt 'action-authority?) => #f)))

   (poo-flow-test-case "rejects drifted or over-bound Provider evidence"
     (let* ((admission (poo-flow-query-admit Query QuerySpace))
            (candidate
             (poo-flow-query-execution-candidate
              'mrr
              'healthcare/case-profile-relations
              "1"
              "sha256:space-v2"
              "sha256:wrong-source"
              'other-parser
              "sha256:provenance-v1"
              "sha256:result-v1"
              17
              #f))
            (receipt
             (poo-flow-query-bind-execution-receipt
              MrrGqlQueryProvider Query admission candidate)))
       (check (.ref receipt 'admitted?) => #f)
       (check (map car (.ref receipt 'diagnostics))
              => '(semantic-revision-mismatch
                   source-content-identity-mismatch
                   parser-identity-mismatch
                   query-result-bound-exceeded
                   incomplete-query-result))
       (check (.ref receipt 'action-authority?) => #f)))

   (poo-flow-test-case "GQL receipt binds one Temporal cut but supplies no check"
     (let* ((admission (poo-flow-query-admit Query QuerySpace))
            (provider-candidate
             (poo-flow-query-execution-candidate
              'mrr 'healthcare/case-profile-relations "1" "sha256:space-v1"
              (poo-flow-query-source-content-identity Query)
              'gerbil-parser "sha256:provenance-v1" "sha256:result-v1"
              3 #t))
            (source-receipt
             (poo-flow-query-bind-execution-receipt
              MrrGqlQueryProvider Query admission provider-candidate))
            (scope
             (poo-flow-candidate-scope
              "scope" "sha256:space-v1" 0 "sha256:coverage"
              '(gql ascent)))
            (gql-receipt
             (poo-flow-gql-candidate-receipt
              "gql-receipt" "candidate" scope Query QuerySpace
              MrrGqlQueryProvider
              source-receipt))
            (exchange
             (poo-flow-candidate-exchange
              "exchange" "candidate" scope (list gql-receipt) '())))
       (check (.ref gql-receipt 'provider-identity) => 'gql)
       (check (.ref gql-receipt 'result-digest) => "sha256:result-v1")
       (check (.ref gql-receipt 'result-count) => 3)
       (check (.ref exchange 'status) => 'pending)
       (check (.ref exchange 'missing-providers) => '(ascent))
       (check (.ref exchange 'unchecked-receipts) => '("gql-receipt"))
       (check (.ref exchange 'admitted?) => #f)
       (check-exception
        (poo-flow-gql-candidate-receipt
         "stale" "candidate"
         (poo-flow-candidate-scope
          "scope" "sha256:space-v2" 1 "sha256:coverage" '(gql ascent))
         Query QuerySpace MrrGqlQueryProvider source-receipt)
        true)
       (check-exception
        (poo-flow-gql-candidate-receipt
         "forged" "candidate" scope Query QuerySpace
         MrrGqlQueryProvider
         (validate PooFlowSourceQueryReceipt
                   (.o (:: @ source-receipt)
                       result-digest: "sha256:other"
                       source-content-identity: "sha256:other-source")))
        true)))

   (poo-flow-test-case "scalar rows replay and check a declared GQL result"
     (let* ((cells
             (list (poo-flow-query-result-cell 'source "source-1")
                   (poo-flow-query-result-cell 'target "profile-1")
                   (poo-flow-query-result-cell 'evidence #t)))
            (row (poo-flow-query-result-row 'row-1 cells))
            (reordered
             (poo-flow-query-result-row 'row-1 (reverse cells)))
            (rows
             (poo-flow-query-result-set
              "result-set" QueryResult (.ref Query 'identity)
              (.ref Query 'version) (.ref Query 'semantic-revision)
              (list row) #t))
            (admission (poo-flow-query-admit Query QuerySpace))
            (provider-candidate
             (poo-flow-query-execution-candidate
              'mrr (.ref Query 'identity) (.ref Query 'version)
              (.ref Query 'semantic-revision)
              (poo-flow-query-source-content-identity Query)
              'gerbil-parser "sha256:provenance-v1"
              (.ref rows 'result-digest) 1 #t))
            (source-receipt
             (poo-flow-query-bind-execution-receipt
              MrrGqlQueryProvider Query admission provider-candidate))
            (scope
             (poo-flow-candidate-scope
              "scope" "sha256:space-v1" 0 "sha256:coverage" '(gql)))
            (candidate-receipt
             (poo-flow-gql-candidate-receipt
              "gql" "candidate" scope Query QuerySpace
              MrrGqlQueryProvider source-receipt))
            (row-check
             (poo-flow-gql-candidate-row-check
              "rows" candidate-receipt Query rows))
            (exchange
             (poo-flow-candidate-exchange
              "exchange" "candidate" scope (list candidate-receipt)
              (list row-check))))
       (check (.ref row 'semantic-digest)
              => (.ref reordered 'semantic-digest))
       (check (.ref rows 'result-count) => 1)
       (check (substring (.ref rows 'result-digest) 0 29)
              => "poo-flow.query.scalar-row-v1:")
       (check (.ref row-check 'verdict) => 'valid)
       (check (.ref exchange 'status) => 'reviewable)
       (check (.ref exchange 'admitted?) => #f)
       (check-exception
        (poo-flow-query-result-set-replay
         (.o (:: @ rows) result-count: 2) QueryResult)
        true)
       (check-exception
        (poo-flow-query-result-row 'duplicate
                                   (list (car cells) (car cells)))
        true)
       (check-exception
        (poo-flow-query-result-set
         "missing-field" QueryResult (.ref Query 'identity)
         (.ref Query 'version) (.ref Query 'semantic-revision)
         (list (poo-flow-query-result-row
                'missing (list (car cells)))) #t)
        true)
       (let* ((other-rows
               (poo-flow-query-result-set
                "other" QueryResult (.ref Query 'identity)
                (.ref Query 'version) (.ref Query 'semantic-revision)
                (list (poo-flow-query-result-row
                       'row-1
                       (list (poo-flow-query-result-cell 'source "different")
                             (cadr cells) (caddr cells)))) #t))
              (invalid
               (poo-flow-gql-candidate-row-check
                "invalid" candidate-receipt Query other-rows)))
         (check (.ref invalid 'verdict) => 'invalid))))

   (poo-flow-test-case "native MRR admission remains incomplete and separate from scalar rows"
     (let* ((cut (test-sha256 #\a))
            (query
             (validate PooFlowQuery
                       (.o (:: @ Query) semantic-revision: cut)))
            (space
             (poo-flow-query-element-space
              'healthcare/case-space cut
              '(case-1 profile-1 source-1) #t))
            (projection
             (poo-flow-mrr-result-admission-projection
              "native" query (test-sha256 #\b) 7
              (test-sha256 #\c) (test-sha256 #\d) cut
              (test-sha256 #\e) 1))
            (admission (poo-flow-query-admit query space))
            (execution-candidate
             (poo-flow-query-execution-candidate
              'mrr (.ref query 'identity) (.ref query 'version) cut
              (poo-flow-query-source-content-identity query)
              'gerbil-parser "sha256:provenance"
              (.ref projection 'result-digest) 1 #t))
            (source-receipt
             (poo-flow-query-bind-execution-receipt
              MrrGqlQueryProvider query admission execution-candidate))
            (scope
             (poo-flow-candidate-scope
              "scope" cut 7 "sha256:coverage" '(gql)))
            (candidate-receipt
             (poo-flow-mrr-projected-candidate-receipt
              "mrr" "candidate" scope query space
              source-receipt projection))
            (exchange
             (poo-flow-candidate-exchange
              "exchange" "candidate" scope (list candidate-receipt)
              (list (poo-flow-candidate-check
                     "claimed-check" candidate-receipt
                     "unverified-native-result" 'valid
                     "sha256:declared-basis")))))
       (check (.ref projection 'native-schema)
              => "mrr.query-result-admission.v1")
       (check (.ref candidate-receipt 'complete?) => #f)
       (check (.ref candidate-receipt 'result-digest)
              => (.ref projection 'result-digest))
       (check (.ref exchange 'status) => 'pending)
       (check (.ref exchange 'incomplete-receipts) => '("mrr"))
       (check (.ref exchange 'unchecked-receipts) => '())
       (check (.ref exchange 'admitted?) => #f)
       (check-exception
        (poo-flow-gql-candidate-row-check
         "wrong-profile" candidate-receipt query
         (poo-flow-query-result-set
          "rows" QueryResult (.ref query 'identity)
          (.ref query 'version) cut
          (list (poo-flow-query-result-row
                 "row"
                 (list (poo-flow-query-result-cell 'source "s")
                       (poo-flow-query-result-cell 'target "t")
                       (poo-flow-query-result-cell 'evidence #t)))) #t))
        true)
       (check-exception
        (poo-flow-mrr-projected-candidate-receipt
         "stale" "candidate"
         (poo-flow-candidate-scope
          "scope" cut 8 "sha256:coverage" '(gql))
         query space source-receipt projection)
        true)
       (check-exception
        (poo-flow-mrr-projected-candidate-receipt
         "forged" "candidate" scope query space source-receipt
         (.o (:: @ projection) generation: 8))
        true)
       (check-exception
        (poo-flow-mrr-projected-candidate-receipt
         "other-snapshot" "candidate" scope query space source-receipt
         (poo-flow-mrr-result-admission-projection
          "other" query (test-sha256 #\b) 7
          (test-sha256 #\c) (test-sha256 #\d)
          (test-sha256 #\f) (test-sha256 #\e) 1))
        true)
       (check-exception
        (poo-flow-mrr-result-admission-projection
         "bad" query "sha256:short" 7
         (test-sha256 #\c) (test-sha256 #\d) cut
         (test-sha256 #\e) 1)
        true)))

   (poo-flow-test-case "rejects undeclared Elements without widening the space"
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

   (poo-flow-test-case "rejects raw GQL and arbitrary Scheme programs"
     (check
      (poo-flow-query?
       (.o (:: @ Query) program: "MATCH (n) RETURN n"))
      => #f)
     (check
      (poo-flow-query?
       (.o (:: @ Query) program: (lambda (_) #t)))
      => #f))

   (poo-flow-test-case "rejects revision drift and incomplete complete-space claims"
     (let* ((space
             (poo-flow-query-element-space
              'healthcare/case-space "sha256:space-v2"
              '(case-1 profile-1 source-1) #f))
            (receipt (poo-flow-query-admit Query space)))
       (check (.ref receipt 'accepted?) => #f)
       (check (map car (.ref receipt 'diagnostics))
              => '(semantic-revision-mismatch incomplete-element-space))
       (check (.ref receipt 'runtime-executed?) => #f)))))
