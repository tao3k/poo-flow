;;; -*- Gerbil -*-
;;; Transaction-shaped class generation and dependent-class evolution.

(import (only-in :clan/poo/object .ref)
        (only-in :clan/poo/mop element?)
        (only-in :std/sort stable-sort)
        "types.ss" "objects.ss" "classes.ss")

(export poo-clos-redefine-class poo-clos-make-instances-obsolete)

(def +poo-clos-unspecified+ (cons 'poo-clos 'unspecified))

;; : (-> ClosClass [ClosClass])
(def (live-direct-subclasses class-value)
  (.ref class-value 'direct-subclasses))

;; : (-> ClosClass [ClosClass])
(def (dependent-closure root)
  ;; Class identity is the graph key. The index makes diamond admission O(1)
  ;; while the returned list remains the stable, functional traversal value.
  (let (visited (make-hash-table-eq))
    (letrec ((visit
              (lambda (class-value result-rev)
                (if (hash-key? visited class-value)
                  result-rev
                  (begin
                    (hash-put! visited class-value #t)
                    (foldl visit
                           (cons class-value result-rev)
                           (live-direct-subclasses class-value)))))))
      (reverse (visit root '())))))

;; : (-> ClosClass Natural)
(def (class-depth class-value)
  (length (poo-clos-class-precedence-list class-value)))

;; : (-> [ClosClass] [ClosClass])
(def (sort-by-depth classes)
  (map cdr
       (stable-sort
        (map (lambda (class-value)
               (cons (class-depth class-value) class-value))
             classes)
        (lambda (left right) (< (car left) (car right))))))

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
