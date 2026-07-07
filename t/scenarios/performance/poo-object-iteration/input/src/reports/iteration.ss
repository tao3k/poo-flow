(import (only-in :clan/poo/object .o .for-each! object<-alist))

;;; Scenario input: rejected iteration shape.
;;; It crosses the alist adapter boundary first, then iterates the object on
;;; every hot-loop pass.

(def +report-profile-alist+
  '((field-0 . 0)
    (field-1 . 1)
    (field-2 . 2)
    (field-3 . 3)
    (field-4 . 4)
    (field-5 . 5)))

(def (build-report-profile)
  (object<-alist +report-profile-alist+))

(def (score-report rounds)
  (let ((profile (build-report-profile)))
    (let loop ((i 0) (total 0))
      (if (= i rounds)
        total
        (let ((step 0))
          (.for-each! profile
            (lambda (_ value)
              (set! step (+ step value))))
          (loop (+ i 1) (+ total step)))))))
