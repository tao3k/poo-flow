;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: deterministic projection from the native POO GQL AST to source.
;;; The parser remains owned by gerbil-parser; this module neither parses nor
;;; executes a Query.
(import (only-in :clan/poo/object .ref)
        (only-in :gerbil/core call-with-output-string)
        (only-in "objects.ss" poo-flow-gql-query-program?))

(export poo-flow-query-program->gql
        poo-flow-query->gql)

(def (gql-name value)
  (if (symbol? value) (symbol->string value) value))

(def (write-gql-string value port)
  (write-char #\' port)
  (string-for-each
   (lambda (character)
     (when (char=? character #\') (write-char #\' port))
     (write-char character port))
   value)
  (write-char #\' port))

(def (write-gql-node node port)
  (display "(" port)
  (display (gql-name (.ref node 'binding)) port)
  (display ":" port)
  (display (gql-name (.ref node 'label)) port)
  (display ")" port))

(def (write-gql-path path port)
  (write-gql-node (.ref path 'start) port)
  (let loop ((step (.ref path 'next)))
    (when step
      (display "-[:" port)
      (display (gql-name (.ref step 'relation)) port)
      (display "]->" port)
      (write-gql-node (.ref step 'target) port)
      (loop (.ref step 'next)))))

(def (write-gql-property property port)
  (display (gql-name (.ref property 'binding)) port)
  (display "." port)
  (display (gql-name (.ref property 'property)) port))

(def (write-gql-literal literal port)
  (case (.ref literal 'literal-kind)
    ((string) (write-gql-string (.ref literal 'value) port))
    ((symbol) (write-gql-string (symbol->string (.ref literal 'value)) port))
    ((integer) (display (.ref literal 'value) port))
    ((boolean) (display (if (.ref literal 'value) "TRUE" "FALSE") port))))

(def (write-gql-equals equals port)
  (write-gql-property (.ref equals 'left) port)
  (display " = " port)
  (write-gql-literal (.ref equals 'right) port))

(def (write-gql-projections projection port)
  (let loop ((current projection) (first? #t))
    (when current
      (unless first? (display ", " port))
      (write-gql-property (.ref current 'expression) port)
      (loop (.ref current 'next) #f))))

(def (poo-flow-query-program->gql program)
  (unless (poo-flow-gql-query-program? program)
    (error "invalid POO GQL query program" program))
  (call-with-output-string
   (lambda (port)
     (display "MATCH " port)
     (write-gql-path (.ref program 'match) port)
     (display "\n" port)
     (when (.ref program 'where)
       (display "WHERE " port)
       (write-gql-equals (.ref program 'where) port)
       (display "\n" port))
     (display "RETURN " port)
     (write-gql-projections (.ref program 'project) port)
     (display "\n" port))))

(def (poo-flow-query->gql query)
  (poo-flow-query-program->gql (.ref query 'program)))
