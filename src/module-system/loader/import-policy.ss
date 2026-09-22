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
        poo-flow-module-owner-import-file-observations
        poo-flow-build-bootstrap-import-datum-observations
        poo-flow-build-bootstrap-import-port-observations
        poo-flow-build-bootstrap-import-file-observations
        poo-flow-build-bootstrap-datum-observations
        poo-flow-build-bootstrap-port-observations
        poo-flow-build-bootstrap-file-observations)


(def poo-flow-module-owner-import-observation-kind
  "poo-flow.module-owner-import-observation.v1")

;;; These are user-facing aggregate surfaces. Module implementation roles must
;;; import the precise owner that defines the bindings they consume.
(def poo-flow-module-forbidden-aggregate-imports
  '(:poo-flow/src/core/api
    :poo-flow/src/module-system/api
    :poo-flow/src/module-system/facade
    :poo-flow/src/module-system/contribution/interface
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

;;; A package build entry executes before its own artifacts exist. Importing a
;;; local package owner here creates a loaded-module/currentness cycle on
;;; macOS, where the compiler emits numbered replacement objects forever.
(def (poo-flow-build-bootstrap-package-owner datum)
  (cond
   ((string? datum)
    (and (or (string-prefix? "./src/" datum)
             (string-prefix? "src/" datum))
         datum))
   ((symbol? datum)
    (let (name (symbol->string datum))
      (and (string-prefix? ":poo-flow/" name) datum)))
   ((pair? datum)
    (or (poo-flow-build-bootstrap-package-owner (car datum))
        (poo-flow-build-bootstrap-package-owner (cdr datum))))
   ((vector? datum)
    (poo-flow-build-bootstrap-package-owner (vector->list datum)))
   (else #f)))

(def (poo-flow-build-bootstrap-import-observation scope owner)
  (list
   (cons 'kind poo-flow-module-owner-import-observation-kind)
   (cons 'scope scope)
   (cons 'owner (if (string? owner) (string->symbol owner) owner))
   (cons 'form 'import)
   (cons 'phase 'build-bootstrap-admission)
   (cons 'status 'build-bootstrap-imports-package-owner)
   (cons 'detail
         (list
          (cons 'code 'build-bootstrap-self-import)
          (cons 'recommendation 'declare-package-spec-only)))
   (cons 'runtime-executed #f)))

;;; PackageSpec already owns native import-closure projection.  Re-entering the
;;; package loader, scanning every Gerbil source, or supplying a parallel
;;; `modules` catalog from build.ss duplicates that owner and can expand the
;;; package before std/make performs its currentness pass.
(def poo-flow-build-bootstrap-forbidden-projection-forms
  '(poo-flow-load-modules all-gerbil-modules modules))

(def (poo-flow-build-bootstrap-projection-form datum)
  (cond
   ((pair? datum)
    (cond
     ;; Quoted package data is inert and must not be interpreted as a build
     ;; projection call.
     ((eq? (car datum) 'quote) #f)
     ((memq (car datum)
            poo-flow-build-bootstrap-forbidden-projection-forms)
      (car datum))
     (else
      (or (poo-flow-build-bootstrap-projection-form (car datum))
          (poo-flow-build-bootstrap-projection-form (cdr datum))))))
   ((vector? datum)
    (poo-flow-build-bootstrap-projection-form (vector->list datum)))
   (else #f)))

(def (poo-flow-build-bootstrap-projection-observation scope form)
  (list
   (cons 'kind poo-flow-module-owner-import-observation-kind)
   (cons 'scope scope)
   (cons 'owner form)
   (cons 'form form)
   (cons 'phase 'build-bootstrap-admission)
   (cons 'status 'build-bootstrap-reimplements-package-projection)
   (cons 'detail
         (list
          (cons 'code 'build-bootstrap-parallel-projection)
          (cons 'recommendation 'declare-public-entry-modules)))
   (cons 'runtime-executed #f)))

(def (poo-flow-build-bootstrap-import-datum-observations scope datum)
  (if (and (pair? datum) (eq? (car datum) 'import))
    (alet (owner (poo-flow-build-bootstrap-package-owner (cdr datum)))
      (list (poo-flow-build-bootstrap-import-observation scope owner)))
    '()))

(def (poo-flow-build-bootstrap-import-port-observations scope port)
  (let loop ((observations-rev '()))
    (let (datum (read port))
      (if (eof-object? datum)
        (reverse observations-rev)
        (loop
         (foldl cons observations-rev
                (poo-flow-build-bootstrap-import-datum-observations
                 scope datum)))))))

(def (poo-flow-build-bootstrap-import-file-observations scope path)
  (call-with-input-file
   path
   (lambda (port)
     (poo-flow-build-bootstrap-import-port-observations scope port))))

;; : (-> Symbol SchemeDatum [Alist])
(def (poo-flow-build-bootstrap-datum-observations scope datum)
  (append
   (or (poo-flow-build-bootstrap-import-datum-observations scope datum) '())
   (let (form (poo-flow-build-bootstrap-projection-form datum))
     (if form
       (list (poo-flow-build-bootstrap-projection-observation scope form))
       '()))))

;; : (-> Symbol InputPort [Alist])
(def (poo-flow-build-bootstrap-port-observations scope port)
  (let loop ((observations-rev '()))
    (let (datum (read port))
      (if (eof-object? datum)
        (reverse observations-rev)
        (loop
         (foldl cons observations-rev
                (poo-flow-build-bootstrap-datum-observations scope datum)))))))

;; : (-> Symbol PathString [Alist])
(def (poo-flow-build-bootstrap-file-observations scope path)
  (call-with-input-file
   path
   (lambda (port)
     (poo-flow-build-bootstrap-port-observations scope port))))
