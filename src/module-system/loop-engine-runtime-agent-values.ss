;;; -*- Gerbil -*-
;;; Boundary: loop-engine runtime agent row/list projection helpers.
;;; Invariant: helpers are pure datum transforms over already-materialized
;;; receipt rows; they do not realize runtime sessions or tool calls.

(import :poo-flow/src/module-system/loop-engine-core)

(export poo-flow-loop-engine-runtime-agent-field-values
        poo-flow-loop-engine-runtime-agent-flat-field-values
        poo-flow-loop-engine-runtime-agent-unique)

;;; Field projection preserves row order for receipt comparison.
;; : (-> [Alist] Symbol [Datum])
(def (poo-flow-loop-engine-runtime-agent-field-values rows key)
  (map (lambda (row)
         (poo-flow-user-loop-engine-intent-ref row key #f))
       rows))

;;; Flat field projection preserves row and in-row order without building
;;; intermediate nested rows.
;; : (-> [Alist] Symbol [Datum])
(def (poo-flow-loop-engine-runtime-agent-flat-field-values rows key)
  (reverse
   (foldl (lambda (row values)
            (let (value
                  (poo-flow-user-loop-engine-intent-ref row key #f))
              (cond
               ((not value) values)
               ((list? value) (foldl cons values value))
               (else (cons value values)))))
          '()
          rows)))

;;; Uniqueness keeps the first visible declaration for topology diagnostics.
;; : (-> [Datum] [Datum])
(def (poo-flow-loop-engine-runtime-agent-unique values)
  (reverse
   (foldl (lambda (value unique)
            (if (member value unique)
              unique
              (cons value unique)))
          '()
          values)))
