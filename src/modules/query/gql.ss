;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: deterministic projection from the native POO GQL AST to source.
;;; The parser remains owned by gerbil-parser; this module neither parses nor
;;; executes a Query.
(import (only-in :clan/poo/object .ref)
        (only-in :gerbil/core string-join)
        (only-in :std/string/misc string-concatenate string-subst)
        (only-in "objects.ss" poo-flow-gql-query-program?))

(export poo-flow-query-program->gql
        poo-flow-query->gql)

(def (gql-name value)
  (if (symbol? value) (symbol->string value) value))

(def (gql-string value)
  (string-append "'" (string-subst value "'" "''") "'"))

(def (gql-node-document node)
  (string-append "(" (gql-name (.ref node 'binding)) ":"
                 (gql-name (.ref node 'label)) ")"))

(def (gql-path-document path)
  (let loop ((step (.ref path 'next))
             (documents (list (gql-node-document (.ref path 'start)))))
    (if step
      (loop (.ref step 'next)
            (cons
             (string-append "-[:" (gql-name (.ref step 'relation)) "]->"
                            (gql-node-document (.ref step 'target)))
             documents))
      (string-concatenate (reverse documents)))))

(def (gql-property-document property)
  (string-append (gql-name (.ref property 'binding)) "."
                 (gql-name (.ref property 'property))))

(def (gql-literal-document literal)
  (case (.ref literal 'literal-kind)
    ((string) (gql-string (.ref literal 'value)))
    ((symbol) (gql-string (symbol->string (.ref literal 'value))))
    ((integer) (number->string (.ref literal 'value)))
    ((boolean) (if (.ref literal 'value) "TRUE" "FALSE"))))

(def (gql-equals-document equals)
  (string-append (gql-property-document (.ref equals 'left)) " = "
                 (gql-literal-document (.ref equals 'right))))

(def (gql-projection-document projection)
  (let loop ((current projection) (documents '()))
    (if current
      (loop (.ref current 'next)
            (cons (gql-property-document (.ref current 'expression))
                  documents))
      (string-join (reverse documents) ", "))))

(def (gql-program-document program)
  (list
   (string-append "MATCH " (gql-path-document (.ref program 'match)) "\n")
   (if (.ref program 'where)
     (string-append "WHERE "
                    (gql-equals-document (.ref program 'where)) "\n")
     "")
   (string-append "RETURN "
                  (gql-projection-document (.ref program 'project)) "\n")))

(def (poo-flow-query-program->gql program)
  (unless (poo-flow-gql-query-program? program)
    (error "invalid POO GQL query program" program))
  (string-concatenate (gql-program-document program)))

(def (poo-flow-query->gql query)
  (poo-flow-query-program->gql (.ref query 'program)))
