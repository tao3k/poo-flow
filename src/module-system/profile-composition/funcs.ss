;;; -*- Gerbil -*-
;;; Reusable indexing functions for profile-composition lowering.

(export poo-flow-composition-leftmost-index-by)

;; The first source declaration wins, matching the prior linear `find` path.
(def (poo-flow-composition-leftmost-index-by key-of values)
  (let (index (make-hash-table-eq))
    (for-each
     (lambda (value)
       (let (key (key-of value))
         (unless (hash-key? index key)
           (hash-put! index key value))))
     values)
    index))
