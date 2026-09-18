;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: source-located, single-expression Composition value files.
;;; Invariant: loading reads one root selector and performs no imports, exports,
;;; directory discovery, Runtime construction or Session execution.

(import (only-in :gerbil/expander/stx syntax->datum)
        (only-in :poo-flow/src/module-system/profile-composition/catalog
                 poo-flow-composition-catalog-ref)
        (only-in :poo-flow/src/module-system/profile-composition/value
                 poo-flow-composition-select))

(export poo-flow-load-composition-value)

(def (poo-flow-read-single-expression path)
  (call-with-input-file
   path
   (lambda (port)
     (let ((root (read-syntax port))
           (tail #f))
       (when (eof-object? root)
         (error "Composition value file is empty" path))
       (set! tail (read-syntax port))
       (unless (eof-object? tail)
         (error "Composition value file must contain exactly one root expression"
                path tail))
       root))))

(def (poo-flow-root-composition-selector root path)
  (let (datum (syntax->datum root))
    (unless (and (pair? datum)
                 (eq? (car datum) 'use-composition)
                 (pair? (cdr datum))
                 (null? (cddr datum))
                 (symbol? (cadr datum)))
      (error "Composition value root must be (use-composition selector)"
             path root))
    (cadr datum)))

;;; The initial value-loader contract admits the zero-override selector path.
;;; Clause expansion remains owned by the hygienic use-composition macro and is
;;; widened only together with its slot protocol and source-location tests.
(def (poo-flow-load-composition-value path catalog)
  (let* ((root (poo-flow-read-single-expression path))
         (selector (poo-flow-root-composition-selector root path))
         (composition
          (poo-flow-composition-catalog-ref catalog selector)))
    (poo-flow-composition-select composition)))
