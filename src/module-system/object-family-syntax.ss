(export defpoo-object-family)

(import (only-in :clan/poo/object .ref object?))

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
