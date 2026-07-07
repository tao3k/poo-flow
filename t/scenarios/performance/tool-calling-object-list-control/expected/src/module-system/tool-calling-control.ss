(import (only-in :clan/poo/object .o .ref))

;;; Scenario expected: native POO remains the control-plane surface.
;;; The repair is object-list/index discipline, not replacing POO with vectors
;;; or raw records.

(def (poo-flow-tool-call-entry entry-key entry-value)
  (.o (kind 'poo-flow-tool-call-entry)
      (key entry-key)
      (value entry-value)))

(def (poo-flow-tool-call-entry-index entry-list)
  (let loop ((rest entry-list) (index-cache '()))
    (if (null? rest)
      index-cache
      (let* ((entry (car rest))
             (entry-key (.ref entry 'key))
             (entry-value (.ref entry 'value)))
        (loop (cdr rest)
              (cons (cons entry-key entry-value)
                    index-cache))))))

(def (poo-flow-tool-call-plan plan-name plan-entry-list)
  (let ((plan-index-cache
         (poo-flow-tool-call-entry-index plan-entry-list)))
    (.o (kind 'poo-flow-tool-call-plan)
        (name plan-name)
        (entries plan-entry-list)
        (index plan-index-cache))))

(def (poo-flow-tool-call-fact-set fact-set-name fact-entry-list)
  (let ((fact-index-cache
         (poo-flow-tool-call-entry-index fact-entry-list)))
    (.o (kind 'poo-flow-tool-call-fact-set)
        (name fact-set-name)
        (entries fact-entry-list)
        (index fact-index-cache))))
