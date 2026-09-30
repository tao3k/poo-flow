;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Transaction-shaped class generation and dependent-class evolution.

(import (only-in :clan/poo/object .ref)
        (only-in :clan/poo/mop element?)
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
       (list-sort
        (lambda (left right) (< (car left) (car right)))
        (map (lambda (class-value)
               (cons (class-depth class-value) class-value))
             classes))))

;; : (forall (a) (-> Boolean a a a))
(def (redefinition-option root? supplied fallback)
  (if (and root? (not (eq? supplied +poo-clos-unspecified+)))
    supplied fallback))

;;; Stage all dependent native C4 projections before the first live mutation.
;;; The tables only connect candidate prototypes and declarations; the upstream
;;; POO linearizer still owns the order and rejection decision.
;; : (-> [ClosClass] ClosClass SchemeValue SchemeValue [Pair])
(def (preflight-dependent-projections classes root supers slots)
  (let ((prototypes (make-hash-table-eq))
        (direct-slots (make-hash-table-eq)))
    (map
     (lambda (current)
       (let* ((root? (eq? current root))
              (selected-supers
               (map poo-clos-resolve-class
                    (redefinition-option
                     root? supers (.ref current 'direct-superclasses))))
              (selected-slots
               (redefinition-option root? slots (.ref current 'direct-slots))))
         (hash-put! direct-slots current selected-slots)
         (let (projection
               (%poo-clos-project-class-redefinition
                current selected-supers
                (lambda (owner)
                  (or (hash-get prototypes owner)
                      (.ref owner 'instance-prototype)))
                (lambda (owner)
                  (or (hash-get direct-slots owner)
                      (.ref owner 'direct-slots)))))
           (hash-put! prototypes current (.ref projection 'prototype))
           (cons current projection))))
     classes)))

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
  (let* ((classes (sort-by-depth (dependent-closure class-value)))
         (projections
          (preflight-dependent-projections
           classes class-value supers slots)))
    (for-each
     (lambda (current+projection)
       (let* ((current (car current+projection))
              (root? (eq? current class-value)))
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
           root? different-handler (.ref current 'different-class-update-handler))
          projection: (cdr current+projection))))
     projections))
  class-value)

;; : (-> ClosClass ClosClass)
(def (poo-clos-make-instances-obsolete class-value)
  (poo-clos-redefine-class class-value))
