;;; Pure POO values governed by existing CLOS class and effective-slot metadata.
;;; These are snapshots, not mutable CLOS lifecycle instances.
(import (only-in :clan/poo/object .o .ref .slot? object? compute-precedence-list!)
        (only-in :poo-flow/src/module-system/poo-clos/classes
                 poo-clos-class poo-clos-direct-slot-definition
                 poo-clos-class-effective-slots))
(export poo-clos-class poo-clos-direct-slot-definition
        poo-flow-model-prototype poo-flow-model? poo-flow-check-model)

(def (poo-flow-model-prototype class-value)
  (.ref class-value 'instance-prototype))

;;; Check actual prototype ancestry and every inherited predicate. A copied
;;; kind or class marker is insufficient; derived slot overrides are rechecked.
(def (poo-flow-model? class-value candidate)
  (and (object? candidate)
       (memq (poo-flow-model-prototype class-value)
             (compute-precedence-list! candidate))
       (andmap
        (lambda (slot)
          (let (name (.ref slot 'identity))
            (and (eq? (.ref slot 'allocation) 'instance)
                 (.slot? candidate name)
                 (andmap (lambda (predicate) (predicate (.ref candidate name)))
                         (.ref slot 'type-predicates)))))
        (poo-clos-class-effective-slots class-value))
       #t))

(def (poo-flow-check-model class-value candidate)
  (unless (poo-flow-model? class-value candidate)
    (error "invalid POO model" (.ref class-value 'identity)))
  candidate)
