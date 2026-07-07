(import (only-in :clan/poo/object .o .ref))

;;; Scenario expected: native POO is constructed once at the boundary and the
;;; hot loop reuses the materialized object shape.

(def +report-profile+
  (.o (name 'construction-profile)
      (weight 7)
      (scale 11)
      (policy 'native-poo)
      (runtime 'control-plane)))

(def (build-report-profile)
  +report-profile+)

(def (score-report rounds)
  (let* ((profile (build-report-profile))
         (weight (.ref profile 'weight))
         (scale (.ref profile 'scale))
         (step (+ weight scale)))
    (let loop ((i 0) (total 0))
      (if (= i rounds)
        total
        (loop (+ i 1) (+ total step))))))
