;;; -*- Gerbil -*-
;;; Boundary: compose-clause profile projection for composition stages.
;;; Invariant: projection scans metadata only; it never evaluates graph/loop.

(import (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/profile-composition-accessors)

(export poo-flow-composition-stage-compose-profiles)

;;; Returns profile objects selected by a stage compose clause.
;;; Scan boundary: this is a metadata lookup, not graph or loop evaluation.
;;   | doc m%
;;       # Examples
;;       (poo-flow-composition-stage-compose-profiles production-stage)
;;   | result: ordered profile objects selected from module slots
;; : (-> PooFlowCompositionStage PooProfileList)
(def (poo-flow-composition-stage-compose-profiles composition-stage)
  (let loop ((clauses (poo-flow-composition-stage-clauses
                       composition-stage)))
    (cond
     ((null? clauses) [])
     ((eq? (.ref (car clauses) 'clause-kind) 'compose)
      (.ref (car clauses) 'payload))
     (else (loop (cdr clauses))))))
