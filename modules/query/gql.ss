;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO Flow metadata validation around parser-owned GQL projection.
;;; Gerbil Parser owns the syntax graph and source renderer; this module only
;;; adapts a governed POO Flow Query to that language boundary.
(import (only-in :clan/poo/object .ref)
        (only-in :gerbil-parser/src/modules/parser/graph-syntax
                 graph-syntax-program->source)
        (only-in "objects.ss" poo-flow-gql-query-program?))

(export poo-flow-query-program->gql
        poo-flow-query->gql)

(def (poo-flow-query-program->gql program)
  (unless (poo-flow-gql-query-program? program)
    (error "invalid POO GQL query program" program))
  (graph-syntax-program->source program))

(def (poo-flow-query->gql query)
  (poo-flow-query-program->gql (.ref query 'program)))
