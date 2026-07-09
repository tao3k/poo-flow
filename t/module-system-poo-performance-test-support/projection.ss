;;; -*- Gerbil -*-
;;; Boundary: POO performance cases for fixed slot projection.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-ref
                 benchmark-receipt-pass?)
        (only-in :clan/poo/object
                 .get
                 .o)
        :poo-flow/t/support/poo-performance-fixtures
        :poo-flow/t/support/poo-performance)

(export module-system-poo-performance-projection-test)

;; : (-> Alist Unit)
(def (module-system-poo-performance-projection-display-receipt receipt)
  (display "[poo-flow-benchmark] ")
  (write (benchmark-fixture-ref receipt 'feature))
  (display " ")
  (write receipt)
  (newline)
  (force-output))

;; : PooObject
(def module-system-poo-performance-fixed-slot-profile
  (.o (base 11)
      (limit 17)
      (step 3)
      (weight 5)
      (offset 7)))

;; module-system-poo-performance-fixed-slot-sum
;;   : (-> PooObject Integer Integer)
;;   | doc m%
;;       Projects fixed POO lenses once, then keeps the benchmark loop scalar.
;;
;;       # Examples
;;       ```scheme
;;       (module-system-poo-performance-fixed-slot-sum
;;        module-system-poo-performance-fixed-slot-profile
;;        1)
;;       ;; => 43
;;       ```
;;     %
(def (module-system-poo-performance-fixed-slot-sum profile rounds)
  (let* ((family +poo-performance-fixed-slot-projection-family+)
         (base-lens (poo-performance-family-slot-lens family 'base))
         (limit-lens (poo-performance-family-slot-lens family 'limit))
         (step-lens (poo-performance-family-slot-lens family 'step))
         (weight-lens (poo-performance-family-slot-lens family 'weight))
         (offset-lens (poo-performance-family-slot-lens family 'offset))
         (base (poo-performance-family-slot-lens-ref base-lens profile))
         (limit (poo-performance-family-slot-lens-ref limit-lens profile))
         (step (poo-performance-family-slot-lens-ref step-lens profile))
         (weight (poo-performance-family-slot-lens-ref weight-lens profile))
         (offset (poo-performance-family-slot-lens-ref offset-lens profile))
         (slot-total (+ base limit step weight offset)))
    (+ (* slot-total rounds)
       (quotient (* rounds (- rounds 1)) 2))))

;; : TestCase
(def module-system-poo-performance-fixed-slot-projection-case
  (test-case "projects fixed POO slots once before scalar loops"
    (let* ((rounds 4000)
           (expected (module-system-poo-performance-fixed-slot-sum
                      module-system-poo-performance-fixed-slot-profile
                      rounds))
           (receipt
            (poo-performance-run-gate
             (poo-performance-fixed-slot-projection-fixture)
             (lambda ()
               (module-system-poo-performance-fixed-slot-sum
                module-system-poo-performance-fixed-slot-profile
                rounds)))))
      (check-equal? (.get module-system-poo-performance-fixed-slot-profile base)
                    11)
      (check-equal? expected 8170000)
      (module-system-poo-performance-projection-display-receipt receipt)
      (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestSuite
(def module-system-poo-performance-projection-test
  (test-suite "poo-flow module system POO projection performance"
    module-system-poo-performance-fixed-slot-projection-case))
