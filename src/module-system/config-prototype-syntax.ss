;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for module config POO prototype declarations.
;;; Invariant: generated forms are ordinary POO objects and predicates; public
;;; config authoring remains prototype composition plus named conversion helpers.

(import (only-in :clan/poo/object .ref .slot? object? object<-alist))

(export defpoo-module-config-prototype
        defpoo-module-config-kind-predicate
        defpoo-module-config-converter)

;; defpoo-module-config-prototype
;;   : internal declaration helper for fixed POO config prototype objects.
;;     The call site owns every slot and default value. The macro removes only
;;     the repeated object<-alist/list/cons frame.
(defrules defpoo-module-config-prototype
  (slots)
  ((_ binding
      (slots ((slot-key slot-value) ...)))
   (def binding
     (object<-alist
      (list (cons 'slot-key slot-value) ...)))))

;; defpoo-module-config-kind-predicate
;;   : internal predicate helper for prototype objects identified by a kind
;;     slot. Predicate names stay public ordinary functions.
(defrules defpoo-module-config-kind-predicate ()
  ((_ predicate kind-expr)
   (def (predicate value)
     (and (object? value)
          (.slot? value 'kind)
          (eq? (.ref value 'kind) kind-expr)))))

;; defpoo-module-config-converter
;;   : internal converter helper for prototype-to-domain constructors. The call
;;     site names the constructor and every argument; the macro removes only the
;;     repeated `.ref` frame around prototype slots.
(defrules defpoo-module-config-converter
  (constructor arguments slot value)
  ((_ converter (prototype argument ...)
      (constructor constructor-expr)
      (arguments argument-row ...))
   (def (converter prototype argument ...)
     (constructor-expr
      (defpoo-module-config-converter-argument prototype argument-row)
      ...))))

(defrules defpoo-module-config-converter-argument
  (slot value)
  ((_ prototype (slot slot-key))
   (.ref prototype 'slot-key))
  ((_ _prototype (value value-expr))
   value-expr))
