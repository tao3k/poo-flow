;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: canonical prototypes and validated value constructors.
;;; Invariant: ordinary authors derive Query values through native slot algebra.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :clan/poo/mop validate)
        (only-in :std/list/list every)
        (only-in :gerbil-parser/languages/gql/iso-39075-2024/query-syntax
                 GqlQueryNode.
                 GqlQueryStep.
                 GqlQueryPath.
                 GqlQueryProperty.
                 GqlQueryLiteral.
                 GqlQueryEquals.
                 GqlQueryProjection.
                 GqlQueryProgram.
                 gql-query-program?)
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
        PooFlowGqlQueryLanguage.
        PooFlowQueryProgram.
        GqlQueryNode.
        GqlQueryStep.
        GqlQueryPath.
        GqlQueryProperty.
        GqlQueryLiteral.
        GqlQueryEquals.
        GqlQueryProjection.
        GqlQueryProgram.
        PooFlowGqlQueryProgram.
        PooFlowQueryElementSpace.
        PooFlowQueryResultContract.
        poo-flow-query-element-space
        poo-flow-gql-query-program?
        poo-flow-query-result-contract)

(def (query-program-has-slots? value slots)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot)) slots)))

(def (poo-flow-gql-query-program? value)
  (and (gql-query-program? value)
       (query-program-has-slots?
        value '(kind identity language-identity representation
                     immutable?))
       (eq? (.ref value 'kind) poo-flow-query-program-kind)
       (eq? (.ref value 'language-identity) 'gql)
       (eq? (.ref value 'representation) 'poo-gql-ast)
       (eq? (.ref value 'immutable?) #t)))

(def PooFlowQueryProgram.
  (.o kind: poo-flow-query-program-kind
      identity: #f
      language-identity: #f
      representation: 'poo-object
      immutable?: #t))

(def PooFlowGqlQueryProgram.
  (.o (:: @ GqlQueryProgram.)
      kind: poo-flow-query-program-kind
      identity: #f
      language-identity: 'gql
      representation: 'poo-gql-ast
      immutable?: #t))

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
      authoring-surface: 'scheme-poo
      source-surface: 'unbound
      execution-boundary: 'external-provider
      runtime-owner: 'unbound
      parser-owner: #f
      syntax-contract: #f
      .program?: (lambda (_) #f)
      raw-source-allowed?: #f
      action-authority?: #f
      runtime-executed?: #f))

;;; There is one semantic language.  Scheme is the host syntax used to author
;;; this GQL-aligned POO AST; it is not a competing Query language.
(def PooFlowGqlQueryLanguage.
  (.o (:: @ PooFlowQueryLanguage.)
      identity: 'gql
      representation: 'poo-gql-ast
      authoring-surface: 'scheme-poo
      source-surface: 'gql
      execution-boundary: 'external-provider
      runtime-owner: 'mrr
      parser-owner: 'gerbil-parser
      syntax-contract: "iso-iec-39075-2024.opengql-1.9.0-syntax.v1"
      .program?: poo-flow-gql-query-program?))

(def PooFlowQuery.
  (.o kind: poo-flow-query-kind
      identity: #f
      version: #f
      semantic-revision: #f
      element-space-identity: #f
      selected-element-identities: '()
      language: PooFlowGqlQueryLanguage.
      program:
      (.o (:: @ PooFlowGqlQueryProgram.)
          identity: 'unbound-query-program
          match:
          (.o (:: @ GqlQueryPath.)
              start: (.o (:: @ GqlQueryNode.) binding: 'x label: 'Element))
          project:
          (.o (:: @ GqlQueryProjection.)
              expression:
              (.o (:: @ GqlQueryProperty.) binding: 'x property: 'identity)))
      result-bound: 1
      completeness-requirement: 'bounded
      evidence-requirements: '()
      visibility-request: 'restricted
      result-contract: PooFlowQueryResultContract.
      mutation-authority?: #f
      action-authority?: #f
      runtime-executed?: #f))

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
