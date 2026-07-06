;;; -*- Gerbil -*-
;;; Boundary: POO builders for profile composition objects.
;;; Invariant: builders store selected profile objects, not registry keys.

(import (only-in :clan/poo/object .o .ref))

(export poo-flow-profile-ref
        poo-flow-composition-module-binding
        poo-flow-composition-clause
        poo-flow-composition-stage
        poo-flow-composition-object)

;;; Selects a profile slot from a POO module object.
;;   | doc m%
;;       # Examples
;;       (poo-flow-profile-ref session 'hardened)
;;   | result: selected profile object stored on the module slot
;; : (-> PooModule Symbol PooProfile)
(def (poo-flow-profile-ref module slot)
  (.ref module slot))

;;; Captures the lexical alias and module object used by a composition.
;;   | doc m%
;;       # Examples
;;       (poo-flow-composition-module-binding 'session session-module)
;;   | result: module binding metadata object
;; : (-> Symbol PooModule PooFlowCompositionModuleBinding)
(def (poo-flow-composition-module-binding alias module)
  (let ((alias-value alias)
        (module-value module))
    (.o (kind 'poo-flow.composition.module)
        (alias alias-value)
        (module module-value))))

;;; Stores one stage clause payload without interpreting engine semantics.
;;   | doc m%
;;       # Examples
;;       (poo-flow-composition-clause 'graph '(guarded-flow))
;;   | result: clause object tagged by clause kind
;; : (-> Symbol PooFlowCompositionPayload PooFlowCompositionClause)
(def (poo-flow-composition-clause kind payload)
  (let ((kind-value kind)
        (payload-value payload))
    (.o (kind 'poo-flow.composition.clause)
        (clause-kind kind-value)
        (payload payload-value))))

;;; Builds a named composition stage from clause objects.
;;   | doc m%
;;       # Examples
;;       (poo-flow-composition-stage 'production clauses)
;;   | result: stage object with name and ordered clauses
;; : (-> Symbol List PooFlowCompositionStage)
(def (poo-flow-composition-stage name clauses)
  (let ((name-value name)
        (clauses-value clauses))
    (.o (kind 'poo-flow.composition.stage)
        (name name-value)
        (clauses clauses-value))))

;;; Builds the top-level composition object.
;;   | doc m%
;;       # Examples
;;       (poo-flow-composition-object 'rag module-bindings stages)
;;   | result: composition object containing module bindings and stages
;; : (-> Symbol List List PooFlowComposition)
(def (poo-flow-composition-object name module-bindings stages)
  (let ((name-value name)
        (module-bindings-value module-bindings)
        (stages-value stages))
    (.o (kind 'poo-flow.composition)
        (name name-value)
        (modules module-bindings-value)
        (stages stages-value))))
