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
  (foldr cons tail rows))

;; defpoo-session-policy-family
;; : (-> Syntax Syntax)
;; | doc m%
;;   Generate a session policy constructor family while keeping runtime
;;   validation in the generated ordinary function.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-policy-family make-policy object (kind k) ...)
;;   ;; => policy constructor definitions
;;   ```
(defrules defpoo-session-policy-family
  (kind schema default-action scope-ref parameters slots validate
        emit scope-ref-value)
  ((_ constructor policy-object
      (kind kind-expr)
      (schema schema-expr)
      (default-action default-action-expr)
      (scope-ref scope-ref-expr)
      (parameters (policy-name arg ... . maybe-metadata))
      (slots ((slot-key slot-value) ...))
      (validate validation ...))
   (defpoo-session-policy-family
    (emit constructor policy-object
      (kind kind-expr)
      (schema schema-expr)
      (default-action default-action-expr)
      (parameters (policy-name arg ... . maybe-metadata))
      (scope-ref-value scope-ref-expr)
      (slots ((slot-key slot-value) ...))
      (validate validation ...))))
  ((_ constructor policy-object
      (kind kind-expr)
      (schema schema-expr)
      (default-action default-action-expr)
      (parameters (policy-name scope-ref-param arg ... . maybe-metadata))
      (slots ((slot-key slot-value) ...))
      (validate validation ...))
   (defpoo-session-policy-family
    (emit constructor policy-object
      (kind kind-expr)
      (schema schema-expr)
      (default-action default-action-expr)
      (parameters
       (policy-name scope-ref-param arg ... . maybe-metadata))
      (scope-ref-value scope-ref-param)
      (slots ((slot-key slot-value) ...))
      (validate validation ...))))
  ((_ (emit constructor policy-object
       (kind kind-expr)
       (schema schema-expr)
       (default-action default-action-expr)
       (parameters (policy-name arg ... . maybe-metadata))
       (scope-ref-value scope-ref-expr)
       (slots ((slot-key slot-value) ...))
       (validate validation ...)))
   ;; Engineering note: policy-sensitive helpers in this owner keep explicit
   ;; contracts adjacent to definitions so downstream reports stay actionable.
   ;; : (-> Any Any)
   (def (constructor policy-name arg ... . maybe-metadata)
     validation ...
     (apply policy-object
            kind-expr
            schema-expr
            policy-name
            scope-ref-expr
            default-action-expr
            (list (cons slot-key slot-value) ...)
            maybe-metadata))))

;; defpoo-session-policy-slot-accessors
;; : (-> Syntax Syntax)
;; | doc m%
;;   Generate ordinary accessors for repeated POO-backed policy slots.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-policy-slot-accessors read (name key default))
;;   ;; => slot accessor definitions
;;   ```
(defrules defpoo-session-policy-slot-accessors ()
  ((_ slot-reader
      (accessor slot-key default-expr)
      ...)
   (begin
     ;; : (-> Any Any)
     (def (accessor policy)
       (slot-reader policy 'slot-key default-expr))
     ...)))

;; defpoo-session-alist-accessors
;; : (-> Syntax Syntax)
;; | doc m%
;;   Generate accessors for bounded alist helper rows such as tool grants.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-alist-accessors read (tool tool #f))
;;   ;; => alist accessor definitions
;;   ```
(defrules defpoo-session-alist-accessors ()
  ((_ alist-ref
      (accessor slot-key default-expr)
      ...)
   (begin
     ;; : (-> Any Any)
     (def (accessor value)
       (alist-ref value 'slot-key default-expr))
     ...)))

;; defpoo-session-object-accessors
;; : (-> Syntax Syntax)
;; | doc m%
;;   Generate accessors for stable POO-backed receipt objects.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-object-accessors read (kind kind))
;;   ;; => object accessor definitions
;;   ```
(defrules defpoo-session-object-accessors ()
  ((_ object-ref
      (accessor slot-key)
      ...)
   (begin
     ;; : (-> Any Any)
     (def (accessor value)
       (object-ref value 'slot-key))
     ...)))

;; defpoo-session-policy-projection
;; : (-> Syntax Syntax)
;; | doc m%
;;   Generate one stable session policy alist projection with explicit rows.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-policy-projection project (policy) (rows (value kind kind)))
;;   ;; => policy projection definition
;;   ```
(defrules defpoo-session-policy-projection
  (require slot-reader durable rows slot value)
  ((_ constructor
      (policy)
      (require require-proc message policy-predicate)
      (slot-reader slot-reader-proc)
      (durable durable-rows-proc)
      (rows row ...))
   ;; : (-> Any Any)
   (def (constructor policy)
     (require-proc message (policy-predicate policy) policy)
     (poo-flow-session-policy-rows/tail
      (list
       (defpoo-session-policy-projection-row policy
                                             slot-reader-proc
                                             row)
       ...)
      (durable-rows-proc policy)))))

;;; Boundary: policy projection rows keep macro-generated policy receipt fields
;;; hygienic and contract-visible.
;; defpoo-session-policy-projection-row
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expand one policy projection row as either a slot read or derived value.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-policy-projection-row policy read (value kind kind))
;;   ;; => projection row pair
;;   ```
(defrules defpoo-session-policy-projection-row
  (slot value)
  ((_ policy slot-reader (slot slot-key default-expr))
   (cons 'slot-key (slot-reader policy 'slot-key default-expr)))
  ((_ policy _slot-reader (value field-key field-expr))
   (cons 'field-key field-expr)))

;; defpoo-session-object-projection
;; : (-> Syntax Syntax)
;; | doc m%
;;   Generate one stable POO object projection with explicit ordered rows.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-object-projection project (object) (rows (slot kind)))
;;   ;; => object projection definition
;;   ```
(defrules defpoo-session-object-projection
  (require object-reader rows slot value)
  ((_ constructor
      (object)
      (require require-proc message object-predicate)
      (object-reader object-reader-proc)
      (rows row ...))
   ;; : (-> Any Any)
   (def (constructor object)
     (require-proc message (object-predicate object) object)
     (list
      (defpoo-session-object-projection-row object
                                            object-reader-proc
                                            row)
      ...))))

;;; Boundary: object projection rows preserve POO slot semantics when session
;;; policy macros lower object fields into receipts.
;; defpoo-session-object-projection-row
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expand one object projection row as either a POO slot read or derived value.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-object-projection-row object read (slot kind))
;;   ;; => object projection row pair
;;   ```
(defrules defpoo-session-object-projection-row
  (slot value)
  ((_ object object-reader (slot slot-key))
   (cons 'slot-key (object-reader object 'slot-key)))
  ((_ object _object-reader (value field-key field-expr))
   (cons 'field-key field-expr)))

;; defpoo-session-object-projection-batch
;; : (-> Syntax Syntax)
;; | doc m%
;;   Generate a batch projector with one list guard and an explicit row projector.
;;   # Examples
;;   ```scheme
;;   (defpoo-session-object-projection-batch project-all (items) (projector project))
;;   ;; => batch projection definition
;;   ```
(defrules defpoo-session-object-projection-batch
  (projector error-message)
  ((_ constructor (items)
      (projector projector-expr)
      (error-message message-expr))
   ;; : (-> Any Any)
   (def (constructor items)
     (if (list? items)
       (map projector-expr items)
       (error message-expr items)))))
