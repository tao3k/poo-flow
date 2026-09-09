;;; -*- Gerbil -*-
;;; Boundary: extension node merge and operation application helpers.

(import (only-in :clan/poo/object
                 .o
                 .ref
                 object?)
        :poo-flow/src/module-system/extension/support/data)

(export poo-flow-module-extension-slots-merge
        poo-flow-module-extension-node-merge
        poo-flow-module-extension-children-merge-one
        poo-flow-module-extension-children-merge
        poo-flow-module-extension-children-remove
        poo-flow-module-extension-apply-slot-list-op
        poo-flow-module-extension-flush-node-extends
        poo-flow-module-extension-flush-slot-overrides
        poo-flow-module-extension-flush-pending)

;; poo-flow-module-extension-slots-merge
;;   : (-> PooModuleSlotMap PooModuleSlotMap PooModuleSlotMap)
;;   | doc m%
;;       `poo-flow-module-extension-slots-merge` merges slot rows by key while
;;       preserving first declaration order and applying the last override.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-slots-merge
;;        (list (poo-flow-module-extension-entry 'mode 'strict))
;;        (list (poo-flow-module-extension-entry 'mode 'relaxed)
;;              (poo-flow-module-extension-entry 'features '(extra))))
;;       ;; => ((mode . relaxed) (features extra))
;;       ```
;;     %
(def (poo-flow-module-extension-slots-merge base extra)
  (let ((base-seen (make-hash-table))
        (override-seen (make-hash-table))
        (overrides (make-hash-table))
        (new-seen (make-hash-table))
        (replacement-used (make-hash-table)))
    ;; : (-> Any Any)
    (def (entry-slot entry)
      (poo-flow-module-extension-entry-key entry))
    (for-each
     (lambda (entry)
       (hash-put! base-seen
                  (entry-slot entry)
                  #t))
     base)
    ;; : (-> Any Any)
    (def (finish-entry entry)
      (let (slot (entry-slot entry))
        (if (and (hash-get override-seen slot)
                 (not (hash-get replacement-used slot)))
          (begin
            (hash-put! replacement-used slot #t)
            (poo-flow-module-extension-entry
             slot
             (hash-get overrides slot)))
          entry)))
    ;; : (-> Any Any)
    (def (finish-base/rev entries rows-rev)
      (if (null? entries)
        rows-rev
        (finish-base/rev (cdr entries)
                         (cons (finish-entry (car entries)) rows-rev))))
    ;; : (-> Any Any)
    (def (finish-new/rev slots rows-rev)
      (if (null? slots)
        rows-rev
        (finish-new/rev
         (cdr slots)
         (cons (poo-flow-module-extension-entry
                (car slots)
                (hash-get overrides (car slots)))
               rows-rev))))
    ;; : (-> Any Any)
    (def (finish new-order)
      (reverse
       (finish-new/rev
        (reverse new-order)
        (finish-base/rev base '()))))
    (let loop ((entries extra) (new-order '()))
      (if (null? entries)
        (finish new-order)
        (let* ((entry (car entries))
               (slot (entry-slot entry))
               (next-new-order
                (if (or (hash-get base-seen slot)
                        (hash-get new-seen slot))
                  new-order
                  (begin
                    (hash-put! new-seen slot #t)
                    (cons slot new-order)))))
          (hash-put! override-seen slot #t)
          (hash-put! overrides
                     slot
                     (poo-flow-module-extension-entry-value entry))
          (loop (cdr entries) next-new-order))))))

;; poo-flow-module-extension-node-merge
;;   : (-> PooModuleExtensionNode PooModuleExtensionNode PooModuleExtensionNode)
;;   | doc m%
;;       `poo-flow-module-extension-node-merge` combines two nodes with the
;;       same identity by merging slots and children through the extension
;;       merge rules used by inheritance and contribution application.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-node-merge base-node extension-node)
;;       ;; => merged extension node
;;       ```
;;     %
(def (poo-flow-module-extension-node-merge base extra)
  (poo-flow-module-extension-node
   (poo-flow-module-extension-node-identity base)
   (poo-flow-module-extension-slots-merge
    (poo-flow-module-extension-node-slots base)
    (poo-flow-module-extension-node-slots extra))
   (poo-flow-module-extension-children-merge
    (poo-flow-module-extension-node-children base)
    (poo-flow-module-extension-node-children extra))))

;; poo-flow-module-extension-children-merge-one
;;   : (-> (List PooModuleExtensionNode) PooModuleExtensionNode (List PooModuleExtensionNode))
;;   | doc m%
;;       `poo-flow-module-extension-children-merge-one` merges one child into
;;       an ordered child list by identity, replacing the first matching child
;;       and appending when the identity is new.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-children-merge-one children extra-child)
;;       ;; => children with extra-child merged by identity
;;       ```
;;     %
(def (poo-flow-module-extension-children-merge-one children extra-child)
  (cond ((null? children) (list extra-child))
        ((equal? (poo-flow-module-extension-node-identity (car children))
                 (poo-flow-module-extension-node-identity extra-child))
         (cons (poo-flow-module-extension-node-merge (car children) extra-child)
               (cdr children)))
        (else
         (cons (car children)
               (poo-flow-module-extension-children-merge-one (cdr children)
                                                             extra-child)))))

;; poo-flow-module-extension-children-merge
;;   : (-> (List PooModuleExtensionNode) (List PooModuleExtensionNode) (List PooModuleExtensionNode))
;;   | doc m%
;;       `poo-flow-module-extension-children-merge children extra-children`
;;       merges children by node identity, preserving existing child order and
;;       appending identities that appear only in `extra-children`.
;;
;;       # Examples
;;       ```scheme
;;       (map poo-flow-module-extension-node-identity
;;            (poo-flow-module-extension-children-merge
;;             (list (poo-flow-module-extension-node 'root [] []))
;;             (list (poo-flow-module-extension-node 'root '((role . main)) [])
;;                   (poo-flow-module-extension-node 'leaf [] []))))
;;       ;; => (root leaf)
;;       ```
;;     %
(def (poo-flow-module-extension-children-merge children extra-children)
  (if (null? extra-children)
    children
    (let ((base-seen (make-hash-table))
          (base-first (make-hash-table))
          (override-seen (make-hash-table))
          (overrides (make-hash-table))
          (new-seen (make-hash-table))
          (replacement-used (make-hash-table)))
      (for-each
       (lambda (child)
         (let (key (poo-flow-module-extension-node-identity child))
           (if (not (hash-get base-seen key))
             (begin
               (hash-put! base-seen key #t)
               (hash-put! base-first key child))
             #f)))
       children)
      ;; : (-> Any Any)
      (def (finish-child child)
        (let (identity (poo-flow-module-extension-node-identity child))
          (if (and (hash-get override-seen identity)
                   (not (hash-get replacement-used identity)))
            (begin
              (hash-put! replacement-used identity #t)
              (hash-get overrides identity))
            child)))
      ;; : (-> Any Any)
      (def (finish-children/rev remaining rows-rev)
        (if (null? remaining)
          rows-rev
          (finish-children/rev
           (cdr remaining)
           (cons (finish-child (car remaining)) rows-rev))))
      ;; : (-> Any Any)
      (def (finish-new/rev identities rows-rev)
        (if (null? identities)
          rows-rev
          (finish-new/rev
           (cdr identities)
           (cons (hash-get overrides (car identities)) rows-rev))))
      ;; : (-> Any Any)
      (def (finish new-order)
        (reverse
         (finish-new/rev
          (reverse new-order)
          (finish-children/rev children '()))))
      (let loop-extra ((remaining extra-children)
                       (new-order '()))
        (if (null? remaining)
          (finish new-order)
          (let* ((child (car remaining))
                 (identity (poo-flow-module-extension-node-identity child))
                 (current (hash-get overrides identity))
                 (base-child (hash-get base-first identity))
                 (seed (if current current base-child))
                 (next-new-order
                  (if (or (hash-get base-seen identity)
                          (hash-get new-seen identity))
                    new-order
                    (begin
                      (hash-put! new-seen identity #t)
                      (cons identity new-order)))))
            (hash-put! override-seen identity #t)
            (hash-put! overrides identity
                       (if seed
                         (poo-flow-module-extension-node-merge seed child)
                         child))
            (loop-extra (cdr remaining) next-new-order)))))))

;; poo-flow-module-extension-children-remove
;;   : (-> (List PooModuleExtensionNode) Symbol (List PooModuleExtensionNode))
;;   | doc m%
;;       `poo-flow-module-extension-children-remove` removes children matching
;;       one identity while preserving the order of every remaining child.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-children-remove children 'obsolete)
;;       ;; => children without the obsolete identity
;;       ```
;;     %
(def (poo-flow-module-extension-children-remove children identity)
  (filter (lambda (child)
            (not (equal? (poo-flow-module-extension-node-identity child)
                         identity)))
          children))

;; poo-flow-module-extension-apply-slot-list-op
;;   : (-> PooModuleExtensionNode PooModuleExtensionOperation Boolean PooModuleExtensionNode)
;;   | doc m%
;;       `poo-flow-module-extension-apply-slot-list-op` normalizes scalar and
;;       list operation values before appending or prepending distinct slot
;;       members, keeping feature rows deterministic.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-apply-slot-list-op node operation #t)
;;       ;; => node with normalized distinct list-slot values
;;       ```
;;     %
(def (poo-flow-module-extension-apply-slot-list-op node operation append?)
  (let* ((slot (poo-flow-module-extension-operation-slot operation))
         (current (poo-flow-module-extension-list-value
                   (poo-flow-module-extension-alist-ref/default
                    (poo-flow-module-extension-node-slots node) slot '())))
         (extra (poo-flow-module-extension-list-value
                 (poo-flow-module-extension-operation-value operation)))
         (next (if append?
                 (poo-flow-module-extension-append-distinct current extra)
                 (poo-flow-module-extension-append-distinct extra current))))
    (poo-flow-module-extension-replace-node
     node
     (poo-flow-module-extension-alist-set
      (poo-flow-module-extension-node-slots node) slot next)
     (poo-flow-module-extension-node-children node))))

;; poo-flow-module-extension-flush-node-extends
;;   : (-> PooModuleExtensionNode (List PooModuleExtensionNode) PooModuleExtensionNode)
;;   | doc m%
;;       `poo-flow-module-extension-flush-node-extends` materializes reversed
;;       pending node extensions into a node through child merge semantics.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-flush-node-extends node reversed-children)
;;       ;; => node with pending child extensions merged
;;       ```
;;     %
(def (poo-flow-module-extension-flush-node-extends node reversed-children)
  (if (null? reversed-children)
    node
    (poo-flow-module-extension-replace-node
     node
     (poo-flow-module-extension-node-slots node)
     (poo-flow-module-extension-children-merge
      (poo-flow-module-extension-node-children node)
      (reverse reversed-children)))))

;; poo-flow-module-extension-flush-slot-overrides
;;   : (-> PooModuleExtensionNode PooModuleSlotMap PooModuleExtensionNode)
;;   | doc m%
;;       `poo-flow-module-extension-flush-slot-overrides` materializes reversed
;;       pending slot override rows through deterministic slot merge semantics.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-flush-slot-overrides node reversed-overrides)
;;       ;; => node with pending slot overrides merged
;;       ```
;;     %
(def (poo-flow-module-extension-flush-slot-overrides node reversed-overrides)
  (if (null? reversed-overrides)
    node
    (poo-flow-module-extension-replace-node
     node
     (poo-flow-module-extension-slots-merge
      (poo-flow-module-extension-node-slots node)
      (reverse reversed-overrides))
     (poo-flow-module-extension-node-children node))))

;; poo-flow-module-extension-flush-pending
;;   : (-> PooModuleExtensionNode (List PooModuleExtensionNode) PooModuleSlotMap PooModuleExtensionNode)
;;   | doc m%
;;       `poo-flow-module-extension-flush-pending` commits delayed node
;;       extensions and slot overrides into the current node before an
;;       operation that cannot be coalesced is applied.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-flush-pending node children overrides)
;;       ;; => node with pending child and slot batches materialized
;;       ```
;;     %
(def (poo-flow-module-extension-flush-pending node reversed-children reversed-overrides)
  (poo-flow-module-extension-flush-node-extends
   (poo-flow-module-extension-flush-slot-overrides node reversed-overrides)
   reversed-children))
