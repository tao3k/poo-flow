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

;; poo-flow-module-rows/tail
;;   : (-> List List List)
;;   | contract: append fixed projection rows before already-owned tail rows
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-rows/tail '((kind . module)) '((name . core)))
;;       ;; => ((kind . module) (name . core))
;;       ```
;;     %
(def (poo-flow-module-rows/tail rows tail)
  (append rows tail))

;; poo-flow-module-rows-into/rev
;;   : (-> List List List)
;;   | contract: prepend rows in reverse order onto an existing reversed spine
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-rows-into/rev '(a b) '(tail))
;;       ;; => (b a tail)
;;       ```
;;     %
(def (poo-flow-module-rows-into/rev rows rows-rev)
  (append (reverse rows) rows-rev))

;; poo-flow-module-field-rows
;;   : (-> FieldRow... Alist)
;;   | contract: lower fixed field clauses to ordered alist rows
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-field-rows (kind 'module) (name 'core))
;;       ;; => ((kind . module) (name . core))
;;       ```
;;     %
(defrules poo-flow-module-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

;; poo-flow-module-field-rows/tail
;;   : (-> List FieldRow... Alist)
;;   | contract: lower fixed field clauses and append caller-owned tail rows
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-field-rows/tail '((tail . value)) (kind 'module))
;;       ;; => ((kind . module) (tail . value))
;;       ```
;;     %
(defrules poo-flow-module-field-rows/tail ()
  ((_ tail (field value) ...)
   (poo-flow-module-rows/tail
    (poo-flow-module-field-rows (field value) ...)
    tail)))

;; defpoo-module-final-projection
;;   : (-> ProjectionDeclaration Syntax)
;;   | contract: generate one fixed module-system alist projection function
;;   | doc m%
;;       Rows are explicit and ordered at the call site. Field keys are fixed
;;       symbols, not dynamic expressions. Guarded rows preserve existing safe
;;       defaults for legacy projection inputs while keeping the final shape
;;       explicit.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-module-final-projection module->alist (module)
;;         (bindings ())
;;         (fields ((kind 'module))))
;;       ;; => defines module->alist
;;       ```
;;     %
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
;;   : (-> ProjectionBatchDeclaration Syntax)
;;   | contract: generate a guarded map projection over a list of values
;;   | doc m%
;;       The single-row projector stays explicit at the call site; the generated
;;       collection function owns only the list guard and map frame.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-module-final-projection-batch modules->alist (items)
;;         (projector module->alist)
;;         (error-message "expected modules"))
;;       ;; => defines modules->alist
;;       ```
;;     %
(defrules defpoo-module-final-projection-batch
  (projector error-message)
  ((_ constructor (items)
      (projector projector-expr)
      (error-message message-expr))
   (def (constructor items)
     (if (list? items)
       (map projector-expr items)
       (error message-expr items)))))
