;;; -*- Gerbil -*-
;;; Boundary: native POO descriptors own method-combination data contracts.
;;; Invariant: no registry or surrogate record DSL participates in admission.
(import (only-in :clan/poo/object .o .ref .slot? object? compute-precedence-list!)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/sugar cut))
(export CombinationGeneric CombinationMethod CombinationBundle CombinationFailure
        CombinationPlan CombinationFrame combination-instance?)

;;; One owner-local alias marks where POO Flow specializes the upstream type
;;; metaobject rather than presenting each descriptor as a dependency adapter.
(def CombinationType. Type.)

;; : (-> POOType Symbol POOObject)
(def (combination-prototype type-value kind-value)
  (.o .type: type-value kind: kind-value schema: 'v1))

;; : (-> POOType POOObject)
(def (combination-plan-prototype type)
  (.o (:: self)
      .type: type
      kind: 'poo-combination/plan
      schema: 'v1
      valid?: (element? type self)))

;; : (-> POOObject Object Boolean)
(def (combination-instance? prototype candidate)
  (and (object? candidate)
       (if (memq prototype (compute-precedence-list! candidate)) #t #f)))

;; : (-> POOObject Symbol Procedure Boolean)
(def (field-valid? candidate name predicate)
  (and (.slot? candidate name) (predicate (.ref candidate name))))

;; : (-> POOObject (List Symbol) (List Procedure) Boolean)
(def (fields? candidate names predicates)
  (andmap (cut field-valid? candidate <> <>) names predicates))

;; : (-> Object Boolean)
(def (natural? value) (and (exact-integer? value) (>= value 0)))
;; : (-> Object Boolean)
(def (symbol-or-false? value) (or (not value) (symbol? value)))
;; : (-> Object Boolean)
(def (combination-from? value) (if (memq value '(instance type)) #t #f))
;; : (-> Object Boolean)
(def (collector-slot? value)
  (and (symbol? value)
       (not (memq value '(poo/combination/owners poo/combination/owners-valid?)))))
;; : (-> Object Boolean)
(def (method-or-false? value) (or (not value) (element? CombinationMethod value)))
;; : (-> Object Boolean)
(def (methods? value)
  (and (list? value) (andmap (cut element? CombinationMethod <>) value)))

;; : (-> Object Boolean)
(def (combination-generic-element? candidate)
  (and (combination-instance? (.ref CombinationGeneric 'proto) candidate)
       (fields? candidate '(identity collector-slot from required rest? root)
         (list symbol? collector-slot? combination-from? natural? boolean? object?))))

;;; Invariant: a generic binds dispatch ownership, arity, and root ancestry together.
(define-type (CombinationGeneric @ CombinationType.)
  proto: (combination-prototype CombinationGeneric 'poo-combination/generic)
  .element?: combination-generic-element?)

;; : (-> Object Boolean)
(def (combination-method-element? candidate)
  (and (combination-instance? (.ref CombinationMethod 'proto) candidate)
       (fields? candidate '(identity body) (list symbol? procedure?))))

;;; Boundary: method descriptors admit a stable identity and executable body only.
(define-type (CombinationMethod @ CombinationType.)
  proto: (combination-prototype CombinationMethod 'poo-combination/method)
  .element?: combination-method-element?)

;; : (-> Object Boolean)
(def (combination-bundle-element? candidate)
  (and (combination-instance? (.ref CombinationBundle 'proto) candidate)
       (fields? candidate '(around before primary after)
         (list method-or-false? method-or-false? method-or-false? method-or-false?))))

;;; Invariant: each prototype contributes at most one method per qualifier.
(define-type (CombinationBundle @ CombinationType.)
  proto: (combination-prototype CombinationBundle 'poo-combination/bundle)
  .element?: combination-bundle-element?)

;; : (-> Object Boolean)
(def (combination-failure-element? candidate)
  (and (combination-instance? (.ref CombinationFailure 'proto) candidate)
       (fields? candidate '(code generic qualifier method)
         (list symbol? symbol-or-false? symbol-or-false? symbol-or-false?))))

;;; Boundary: typed failure values preserve dispatch identity without string parsing.
(define-type (CombinationFailure @ CombinationType.)
  proto: (combination-prototype CombinationFailure 'poo-combination/failure)
  .element?: combination-failure-element?)

;; : (-> Object Boolean)
(def (combination-plan-element? candidate)
  (and (combination-instance? (.ref CombinationPlan 'proto) candidate)
       (fields? candidate '(generic around before primary after)
         (list (cut element? CombinationGeneric <>) methods? methods? methods? methods?))))

;;; Invariant: plan validity is derived from the same descriptor used by admission.
(define-type (CombinationPlan @ CombinationType.)
  proto: (combination-plan-prototype CombinationPlan)
  .element?: combination-plan-element?)

;; : (-> Object Boolean)
(def (combination-plan-instance? value)
  (combination-instance? (.ref CombinationPlan 'proto) value))
;; : (-> Object Boolean)
(def (invocation-arguments? value) (and (list? value) (pair? value)))
;; : (-> Object Boolean)
(def (next-method? value) (or (not value) (procedure? value)))
;; : (-> Object Boolean)
(def (qualifier? value) (if (memq value '(around before primary after)) #t #f))

;; : (-> Object Boolean)
(def (combination-frame-element? candidate)
  (and (combination-instance? (.ref CombinationFrame 'proto) candidate)
       (fields? candidate '(plan arguments next qualifier method)
         (list combination-plan-instance? invocation-arguments? next-method? qualifier?
               (cut element? CombinationMethod <>)))))

;;; Boundary: a frame captures one plan, argument set, continuation, qualifier, and method.
(define-type (CombinationFrame @ CombinationType.)
  proto: (combination-prototype CombinationFrame 'poo-combination/frame)
  .element?: combination-frame-element?)
