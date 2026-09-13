;;; -*- Gerbil -*-
;;; Boundary: pure policy-grant reference collection and merge operations.

(import (only-in :std/misc/list delete-duplicates/hash)
        (only-in :std/srfi/1 filter map)
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy)

(export poo-flow-tool-policy-grant-tool-refs
        poo-flow-tool-policy-grants
        poo-flow-tool-unique-symbols
        poo-flow-tool-merge-policy-tool-refs
        poo-flow-tool-policy-tool-refs)

;; : (-> [PooSessionToolGrant] [Symbol])
(def (poo-flow-tool-policy-grant-tool-refs grants)
  (map poo-flow-session-tool-grant-tool-ref grants))

;; : (-> PooSessionPolicy [PooSessionToolGrant])
(def (poo-flow-tool-policy-grants policy)
  (poo-flow-session-alist-ref
   (poo-flow-session-policy->alist policy)
   'tool-grants
   '()))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-tool-unique-symbols values seen)
  (let (seen-table (make-hash-table-eq))
    (for-each (lambda (value) (hash-put! seen-table value #t)) seen)
    (delete-duplicates/hash
     (filter (lambda (value) (not (eq? value '*))) values)
     table: seen-table
     from-end?: #t)))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-tool-merge-policy-tool-refs agent-tool-refs hook-tool-refs)
  (poo-flow-tool-unique-symbols
   (append agent-tool-refs hook-tool-refs)
   '()))

;; : (-> PooSessionPolicy [Symbol])
(def (poo-flow-tool-policy-tool-refs policy)
  (poo-flow-tool-unique-symbols
   (poo-flow-tool-policy-grant-tool-refs
    (poo-flow-tool-policy-grants policy))
   '()))
