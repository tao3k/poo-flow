;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for repeated session receipt record projections.
;;; Invariant: generated forms are ordinary receipt accessors and final alist
;;; projections; they are not public authoring syntax.

(export defpoo-session-record-accessors
        defpoo-session-receipt-projection
        defpoo-session-receipt-projection-batch
        defpoo-session-record-projection)

;; defpoo-session-record-accessors
;; : (-> Syntax Syntax)
;; | doc m%
;;   Generate ordinary accessors around record-backed session receipt fields.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-record-accessors (receipt-id record-id))
;;   ;; => receipt accessor definitions
;;   ```
(defrules defpoo-session-record-accessors ()
  ((_ (accessor record-accessor) ...)
   (begin
     ;; Engineering note: policy-sensitive helpers in this owner keep explicit
     ;; contracts adjacent to definitions so downstream reports stay actionable.
     ;; : (-> Any Any)
     (def (accessor receipt)
       (record-accessor receipt))
     ...)))

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

;; defpoo-session-receipt-projection-batch
;; : (-> Syntax Syntax)
;; | doc m%
;;   Generate a batch receipt projector with a list guard and ordered rows.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-receipt-projection-batch project-all (items) (projector project))
;;   ;; => batch receipt projection definition
;;   ```
(defrules defpoo-session-receipt-projection-batch
  (projector error-message)
  ((_ constructor (items)
      (projector projector-expr)
      (error-message message-expr))
   ;; : (-> Any Any)
   (def (constructor items)
     (if (list? items)
       (let loop ((remaining-items items)
                  (rows-rev '()))
         (if (null? remaining-items)
           (reverse rows-rev)
           (loop (cdr remaining-items)
                 (cons (projector-expr (car remaining-items))
                       rows-rev))))
       (error message-expr items)))))

;; defpoo-session-record-projection
;; : (-> Syntax Syntax)
;; | doc m%
;;   Forward legacy record projection declarations to receipt projection generation.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-record-projection project (receipt) (fields ((kind kind))))
;;   ;; => receipt projection definition
;;   ```
(defrules defpoo-session-record-projection ()
  ((_ constructor arguments clause ...)
   (defpoo-session-receipt-projection constructor arguments clause ...)))
