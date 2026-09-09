;;; Boundary: generates the approved POO object-family predicate and accessor surface.
;;; Invariant: expansion produces ordinary POO-native bindings with no runtime registry.
(export defpoo-object-family)

(import (only-in :clan/poo/object .o .ref .slot? object?))

;; defpoo-object-family
;;   : (-> Identifier Identifier Clauses ObjectFamilyBindings)
;;   | doc m%
;;       Generate a POO object predicate, accessors, and alist projections.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-object-family kind predicate (accessors) (projections))
;;       ;; => binds the declared object family helpers
;;       ```
;;     %
(defrules defpoo-object-family (prototype constructor accessors projections)
  ((_ (accessors (accessor-name slot-name) ...)
      (projections
       (projection-name (field-name projection-slot-name) ...) ...))
   (begin
     (def (accessor-name value)
       (.ref value 'slot-name))
     ...
     (def (projection-name value)
       (list
        (cons 'field-name (.ref value 'projection-slot-name))
        ...))
     ...))
  ((_ (reader reader-name)
      (accessors (accessor-name slot-name) ...))
   (begin
     (def (accessor-name value)
       (reader-name value slot-name))
     ...))
  ((_ (prototype prototype-name marker-slot predicate-name)
      (constructor constructor-name (argument-name slot-name) ...)
      (accessors (accessor-name accessor-slot-name) ...)
      (projections
       (projection-name (field-name projection-slot-name) ...) ...))
   (begin
     (def prototype-name
       (.o (marker-slot #t)))
     (def (constructor-name argument-name ...)
       (.o (:: @ prototype-name)
           (slot-name argument-name) ...))
     (def (predicate-name value)
       (and (object? value)
            (.slot? value 'marker-slot)
            (.ref value 'marker-slot)))
     (def (accessor-name value)
       (.ref value 'accessor-slot-name))
     ...
     (def (projection-name value)
       (list
        (cons 'field-name (.ref value 'projection-slot-name))
        ...))
     ...))
  ((_ (prototype prototype-name marker-slot predicate-name
                 (prototype-slot prototype-value) ...)
      (constructor constructor-name (argument-name slot-name) ...)
      (accessors (accessor-name accessor-slot-name) ...)
      (projections
       (projection-name (field-name projection-slot-name) ...) ...))
   (begin
     (def prototype-name
       (.o (marker-slot #t)
           (prototype-slot prototype-value) ...))
     (def (constructor-name argument-name ...)
       (.o (:: @ prototype-name)
           (slot-name argument-name) ...))
     (def (predicate-name value)
       (and (object? value)
            (.slot? value 'marker-slot)
            (.ref value 'marker-slot)))
     (def (accessor-name value)
       (.ref value 'accessor-slot-name))
     ...
     (def (projection-name value)
       (list
        (cons 'field-name (.ref value 'projection-slot-name))
        ...))
     ...))
  ((_ kind-constant predicate-name
      (accessors (accessor-name slot-name) ...)
      (projections
       (projection-name (field-name projection-slot-name) ...) ...))
   (begin
     (def (predicate-name value)
       (and (object? value)
            (with-catch
             (lambda (_failure) #f)
             (lambda ()
               (eq? (.ref value 'kind) kind-constant)))))
     (def (accessor-name value)
       (.ref value 'slot-name))
     ...
     (def (projection-name value)
       (list
        (cons 'field-name (.ref value 'projection-slot-name))
        ...))
     ...)))
