(import (only-in :clan/poo/object .o .ref))

;;; Scenario input: receipt projection is a fresh POO/alist traversal on every
;;; runtime boundary call.

(def (loop-capability-receipt name status facts)
  (.o (name name)
      (status status)
      (facts facts)))

(def (loop-capability-receipt->alist receipt)
  (list (cons 'name (.ref receipt 'name))
        (cons 'status (.ref receipt 'status))
        (cons 'facts (.ref receipt 'facts))))
