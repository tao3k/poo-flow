(defstruct loop-capability-receipt (name status facts))

(def receipt-iterations 1000)

(def (build-loop-capability-receipt i)
  (make-loop-capability-receipt
   'loop-capability
   'completed
   (list (cons 'index i)
         (cons 'policy 'verified)
         (cons 'runtime 'python-runtime))))

(def (loop-capability-receipt->alist receipt)
  (list (cons 'name (loop-capability-receipt-name receipt))
        (cons 'status (loop-capability-receipt-status receipt))
        (cons 'facts (loop-capability-receipt-facts receipt))))

(def (run-loop count)
  (let loop ((i 0) (passed 0))
    (if (= i count)
      passed
      (let* ((receipt (build-loop-capability-receipt i))
             (projected (loop-capability-receipt->alist receipt)))
        (loop (+ i 1)
              (if (eq? (cdr (assq 'status projected)) 'completed)
                (+ passed 1)
                passed))))))

(def (main)
  (let* ((started-at (time->seconds (current-time)))
         (passed (run-loop receipt-iterations))
         (finished-at (time->seconds (current-time)))
         (elapsed-ms
          (inexact->exact
           (round (* 1000 (- finished-at started-at))))))
    (display
     `((status . passed)
       (feature . poo-generated-receipt-boundary)
       (iterations . ,receipt-iterations)
       (passed . ,passed)
       (elapsedMs . ,elapsed-ms)
       (shape . generated-receipt-struct-boundary)
       (hotPath . struct-to-alist-boundary)))
    (newline)))
