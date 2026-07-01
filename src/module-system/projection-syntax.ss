;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for module-system final alist projections.
;;; Invariant: generated functions are inspection, receipt, or presentation
;;; boundaries only; module activation and resolver logic stay explicit.

(export poo-flow-module-rows/tail
        poo-flow-module-rows-into/rev
        poo-flow-module-field-rows
        poo-flow-module-field-rows/tail
        defpoo-module-final-projection
        defpoo-module-final-projection-batch)

;; : (-> List List List)
(def (poo-flow-module-rows/tail rows tail)
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

;; : (-> List List List)
(def (poo-flow-module-rows-into/rev rows rows-rev)
  (if (null? rows)
    rows-rev
    (poo-flow-module-rows-into/rev
     (cdr rows)
     (cons (car rows) rows-rev))))

(defrules poo-flow-module-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

(defrules poo-flow-module-field-rows/tail ()
  ((_ tail (field value) ...)
   (poo-flow-module-rows/tail
    (poo-flow-module-field-rows (field value) ...)
    tail)))

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
