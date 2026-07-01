;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for repeated session receipt record projections.
;;; Invariant: generated forms are ordinary receipt accessors and final alist
;;; projections; they are not public authoring syntax.

(export defpoo-session-record-accessors
        defpoo-session-receipt-projection
        defpoo-session-receipt-projection-batch
        defpoo-session-record-projection)

;; defpoo-session-record-accessors
;;   : internal accessor generator for record-backed session receipts.
;;     Public accessor names stay ordinary functions; the macro removes only the
;;     repeated wrapper frame around generated record accessors.
(defrules defpoo-session-record-accessors ()
  ((_ (accessor record-accessor) ...)
   (begin
     (def (accessor receipt)
       (record-accessor receipt))
     ...)))

;; defpoo-session-receipt-projection
;;   : internal projection generator for stable receipt alists.
;;     Rows remain explicit and ordered at the call site. Bindings keep repeated
;;     derived values visible without hiding receipt policy decisions. Optional
;;     require clauses keep receipt validation at the generated function
;;     boundary.
(defrules defpoo-session-receipt-projection
  (require bindings fields)
  ((_ constructor (argument ...)
      (require require-proc message valid-expr subject-expr)
      (bindings ((binding-name binding-expr) ...))
      (fields ((field-key field-expr) ...)))
   (def (constructor argument ...)
     (require-proc message valid-expr subject-expr)
     (let* ((binding-name binding-expr) ...)
       (list (cons field-key field-expr) ...))))
  ((_ constructor (argument ...)
      (bindings ((binding-name binding-expr) ...))
      (fields ((field-key field-expr) ...)))
   (def (constructor argument ...)
     (let* ((binding-name binding-expr) ...)
       (list (cons field-key field-expr) ...)))))

;; defpoo-session-receipt-projection-batch
;;   : internal collection projector for session receipt alists. The single
;;     receipt projection remains explicit; this macro owns only the shared
;;     list guard and ordered accumulator frame.
(defrules defpoo-session-receipt-projection-batch
  (projector error-message)
  ((_ constructor (items)
      (projector projector-expr)
      (error-message message-expr))
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

;; Backward-compatible name for the first record-backed slices. New session
;; receipt projections should use =defpoo-session-receipt-projection=.
(defrules defpoo-session-record-projection ()
  ((_ constructor arguments clause ...)
   (defpoo-session-receipt-projection constructor arguments clause ...)))
