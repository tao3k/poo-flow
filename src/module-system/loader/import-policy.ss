;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: reader-native policy for imports written inside a POO module role.
;;; Invariant: this owner reads datums only; it never expands or evaluates them.

(export poo-flow-module-owner-import-observation-kind
        poo-flow-module-forbidden-aggregate-imports
        poo-flow-module-owner-import-datum-observations
        poo-flow-module-owner-import-port-observations
        poo-flow-module-owner-import-file-observations)

(def poo-flow-module-owner-import-observation-kind
  "poo-flow.module-owner-import-observation.v1")

;;; These are user-facing aggregate surfaces. Module implementation roles must
;;; import the precise owner that defines the bindings they consume.
(def poo-flow-module-forbidden-aggregate-imports
  '(:poo-flow/src/core/api
    :poo-flow/src/module-system/api
    :poo-flow/src/module-system/facade
    :poo-flow/src/user-interface/facade
    :poo-flow/src/feature-system/interface))

(def (poo-flow-module-import-datum-first-member datum members)
  (cond
   ((and (symbol? datum) (memq datum members)) datum)
   ((pair? datum)
    (or (poo-flow-module-import-datum-first-member (car datum) members)
        (poo-flow-module-import-datum-first-member (cdr datum) members)))
   ((vector? datum)
    (poo-flow-module-import-datum-first-member (vector->list datum) members))
   (else #f)))

(def (poo-flow-module-owner-import-observation scope owner)
  (list
   (cons 'kind poo-flow-module-owner-import-observation-kind)
   (cons 'scope scope)
   (cons 'owner owner)
   (cons 'form 'import)
   (cons 'phase 'module-admission)
   (cons 'status 'aggregate-owner-import)
   (cons 'detail
         (list
          (cons 'code 'module-owner-import-expands-aggregate-facade)
          (cons 'recommendation 'import-precise-owner)))
   (cons 'runtime-executed #f)))

;; : (-> Symbol SchemeDatum [Alist])
(def (poo-flow-module-owner-import-datum-observations scope datum)
  (if (and (pair? datum) (eq? (car datum) 'import))
    (let (owner
          (poo-flow-module-import-datum-first-member
           (cdr datum)
           poo-flow-module-forbidden-aggregate-imports))
      (if owner
        (list (poo-flow-module-owner-import-observation scope owner))
        '()))
    '()))

;; : (-> Symbol InputPort [Alist])
(def (poo-flow-module-owner-import-port-observations scope port)
  (let loop ((observations-rev '()))
    (let (datum (read port))
      (if (eof-object? datum)
        (reverse observations-rev)
        (let collect
             ((remaining
               (poo-flow-module-owner-import-datum-observations scope datum))
              (next observations-rev))
          (if (null? remaining)
            (loop next)
            (collect (cdr remaining) (cons (car remaining) next))))))))

;; : (-> Symbol PathString [Alist])
(def (poo-flow-module-owner-import-file-observations scope path)
  (call-with-input-file
   path
   (lambda (port)
     (poo-flow-module-owner-import-port-observations scope port))))
