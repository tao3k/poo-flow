;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; POO-native language and qualification values. gerbil-parser alone owns
;;; the lossless TLA+ syntax tree; this module defines no parallel AST.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :gerbil-parser/languages/tla-plus/v1/parser
                 +tla-plus-syntax-contract+))
(export PooFlowTlaLanguage. PooFlowTlaDocument. poo-flow-tla-document?)

(def PooFlowTlaLanguage.
  (.o identity: 'tla-plus
      parser-owner: 'gerbil-parser
      syntax-contract: +tla-plus-syntax-contract+
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

(def (poo-flow-tla-document? value)
  (and (object? value)
       (.slot? value 'language)
       (.slot? value '.parser-cst)
       (.slot? value 'exact-roundtrip?)
       (eq? (.ref value 'language) PooFlowTlaLanguage.)
       (procedure? (.ref value '.parser-cst))
       (eq? (.ref value 'exact-roundtrip?) #t)))
