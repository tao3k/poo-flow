;;; -*- Gerbil -*-
;;; Boundary: shared performance-test helpers for synthetic fixture data.
;;; Invariant: helper functions are pure except elapsed measurement thunks.

(import :gerbil/gambit
        (only-in :std/srfi/1 iota))

(export poo-flow-performance-build-list
        poo-flow-performance-elapsed-ms
        poo-flow-performance-best-elapsed-ms)

;;; Intent: construct deterministic index-addressed fixture lists.
;;; Boundary: callers own the item constructor and count.
;; : (-> Integer (-> Integer Object) [Object])
(def (poo-flow-performance-build-list count make-value)
  (map make-value (iota count)))

;;; Intent: measure one thunk execution in milliseconds.
;;; Boundary: the thunk owns side effects; this helper owns only timing.
;; : (-> (-> Unit Object) Rational)
(def (poo-flow-performance-elapsed-ms thunk)
  (let (start-jiffy (current-jiffy))
    (thunk)
    (/ (* (- (current-jiffy) start-jiffy) 1000)
       (jiffies-per-second))))

;;; Intent: report the best elapsed time across repeated benchmark attempts.
;;; Boundary: zero attempts preserves the previous #f result shape.
;; : (-> Integer (-> Unit Object) Object)
(def (poo-flow-performance-best-elapsed-ms attempts thunk)
  (if (<= attempts 0)
    #f
    (apply min
           (map (lambda (_attempt)
                  (poo-flow-performance-elapsed-ms thunk))
                (iota attempts)))))
