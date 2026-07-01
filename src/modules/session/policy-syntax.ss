;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for repeated session policy object families.
;;; Invariant: macros expand to ordinary public constructors over POO-native
;;; session policy objects. They are internal generation helpers, not a user DSL.

(export defpoo-session-policy-family
        defpoo-session-policy-slot-accessors
        defpoo-session-alist-accessors
        defpoo-session-object-accessors
        defpoo-session-policy-projection
        defpoo-session-object-projection
        defpoo-session-object-projection-batch)

;; : (-> List List List)
(def (poo-flow-session-policy-rows/tail rows tail)
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

;; defpoo-session-policy-family
;;   : internal syntax generator for a session policy constructor family.
;;     The call site supplies the base constructor, contract symbols, parameter
;;     names, slot projection keys, and runtime validations. Expansion remains
;;     plain Scheme code that calls =poo-flow-session-policy-object=.
(defrules defpoo-session-policy-family
  (kind schema default-action scope-ref parameters slots validate)
  ((_ constructor policy-object
      (kind kind-expr)
      (schema schema-expr)
      (default-action default-action-expr)
      (scope-ref scope-ref-expr)
      (parameters (policy-name arg ... . maybe-metadata))
      (slots ((slot-key slot-value) ...))
      (validate validation ...))
   (def (constructor policy-name arg ... . maybe-metadata)
     validation ...
     (apply policy-object
            kind-expr
            schema-expr
            policy-name
            scope-ref-expr
            default-action-expr
            (list (cons slot-key slot-value) ...)
            maybe-metadata)))
  ((_ constructor policy-object
      (kind kind-expr)
      (schema schema-expr)
      (default-action default-action-expr)
      (parameters (policy-name scope-ref-param arg ... . maybe-metadata))
      (slots ((slot-key slot-value) ...))
      (validate validation ...))
   (def (constructor policy-name scope-ref-param arg ... . maybe-metadata)
     validation ...
     (apply policy-object
            kind-expr
            schema-expr
            policy-name
            scope-ref-param
            default-action-expr
            (list (cons slot-key slot-value) ...)
            maybe-metadata))))

;; defpoo-session-policy-slot-accessors
;;   : internal accessor generator for POO-backed policy slots.
;;     Accessor names stay public and ordinary; the macro removes only the
;;     repeated slot/default frame.
(defrules defpoo-session-policy-slot-accessors ()
  ((_ slot-reader
      (accessor slot-key default-expr)
      ...)
   (begin
     (def (accessor policy)
       (slot-reader policy 'slot-key default-expr))
     ...)))

;; defpoo-session-alist-accessors
;;   : internal accessor generator for final alist-shaped helper rows.
;;     It is used only for boundary helper records such as tool grants.
(defrules defpoo-session-alist-accessors ()
  ((_ alist-ref
      (accessor slot-key default-expr)
      ...)
   (begin
     (def (accessor value)
       (alist-ref value 'slot-key default-expr))
     ...)))

;; defpoo-session-object-accessors
;;   : internal accessor generator for POO-backed receipt objects.
;;     Use this for stable receipt rows whose public accessor names are ordinary
;;     functions and whose values are final report data.
(defrules defpoo-session-object-accessors ()
  ((_ object-ref
      (accessor slot-key)
      ...)
   (begin
     (def (accessor value)
       (object-ref value 'slot-key))
     ...)))

;; defpoo-session-policy-projection
;;   : internal projection generator for the stable session policy alist.
;;     Rows are explicit and ordered at the call site. Slot rows go through the
;;     named slot reader; value rows keep derived expressions visible.
(defrules defpoo-session-policy-projection
  (require slot-reader durable rows slot value)
  ((_ constructor
      (policy)
      (require require-proc message policy-predicate)
      (slot-reader slot-reader-proc)
      (durable durable-rows-proc)
      (rows row ...))
   (def (constructor policy)
     (require-proc message (policy-predicate policy) policy)
     (poo-flow-session-policy-rows/tail
      (list
       (defpoo-session-policy-projection-row policy
                                             slot-reader-proc
                                             row)
       ...)
      (durable-rows-proc policy)))))

(defrules defpoo-session-policy-projection-row
  (slot value)
  ((_ policy slot-reader (slot slot-key default-expr))
   (cons 'slot-key (slot-reader policy 'slot-key default-expr)))
  ((_ policy _slot-reader (value field-key field-expr))
   (cons 'field-key field-expr)))

;; defpoo-session-object-projection
;;   : internal projection generator for POO receipt objects.
;;     Rows remain explicit and ordered at the call site. Slot rows read through
;;     the named object reader; value rows keep derived expressions visible.
(defrules defpoo-session-object-projection
  (require object-reader rows slot value)
  ((_ constructor
      (object)
      (require require-proc message object-predicate)
      (object-reader object-reader-proc)
      (rows row ...))
   (def (constructor object)
     (require-proc message (object-predicate object) object)
     (list
      (defpoo-session-object-projection-row object
                                            object-reader-proc
                                            row)
      ...))))

(defrules defpoo-session-object-projection-row
  (slot value)
  ((_ object object-reader (slot slot-key))
   (cons 'slot-key (object-reader object 'slot-key)))
  ((_ object _object-reader (value field-key field-expr))
   (cons 'field-key field-expr)))

;; defpoo-session-object-projection-batch
;;   : internal collection projector for session object-backed receipt alists.
;;     The row projector stays visible at the call site; the generated function
;;     supplies only the common list guard and map frame.
(defrules defpoo-session-object-projection-batch
  (projector error-message)
  ((_ constructor (items)
      (projector projector-expr)
      (error-message message-expr))
   (def (constructor items)
     (if (list? items)
       (map projector-expr items)
       (error message-expr items)))))
