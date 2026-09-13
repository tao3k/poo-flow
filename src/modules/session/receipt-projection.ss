;;; -*- Gerbil -*-
;;; Boundary: functional runtime helpers for session receipt projections.
;;; Invariant: helpers only transform inert receipt values; they never execute
;;; agent runtime behavior or mutate session state.

(export poo-flow-session-receipt-projection-batch)

;; : (-> List Procedure String List)
(def (poo-flow-session-receipt-projection-batch items projector error-message)
  (if (list? items)
    (map projector items)
    (error error-message items)))
