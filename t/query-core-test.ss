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

(def Query
  (validate
   PooFlowQuery
   (.o (:: @ PooFlowQuery.)
       identity: 'healthcare/case-profile-relations
       version: "1"
       semantic-revision: "sha256:space-v1"
       element-space-identity: 'healthcare/case-space
       selected-element-identities: '(case-1 profile-1)
       language: PooFlowSchemeQueryLanguage.
       program:
       (poo-flow-scheme-query-program
        'healthcare-case-profile-relations-program
        'healthcare-case-profile-relations-predicate)
       domains: '(case profile)
       traversal: '(HAS_EFFECTIVE_PROFILE)
       result-bound: 16
       completeness-requirement: 'complete
       evidence-requirements: '(provenance-root result-digest)
       visibility-request: 'organization
       result-contract: QueryResult)))

(def GqlProgram
  (poo-flow-gql-query-program
   'healthcare-case-profile-relations-gql
   'healthcare/reasoning/case-profile-relations
   "sha256:7a3a88a9ebd24cd738d426c0def633247d1a0fc13e9e37cca13bb23e90ba0c63"
   "sha256:b6d16381120814d44ea00a4f9ad8f0a6cba4e7eef6cf2ddbf2cf2dc16104b13b"
   "iso-iec-39075-2024.opengql-1.9.0-syntax.v1"))

(def query-core-test
  (test-suite
   "canonical Query core"

   (test-case "publishes one POO Query module interface"
     (check (.ref PooFlowQueryModule. 'query) => PooFlowQuery.)
     (check (.ref (.ref PooFlowQueryModule. 'languages) 'scheme)
            => PooFlowSchemeQueryLanguage.)
     (check (.ref (.ref PooFlowQueryModule. 'languages) 'gql)
            => PooFlowGqlQueryLanguage.)
     (check (.ref PooFlowGqlQueryLanguage. 'parser-owner)
            => 'gerbil-parser)
     (check (.ref PooFlowQueryModule. 'element-space)
            => PooFlowQueryElementSpace.)
     (check (.ref PooFlowQueryModule. 'result-contract)
            => PooFlowQueryResultContract.))

   (test-case "extends the language registry through native slot algebra"
     (let (module
           (.o (:: @ PooFlowQueryModule.)
               languages: =>.+
               (.o scheme-analysis: PooFlowSchemeQueryLanguage.)))
       (check (.ref (.ref module 'languages) 'scheme)
              => PooFlowSchemeQueryLanguage.)
       (check (.ref (.ref module 'languages) 'gql)
              => PooFlowGqlQueryLanguage.)
       (check (.ref (.ref module 'languages) 'scheme-analysis)
              => PooFlowSchemeQueryLanguage.)))

   (test-case "admits a bounded read-only Query against its ElementSpace"
     (let (receipt (poo-flow-query-admit Query QuerySpace))
       (check (poo-flow-query-admission-receipt? receipt) => #t)
       (check (.ref receipt 'accepted?) => #t)
       (check (.ref receipt 'diagnostics) => '())
       (check (.ref receipt 'semantic-revision) => "sha256:space-v1")
       (check (.ref receipt 'language-identity) => 'scheme)
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

   (test-case "rejects raw GQL source as a Query program"
     (check
      (poo-flow-query?
       (.o (:: @ Query)
           language: PooFlowGqlQueryLanguage.
           program: "MATCH (n) RETURN n"))
      => #f))

   (test-case "admits only a parser-bound GQL program receipt"
     (let* ((query
             (.o (:: @ Query)
                 identity: 'healthcare/case-profile-relations-gql
                 language: PooFlowGqlQueryLanguage.
                 program: GqlProgram))
            (receipt (poo-flow-query-admit query QuerySpace)))
       (check (.ref receipt 'accepted?) => #t)
       (check (.ref receipt 'language-identity) => 'gql)
       (check (.ref GqlProgram 'parser-identity) => 'gerbil-parser)
       (check (.ref GqlProgram 'parsed?) => #t)
       (check (.ref GqlProgram 'roundtrip?) => #t)))

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
