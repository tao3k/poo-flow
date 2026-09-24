;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: canonical prototypes and validated value constructors.
;;; Invariant: ordinary authors derive Query values through native slot algebra.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :clan/poo/mop validate)
        (only-in :std/list/list every)
        (only-in "types.ss"
                 poo-flow-query-kind
                 poo-flow-query-language-kind
                 poo-flow-query-program-kind
                 poo-flow-query-element-space-kind
                 poo-flow-query-result-contract-kind
                 PooFlowQuery PooFlowQueryLanguage PooFlowQueryProgram
                 PooFlowQueryElementSpace
                 PooFlowQueryResultContract))

(export PooFlowQuery.
        PooFlowQueryLanguage.
        PooFlowSchemeQueryLanguage.
        PooFlowGqlQueryLanguage.
        PooFlowQueryProgram.
        PooFlowSchemeQueryProgram.
        PooFlowGqlQueryProgram.
        PooFlowQueryElementSpace.
        PooFlowQueryResultContract.
        poo-flow-query-element-space
        poo-flow-scheme-query-program
        poo-flow-gql-query-program
        poo-flow-query-result-contract)

(def (query-program-has-slots? value slots)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot)) slots)))

(def (query-content-id? value)
  (and (string? value)
       (= (string-length value) 71)
       (string=? (substring value 0 7) "sha256:")))

(def (scheme-query-program? value)
  (and (query-program-has-slots?
        value '(kind identity language-identity representation entrypoint
                     immutable?))
       (eq? (.ref value 'kind) poo-flow-query-program-kind)
       (eq? (.ref value 'language-identity) 'scheme)
       (eq? (.ref value 'representation) 'named-poo-expression)
       (symbol? (.ref value 'entrypoint))
       (eq? (.ref value 'immutable?) #t)))

(def (gql-query-program? value)
  (and (query-program-has-slots?
        value '(kind identity language-identity representation
                     parser-identity syntax-contract source-identity
                     source-content-id grammar-content-id parsed? roundtrip?
                     immutable?))
       (eq? (.ref value 'kind) poo-flow-query-program-kind)
       (eq? (.ref value 'language-identity) 'gql)
       (eq? (.ref value 'representation) 'parser-artifact-receipt)
       (eq? (.ref value 'parser-identity) 'gerbil-parser)
       (string? (.ref value 'syntax-contract))
       (or (symbol? (.ref value 'source-identity))
           (string? (.ref value 'source-identity)))
       (query-content-id? (.ref value 'source-content-id))
       (query-content-id? (.ref value 'grammar-content-id))
       (eq? (.ref value 'parsed?) #t)
       (eq? (.ref value 'roundtrip?) #t)
       (eq? (.ref value 'immutable?) #t)))

(def PooFlowQueryProgram.
  (.o kind: poo-flow-query-program-kind
      identity: #f
      language-identity: #f
      representation: 'poo-object
      immutable?: #t))

(def PooFlowSchemeQueryProgram.
  (.o (:: @ PooFlowQueryProgram.)
      language-identity: 'scheme
      representation: 'named-poo-expression
      entrypoint: #f))

(def PooFlowGqlQueryProgram.
  (.o (:: @ PooFlowQueryProgram.)
      language-identity: 'gql
      representation: 'parser-artifact-receipt
      parser-identity: 'gerbil-parser
      syntax-contract: #f
      source-identity: #f
      source-content-id: #f
      grammar-content-id: #f
      parsed?: #t
      roundtrip?: #t))

(def PooFlowQueryResultContract.
  (.o kind: poo-flow-query-result-contract-kind
      identity: #f
      result-kind: 'query-result
      required-fields: '()
      max-results: 1
      immutable?: #t))

(def PooFlowQueryElementSpace.
  (.o kind: poo-flow-query-element-space-kind
      identity: #f
      semantic-revision: #f
      element-identities: '()
      complete?: #f
      immutable?: #t
      runtime-executed?: #f))

(def PooFlowQueryLanguage.
  (.o kind: poo-flow-query-language-kind
      identity: #f
      representation: 'poo-object
      execution-boundary: 'external-provider
      runtime-owner: 'unbound
      parser-owner: #f
      syntax-contract: #f
      .program?: (lambda (_) #f)
      raw-source-allowed?: #f
      action-authority?: #f
      runtime-executed?: #f))

;;; Scheme programs are named POO/pure-function projections.  The public Query
;;; never stores an anonymous lambda as its language program.
(def PooFlowSchemeQueryLanguage.
  (.o (:: @ PooFlowQueryLanguage.)
      identity: 'scheme
      representation: 'named-poo-expression
      execution-boundary: 'pure-control-plane
      runtime-owner: 'poo-flow
      .program?: scheme-query-program?))

;;; GQL programs are parser-admitted receipts. Raw source and the parser's
;;; internal alist artifact never become the public Query value.
(def PooFlowGqlQueryLanguage.
  (.o (:: @ PooFlowQueryLanguage.)
      identity: 'gql
      representation: 'parser-artifact-receipt
      execution-boundary: 'external-provider
      runtime-owner: 'mrr
      parser-owner: 'gerbil-parser
      syntax-contract: "iso-iec-39075-2024.opengql-1.9.0-syntax.v1"
      .program?: gql-query-program?))

(def PooFlowQuery.
  (.o kind: poo-flow-query-kind
      identity: #f
      version: #f
      semantic-revision: #f
      element-space-identity: #f
      selected-element-identities: '()
      language: PooFlowSchemeQueryLanguage.
      program:
      (.o (:: @ PooFlowSchemeQueryProgram.)
          identity: 'unbound-query-program
          entrypoint: 'unbound-query-program)
      domains: '()
      traversal: '()
      result-bound: 1
      completeness-requirement: 'bounded
      evidence-requirements: '()
      visibility-request: 'restricted
      result-contract: PooFlowQueryResultContract.
      mutation-authority?: #f
      action-authority?: #f
      runtime-executed?: #f))

(def (poo-flow-scheme-query-program identity-value entrypoint-value)
  (let (value
        (validate
         PooFlowQueryProgram
         (.o (:: @ PooFlowSchemeQueryProgram.)
             identity: identity-value
             entrypoint: entrypoint-value)))
    (unless (scheme-query-program? value)
      (error "invalid Scheme Query program" value))
    value))

(def (poo-flow-gql-query-program identity-value source-identity-value
                                 source-content-id-value
                                 grammar-content-id-value
                                 syntax-contract-value)
  (let (value
        (validate
         PooFlowQueryProgram
         (.o (:: @ PooFlowGqlQueryProgram.)
             identity: identity-value
             source-identity: source-identity-value
             source-content-id: source-content-id-value
             grammar-content-id: grammar-content-id-value
             syntax-contract: syntax-contract-value)))
    (unless (gql-query-program? value)
      (error "invalid parser-admitted GQL Query program" value))
    value))

(def (poo-flow-query-element-space identity-value semantic-revision-value
                                   element-identities-value complete?-value)
  (validate
   PooFlowQueryElementSpace
   (.o (:: @ PooFlowQueryElementSpace.)
       identity: identity-value
       semantic-revision: semantic-revision-value
       element-identities: element-identities-value
       complete?: complete?-value)))

(def (poo-flow-query-result-contract identity-value result-kind-value
                                     required-fields-value max-results-value)
  (validate
   PooFlowQueryResultContract
   (.o (:: @ PooFlowQueryResultContract.)
       identity: identity-value
       result-kind: result-kind-value
       required-fields: required-fields-value
       max-results: max-results-value)))
