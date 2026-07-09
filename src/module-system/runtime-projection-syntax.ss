;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for runtime manifest and receipt projections.
;;; Invariant: generated forms produce final boundary alists only; they are not
;;; user-facing authoring syntax and do not execute runtime work.

(export defpoo-runtime-receipt-projection)

;; defpoo-runtime-receipt-projection
;; : (-> Syntax Syntax)
;; | doc m%
;;   Declare a bounded runtime receipt projection that evaluates local
;;   bindings once and serializes fixed fields for ABI handoff.
;;   # Examples
;;   ```scheme
;;   (defpoo-runtime-receipt-projection make-receipt (r)
;;     (bindings ((status (runtime-response-status r))))
;;     (fields ((status status))))
;;   ;; => make-receipt
;;   ```
(defrules defpoo-runtime-receipt-projection
  (bindings fields)
  ((_ constructor (argument ...)
      (bindings ((binding-name binding-expr) ...))
      (fields ((field-key field-expr) ...)))
   ;; Engineering note: policy-sensitive helpers in this owner keep explicit
   ;; contracts adjacent to definitions so downstream reports stay actionable.
   ;; : (-> Any Any)
   (def (constructor argument ...)
     (let* ((binding-name binding-expr) ...)
       (list (cons field-key field-expr) ...)))))
