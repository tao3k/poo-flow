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
  (match grants
    ([] '())
    ([grant . rest]
     (cons (poo-flow-session-tool-grant-tool-ref grant)
           (poo-flow-tool-policy-grant-tool-refs rest)))))

;; : (-> PooSessionPolicy [PooSessionToolGrant])
(def (poo-flow-tool-policy-grants policy)
  (poo-flow-session-alist-ref
   (poo-flow-session-policy->alist policy)
   'tool-grants
   '()))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-tool-unique-symbols values seen)
  (match values
    ([] '())
    ([value . rest]
     (if (or (eq? value '*) (member value seen))
       (poo-flow-tool-unique-symbols rest seen)
       (cons value
             (poo-flow-tool-unique-symbols rest (cons value seen)))))))

;; : (-> [Symbol] [Symbol] [Symbol] (Values [Symbol] [Symbol]))
(def (poo-flow-tool-unique-symbols/accumulate values seen values-rev)
  (match values
    ([] (values seen values-rev))
    ([value . rest]
     (if (or (eq? value '*) (member value seen))
       (poo-flow-tool-unique-symbols/accumulate rest seen values-rev)
       (poo-flow-tool-unique-symbols/accumulate
        rest
        (cons value seen)
        (cons value values-rev))))))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-tool-merge-policy-tool-refs agent-tool-refs hook-tool-refs)
  (let-values (((agent-seen agent-values-rev)
                (poo-flow-tool-unique-symbols/accumulate
                 agent-tool-refs '() '())))
    (let-values (((_ hook-values-rev)
                  (poo-flow-tool-unique-symbols/accumulate
                   hook-tool-refs agent-seen agent-values-rev)))
      (reverse hook-values-rev))))

;; : (-> PooSessionPolicy [Symbol])
(def (poo-flow-tool-policy-tool-refs policy)
  (poo-flow-tool-unique-symbols
   (poo-flow-tool-policy-grant-tool-refs
    (poo-flow-tool-policy-grants policy))
   '()))
