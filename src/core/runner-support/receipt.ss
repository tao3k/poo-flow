;;; -*- Gerbil -*-
;;; Boundary: receipt traversal helpers used by runner recovery projections.

(import :poo-flow/src/core/receipt)

(export first-failed-receipt)

;;; Receipt trees preserve nested subflow and adapter evidence. The first
;;; failed receipt is the recovery target closest to execution.
;; : (-> Receipt MaybeReceipt)
(def (first-failed-receipt receipt)
  (if (receipt-failed? receipt)
    receipt
    (first-failed-receipt-in (receipt-children receipt))))

;;; Boundary: first failed receipt in is the policy-visible edge for core
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [Receipt] MaybeReceipt)
(def (first-failed-receipt-in receipts)
  (if (null? receipts)
    #f
    (let (failed (first-failed-receipt (car receipts)))
      (if failed
        failed
        (first-failed-receipt-in (cdr receipts))))))
