;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for module-system final alist projections.
;;; Invariant: generated functions are inspection, receipt, or presentation
;;; boundaries only; module activation and resolver logic stay explicit.

(export defpoo-module-final-projection
        defpoo-module-final-projection-batch)

;; defpoo-module-final-projection
;;   : internal syntax generator for fixed module-system alist projections.
;;     Rows are explicit and ordered at the call site. Field keys are fixed
;;     symbols, not dynamic expressions. Guarded rows preserve existing safe
;;     defaults for legacy projection inputs while keeping the final shape
;;     explicit.
(defrules defpoo-module-final-projection
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

;; defpoo-module-final-projection-batch
;;   : internal syntax generator for bounded final projection batches. The
;;     single-row projector stays explicit at the call site; the generated
;;     collection function owns only the list guard and map frame.
(defrules defpoo-module-final-projection-batch
  (projector error-message)
  ((_ constructor (items)
      (projector projector-expr)
      (error-message message-expr))
   (def (constructor items)
     (if (list? items)
       (map projector-expr items)
       (error message-expr items)))))
