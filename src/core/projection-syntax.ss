;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for core receipt/projection alists.
;;; Invariant: generated functions are final boundary projections only; public
;;; object construction remains ordinary core code.

(export poo-flow-core-rows/tail
        poo-flow-core-field-rows
        poo-flow-core-field-rows/tail
        defpoo-core-receipt-projection)

;; : (-> List List List)
(def (poo-flow-core-rows/tail rows tail)
  (let loop ((remaining-rows rows)
             (rows-rev '()))
    (if (null? remaining-rows)
      (let restore ((remaining-rev rows-rev)
                    (result tail))
        (if (null? remaining-rev)
          result
          (restore (cdr remaining-rev)
                   (cons (car remaining-rev) result))))
      (loop (cdr remaining-rows)
            (cons (car remaining-rows) rows-rev)))))

(defrules poo-flow-core-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

(defrules poo-flow-core-field-rows/tail ()
  ((_ tail (field value) ...)
   (poo-flow-core-rows/tail
    (poo-flow-core-field-rows (field value) ...)
    tail)))

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
