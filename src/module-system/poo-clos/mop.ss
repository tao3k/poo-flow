;;; -*- Gerbil -*-
;;; Separately admitted, read-only MOP-EXTENDED capability profile.

(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop element?)
        "types.ss" "objects.ss")

(export ClosMopProfile poo-clos-mop-extended-profile
        poo-clos-mop-profile-admits?)

;; : POOObject
(def ClosMopProfile. (.ref ClosMopProfile 'proto))

;; | ClosMopProfile = POOObject
;; poo-clos-mop-extended-profile
;;   : (-> ClosMopProfile)
;;   | contract: returns the closed portable extension inventory without
;;     registering new metaclasses or changing native POO dispatch.
;;   | doc m%
;;       `poo-clos-mop-extended-profile` separates de facto MOP capabilities
;;       from the ANSI CLOS conformance profile.
;;
;;       # Examples
;;       ```scheme
;;       (poo-clos-mop-extended-profile)
;;       ;; => sealed-mop-profile
;;       ```
;;
;;       result: a checked read-only POO capability descriptor.
;;     %
(def (poo-clos-mop-extended-profile)
  (checked
   ClosMopProfile
   (.o (:: @ ClosMopProfile.)
       identity: 'mop-extended version: 'v1 status: 'admitted
       operations:
       '(class-name class-generation class-direct-superclasses
         class-direct-subclasses class-direct-slots class-default-initargs
         class-predecessor class-successor class-obsolete?
         slot-name slot-allocation slot-initargs slot-readers slot-writers
         slot-defining-classes slot-storage-class
         specializer-kind specializer-object
         method-name method-qualifiers method-specializers method-lambda-list
         generic-name generic-methods generic-lambda-list
         generic-argument-precedence-order generic-method-combination
         generic-generation)
       dependency-readers:
       '(class-direct-superclasses class-direct-subclasses
         class-predecessor class-successor)
       customization-protocols:
       '(no-applicable-method no-next-method compute-applicable-methods
         compute-effective-method update-instance-for-redefined-class
         update-instance-for-different-class slot-missing slot-unbound)
       sealed?: #t
       documentation:
       "Portable read-only MOP subset; native POO owns C3 and metaobject identity")
   'invalid-mop-profile))

;; : (-> ClosMopProfile Symbol Boolean)
(def (poo-clos-mop-profile-admits? profile-value operation)
  (unless (element? ClosMopProfile profile-value)
    (clos-fail 'invalid-mop-profile))
  (if (memq operation (.ref profile-value 'operations)) #t #f))
