;;; -*- Gerbil -*-
;;; Boundary: hygienic helpers for workflow CI/CD final row projections.
;;; Invariant: generated rows are plain alists at POO object, runtime manifest,
;;; receipt, pipeline, and Marlin handoff boundaries.

(export poo-flow-cicd-rows/tail
        poo-flow-cicd-rows-into/rev
        poo-flow-cicd-field-rows
        poo-flow-cicd-field-rows/tail)

;; : (-> List List List)
(def (poo-flow-cicd-rows/tail rows tail)
  (foldr cons tail rows))

;; : (-> List List List)
(def (poo-flow-cicd-rows-into/rev rows rows-rev)
  (if (null? rows)
    rows-rev
    (poo-flow-cicd-rows-into/rev
     (cdr rows)
     (cons (car rows) rows-rev))))

;;; Boundary: CI/CD field rows keep workflow projection macros hygienic while
;;; preserving pipeline slot names for runtime handoff.
;; poo-flow-cicd-field-rows
;; : (-> CicdFieldRowsClauseSyntax CicdFieldRowsExpansionSyntax)
;; | doc m%
;;   Expands CI/CD pipeline field clauses into stable projection rows.
;;   # Examples
;;   ```scheme
;;   (poo-flow-cicd-field-rows (pipeline 'default))
;;   ;; => ((pipeline . default))
;;   ```
(defrules poo-flow-cicd-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

;;; Boundary: CI/CD tail field rows preserve the projection ABI for variadic
;;; pipeline clauses.
;; poo-flow-cicd-field-rows/tail
;; : (-> CicdFieldRowsTailSyntax CicdRowsExpansionSyntax)
;; | doc m%
;;   Prepends CI/CD field rows to an existing pipeline row tail.
;;   # Examples
;;   ```scheme
;;   (poo-flow-cicd-field-rows/tail tail (checks 'unit))
;;   ;; => (poo-flow-cicd-rows/tail ((checks . unit)) tail)
;;   ```
(defrules poo-flow-cicd-field-rows/tail ()
  ((_ tail (field value) ...)
   (poo-flow-cicd-rows/tail
    (poo-flow-cicd-field-rows (field value) ...)
    tail)))
