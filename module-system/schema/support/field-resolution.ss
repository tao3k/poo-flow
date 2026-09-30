;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: ordered field-contribution resolution for module object graphs.

(import :gerbil/core
        (only-in :clan/poo/object .o .ref)
        :core/extension-graph/interface
        :core/module-system/schema/support/contracts
        :core/module-system/schema/support/slot-policy)

(export poo-flow-module-field-resolution-result
        poo-flow-module-field-resolution-result?
        poo-flow-module-field-resolution-result-extension-result
        poo-flow-module-field-resolution-result-contributions
        poo-flow-module-field-resolution-result-root
        poo-flow-module-field-resolution-result-iterations
        poo-flow-module-field-resolution-result-stable?
        poo-flow-module-config-fast-slot-merge/in-order
        poo-flow-module-config-slot-key-hash-ref
        poo-flow-module-config-fast-slot-merge/sparse
        poo-flow-module-config-fast-slot-merge
        poo-flow-module-config-fast-extension-result
        poo-flow-module-field-contributions-resolve)


;;; Field resolution results preserve the original contributions so diagnostics can
;;; explain both the final graph and the inputs that produced it.
;; : (-> PooModuleExtensionResult [PooModuleFieldContribution] PooModuleFieldResolutionResult)
(def (poo-flow-module-field-resolution-result extension-result contributions)
  (let ((extension-result-value extension-result)
        (contributions-value contributions))
    (.o kind: poo-flow-module-field-resolution-result-kind
        extension-result: extension-result-value
        contributions: contributions-value)))

;; : (-> PooModuleFieldResolutionResultCandidate Boolean)
(def (poo-flow-module-field-resolution-result? value)
  (poo-flow-module-object-kind? value poo-flow-module-field-resolution-result-kind))

;; : (-> PooModuleFieldResolutionResult PooModuleExtensionResult)
(def (poo-flow-module-field-resolution-result-extension-result result)
  (.ref result 'extension-result))
;; : (-> PooModuleFieldResolutionResult [PooModuleFieldContribution])
(def (poo-flow-module-field-resolution-result-contributions result)
  (.ref result 'contributions))
;; : (-> PooModuleFieldResolutionResult PooModuleExtensionNode)
(def (poo-flow-module-field-resolution-result-root result)
  (poo-flow-module-extension-result-root
   (poo-flow-module-field-resolution-result-extension-result result)))
;; : (-> PooModuleFieldResolutionResult Integer)
(def (poo-flow-module-field-resolution-result-iterations result)
  (poo-flow-module-extension-result-iterations
   (poo-flow-module-field-resolution-result-extension-result result)))
;; : (-> PooModuleFieldResolutionResult Boolean)
(def (poo-flow-module-field-resolution-result-stable? result)
  (poo-flow-module-extension-result-stable?
   (poo-flow-module-field-resolution-result-extension-result result)))

;; poo-flow-module-config-fast-slot-merge/in-order
;;   : (-> Symbol PooModuleSlotMap [PooModuleFieldContribution] MaybePooModuleSlotMap)
;;   | doc m%
;;       `poo-flow-module-config-fast-slot-merge/in-order` applies field
;;       contributions while preserving slot order and allocating only when a
;;       value actually changes.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-config-fast-slot-merge/in-order node slots fields)
;;       ;; => maybe-updated-slots
;;       ```
;;     %
(def (poo-flow-module-config-fast-slot-merge/in-order node-identity slots contributions)
  (let ((head '())
        (tail #f)
        (seen (make-hash-table)))
    ;; : (-> Any Any)
    (def (append-entry! entry)
      (let (cell (cons entry '()))
        (if tail
          (begin
            (set-cdr! tail cell)
            (set! tail cell))
          (begin
            (set! head cell)
            (set! tail cell)))))
    ;; : (-> Any Any)
    (def (copy-prefix! stop)
      (let copy ((remaining slots))
        (when (not (eq? remaining stop))
          (append-entry! (car remaining))
          (copy (cdr remaining)))))
    (let loop ((remaining-slots slots)
               (remaining-contributions contributions)
               (changed? #f))
      (cond
       ((null? remaining-slots)
        (if (null? remaining-contributions)
          (if changed?
            head
            slots)
          #f))
       ((null? remaining-contributions) #f)
       (else
        (let ((entry (car remaining-slots))
              (contribution (car remaining-contributions)))
          (if (not (poo-flow-module-field-contribution? contribution))
            #f
            (let* ((target
                    (poo-flow-module-field-contribution-target contribution))
                   (value
                    (poo-flow-module-field-contribution-value contribution))
                   (key
                    (poo-flow-module-field-contribution-field-identity
                     contribution))
                   (slot-key (car entry))
                   (merge
                    (poo-flow-module-field-contribution-merge contribution))
                   (value-type
                    (poo-flow-module-field-contribution-field-value-type
                     contribution))
                   (field-contract?
                    (poo-flow-module-field-contribution-field-contract?
                     contribution))
                   (valid?
                    (or (not field-contract?)
                        (poo-flow-module-value-type-accepts?
                         value-type
                         value))))
              (if (and (equal? target node-identity)
                       valid?
                       (poo-flow-module-slot-policy? merge)
                       (equal? key slot-key))
                (if (hash-get seen slot-key)
                  #f
                  (begin
                    (hash-put! seen slot-key #t)
                    (let* ((current (cdr entry))
                           (next-value
                            (poo-flow-module-slot-apply-policy
                             merge
                             current
                             value))
                           (value-changed?
                            (not (or (eq? next-value current)
                                     (equal? next-value current)))))
                      (when (and value-changed? (not changed?))
                        (copy-prefix! remaining-slots))
                      (when (or changed? value-changed?)
                        (append-entry! (if value-changed?
                                         (cons key next-value)
                                         entry)))
                      (loop (cdr remaining-slots)
                            (cdr remaining-contributions)
                            (or changed? value-changed?)))))
                #f)))))))))

;; : (-> HashTable Symbol Value)
(def (poo-flow-module-config-slot-key-hash-ref table key)
  (hash-get table key))

;; poo-flow-module-config-fast-slot-merge/sparse
;;   : (-> Symbol PooModuleSlotMap [PooModuleFieldContribution] MaybePooModuleSlotMap)
;;   | doc m%
;;       `poo-flow-module-config-fast-slot-merge/sparse` handles sparse or
;;       repeated slot updates with hash-indexed state while keeping append and
;;       remove semantics equivalent to the ordered merge path.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-config-fast-slot-merge/sparse node slots fields)
;;       ;; => maybe-updated-slots
;;       ```
;;     %
(def (poo-flow-module-config-fast-slot-merge/sparse node-identity slots contributions)
  (let ((seen (make-hash-table))
        (updated (make-hash-table))
        (updates (make-hash-table))
        (value-indexes (make-hash-table))
        (append-active (make-hash-table))
        (append-bases (make-hash-table))
        (append-additions (make-hash-table)))
    ;; : (-> Any Any)
    (def (slot-value-index key current)
      (let (index (poo-flow-module-config-slot-key-hash-ref value-indexes key))
        (if index
          index
          (let (next-index
                (poo-flow-module-slot-value-index
                 (poo-flow-module-slot-list-value current)))
            (hash-put! value-indexes key next-index)
            next-index))))
    ;; : (-> Any Any)
    (def (record-slot-value-index! key value)
      (hash-put! value-indexes
                 key
                 (poo-flow-module-slot-value-index
                  (poo-flow-module-slot-list-value value))))
    ;; : (-> Any Any)
    (def (materialize-append-state key)
      (let ((base (poo-flow-module-config-slot-key-hash-ref
                   append-bases
                   key))
            (additions (poo-flow-module-config-slot-key-hash-ref
                        append-additions
                        key)))
        (if (null? additions)
          base
          (append base (reverse additions)))))
    ;; : (-> Any Any)
    (def (flush-append-state! key)
      (if (poo-flow-module-config-slot-key-hash-ref append-active key)
        (let (value (materialize-append-state key))
          (hash-put! updates key value)
          (hash-put! append-active key #f)
          (record-slot-value-index! key value)
          value)
        (poo-flow-module-config-slot-key-hash-ref updates key)))
    ;; : (-> Any Any)
    (def (resolved-slot-update key)
      (if (poo-flow-module-config-slot-key-hash-ref append-active key)
        (flush-append-state! key)
        (poo-flow-module-config-slot-key-hash-ref updates key)))
    ;; : (-> Any Any)
    (def (append-slot-value! key current value)
      (let ((current-list (poo-flow-module-slot-list-value current))
            (extra (poo-flow-module-slot-list-value value))
            (active? (poo-flow-module-config-slot-key-hash-ref
                      append-active
                      key)))
        (when (not active?)
          (hash-put! append-active key #t)
          (hash-put! append-bases key current-list)
          (hash-put! append-additions key '())
          (hash-put! updates key current-list))
        (let (seen-values (slot-value-index key current-list))
          (let loop ((remaining extra)
                     (additions
                      (poo-flow-module-config-slot-key-hash-ref
                       append-additions
                       key))
                     (changed? #f))
            (cond
             ((null? remaining)
              (hash-put! append-additions key additions)
              changed?)
             ((hash-get seen-values (car remaining))
              (loop (cdr remaining) additions changed?))
            (else
             (hash-put! seen-values (car remaining) #t)
             (loop (cdr remaining)
                    (cons (car remaining) additions)
                    #t)))))))
    ;; : (-> Any Any)
    (def (materialize-existing-slots/rev remaining rows-rev)
      (if (null? remaining)
        rows-rev
        (let (key (car (car remaining)))
          (materialize-existing-slots/rev
           (cdr remaining)
           (cons (if (poo-flow-module-config-slot-key-hash-ref updated key)
                   (cons key (resolved-slot-update key))
                   (car remaining))
                 rows-rev)))))
    ;; : (-> Any Any)
    (def (materialize-new-slots/rev keys rows-rev)
      (if (null? keys)
        rows-rev
        (materialize-new-slots/rev
         (cdr keys)
         (cons (cons (car keys) (resolved-slot-update (car keys)))
               rows-rev))))
    ;; : (-> Any Any)
    (def (materialize-updated-slots new-order)
      (reverse
       (materialize-new-slots/rev
        (reverse new-order)
        (materialize-existing-slots/rev slots '()))))
    (let init ((remaining slots))
      (cond
       ((null? remaining)
        (let apply-contributions ((rest contributions)
                                  (new-order '())
                                  (changed? #f))
          (if (null? rest)
            (if (and (not changed?) (null? new-order))
              slots
              (materialize-updated-slots new-order))
            (let* ((contribution (car rest))
                   (target
                    (poo-flow-module-field-contribution-target contribution))
                   (value
                    (poo-flow-module-field-contribution-value contribution))
                   (field-contract?
                    (poo-flow-module-field-contribution-field-contract?
                     contribution))
                   (valid?
                    (or (not field-contract?)
                        (poo-flow-module-value-type-accepts?
                         (poo-flow-module-field-contribution-field-value-type
                          contribution)
                         value)))
                   (key
                    (poo-flow-module-field-contribution-field-identity
                     contribution))
                   (merge
                    (poo-flow-module-field-contribution-merge contribution)))
              (if (and (equal? target node-identity)
                       valid?
                       (poo-flow-module-slot-policy? merge))
                (let* ((entry (poo-flow-module-config-slot-key-hash-ref
                               seen
                               key))
                       (known? (and entry #t))
                       (next-new-order
                        (if known?
                          new-order
                          (begin
                            (hash-put! seen key (cons key #f))
                            (cons key new-order))))
                       (current
                        (cond
                         ((poo-flow-module-config-slot-key-hash-ref
                           updated
                           key)
                          (if (and (not (eq? merge 'append))
                                   (poo-flow-module-config-slot-key-hash-ref
                                    append-active
                                    key))
                            (flush-append-state! key)
                            (poo-flow-module-config-slot-key-hash-ref
                             updates
                             key)))
                         (known? (cdr entry))
                         (else '())))
                       (append-merge? (eq? merge 'append)))
                  (if append-merge?
                    (let* ((value-changed?
                            (append-slot-value! key current value))
                           (next-changed?
                            (or changed?
                                (not known?)
                                value-changed?)))
                      (when (or (not known?) value-changed?)
                        (hash-put! updated key #t))
                      (apply-contributions (cdr rest)
                                           next-new-order
                                           next-changed?))
                    (let* ((next-value
                            (poo-flow-module-slot-apply-policy
                             merge
                             current
                             value))
                           (value-changed?
                            (not (or (eq? next-value current)
                                     (equal? next-value current))))
                           (next-changed?
                            (or changed?
                                (not known?)
                                value-changed?)))
                      (when (or (not known?) value-changed?)
                        (hash-put! updated key #t)
                        (hash-put! updates key next-value)
                        (record-slot-value-index! key next-value))
                      (apply-contributions (cdr rest)
                                           next-new-order
                                           next-changed?))))
                #f)))))
       ((hash-get seen (caar remaining)) #f)
       (else
       (hash-put! seen (caar remaining) (car remaining))
       (init (cdr remaining)))))))

;; : (-> PooModuleSlotMap [PooModuleFieldContribution] MaybePooModuleSlotMap)
(def (poo-flow-module-config-fast-slot-merge node-identity slots contributions)
  (or (poo-flow-module-config-fast-slot-merge/in-order
       node-identity
       slots
       contributions)
      (poo-flow-module-config-fast-slot-merge/sparse
       node-identity
       slots
       contributions)))

;;; The fast extension result is valid only for childless nodes; child graphs
;;; require the general contribution resolver to preserve nested semantics.
;; : (-> PooModuleExtensionNode [PooModuleFieldContribution] MaybePooModuleExtensionResult)
(def (poo-flow-module-config-fast-extension-result base contributions)
  (let ((children (poo-flow-module-extension-node-children base))
        (node-identity (poo-flow-module-extension-node-identity base))
        (slots (poo-flow-module-extension-node-slots base)))
    (if (null? children)
      (let (merged-slots
            (poo-flow-module-config-fast-slot-merge
             node-identity
             slots
             contributions))
        (if merged-slots
          (poo-flow-module-extension-result
           (poo-flow-module-extension-node node-identity merged-slots '())
           (if (equal? merged-slots slots) 0 1)
           #t)
          #f))
      #f)))

;; : (-> PooModuleExtensionNode [PooModuleFieldContribution] PooModuleFieldResolutionResult)
(def (poo-flow-module-field-contributions-resolve base contributions)
  (poo-flow-module-field-resolution-result
   (or (poo-flow-module-config-fast-extension-result base contributions)
       (poo-flow-module-extension-resolve
        base
        (poo-flow-module-field-contributions->extensions contributions)))
   contributions))
