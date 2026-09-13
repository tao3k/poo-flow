;;; -*- Gerbil -*-
;;; Boundary: functional helpers for repeated session receipt projections.
;;; Invariant: receipt owners define ordinary functions and delegate only the
;;; shared list traversal here; this module is not a user syntax surface.

(export defpoo-session-receipt-projection)

;; defpoo-session-receipt-projection
;; : (-> Syntax Syntax)
;; | doc m%
;;   Generate a stable receipt alist projection with optional validation.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-receipt-projection project (receipt) (fields ((kind kind))))
;;   ;; => receipt projection definition
;;   ```
(defrules defpoo-session-receipt-projection
  (require bindings fields)
  ((_ constructor (argument ...)
      (require require-proc message valid-expr subject-expr)
      (bindings ((binding-name binding-expr) ...))
      (fields ((field-key field-expr) ...)))
   ;; : (-> Any Any)
   (def (constructor argument ...)
     (require-proc message valid-expr subject-expr)
     (let* ((binding-name binding-expr) ...)
       (list (cons field-key field-expr) ...))))
  ((_ constructor (argument ...)
      (bindings ((binding-name binding-expr) ...))
      (fields ((field-key field-expr) ...)))
   ;; : (-> Any Any)
   (def (constructor argument ...)
     (let* ((binding-name binding-expr) ...)
       (list (cons field-key field-expr) ...)))))
