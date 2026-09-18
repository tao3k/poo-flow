;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO accessors for profile composition objects.
;;; Invariant: accessors do not interpret graph, loop, or proof payloads.

(import (only-in :clan/poo/object .ref))

(export poo-flow-scenario-case-name
        poo-flow-scenario-case-modules
        poo-flow-scenario-case-profiles
        poo-flow-scenario-case-stages
        poo-flow-scenario-stage-name
        poo-flow-scenario-stage-clauses)

;;; Returns the symbolic composition name.
;;   | doc m%
;;       # Examples
;;       (poo-flow-scenario-case-name composition)
;;   | result: composition name symbol
;; : (-> PooFlowScenarioCase Symbol)
(def (poo-flow-scenario-case-name composition)
  (.ref composition 'name))

;;; Returns module alias binding objects captured by the composer.
;;   | doc m%
;;       # Examples
;;       (poo-flow-scenario-case-modules composition)
;;   | result: ordered module binding objects
;; : (-> PooFlowScenarioCase List)
(def (poo-flow-scenario-case-modules composition)
  (.ref composition 'modules))

;;; Returns top-level profiles selected by the composition.
;; : (-> PooFlowScenarioCase List)
(def (poo-flow-scenario-case-profiles composition)
  (.ref composition 'profiles))

;;; Returns all stages in declaration order.
;;   | doc m%
;;       # Examples
;;       (poo-flow-scenario-case-stages composition)
;;   | result: ordered composition stages
;; : (-> PooFlowScenarioCase List)
(def (poo-flow-scenario-case-stages composition)
  (.ref composition 'stages))

;;; Returns the name of a composition stage.
;;   | doc m%
;;       # Examples
;;       (poo-flow-scenario-stage-name production-stage)
;;   | result: stage name symbol
;; : (-> PooFlowScenarioStage Symbol)
(def (poo-flow-scenario-stage-name composition-stage)
  (.ref composition-stage 'name))

;;; Returns raw clause objects stored on a stage.
;;   | doc m%
;;       # Examples
;;       (poo-flow-scenario-stage-clauses production-stage)
;;   | result: ordered stage clause objects
;; : (-> PooFlowScenarioStage List)
(def (poo-flow-scenario-stage-clauses composition-stage)
  (.ref composition-stage 'clauses))
