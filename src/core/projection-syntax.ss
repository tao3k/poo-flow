;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for core receipt/projection alists.
;;; Invariant: generated functions are final boundary projections only; public
;;; object construction remains ordinary core code.

(export defpoo-core-receipt-projection)

;; defpoo-core-receipt-projection
;;   : internal syntax generator for fixed core receipt alists.
;;     The call site names the function, arguments, local bindings, and every
;;     projected field so expansion stays ordinary Scheme. Field names are
;;     fixed alist keys, not expressions.
(defrules defpoo-core-receipt-projection
  (bindings fields)
  ((_ constructor (argument ...)
      (bindings ((binding-name binding-expr) ...))
      (fields ((field-key field-expr) ...)))
   (def (constructor argument ...)
     (let* ((binding-name binding-expr) ...)
       (list (cons 'field-key field-expr) ...)))))
