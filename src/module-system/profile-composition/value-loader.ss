;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: source-located, single-expression Composition value files.
;;; Invariant: loading reads one root selector and performs no imports, exports,
;;; directory discovery, Runtime construction or Session execution.

(import (only-in :gerbil/expander/core eval-syntax)
        (only-in :gerbil/expander/stx datum->syntax stx-source syntax->datum)
        (only-in :poo-flow/src/module-system/profile-composition/catalog
                 current-poo-flow-composition-catalog))

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

(def (poo-flow-validate-composition-root root path)
  (let (datum (syntax->datum root))
    (unless (and (pair? datum)
                 (eq? (car datum) 'use-composition)
                 (pair? (cdr datum))
                 (symbol? (cadr datum)))
      (error "Composition value root must be (use-composition selector ...)"
             path root))
    root))

;;; The bounded prelude is implementation-owned. Downstream value files contain
;;; no import/export forms; the exact public macro used by ordinary modules also
;;; expands the loaded root, so there is no second clause interpreter.
(def (poo-flow-load-composition-value path catalog)
  (let* ((root
          (poo-flow-validate-composition-root
           (poo-flow-read-single-expression path)
           path))
         (bounded-form
          (datum->syntax
           #f
           (list
            'begin
            '(import :poo-flow/src/module-system/profile-composition/interface)
            (syntax->datum root))
           (stx-source root))))
    (parameterize
        ((current-poo-flow-composition-catalog catalog))
      (eval-syntax bounded-form))))
