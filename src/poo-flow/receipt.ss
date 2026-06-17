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
        receipt-status
        receipt-error
        receipt-children
        receipt-ok?
        receipt-failed?)

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
   status
   error
   children)
  transparent: #t)

(def (receipt-ok? receipt)
  (eq? (receipt-status receipt) 'ok))

(def (receipt-failed? receipt)
  (eq? (receipt-status receipt) 'failed))
