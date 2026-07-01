;;; -*- Gerbil -*-
;;; Boundary: hygienic helpers for agent-sandbox final row projections.
;;; Invariant: generated rows remain plain alists at request, validation,
;;; profile, and Marlin handoff boundaries.

(export agent-sandbox-rows/tail
        agent-sandbox-rows-into/rev
        agent-sandbox-field-rows
        agent-sandbox-field-rows/tail)

;; : (-> Alist Alist Alist)
(def (agent-sandbox-rows/tail rows tail)
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

;; : (-> [Alist] [Alist] [Alist])
(def (agent-sandbox-rows-into/rev rows rows-rev)
  (if (null? rows)
    rows-rev
    (agent-sandbox-rows-into/rev
     (cdr rows)
     (cons (car rows) rows-rev))))

(defrules agent-sandbox-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

(defrules agent-sandbox-field-rows/tail ()
  ((_ tail (field value) ...)
   (agent-sandbox-rows/tail
    (agent-sandbox-field-rows (field value) ...)
    tail)))
