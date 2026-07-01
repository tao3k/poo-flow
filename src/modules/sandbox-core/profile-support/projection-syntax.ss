;;; -*- Gerbil -*-
;;; Boundary: hygienic helpers for sandbox-core profile support projections.
;;; Invariant: generated rows are plain alists at derivation metadata,
;;; validation, policy, and presentation receipt boundaries.

(export poo-flow-sandbox-profile-rows/tail
        poo-flow-sandbox-profile-rows-into/rev
        poo-flow-sandbox-profile-field-rows
        poo-flow-sandbox-profile-field-rows/tail)

;; : (-> List List List)
(def (poo-flow-sandbox-profile-rows/tail rows tail)
  (let loop ((remaining-rows rows)
             (rows-rev '()))
    (if (null? remaining-rows)
      (let restore ((remaining-rev rows-rev)
                    (result tail))
        (if (null? remaining-rev)
          result
          (restore (cdr remaining-rev)
                   (cons (car remaining-rev) result))))
      (loop (cdr remaining-rows)
            (cons (car remaining-rows) rows-rev)))))

;; : (-> List List List)
(def (poo-flow-sandbox-profile-rows-into/rev rows rows-rev)
  (if (null? rows)
    rows-rev
    (poo-flow-sandbox-profile-rows-into/rev
     (cdr rows)
     (cons (car rows) rows-rev))))

(defrules poo-flow-sandbox-profile-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

(defrules poo-flow-sandbox-profile-field-rows/tail ()
  ((_ tail (field value) ...)
   (poo-flow-sandbox-profile-rows/tail
    (poo-flow-sandbox-profile-field-rows (field value) ...)
    tail)))
