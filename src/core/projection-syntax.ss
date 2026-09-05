;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for core receipt/projection alists.
;;; Invariant: generated functions are final boundary projections only; public
;;; object construction remains ordinary core code.

(export poo-flow-core-rows/tail
        poo-flow-core-field-rows
        poo-flow-core-field-rows/tail
        defpoo-core-receipt-projection)

;;; Core projection row helpers are deliberately small: macro-generated
;;; receipt functions use them only to assemble final alist boundaries.
;; poo-flow-core-rows/tail
;;   : (-> Alist Alist Alist)
;;   | contract: ordered core projection rows followed by caller-owned tail rows
;;   | result: a fresh ordered alist preserving the row sequence before tail
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-core-rows/tail '((kind . receipt)) '((metadata)))
;;       ;; => ((kind . receipt) (metadata))
;;       ```
;;     %
(def (poo-flow-core-rows/tail rows tail)
  (append rows tail))

;; poo-flow-core-field-rows
;;   : (-> Syntax Alist)
;;   | contract: lower fixed field clauses into literal alist rows
;;   | result: ordered alist rows with symbols matching the field names
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-core-field-rows (kind 'receipt) (status 'ok))
;;       ;; => ((kind . receipt) (status . ok))
;;       ```
;;     %
(defrules poo-flow-core-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

;; poo-flow-core-field-rows/tail
;;   : (-> Syntax Alist)
;;   | contract: lower fixed field clauses and append caller-owned tail rows
;;   | result: ordered field rows followed by the supplied tail alist
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-core-field-rows/tail '((metadata)) (kind 'receipt))
;;       ;; => ((kind . receipt) (metadata))
;;       ```
;;     %
(defrules poo-flow-core-field-rows/tail ()
  ((_ tail (field value) ...)
   (poo-flow-core-rows/tail
    (poo-flow-core-field-rows (field value) ...)
    tail)))

;; defpoo-core-receipt-projection
;;   : (-> Syntax Definition)
;;   | contract: generate fixed core receipt projection functions
;;   | result: the generated function returns an ordered core receipt alist
;;   | doc m%
;;       The call site names the function, arguments, local bindings, and every
;;       projected field so expansion stays ordinary Scheme. Field names are
;;       fixed alist keys, not expressions, and generated functions keep
;;       projection-only behavior at the core receipt boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-core-receipt-projection make-row (value)
;;         (bindings ((status-value 'ok)))
;;         (fields ((kind 'receipt)
;;                  (status status-value))))
;;       ;; => (make-row 1)
;;       ;; => ((kind . receipt) (status . ok))
;;       ```
;;     %
(defrules defpoo-core-receipt-projection
  (bindings fields)
  ((_ constructor (argument ...)
      (bindings ((binding-name binding-expr) ...))
      (fields ((field-key field-expr) ...)))
   (def (constructor argument ...)
     (let* ((binding-name binding-expr) ...)
       (list (cons 'field-key field-expr) ...)))))
