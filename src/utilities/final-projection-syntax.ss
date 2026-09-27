;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: shared hygienic macros for final alist projections.
;;; Invariant: generated functions are inspection, receipt, or presentation
;;; boundaries only; module activation and resolver logic stay explicit.

(import :poo-flow/src/utilities/product-syntax)

(export poo-flow-product-rows/tail
        poo-flow-product-rows-into/rev
        poo-flow-product-field-rows
        poo-flow-product-field-rows/tail
        defpoo-final-projection
        defpoo-final-projection-batch)

;; defpoo-final-projection
;;   : (-> ProjectionDeclaration Syntax)
;;   | contract: generate one fixed alist projection function
;;   | doc m%
;;       Rows are explicit and ordered at the call site. Field keys are fixed
;;       symbols, not dynamic expressions. Guarded rows provide an explicit
;;       fallback while keeping the final shape explicit.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-final-projection module->alist (module)
;;         (bindings ())
;;         (fields ((kind 'module))))
;;       ;; => defines module->alist
;;       ```
;;     %
(defrules defpoo-final-projection
  (guard bindings fields)
  ((_ constructor (argument ...)
      (guard guard-expr fallback-expr)
      (bindings ((binding-name binding-expr) ...))
      (fields ((field-key field-expr) ...)))
   (def (constructor argument ...)
     (if guard-expr
       (let* ((binding-name binding-expr) ...)
         (list (cons 'field-key field-expr) ...))
       fallback-expr)))
  ((_ constructor (argument ...)
      (bindings ((binding-name binding-expr) ...))
      (fields ((field-key field-expr) ...)))
   (def (constructor argument ...)
     (let* ((binding-name binding-expr) ...)
       (list (cons 'field-key field-expr) ...)))))

;; defpoo-final-projection-batch
;;   : (-> ProjectionBatchDeclaration Syntax)
;;   | contract: generate a guarded map projection over a list of values
;;   | doc m%
;;       The single-row projector stays explicit at the call site; the generated
;;       collection function owns only the list guard and map frame.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-final-projection-batch modules->alist (items)
;;         (projector module->alist)
;;         (error-message "expected modules"))
;;       ;; => defines modules->alist
;;       ```
;;     %
(defrules defpoo-final-projection-batch
  (projector error-message)
  ((_ constructor (items)
      (projector projector-expr)
      (error-message message-expr))
   (def (constructor items)
     (if (list? items)
       (map projector-expr items)
       (error message-expr items)))))
