;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; One POO entry object exposes parser-owned TLA+ qualification. Semantic
;;; validation and TLC model checking remain separate assurance providers.
(import (only-in :clan/poo/object .o)
        (only-in "objects.ss" PooFlowTlaLanguage. PooFlowTlaDocument.)
        (only-in "funs.ss" poo-flow-tla-parse-source poo-flow-tla-parser-cst))

(export PooFlowTlaPlusModule.)

(def PooFlowTlaPlusModule.
  (.o kind: 'poo-flow.tla-plus.module
      identity: 'poo-flow/modules/tla-plus
      language: PooFlowTlaLanguage.
      document: PooFlowTlaDocument.
      .parse-source: poo-flow-tla-parse-source
      .parser-cst: poo-flow-tla-parser-cst
      semantic-validation?: #f
      model-checking?: #f))
