;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO builders for profile composition objects.
;;; Invariant: builders store selected profile objects, not registry keys.

(import (only-in :clan/poo/object .o .ref))

(export poo-flow-profile-ref
        poo-flow-scenario-module-binding
        poo-flow-scenario-profile-binding)

;;; Selects a profile slot from a POO module object.
;;   | doc m%
;;       # Examples
;;       (poo-flow-profile-ref session 'hardened)
;;   | result: selected profile object stored on the module slot
;; : (-> PooModule Symbol PooProfile)
(import :poo-flow/src/utilities/functional)

(export poo-flow-scenario-case-multiplicity
        poo-flow-scenario-case-launch-range
        poo-flow-scenario-case-multiplicities->launch-ranges
        poo-flow-scenario-case-workload
        poo-flow-scenario-case-workload/ref)

(def (poo-flow-profile-ref module slot)
  (.ref module slot))

;;; Captures the lexical alias and module object used by a composition.
;;   | doc m%
;;       # Examples
;;       (poo-flow-scenario-module-binding 'session session-module)
;;   | result: module binding metadata object
;; : (-> Symbol PooModule PooFlowScenarioModuleBinding)
(def (poo-flow-scenario-module-binding alias module)
  (let ((alias-value alias)
        (module-value module))
    (.o (kind 'poo-flow.scenario.module-binding.v1)
        (alias alias-value)
        (module module-value))))

;;; Builds the top-level composition object with composition-level profiles.
;; : (-> Symbol List List List PooFlowScenarioCase)
(def (poo-flow-scenario-profile-binding alias slot)
  (let ((alias-value alias)
        (slot-value slot))
    (.o (kind 'poo-flow.scenario.profile-binding.v1)
        (alias alias-value)
        (slot slot-value))))


(def (poo-flow-scenario-case-multiplicity composition count)
  (unless (and (integer? count) (> count 0))
    (error "POO Flow composition multiplicity must be a positive integer"
           count))
  (let ((composition-value composition)
        (count-value count))
    (.o (kind 'poo-flow.scenario.multiplicity.v1)
        (composition composition-value)
        (count count-value))))

(def (poo-flow-scenario-case-launch-range composition start count)
  (unless (and (integer? start) (>= start 0))
    (error "POO Flow composition launch range start must be a non-negative integer"
           start))
  (unless (and (integer? count) (> count 0))
    (error "POO Flow composition launch range count must be a positive integer"
           count))
  (let ((composition-value composition)
        (start-value start)
        (count-value count))
    (.o (kind 'poo-flow.scenario.launch-range.v1)
        (composition composition-value)
        (start start-value)
        (count count-value)
        (end (+ start-value count-value)))))

(def (poo-flow-scenario-case-multiplicities->launch-ranges multiplicities)
  (unless (and (list? multiplicities) (pair? multiplicities))
    (error "POO Flow composition workload requires at least one multiplicity"))
  (let* ((state
          (poo-flow-fold-left
           (lambda (multiplicity state)
             (unless (eq? (.ref multiplicity 'kind)
                          'poo-flow.scenario.multiplicity.v1)
               (error "POO Flow composition workload requires multiplicity objects"
                      multiplicity))
             (let* ((start (car state))
                    (ranges (cdr state))
                    (count (.ref multiplicity 'count))
                    (launch-range
                     (poo-flow-scenario-case-launch-range
                      (.ref multiplicity 'composition)
                      start
                      count)))
               (cons (+ start count)
                     (cons launch-range ranges))))
           (cons 0 '())
           multiplicities))
         (ranges (cdr state)))
    (list->vector (reverse ranges))))

(def (poo-flow-scenario-case-workload multiplicities)
  (let* ((launch-ranges-value
          (poo-flow-scenario-case-multiplicities->launch-ranges multiplicities))
         (last-range
          (vector-ref launch-ranges-value
                      (- (vector-length launch-ranges-value) 1)))
         (total-count-value (.ref last-range 'end)))
    (.o (kind 'poo-flow.scenario.workload.v1)
        (launch-ranges launch-ranges-value)
        (total-count total-count-value))))

;; : (-> PooFlowScenarioLaunchRange Integer Integer
;;       PooFlowScenarioInstanceRef)
(def (poo-flow-scenario-case-instance-ref launch-range ordinal start)
  (let ((composition-value (.ref launch-range 'composition))
        (launch-range-value launch-range)
        (ordinal-value ordinal)
        (local-ordinal-value (- ordinal start)))
    (.o (kind 'poo-flow.scenario.instance-ref.v1)
        (composition composition-value)
        (launch-range launch-range-value)
        (ordinal ordinal-value)
        (local-ordinal local-ordinal-value))))

;; Binary search remains a bounded lookup over the immutable range vector; the
;; recursive helper makes its search boundary explicit instead of accumulating
;; a list transform in the public workload accessor.
;; : (-> Vector Integer Integer Integer PooFlowScenarioInstanceRef)
(def (poo-flow-scenario-case-launch-range-ref launch-ranges ordinal low high)
  (let* ((middle (quotient (+ low high) 2))
         (launch-range (vector-ref launch-ranges middle))
         (start (.ref launch-range 'start))
         (end (.ref launch-range 'end)))
    (cond
     ((< ordinal start)
      (poo-flow-scenario-case-launch-range-ref
       launch-ranges ordinal low (- middle 1)))
     ((>= ordinal end)
      (poo-flow-scenario-case-launch-range-ref
       launch-ranges ordinal (+ middle 1) high))
     (else
      (poo-flow-scenario-case-instance-ref launch-range ordinal start)))))

(def (poo-flow-scenario-case-workload/ref workload ordinal)
  (let ((total-count (.ref workload 'total-count))
        (launch-ranges (.ref workload 'launch-ranges)))
    (unless (and (integer? ordinal)
                 (>= ordinal 0)
                 (< ordinal total-count))
      (error "POO Flow composition workload ordinal is out of range"
             ordinal
             total-count))
    (poo-flow-scenario-case-launch-range-ref
     launch-ranges ordinal 0 (- (vector-length launch-ranges) 1))))
