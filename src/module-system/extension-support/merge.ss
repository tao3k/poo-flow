;;; -*- Gerbil -*-
;;; Boundary: extension node merge and operation application helpers.

(import (only-in :clan/poo/object
                 .o
                 .ref
                 object?)
        (only-in :std/sugar foldl)
        :poo-flow/src/module-system/extension-support/data)

(export poo-flow-module-extension-slots-merge
        poo-flow-module-extension-node-merge
        poo-flow-module-extension-children-merge-one
        poo-flow-module-extension-children-merge
        poo-flow-module-extension-children-remove
        poo-flow-module-extension-apply-slot-list-op
        poo-flow-module-extension-apply-operation
        poo-flow-module-extension-flush-node-extends
        poo-flow-module-extension-flush-slot-overrides
        poo-flow-module-extension-flush-pending
        poo-flow-module-extension-slot-append-operation?
        poo-flow-module-extension-flush-slot-append
        poo-flow-module-extension-coalesce-slot-appends
        poo-flow-module-extension-operation-state)

;; poo-flow-module-extension-slots-merge
;;   : (-> PooModuleSlotMap PooModuleSlotMap PooModuleSlotMap)
;;   | doc m%
;;       `poo-flow-module-extension-slots-merge` merges slot rows by key while
;;       preserving first declaration order and applying the last override.
;;     %
(def (poo-flow-module-extension-slots-merge base extra)
  (let ((base-seen (make-hash-table))
        (override-seen (make-hash-table))
        (overrides (make-hash-table))
        (new-seen (make-hash-table))
        (replacement-used (make-hash-table)))
    (for-each
     (lambda (entry)
       (hash-put! base-seen
                  (poo-flow-module-extension-entry-key entry)
                  #t))
     base)
    (let loop ((entries extra) (new-keys '()))
      (if (null? entries)
        (append
         (map (lambda (entry)
                (let (key (poo-flow-module-extension-entry-key entry))
                  (if (and (hash-get override-seen key)
                           (not (hash-get replacement-used key)))
                    (begin
                      (hash-put! replacement-used key #t)
                      (poo-flow-module-extension-entry
                       key
                       (hash-get overrides key)))
                    entry)))
              base)
         (map (lambda (key)
                (poo-flow-module-extension-entry
                 key
                 (hash-get overrides key)))
              (reverse new-keys)))
        (let* ((entry (car entries))
               (key (poo-flow-module-extension-entry-key entry))
               (next-new-keys
                (if (or (hash-get base-seen key)
                        (hash-get new-seen key))
                  new-keys
                  (begin
                    (hash-put! new-seen key #t)
                    (cons key new-keys)))))
          (hash-put! override-seen key #t)
          (hash-put! overrides
                     key
                     (poo-flow-module-extension-entry-value entry))
          (loop (cdr entries) next-new-keys))))))

;; : (-> PooModuleExtensionNode PooModuleExtensionNode PooModuleExtensionNode)
(def (poo-flow-module-extension-node-merge base extra)
  (poo-flow-module-extension-node
   (poo-flow-module-extension-node-identity base)
   (poo-flow-module-extension-slots-merge
    (poo-flow-module-extension-node-slots base)
    (poo-flow-module-extension-node-slots extra))
   (poo-flow-module-extension-children-merge
    (poo-flow-module-extension-node-children base)
    (poo-flow-module-extension-node-children extra))))

;; : (-> [PooModuleExtensionNode] PooModuleExtensionNode [PooModuleExtensionNode])
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
      (let loop-extra ((remaining extra-children)
                       (new-keys '()))
        (if (null? remaining)
          (append
           (map (lambda (child)
                  (let (key (poo-flow-module-extension-node-identity child))
                    (if (and (hash-get override-seen key)
                             (not (hash-get replacement-used key)))
                      (begin
                        (hash-put! replacement-used key #t)
                        (hash-get overrides key))
                      child)))
                children)
           (map (lambda (key)
                  (hash-get overrides key))
                (reverse new-keys)))
          (let* ((child (car remaining))
                 (key (poo-flow-module-extension-node-identity child))
                 (current (hash-get overrides key))
                 (base-child (hash-get base-first key))
                 (seed (if current current base-child))
                 (next-new-keys
                  (if (or (hash-get base-seen key)
                          (hash-get new-seen key))
                    new-keys
                    (begin
                      (hash-put! new-seen key #t)
                      (cons key new-keys)))))
            (hash-put! override-seen key #t)
            (hash-put! overrides key
                       (if seed
                         (poo-flow-module-extension-node-merge seed child)
                         child))
            (loop-extra (cdr remaining) next-new-keys)))))))

;; : (-> [PooModuleExtensionNode] Symbol [PooModuleExtensionNode])
(def (poo-flow-module-extension-children-remove children identity)
  (cond ((null? children) '())
        ((equal? (poo-flow-module-extension-node-identity (car children)) identity)
         (poo-flow-module-extension-children-remove (cdr children) identity))
        (else
         (cons (car children)
               (poo-flow-module-extension-children-remove (cdr children) identity)))))

;;; List slot operations normalize scalar input before merge, so user-facing
;;; feature rows can pass either one value or a list value consistently.
;; : (-> PooModuleExtensionNode PooModuleExtensionOperation Boolean PooModuleExtensionNode)
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

;;; Operation application is deliberately total: unknown operation names leave
;;; the node unchanged so extension doctors can report policy mistakes later.
;; : (-> PooModuleExtensionNode PooModuleExtensionOperation PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-operation node operation)
  (let (action (poo-flow-module-extension-operation-action operation))
    (cond
     ((eq? action 'slot-override)
      (poo-flow-module-extension-replace-node
       node
       (poo-flow-module-extension-alist-set
        (poo-flow-module-extension-node-slots node)
        (poo-flow-module-extension-operation-slot operation)
        (poo-flow-module-extension-operation-value operation))
       (poo-flow-module-extension-node-children node)))
     ((eq? action 'slot-append)
      (poo-flow-module-extension-apply-slot-list-op node operation #t))
     ((eq? action 'slot-prepend)
      (poo-flow-module-extension-apply-slot-list-op node operation #f))
     ((eq? action 'slot-remove)
      (let* ((slot (poo-flow-module-extension-operation-slot operation))
             (current (poo-flow-module-extension-list-value
                       (poo-flow-module-extension-alist-ref/default
                        (poo-flow-module-extension-node-slots node) slot '())))
             (removed (poo-flow-module-extension-list-value
                       (poo-flow-module-extension-operation-value operation))))
        (poo-flow-module-extension-replace-node
         node
         (poo-flow-module-extension-alist-set
          (poo-flow-module-extension-node-slots node)
          slot
          (poo-flow-module-extension-remove-elements current removed))
         (poo-flow-module-extension-node-children node))))
     ((eq? action 'node-extend)
      (poo-flow-module-extension-replace-node
       node
       (poo-flow-module-extension-node-slots node)
       (poo-flow-module-extension-children-merge-one
        (poo-flow-module-extension-node-children node)
        (poo-flow-module-extension-operation-node operation))))
     ((eq? action 'node-remove)
      (poo-flow-module-extension-replace-node
       node
       (poo-flow-module-extension-node-slots node)
       (poo-flow-module-extension-children-remove
        (poo-flow-module-extension-node-children node)
        (poo-flow-module-extension-operation-target operation))))
     (else node))))

;; : (-> PooModuleExtensionNode [PooModuleExtensionNode] PooModuleExtensionNode)
(def (poo-flow-module-extension-flush-node-extends node reversed-children)
  (if (null? reversed-children)
    node
    (poo-flow-module-extension-replace-node
     node
     (poo-flow-module-extension-node-slots node)
     (poo-flow-module-extension-children-merge
      (poo-flow-module-extension-node-children node)
      (reverse reversed-children)))))

;; : (-> PooModuleExtensionNode PooModuleSlotMap PooModuleExtensionNode)
(def (poo-flow-module-extension-flush-slot-overrides node reversed-overrides)
  (if (null? reversed-overrides)
    node
    (poo-flow-module-extension-replace-node
     node
     (poo-flow-module-extension-slots-merge
      (poo-flow-module-extension-node-slots node)
      (reverse reversed-overrides))
     (poo-flow-module-extension-node-children node))))

;; : (-> PooModuleExtensionNode [PooModuleExtensionNode] PooModuleSlotMap PooModuleExtensionNode)
(def (poo-flow-module-extension-flush-pending node reversed-children reversed-overrides)
  (poo-flow-module-extension-flush-node-extends
   (poo-flow-module-extension-flush-slot-overrides node reversed-overrides)
   reversed-children))

;; : (-> PooModuleExtensionOperation Boolean)
(def (poo-flow-module-extension-slot-append-operation? operation)
  (eq? (poo-flow-module-extension-operation-action operation)
       'slot-append))

;; : (-> Boolean MaybeSymbol [PooModuleSlotValue] [PooModuleExtensionOperation] [PooModuleExtensionOperation])
(def (poo-flow-module-extension-flush-slot-append pending? slot reversed-values output)
  (if pending?
    (cons (poo-flow-module-extension-slot-append
           slot
           (reverse reversed-values))
          output)
    output))

;; poo-flow-module-extension-coalesce-slot-appends
;;   : (-> [PooModuleExtensionOperation] [PooModuleExtensionOperation])
;;   | doc m%
;;       `poo-flow-module-extension-coalesce-slot-appends` folds adjacent slot
;;       appends for the same slot into one append batch before operations are
;;       applied to the extension node.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-coalesce-slot-appends operations)
;;       ;; => coalesced-operations
;;       ```
;;     %
(def (poo-flow-module-extension-coalesce-slot-appends operations)
  (let loop ((remaining operations)
             (pending? #f)
             (pending-slot #f)
             (pending-values '())
             (output '()))
    (if (null? remaining)
      (reverse
       (poo-flow-module-extension-flush-slot-append pending?
                                                    pending-slot
                                                    pending-values
                                                    output))
      (let (operation (car remaining))
        (if (poo-flow-module-extension-slot-append-operation? operation)
          (let* ((slot (poo-flow-module-extension-operation-slot operation))
                 (values
                  (poo-flow-module-extension-list-value
                   (poo-flow-module-extension-operation-value operation))))
            (if (and pending?
                     (equal? pending-slot slot))
              (loop (cdr remaining)
                    #t
                    pending-slot
                    (foldl cons pending-values values)
                    output)
              (loop (cdr remaining)
                    #t
                    slot
                    (reverse values)
                    (poo-flow-module-extension-flush-slot-append
                     pending?
                     pending-slot
                     pending-values
                     output))))
          (loop (cdr remaining)
                #f
                #f
                '()
                (cons operation
                      (poo-flow-module-extension-flush-slot-append
                       pending?
                       pending-slot
                       pending-values
                       output))))))))

;; : (-> PooModuleExtensionOperation PooModuleExtensionOperationState
;;       PooModuleExtensionOperationState)
;; | type PooModuleExtensionOperationState =
;;     (Tuple PooModuleExtensionNode
;;            [PooModuleExtensionNode]
;;            [PooModuleSlotOverride])
(def (poo-flow-module-extension-operation-state operation state)
  (match state
    ([current pending-node-extends pending-slot-overrides]
     (let (action (poo-flow-module-extension-operation-action operation))
       (cond
        ((eq? action 'node-extend)
         [current
          (cons (poo-flow-module-extension-operation-node operation)
                pending-node-extends)
          pending-slot-overrides])
        ((eq? action 'slot-override)
         [current
          pending-node-extends
          (cons (cons (poo-flow-module-extension-operation-slot operation)
                      (poo-flow-module-extension-operation-value operation))
                pending-slot-overrides)])
        (else
         [(poo-flow-module-extension-apply-operation
           (poo-flow-module-extension-flush-pending current
                                                    pending-node-extends
                                                    pending-slot-overrides)
           operation)
          '()
          '()]))))))

;; poo-flow-module-extension-apply-operations
;;   : (-> PooModuleExtensionNode (List PooModuleExtensionOperation) PooModuleExtensionNode)
;;   | doc m%
;;       `poo-flow-module-extension-apply-operations node operations` applies
;;       an operation stream to one node, coalescing adjacent node extensions
;;       and slot overrides before flushing them into the graph.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-node-slots
;;        (poo-flow-module-extension-apply-operations
;;         (poo-flow-module-extension-node 'root '((features . (base))) [])
;;         (list (poo-flow-module-extension-slot-append 'features '(extra))
;;               (poo-flow-module-extension-slot-override 'mode 'strict))))
;;       ;; => ((features base extra) (mode . strict))
;;       ```
;;     %
