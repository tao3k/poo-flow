;;; -*- Gerbil -*-
;;; Boundary: POO builders for profile composition objects.
;;; Invariant: builders store selected profile objects, not registry keys.

(import (only-in :clan/poo/object .o .ref))

(export poo-flow-profile-ref
        poo-flow-composition-module-binding
        poo-flow-composition-clause
        poo-flow-composition-stage
        poo-flow-composition-object
        poo-flow-composition-profile-binding
        poo-flow-composition-object/profile-bindings
        poo-flow-composition-object/profiles)

;;; Selects a profile slot from a POO module object.
;;   | doc m%
;;       # Examples
;;       (poo-flow-profile-ref session 'hardened)
;;   | result: selected profile object stored on the module slot
;; : (-> PooModule Symbol PooProfile)
(import :poo-flow/src/utilities/functional)

(export poo-flow-composition-multiplicity
        poo-flow-composition-launch-range
        poo-flow-composition-multiplicities->launch-ranges
        poo-flow-composition-workload
        poo-flow-composition-workload/ref)

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
  (poo-flow-composition-object/profiles name module-bindings '() stages))

;;; Builds the top-level composition object with composition-level profiles.
;; : (-> Symbol List List List PooFlowComposition)
(def (poo-flow-composition-profile-binding alias slot)
  (let ((alias-value alias)
        (slot-value slot))
    (.o (kind 'poo-flow.composition.profile-binding)
        (alias alias-value)
        (slot slot-value))))

(def (poo-flow-composition-object/profile-bindings
      name module-bindings profiles stages profile-bindings)
  (let ((name-value name)
        (module-bindings-value module-bindings)
        (profiles-value profiles)
        (stages-value stages)
        (profile-bindings-value profile-bindings))
    (.o (kind 'poo-flow.composition)
        (name name-value)
        (modules module-bindings-value)
        (profiles profiles-value)
        (stages stages-value)
        (profile-bindings profile-bindings-value))))

(def (poo-flow-composition-multiplicity composition count)
  (unless (and (integer? count) (> count 0))
    (error "POO Flow composition multiplicity must be a positive integer"
           count))
  (let ((composition-value composition)
        (count-value count))
    (.o (kind 'poo-flow.composition.multiplicity)
        (composition composition-value)
        (count count-value))))

(def (poo-flow-composition-launch-range composition start count)
  (unless (and (integer? start) (>= start 0))
    (error "POO Flow composition launch range start must be a non-negative integer"
           start))
  (unless (and (integer? count) (> count 0))
    (error "POO Flow composition launch range count must be a positive integer"
           count))
  (let ((composition-value composition)
        (start-value start)
        (count-value count))
    (.o (kind 'poo-flow.composition.launch-range)
        (composition composition-value)
        (start start-value)
        (count count-value)
        (end (+ start-value count-value)))))

(def (poo-flow-composition-multiplicities->launch-ranges multiplicities)
  (unless (and (list? multiplicities) (pair? multiplicities))
    (error "POO Flow composition workload requires at least one multiplicity"))
  (let* ((state
          (poo-flow-fold-left
           (lambda (multiplicity state)
             (unless (eq? (.ref multiplicity 'kind)
                          'poo-flow.composition.multiplicity)
               (error "POO Flow composition workload requires multiplicity objects"
                      multiplicity))
             (let* ((start (car state))
                    (ranges (cdr state))
                    (count (.ref multiplicity 'count))
                    (launch-range
                     (poo-flow-composition-launch-range
                      (.ref multiplicity 'composition)
                      start
                      count)))
               (cons (+ start count)
                     (cons launch-range ranges))))
           (cons 0 '())
           multiplicities))
         (ranges (cdr state)))
    (list->vector (reverse ranges))))

(def (poo-flow-composition-workload multiplicities)
  (let* ((launch-ranges-value
          (poo-flow-composition-multiplicities->launch-ranges multiplicities))
         (last-range
          (vector-ref launch-ranges-value
                      (- (vector-length launch-ranges-value) 1)))
         (total-count-value (.ref last-range 'end)))
    (.o (kind 'poo-flow.composition.workload)
        (launch-ranges launch-ranges-value)
        (total-count total-count-value))))

(def (poo-flow-composition-workload/ref workload ordinal)
  (let ((total-count (.ref workload 'total-count))
        (launch-ranges (.ref workload 'launch-ranges)))
    (unless (and (integer? ordinal)
                 (>= ordinal 0)
                 (< ordinal total-count))
      (error "POO Flow composition workload ordinal is out of range"
             ordinal
             total-count))
    (let loop ((low 0)
               (high (- (vector-length launch-ranges) 1)))
      (let* ((middle (quotient (+ low high) 2))
             (launch-range (vector-ref launch-ranges middle))
             (start (.ref launch-range 'start))
             (end (.ref launch-range 'end)))
        (cond
         ((< ordinal start)
          (loop low (- middle 1)))
         ((>= ordinal end)
          (loop (+ middle 1) high))
         (else
          (let ((composition-value (.ref launch-range 'composition))
                (launch-range-value launch-range)
                (ordinal-value ordinal)
                (local-ordinal-value (- ordinal start)))
            (.o (kind 'poo-flow.composition.instance-ref)
                (composition composition-value)
                (launch-range launch-range-value)
                (ordinal ordinal-value)
                (local-ordinal local-ordinal-value)))))))))

(def (poo-flow-composition-object/profiles name module-bindings profiles stages)
  (poo-flow-composition-object/profile-bindings
   name module-bindings profiles stages '()))
