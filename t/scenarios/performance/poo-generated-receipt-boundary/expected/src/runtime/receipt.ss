;;; Scenario expected: the receipt boundary is generated once as a struct, and
;;; ->alist is the only runtime-language projection boundary.

(defstruct loop-capability-receipt (name status facts))

(def (build-loop-capability-receipt name status facts)
  (make-loop-capability-receipt name status facts))

(def (loop-capability-receipt->alist receipt)
  (list (cons 'name (loop-capability-receipt-name receipt))
        (cons 'status (loop-capability-receipt-status receipt))
        (cons 'facts (loop-capability-receipt-facts receipt))))
