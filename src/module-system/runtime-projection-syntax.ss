;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for runtime manifest and receipt projections.
;;; Invariant: generated forms produce final boundary alists only; they are not
;;; user-facing authoring syntax and do not execute runtime work.

(export defpoo-runtime-receipt-projection)

;; defpoo-runtime-receipt-projection
;;   : internal syntax generator for fixed runtime receipt alists.
;;     The call site names the function, argument list, local bindings, and
;;     every projected field. Expansion remains an ordinary function returning
;;     a final alist.
(defrules defpoo-runtime-receipt-projection
  (bindings fields)
  ((_ constructor (argument ...)
      (bindings ((binding-name binding-expr) ...))
      (fields ((field-key field-expr) ...)))
   (def (constructor argument ...)
     (let* ((binding-name binding-expr) ...)
       (list (cons field-key field-expr) ...)))))
