;;; -*- Gerbil -*-
;;; Boundary: loop-engine POO prototype-kind predicates.
;;; Invariant: only recognized prototype descendants lower into report rows.

(import (only-in :clan/poo/object .ref .slot? object?)
        :poo-flow/src/module-system/loop-engine-prototypes)

(export poo-flow-user-loop-engine-poo-kind?
        poo-flow-user-loop-engine-poo-use-case?
        poo-flow-user-loop-engine-poo-profile?)

;;; Prototype-kind matching is the inheritance gate for every loop-engine POO
;;; object before it can lower into report rows.
;; : (-> Value Symbol Boolean)
(def (poo-flow-user-loop-engine-poo-kind? value kind)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) kind)))

;;; Use-case objects are the only accepted roots for single-loop row lowering;
;;; the predicate is public because tests and diagnostics assert this boundary.
;; : (-> PooFlowLoopEngineUseCaseCandidate Boolean)
(def (poo-flow-user-loop-engine-poo-use-case? value)
  (poo-flow-user-loop-engine-poo-kind?
   value
   +poo-flow-user-loop-engine-use-case-prototype-kind+))

;;; Profile objects are the public `:config` root. Rejecting non-profile values
;;; here keeps downstream modules from smuggling arbitrary POO objects into
;;; runtime handoff projection.
;; : (-> PooFlowLoopEngineProfileCandidate Boolean)
(def (poo-flow-user-loop-engine-poo-profile? value)
  (poo-flow-user-loop-engine-poo-kind?
   value
   +poo-flow-user-loop-engine-profile-prototype-kind+))
