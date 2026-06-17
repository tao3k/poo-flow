;;; -*- Gerbil -*-
;;; Boundary: receipts record observed execution outcomes.
;;; Invariant: retry, scheduling, and adapter policy remain outside receipts.

(export make-receipt
        receipt?
        receipt-flow
        receipt-task
        receipt-kind
        receipt-strategy
        receipt-adapter-decision
        receipt-request-id
        receipt-input
        receipt-output
        receipt-cache
        receipt-frontier
        receipt-status
        receipt-error
        receipt-children
        receipt-ok?
        receipt-failed?)

;;; Children preserve nested execution evidence without forcing a runner to
;;; flatten or discard subflow receipts.
;;; Frontier evidence records which plan node ids were ready before the
;;; observed execution point, keeping scheduler policy inspectable after a run.
;; Receipt <- Flow Task Symbol Strategy AdapterDecision RequestId Value Value Cache [Id] Symbol Error [Receipt]
(defstruct receipt
  (flow
   task
   kind
   strategy
   adapter-decision
   request-id
   input
   output
   cache
   frontier
   status
   error
   children)
  transparent: #t)

;; Boolean <- Receipt
(def (receipt-ok? receipt)
  (eq? (receipt-status receipt) 'ok))

;; Boolean <- Receipt
(def (receipt-failed? receipt)
  (eq? (receipt-status receipt) 'failed))
