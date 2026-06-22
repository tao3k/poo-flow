;;; -*- Gerbil -*-
;;; Boundary: small alist row helpers for loop-engine report projection.
;;; Invariant: helpers only shape rows; they never validate or execute runtime.

(export poo-flow-user-loop-engine-optional-row
        poo-flow-user-loop-engine-optional-list-row)

;;; Optional scalar projection keeps receipt alists compact: absent optional
;;; slots are omitted instead of serialized as false-valued rows.
;; : (-> Symbol Value Alist)
(def (poo-flow-user-loop-engine-optional-row key value)
  (if value (list (cons key value)) '()))

;;; Optional list projection mirrors scalar projection while preserving empty
;;; lists as "no declaration" for report-only policy slots.
;; : (-> Symbol Value Alist)
(def (poo-flow-user-loop-engine-optional-list-row key value)
  (if (null? value) '() (list (cons key value))))
