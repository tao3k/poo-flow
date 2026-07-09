;;; -*- Gerbil -*-
;;; Boundary: compose-clause profile projection for composition stages.
;;; Invariant: projection scans metadata only; it never evaluates graph/loop.

(import (only-in :std/srfi/1 find)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/profile-composition-accessors)

(export poo-flow-composition-stage-compose-profiles)

;;; Returns profile objects selected by a stage compose clause.
;;; Scan boundary: this is a metadata lookup, not graph or loop evaluation.
;; poo-flow-composition-stage-compose-profiles
;; : (-> PooFlowCompositionStage PooProfileList)
;; | doc m%
;;   Extracts ordered profile objects selected by a stage compose clause.
;;   # Examples
;;   ```scheme
;;   (poo-flow-composition-stage-compose-profiles production-stage)
;;   ;; => []
;;   ```
(def (poo-flow-composition-stage-compose-profiles composition-stage)
  (let (compose-clause
        (find
         (lambda (clause)
           (eq? (.ref clause 'clause-kind) 'compose))
         (poo-flow-composition-stage-clauses composition-stage)))
    (if compose-clause
      (.ref compose-clause 'payload)
      [])))
