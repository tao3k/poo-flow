;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; POO-native language and qualification prototypes. gerbil-parser alone owns
;;; the lossless TLA+ syntax tree; this module defines no parallel AST.
(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        (only-in :gerbil-parser/languages/tla-plus/grammars/layout
                 tla-plus-layout-language-grammar)
        (only-in :gerbil-parser/src/language/descriptor language-grammar-contract)
        (only-in "types.ss"
                 PooFlowTlaModelOutline PooFlowTlaTemporalProjection PooFlowTlaBehaviorProjection))
(export poo-flow-tla-behavior-projection-value PooFlowTlaLanguage. PooFlowTlaDocument.
        poo-flow-tla-model-outline-value
        poo-flow-tla-temporal-projection-value)

(def PooFlowTlaLanguage.
  (.o identity: 'tla-plus
      parser-owner: 'gerbil-parser
      syntax-contract: (language-grammar-contract tla-plus-layout-language-grammar)
      representation: 'parser-owned-cst
      semantic-validation?: #f
      model-checking?: #f))

(def PooFlowTlaDocument.
  (.o language: PooFlowTlaLanguage.
      source-digest: #f
      grammar-digest: #f
      source-byte-length: #f
      .parser-cst: #f
      exact-roundtrip?: #f
      semantic-validation?: #f
      model-checking?: #f))

(def (poo-flow-tla-model-outline-value
      document-value module-name variables constants operators)
  (validate
   PooFlowTlaModelOutline
   (.o kind: 'poo-flow.tla-plus.model-outline
       document: document-value
       source-digest: (.ref document-value 'source-digest)
       grammar-digest: (.ref document-value 'grammar-digest)
       module-identity: module-name
       variable-identities: variables
       constant-identities: constants
       operator-identities: operators
       semantic-validation?: #f
       model-checking?: #f)))

(def (poo-flow-tla-temporal-projection-value document-value model-value
       (subset 'poo-flow.tla-plus.literal-hypothesis-family.v1))
  (validate
   PooFlowTlaTemporalProjection
   (.o kind: 'poo-flow.tla-plus.temporal-projection
       document: document-value
       model: model-value
       source-digest: (.ref document-value 'source-digest)
       grammar-digest: (.ref document-value 'grammar-digest)
       semantic-digest: (.ref model-value 'semantic-digest)
       semantic-subset: subset
       model-checking?: #f)))

(def (poo-flow-tla-behavior-projection-value source-document model-value property-value)
  (validate PooFlowTlaBehaviorProjection
    (.o kind: 'poo-flow.tla-plus.behavior-projection document: source-document
        model: model-value property: property-value
        source-digest: (.ref source-document 'source-digest)
        grammar-digest: (.ref source-document 'grammar-digest)
        semantic-digest: (.ref model-value 'semantic-digest)
        semantic-subset: 'poo-flow.tla-plus.logical-step-behavior.v1
        model-checking?: #f action-authorized?: #f)))
