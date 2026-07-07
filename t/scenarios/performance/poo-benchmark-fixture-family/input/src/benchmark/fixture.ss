;;; -*- Gerbil -*-
;;; Input: benchmark fixtures are repeatedly checked as unprojected alists.

(def benchmark-fixture
  '((feature . poo-benchmark-fixture-family)
    (maxRssMb . 512)
    (memoryMetric . resident-set-size)
    (memoryUnit . "MB")
    (target_total . 25ms)
    (observed_total . 18ms)))

(def (benchmark-fixture-ref fixture key default-value)
  (let (entry (assoc key fixture))
    (if entry (cdr entry) default-value)))

(def (benchmark-fixture-hot-loop fixture rounds)
  (let loop ((round 0) (accepted 0))
    (if (>= round rounds)
      accepted
      (loop (+ round 1)
            (if (= (benchmark-fixture-ref fixture 'maxRssMb 0) 512)
              (+ accepted 1)
              accepted)))))
