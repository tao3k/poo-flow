;;; Boundary: generates the approved POO object-family predicate and accessor surface.
;;; Invariant: expansion produces ordinary POO-native bindings with no runtime registry.
(export defpoo-object-family)

(import (only-in :clan/poo/object .ref object?))

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
(defrules defpoo-object-family (accessors projections)
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
