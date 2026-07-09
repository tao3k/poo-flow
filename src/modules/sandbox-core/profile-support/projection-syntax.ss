;;; -*- Gerbil -*-
;;; Boundary: hygienic helpers for sandbox-core profile support projections.
;;; Invariant: generated rows are plain alists at derivation metadata,
;;; validation, policy, and presentation receipt boundaries.

(export poo-flow-sandbox-profile-rows/tail
        poo-flow-sandbox-profile-rows-into/rev
        poo-flow-sandbox-profile-field-rows
        poo-flow-sandbox-profile-field-rows/tail)

;; : (-> List List List)
;;; Sandbox profile projection helpers build bounded row lists for profile macros.
;;; - Keep row-tail helpers pure so module syntax only forwards validated policy rows.
;; : (-> List List List)
(def (poo-flow-sandbox-profile-rows/tail rows tail)
  (foldr cons tail rows))

;; : (-> List List List)
(def (poo-flow-sandbox-profile-rows-into/rev rows rows-rev)
  (if (null? rows)
    rows-rev
    (poo-flow-sandbox-profile-rows-into/rev
     (cdr rows)
     (cons (car rows) rows-rev))))

;;; Boundary: sandbox profile field rows keep generated projections hygienic
;;; while preserving policy-visible profile slot names.
;; poo-flow-sandbox-profile-field-rows
;; : (-> SandboxProfileFieldRowsClauseSyntax SandboxProfileFieldRowsExpansionSyntax)
;; | doc m%
;;   Expands sandbox profile field clauses into stable policy-visible rows.
;;   # Examples
;;   ```scheme
;;   (poo-flow-sandbox-profile-field-rows (filesystem 'workspace))
;;   ;; => ((filesystem . workspace))
;;   ```
(defrules poo-flow-sandbox-profile-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

;;; Boundary: tail field-row expansion preserves the same projection ABI for
;;; variadic sandbox profile object clauses.
;; poo-flow-sandbox-profile-field-rows/tail
;; : (-> SandboxProfileFieldRowsTailSyntax SandboxProfileFieldRowsExpansionSyntax)
;; | doc m%
;;   Prepends sandbox profile field rows to an existing tail expression.
;;   # Examples
;;   ```scheme
;;   (poo-flow-sandbox-profile-field-rows/tail tail (network 'none))
;;   ;; => (poo-flow-sandbox-profile-rows/tail ((network . none)) tail)
;;   ```
(defrules poo-flow-sandbox-profile-field-rows/tail ()
  ((_ tail (field value) ...)
   (poo-flow-sandbox-profile-rows/tail
    (poo-flow-sandbox-profile-field-rows (field value) ...)
    tail)))
