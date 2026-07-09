;;; -*- Gerbil -*-
;;; Boundary: POO accessors for profile composition objects.
;;; Invariant: accessors do not interpret graph, loop, or proof payloads.

(import (only-in :clan/poo/object .ref))

(export poo-flow-composition?
        poo-flow-composition-name
        poo-flow-composition-modules
        poo-flow-composition-profiles
        poo-flow-composition-stages
        poo-flow-composition-stage-name
        poo-flow-composition-stage-clauses)

;;; Recognizes the top-level profile composition object.
;;   | doc m%
;;       # Examples
;;       (poo-flow-composition? composition)
;;   | result: #t only for objects tagged as poo-flow.composition
;; : (-> PooFlowCompositionCandidate Bool)
(def (poo-flow-composition? value)
  (eq? (.ref value 'kind) 'poo-flow.composition))

;;; Returns the symbolic composition name.
;;   | doc m%
;;       # Examples
;;       (poo-flow-composition-name composition)
;;   | result: composition name symbol
;; : (-> PooFlowComposition Symbol)
(def (poo-flow-composition-name composition)
  (.ref composition 'name))

;;; Returns module alias binding objects captured by the composer.
;;   | doc m%
;;       # Examples
;;       (poo-flow-composition-modules composition)
;;   | result: ordered module binding objects
;; : (-> PooFlowComposition List)
(def (poo-flow-composition-modules composition)
  (.ref composition 'modules))

;;; Returns top-level profiles selected by the composition.
;; : (-> PooFlowComposition List)
(def (poo-flow-composition-profiles composition)
  (.ref composition 'profiles))

;;; Returns all stages in declaration order.
;;   | doc m%
;;       # Examples
;;       (poo-flow-composition-stages composition)
;;   | result: ordered composition stages
;; : (-> PooFlowComposition List)
(def (poo-flow-composition-stages composition)
  (.ref composition 'stages))

;;; Returns the name of a composition stage.
;;   | doc m%
;;       # Examples
;;       (poo-flow-composition-stage-name production-stage)
;;   | result: stage name symbol
;; : (-> PooFlowCompositionStage Symbol)
(def (poo-flow-composition-stage-name composition-stage)
  (.ref composition-stage 'name))

;;; Returns raw clause objects stored on a stage.
;;   | doc m%
;;       # Examples
;;       (poo-flow-composition-stage-clauses production-stage)
;;   | result: ordered stage clause objects
;; : (-> PooFlowCompositionStage List)
(def (poo-flow-composition-stage-clauses composition-stage)
  (.ref composition-stage 'clauses))
