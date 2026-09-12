;;; -*- Gerbil -*-
;;; Transaction-shaped class generation and dependent-class evolution.

(import (only-in :clan/poo/object .ref)
        (only-in :clan/poo/mop element?)
        "types.ss" "objects.ss" "classes.ss")

(export poo-clos-redefine-class poo-clos-make-instances-obsolete)

(def +poo-clos-unspecified+ (cons 'poo-clos 'unspecified))

;; : (forall (a) (-> a [a] Boolean))
(def (identity-member? value values)
  (if (memq value values) #t #f))

;; : (-> ClosClass [ClosClass])
(def (live-direct-subclasses class-value)
  (.ref class-value 'direct-subclasses))

;; : (-> ClosClass [ClosClass])
(def (dependent-closure root)
  ;; This recursive fold is dependency-graph reachability, not a transform
  ;; accumulator: identity admission prevents revisiting diamond descendants.
  (letrec ((visit
            (lambda (class-value seen)
              (if (identity-member? class-value seen)
                seen
                (foldl visit (cons class-value seen)
                       (live-direct-subclasses class-value))))))
    (reverse (visit root '()))))

;; : (-> ClosClass Natural)
(def (class-depth class-value)
  (length (poo-clos-class-precedence-list class-value)))

;; : (-> ClosClass [ClosClass] [ClosClass])
(def (insert-by-depth class-value classes)
  (cond
   ((null? classes) (list class-value))
   ((< (class-depth class-value) (class-depth (car classes)))
    (cons class-value classes))
   (else
    (cons (car classes) (insert-by-depth class-value (cdr classes))))))

;; : (-> [ClosClass] [ClosClass])
(def (sort-by-depth classes)
  (foldl insert-by-depth '() classes))

;; : (forall (a) (-> Boolean a a a))
(def (redefinition-option root? supplied fallback)
  (if (and root? (not (eq? supplied +poo-clos-unspecified+)))
    supplied fallback))

;; | ClosClass = POOObject
;; poo-clos-redefine-class
;;   : (-> ClosClass direct-superclasses: [ClosClass]
;;        direct-slots: [ClosDirectSlotDefinition] default-initargs: [Pair]
;;        slot-missing-handler: (Maybe Procedure)
;;        slot-unbound-handler: (Maybe Procedure)
;;        redefinition-update-handler: (Maybe Procedure)
;;        different-class-update-handler: (Maybe Procedure) ClosClass)
;;   | contract: mutates the existing class metaobject in place, preserving the
;;     ANSI class identity while recomputing each dependent class projection.
;;   | doc m%
;;       `poo-clos-redefine-class` preserves old slot layouts as inert evidence.
;;
;;       # Examples
;;       ```scheme
;;       (poo-clos-redefine-class class-value direct-slots: revised-slots)
;;       ;; => revised-class-generation
;;       ```
;;
;;       result: the same class metaobject with an incremented layout generation.
;;     %
(def (poo-clos-redefine-class
      class-value
      direct-superclasses: (supers +poo-clos-unspecified+)
      direct-slots: (slots +poo-clos-unspecified+)
      default-initargs: (defaults +poo-clos-unspecified+)
      slot-missing-handler: (slot-missing +poo-clos-unspecified+)
      slot-unbound-handler: (slot-unbound +poo-clos-unspecified+)
      redefinition-update-handler: (redefinition-handler
                                    +poo-clos-unspecified+)
      different-class-update-handler: (different-handler
                                       +poo-clos-unspecified+))
  (unless (element? ClosClass class-value) (clos-fail 'invalid-class))
  (for-each
   (lambda (current)
     (let (root? (eq? current class-value))
       (%poo-clos-reinitialize-class!
        current
        (map poo-clos-resolve-class
             (redefinition-option
              root? supers (.ref current 'direct-superclasses)))
        (redefinition-option root? slots (.ref current 'direct-slots))
        (redefinition-option
         root? defaults (.ref current 'default-initargs))
        (redefinition-option
         root? slot-missing (.ref current 'slot-missing-handler))
        (redefinition-option
         root? slot-unbound (.ref current 'slot-unbound-handler))
        (redefinition-option
         root? redefinition-handler (.ref current 'redefinition-update-handler))
        (redefinition-option
         root? different-handler (.ref current 'different-class-update-handler)))))
   (sort-by-depth (dependent-closure class-value)))
  class-value)

;; : (-> ClosClass ClosClass)
(def (poo-clos-make-instances-obsolete class-value)
  (poo-clos-redefine-class class-value))
