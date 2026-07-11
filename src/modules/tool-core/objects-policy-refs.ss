;;; -*- Gerbil -*-
;;; Boundary: pure policy-grant reference collection and merge operations.

(import :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy)

(export poo-flow-tool-policy-grant-tool-refs
        poo-flow-tool-policy-grants
        poo-flow-tool-unique-symbols
        poo-flow-tool-merge-policy-tool-refs
        poo-flow-tool-policy-tool-refs)

;; : (-> [PooSessionToolGrant] [Symbol])
(def (poo-flow-tool-policy-grant-tool-refs grants)
  (cond
   ((null? grants) '())
   (else
    (cons (poo-flow-session-tool-grant-tool-ref (car grants))
          (poo-flow-tool-policy-grant-tool-refs (cdr grants))))))

;; : (-> PooSessionPolicy [PooSessionToolGrant])
(def (poo-flow-tool-policy-grants policy)
  (poo-flow-session-alist-ref
   (poo-flow-session-policy->alist policy)
   'tool-grants
   '()))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-tool-unique-symbols values seen)
  (cond
   ((null? values) '())
   ((or (eq? (car values) '*)
        (member (car values) seen))
    (poo-flow-tool-unique-symbols (cdr values) seen))
   (else
    (cons (car values)
          (poo-flow-tool-unique-symbols (cdr values)
                                        (cons (car values) seen))))))

;; : (-> [Symbol] [Symbol] [Symbol] (Cons [Symbol] [Symbol]))
(def (poo-flow-tool-unique-symbols/accumulate values seen values-rev)
  (cond
   ((null? values) (cons seen values-rev))
   ((or (eq? (car values) '*)
        (member (car values) seen))
    (poo-flow-tool-unique-symbols/accumulate
     (cdr values)
     seen
     values-rev))
   (else
    (poo-flow-tool-unique-symbols/accumulate
     (cdr values)
     (cons (car values) seen)
     (cons (car values) values-rev)))))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-tool-merge-policy-tool-refs agent-tool-refs hook-tool-refs)
  (let* ((agent-bundle
          (poo-flow-tool-unique-symbols/accumulate agent-tool-refs '() '()))
         (hook-bundle
          (poo-flow-tool-unique-symbols/accumulate
           hook-tool-refs
           (car agent-bundle)
           (cdr agent-bundle))))
    (reverse (cdr hook-bundle))))

;; : (-> PooSessionPolicy [Symbol])
(def (poo-flow-tool-policy-tool-refs policy)
  (poo-flow-tool-unique-symbols
   (poo-flow-tool-policy-grant-tool-refs
    (poo-flow-tool-policy-grants policy))
   '()))
