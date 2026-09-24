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
        PooFlowGqlQueryLanguage.
        PooFlowQueryProgram.
        PooFlowQueryNode.
        PooFlowQueryStep.
        PooFlowQueryPath.
        PooFlowQueryProperty.
        PooFlowQueryLiteral.
        PooFlowQueryEquals.
        PooFlowQueryProjection.
        PooFlowGqlQueryProgram.
        PooFlowQueryElementSpace.
        PooFlowQueryResultContract.
        poo-flow-query-element-space
        poo-flow-gql-query-program?
        poo-flow-query-result-contract)

(def (query-program-has-slots? value slots)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot)) slots)))

(def (query-node? value)
  (and (query-program-has-slots?
        value '(kind binding label))
       (eq? (.ref value 'kind) 'poo-flow.query.node)
       (symbol? (.ref value 'binding))
       (symbol? (.ref value 'label))))

(def (query-step? value)
  (and (query-program-has-slots?
        value '(kind relation target next))
       (eq? (.ref value 'kind) 'poo-flow.query.step)
       (symbol? (.ref value 'relation))
       (query-node? (.ref value 'target))
       (or (not (.ref value 'next)) (query-step? (.ref value 'next)))))

(def (query-path? value)
  (and (query-program-has-slots? value '(kind start next))
       (eq? (.ref value 'kind) 'poo-flow.query.path)
       (query-node? (.ref value 'start))
       (or (not (.ref value 'next)) (query-step? (.ref value 'next)))))

(def (query-property? value)
  (and (query-program-has-slots? value '(kind binding property))
       (eq? (.ref value 'kind) 'poo-flow.query.property)
       (symbol? (.ref value 'binding))
       (symbol? (.ref value 'property))))

(def (query-literal? value)
  (and (query-program-has-slots? value '(kind literal-kind value))
       (eq? (.ref value 'kind) 'poo-flow.query.literal)
       (case (.ref value 'literal-kind)
         ((string) (string? (.ref value 'value)))
         ((symbol) (symbol? (.ref value 'value)))
         ((integer) (exact-integer? (.ref value 'value)))
         ((boolean) (boolean? (.ref value 'value)))
         (else #f))))

(def (query-equals? value)
  (and (query-program-has-slots? value '(kind left right))
       (eq? (.ref value 'kind) 'poo-flow.query.equals)
       (query-property? (.ref value 'left))
       (query-literal? (.ref value 'right))))

(def (query-projection? value)
  (and (query-program-has-slots? value '(kind expression next))
       (eq? (.ref value 'kind) 'poo-flow.query.projection)
       (query-property? (.ref value 'expression))
       (or (not (.ref value 'next))
           (query-projection? (.ref value 'next)))))

(def (poo-flow-gql-query-program? value)
  (and (query-program-has-slots?
        value '(kind identity language-identity representation
                     match where project immutable?))
       (eq? (.ref value 'kind) poo-flow-query-program-kind)
       (eq? (.ref value 'language-identity) 'gql)
       (eq? (.ref value 'representation) 'poo-gql-ast)
       (query-path? (.ref value 'match))
       (or (not (.ref value 'where)) (query-equals? (.ref value 'where)))
       (query-projection? (.ref value 'project))
       (eq? (.ref value 'immutable?) #t)))

(def PooFlowQueryProgram.
  (.o kind: poo-flow-query-program-kind
      identity: #f
      language-identity: #f
      representation: 'poo-object
      immutable?: #t))

(def PooFlowQueryNode.
  (.o kind: 'poo-flow.query.node binding: #f label: #f))

(def PooFlowQueryStep.
  (.o kind: 'poo-flow.query.step relation: #f target: #f next: #f))

(def PooFlowQueryPath.
  (.o kind: 'poo-flow.query.path start: #f next: #f))

(def PooFlowQueryProperty.
  (.o kind: 'poo-flow.query.property binding: #f property: #f))

(def PooFlowQueryLiteral.
  (.o kind: 'poo-flow.query.literal literal-kind: #f value: #f))

(def PooFlowQueryEquals.
  (.o kind: 'poo-flow.query.equals left: #f right: #f))

(def PooFlowQueryProjection.
  (.o kind: 'poo-flow.query.projection expression: #f next: #f))

(def PooFlowGqlQueryProgram.
  (.o (:: @ PooFlowQueryProgram.)
      language-identity: 'gql
      representation: 'poo-gql-ast
      match: #f
      where: #f
      project: #f))

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
          (.o (:: @ PooFlowQueryPath.)
              start: (.o (:: @ PooFlowQueryNode.) binding: 'x label: 'Element))
          project:
          (.o (:: @ PooFlowQueryProjection.)
              expression:
              (.o (:: @ PooFlowQueryProperty.) binding: 'x property: 'identity)))
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
