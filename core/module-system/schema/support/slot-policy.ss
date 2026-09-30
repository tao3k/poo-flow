;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: pure, ordered field-value policies. POO owns inheritance;
;;; explicit append/prepend/remove are value operations, not module merging.

(import :gerbil/core)

(export poo-flow-module-slot-apply-policy
        poo-flow-module-slot-value-index
        poo-flow-module-slot-append-distinct
        poo-flow-module-slot-append-distinct/indexed
        poo-flow-module-slot-remove-elements
        poo-flow-module-slot-list-value
        poo-flow-module-slot-policy?)

;; : (-> [PooModuleSlotValue] HashTable)
(def (poo-flow-module-slot-value-index values)
  (let (index (make-hash-table))
    (for-each
     (lambda (value)
       (hash-put! index value #t))
     values)
    index))

;;; Distinct append preserves the base list and indexes only when extra values
;;; need admission. The indexed entry is reused by sparse field resolution.
;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-slot-append-distinct base extra)
  (if (null? extra)
    base
    (poo-flow-module-slot-append-distinct/indexed
     base extra (poo-flow-module-slot-value-index base))))

;; : (-> [PooModuleSlotValue] HashTable [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-slot-append-distinct-added/rev extra seen added-rev)
  (append
   (reverse
    (filter-map
     (lambda (value)
       (and (not (hash-get seen value))
            (begin
              (hash-put! seen value #t)
              value)))
     extra))
   added-rev))

;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] HashTable [PooModuleSlotValue])
(def (poo-flow-module-slot-append-distinct/indexed base extra seen)
  (let (added
        (poo-flow-module-slot-append-distinct-added/rev extra seen '()))
    (if (null? added)
      base
      (append base (reverse added)))))

;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-slot-remove-elements values removed)
  (if (null? removed)
    values
    (let (removed-index (poo-flow-module-slot-value-index removed))
      (filter (lambda (value)
                (not (hash-get removed-index value)))
              values))))

;; : (-> PooModuleSlotValue [PooModuleSlotValue])
(def (poo-flow-module-slot-list-value value)
  (cond ((null? value) '())
        ((list? value) value)
        (else (list value))))

;; : (-> Symbol Boolean)
(def (poo-flow-module-slot-policy? policy)
  (or (eq? policy 'override)
      (eq? policy 'append)
      (eq? policy 'prepend)
      (eq? policy 'remove)))

;;; Unknown policies leave the current value unchanged. Contract admission
;;; rejects invalid user rows before they reach this pure operation.
;; : (-> Symbol PooModuleSlotValue PooModuleSlotValue PooModuleSlotValue)
(def (poo-flow-module-slot-apply-policy policy current value)
  (cond
   ((eq? policy 'override) value)
   ((eq? policy 'append)
    (poo-flow-module-slot-append-distinct
     (poo-flow-module-slot-list-value current)
     (poo-flow-module-slot-list-value value)))
   ((eq? policy 'prepend)
    (poo-flow-module-slot-append-distinct
     (poo-flow-module-slot-list-value value)
     (poo-flow-module-slot-list-value current)))
   ((eq? policy 'remove)
    (poo-flow-module-slot-remove-elements
     (poo-flow-module-slot-list-value current)
     (poo-flow-module-slot-list-value value)))
   (else current)))
