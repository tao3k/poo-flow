;;; -*- Gerbil -*-
;;; Boundary: shared slot-row assembly for loop governor POO constructors.

(export loop-governor-slot-rows/tail
        loop-governor-node-slot-rows)

;; : (forall (a) (-> [a] [a] [a]))
;; : (-> Alist Alist Alist)
(def (loop-governor-slot-rows/tail rows tail)
  (foldr cons tail rows))

;; : (-> Symbol Symbol Symbol Boolean Alist Alist)
(def (loop-governor-node-slot-rows name
                                   governance-node-kind
                                   responsibility
                                   human-intervention?
                                   overrides)
  (loop-governor-slot-rows/tail
   (list
    (cons 'name name)
    (cons 'governance-node-kind governance-node-kind)
    (cons 'governance-responsibility responsibility)
    (cons 'human-intervention human-intervention?))
   overrides))
