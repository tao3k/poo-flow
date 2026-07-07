;;; -*- Gerbil -*-
;;; Boundary: executable exercise for fixed-slot POO projection performance.

(import (only-in :clan/poo/object
                 .get
                 .o))

(def fixed-slot-profile
  (.o (base 11)
      (limit 17)
      (step 3)
      (weight 5)
      (offset 7)))

(def (fixed-slot-sum profile rounds)
  (let* ((base (.get profile base))
         (limit (.get profile limit))
         (step (.get profile step))
         (weight (.get profile weight))
         (offset (.get profile offset))
         (slot-total (+ base limit step weight offset)))
    (let loop ((round 0) (total 0))
      (if (>= round rounds)
        total
        (loop (+ round 1)
              (+ total slot-total round))))))

(unless (= (.get fixed-slot-profile base) 11)
  (error "fixed slot profile base drifted"))

(unless (= (fixed-slot-sum fixed-slot-profile 4000) 8170000)
  (error "fixed slot projection proof count drifted"))

(void)
