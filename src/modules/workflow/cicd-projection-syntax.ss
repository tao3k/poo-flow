;;; -*- Gerbil -*-
;;; Boundary: hygienic helpers for workflow CI/CD final row projections.
;;; Invariant: generated rows are plain alists at POO object, runtime manifest,
;;; receipt, pipeline, and Marlin handoff boundaries.

(export poo-flow-cicd-rows/tail
        poo-flow-cicd-rows-into/rev
        poo-flow-cicd-field-rows
        poo-flow-cicd-field-rows/tail)

;; : (-> List List List)
(def (poo-flow-cicd-rows/tail rows tail)
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
(def (poo-flow-cicd-rows-into/rev rows rows-rev)
  (if (null? rows)
    rows-rev
    (poo-flow-cicd-rows-into/rev
     (cdr rows)
     (cons (car rows) rows-rev))))

(defrules poo-flow-cicd-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

(defrules poo-flow-cicd-field-rows/tail ()
  ((_ tail (field value) ...)
   (poo-flow-cicd-rows/tail
    (poo-flow-cicd-field-rows (field value) ...)
    tail)))
