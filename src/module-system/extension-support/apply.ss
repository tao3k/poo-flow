;;; -*- Gerbil -*-
;;; Boundary: extension contribution coalescing and fixed-point application.

(import (only-in :clan/poo/object
                 .o
                 .ref
                 object?)
        :poo-flow/src/module-system/extension-support/data
        :poo-flow/src/module-system/extension-support/merge)

(export poo-flow-module-extension-apply-operations
        poo-flow-module-extension-local-operation?
        poo-flow-module-extension-local-operations?
        poo-flow-module-extension-reverse-onto
        poo-flow-module-extension-flush-coalesced
        poo-flow-module-extension-coalesce-local-contributions
        poo-flow-module-extension-apply-contribution
        poo-flow-module-extension-apply-contributions/coalesced
        poo-flow-module-extension-apply-contributions
        poo-flow-module-extension-node-snapshot
        poo-flow-module-extension-fixed-point-step
        poo-flow-module-extension-fixed-point)

;; : (-> [PooModuleExtensionOperation] PooModuleExtensionOperationState PooModuleExtensionOperationState)
(def (poo-flow-module-extension-operation-state/fold operations state)
  (foldl (lambda (operation current)
           (poo-flow-module-extension-operation-state operation current))
         state
         operations))

;; poo-flow-module-extension-node-extend-operation?
;; : (-> PooModuleExtensionOperation Boolean)
;; | doc m%
;;   Detect node-extension operations before the fast node-extend path runs.
;;   # Examples
;;   ```scheme
;;   (poo-flow-module-extension-node-extend-operation? operation)
;;   ;; => #t for node-extend operations
;;   ```
(def (poo-flow-module-extension-node-extend-operation? operation)
  (eq? (poo-flow-module-extension-operation-action operation) 'node-extend))

;; : (-> [PooModuleExtensionOperation] Boolean)
(def (poo-flow-module-extension-node-extend-operations? operations)
  (andmap poo-flow-module-extension-node-extend-operation? operations))

;; : (-> [PooModuleExtensionNode] [Symbol] [Symbol])
(def (poo-flow-module-extension-child-ids/rev children ids)
  (foldl (lambda (child current)
           (cons (poo-flow-module-extension-node-identity child)
                 current))
         ids
         children))

;; : (-> [PooModuleExtensionNode] HashTable HashTable Unit)
(def (poo-flow-module-extension-index-existing-children! children index seen)
  (for-each
   (lambda (child)
     (let (identity (poo-flow-module-extension-node-identity child))
      (hash-put! index identity child)
      (hash-put! seen identity #t)))
   children))

;; : (-> [PooModuleExtensionOperation] HashTable HashTable [Symbol] [Symbol])
(def (poo-flow-module-extension-index-node-extends! operations
                                                     index
                                                     seen
                                                     new-ids)
  (foldl
   (lambda (operation ids)
     (let* ((node (poo-flow-module-extension-operation-node operation))
            (identity (poo-flow-module-extension-node-identity node))
            (known? (hash-get seen identity)))
       (hash-put! index identity node)
       (if known?
         ids
         (begin
           (hash-put! seen identity #t)
           (cons identity ids)))))
   new-ids
   operations))

;; : (-> [Symbol] HashTable [PooModuleExtensionNode] [PooModuleExtensionNode])
(def (poo-flow-module-extension-ids->children/rev ids index children)
  (foldl (lambda (identity current)
           (cons (hash-get index identity) current))
         children
         ids))

;; poo-flow-module-extension-apply-node-extends
;; : (-> PooModuleExtensionNode [PooModuleExtensionOperation] PooModuleExtensionNode)
;; | doc m%
;;   Apply a batch of node-extend operations by indexing existing and new children.
;;   # Examples
;;   ```scheme
;;   (poo-flow-module-extension-apply-node-extends node operations)
;;   ;; => node with child extensions merged by identity
;;   ```
(def (poo-flow-module-extension-apply-node-extends node operations)
  (let* ((children (poo-flow-module-extension-node-children node))
         (index (make-hash-table))
         (seen (make-hash-table)))
    (poo-flow-module-extension-index-existing-children! children index seen)
    (let* ((base-ids
            (reverse
             (poo-flow-module-extension-child-ids/rev children '())))
           (new-ids
            (reverse
             (poo-flow-module-extension-index-node-extends!
              operations
              index
              seen
              '())))
           (merged-ids (append base-ids new-ids)))
      (poo-flow-module-extension-replace-node
       node
       (poo-flow-module-extension-node-slots node)
       (reverse
        (poo-flow-module-extension-ids->children/rev
         merged-ids
         index
         '()))))))

;; poo-flow-module-extension-apply-operations
;;   : (-> PooModuleExtensionNode (List PooModuleExtensionOperation) PooModuleExtensionNode)
;;   | doc m%
;;       `poo-flow-module-extension-apply-operations` coalesces slot append
;;       operations before applying pending node extension and slot override
;;       batches to one extension node.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-apply-operations node operations)
;;       ;; => node with coalesced local slot operations applied
;;       ```
;;     %
(def (poo-flow-module-extension-apply-operations node operations)
  (if (poo-flow-module-extension-node-extend-operations? operations)
    (poo-flow-module-extension-apply-node-extends node operations)
    (match (poo-flow-module-extension-operation-state/fold
            (poo-flow-module-extension-coalesce-slot-appends operations)
            [node '() '()])
      ([current pending-node-extends pending-slot-overrides]
       (poo-flow-module-extension-flush-pending current
                                                pending-node-extends
                                                pending-slot-overrides)))))

;; poo-flow-module-extension-local-operation?
;; : (-> PooModuleExtensionOperation Boolean)
;; | doc m%
;;   Detect operations that can be coalesced within one target node.
;;   # Examples
;;   ```scheme
;;   (poo-flow-module-extension-local-operation? operation)
;;   ;; => #t for local slot operations
;;   ```
(def (poo-flow-module-extension-local-operation? operation)
  (let (action (poo-flow-module-extension-operation-action operation))
    (or (eq? action 'slot-override)
        (eq? action 'slot-append)
        (eq? action 'slot-prepend)
        (eq? action 'slot-remove))))

;;; Local batches may be coalesced only when every operation stays within the
;;; current target; graph-wide operations must force a contribution boundary.
;; : (-> [PooModuleExtensionOperation] Boolean)
(def (poo-flow-module-extension-local-operations? operations)
  (andmap poo-flow-module-extension-local-operation? operations))

;;; Reversing into an existing tail is the hot append-free path for pending
;;; operation stacks, preserving order without allocating intermediate appends.
;; : (forall (a) (-> (List a) (List a) (List a)))
(def (poo-flow-module-extension-reverse-onto values tail)
  (foldl cons tail values))

;;; Flushing is guarded by the pending flag so empty coalescing state never
;;; creates synthetic contributions or changes target ordering.
;; poo-flow-module-extension-flush-coalesced
;; : (-> Boolean MaybeSymbol [PooModuleExtensionOperation] [PooModuleExtensionContribution] [PooModuleExtensionContribution])
;; | doc m%
;;   Append one pending coalesced contribution when the fold state is active.
;;   # Examples
;;   ```scheme
;;   (poo-flow-module-extension-flush-coalesced #t 'root operations output)
;;   ;; => output with one pending contribution
;;   ```
(def (poo-flow-module-extension-flush-coalesced pending? target reversed-operations output)
  (if pending?
    (cons (poo-flow-module-extension-contribution
           target
           (reverse reversed-operations))
          output)
    output))

;;; Contribution coalescing keeps adjacent same-target local operations in one
;;; batch and flushes as soon as the target or operation scope changes.
;; : (-> PooModuleExtensionCoalesceState PooModuleExtensionContribution PooModuleExtensionCoalesceState)
(def (poo-flow-module-extension-coalesce-contribution-state state contribution)
  (match state
    ([pending? pending-target pending-operations output]
     (let ((target
            (poo-flow-module-extension-contribution-target contribution))
           (operations
            (poo-flow-module-extension-contribution-operations contribution)))
       (if (poo-flow-module-extension-local-operations? operations)
         (if (and pending? (equal? pending-target target))
           [#t
            pending-target
            (poo-flow-module-extension-reverse-onto operations
                                                    pending-operations)
            output]
           [#t
            target
            (reverse operations)
            (poo-flow-module-extension-flush-coalesced pending?
                                                       pending-target
                                                       pending-operations
                                                       output)])
         [#f
          #f
          '()
          (cons contribution
                (poo-flow-module-extension-flush-coalesced
                 pending?
                 pending-target
                 pending-operations
                 output))])))))

;;; Output materialization is the only place the reversed coalescing accumulator
;;; is exposed, keeping the state tuple append-free during the fold.
;; : (-> PooModuleExtensionCoalesceState [PooModuleExtensionContribution])
(def (poo-flow-module-extension-coalesce-state-output state)
  (match state
    ([pending? pending-target pending-operations output]
     (reverse
      (poo-flow-module-extension-flush-coalesced pending?
                                                 pending-target
                                                 pending-operations
                                                 output)))))

;; poo-flow-module-extension-coalesce-local-contributions
;;   : (-> (List PooModuleExtensionContribution) (List PooModuleExtensionContribution))
;;   | doc m%
;;       `poo-flow-module-extension-coalesce-local-contributions contributions`
;;       combines adjacent local contributions for the same target so fixed
;;       point extension passes apply one compact operation batch per target.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-coalesce-local-contributions
;;        (list
;;         (poo-flow-module-extension-contribution
;;          'root
;;          (list (poo-flow-module-extension-slot-override 'mode 'strict)))
;;         (poo-flow-module-extension-contribution
;;          'root
;;          (list (poo-flow-module-extension-slot-append 'features
;;                                                      '(extra))))))
;;       ;; => ((root (slot-override slot-append)))
;;       ```
;;     %
(def (poo-flow-module-extension-coalesce-local-contributions/fold
      contributions
      state)
  (foldl (lambda (contribution current)
           (poo-flow-module-extension-coalesce-contribution-state
            current
            contribution))
         state
         contributions))

;; : (-> [PooModuleExtensionContribution] [PooModuleExtensionContribution])
(def (poo-flow-module-extension-coalesce-local-contributions contributions)
  (poo-flow-module-extension-coalesce-state-output
   (poo-flow-module-extension-coalesce-local-contributions/fold
    contributions
    [#f #f '() '()])))

;;; Contribution application recurses through children after the current target
;;; has been patched, which keeps parent and child updates in one graph walk.
;; : (-> PooModuleExtensionNode PooModuleExtensionContribution PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-contribution-children/rev
      children
      contribution
      children-rev)
  (foldl (lambda (child current)
           (cons (poo-flow-module-extension-apply-contribution
                  child
                  contribution)
                 current))
         children-rev
         children))

;; : (-> [PooModuleExtensionNode] PooModuleExtensionContribution [PooModuleExtensionNode])
(def (poo-flow-module-extension-apply-contribution-children children
                                                            contribution)
  (map (lambda (child)
         (poo-flow-module-extension-apply-contribution child contribution))
       children))

;; poo-flow-module-extension-apply-contribution
;; : (-> PooModuleExtensionNode PooModuleExtensionContribution PooModuleExtensionNode)
;; | doc m%
;;   Apply one contribution to its target node or recurse into children.
;;   # Examples
;;   ```scheme
;;   (poo-flow-module-extension-apply-contribution node contribution)
;;   ;; => node with the matching target patched
;;   ```
(def (poo-flow-module-extension-apply-contribution node contribution)
  (let* ((target (poo-flow-module-extension-contribution-target contribution))
         (identity (poo-flow-module-extension-node-identity node)))
    (if (equal? target identity)
      (poo-flow-module-extension-apply-operations
       node
       (poo-flow-module-extension-contribution-operations contribution))
      (poo-flow-module-extension-replace-node
       node
       (poo-flow-module-extension-node-slots node)
       (poo-flow-module-extension-apply-contribution-children
        (poo-flow-module-extension-node-children node)
        contribution)))))

;;; The coalesced path assumes contribution order is already compacted, so it
;;; can fold directly over graph updates without another normalization pass.
;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-contributions/coalesced-loop
      current
      contributions)
  (foldl (lambda (contribution node)
           (poo-flow-module-extension-apply-contribution node contribution))
         current
         contributions))

;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-contributions/coalesced node contributions)
  (poo-flow-module-extension-apply-contributions/coalesced-loop node
                                                                contributions))

;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-contributions node contributions)
  (poo-flow-module-extension-apply-contributions/coalesced
   node
   (poo-flow-module-extension-coalesce-local-contributions contributions)))

;;; Snapshot comparison keeps fixed-point convergence structural and independent
;;; of POO object identity or lazy slot internals.
;; : (-> PooModuleExtensionNode PooModuleExtensionSnapshot)
;; | PooModuleExtensionSnapshot = List
(def (poo-flow-module-extension-node-snapshot node)
  (list (poo-flow-module-extension-node-identity node)
        (poo-flow-module-extension-node-slots node)
        (map poo-flow-module-extension-node-snapshot
             (poo-flow-module-extension-node-children node))))

;; : (-> PooModuleExtensionContribution Boolean)
(def (poo-flow-module-extension-local-contribution? contribution)
  (poo-flow-module-extension-local-operations?
   (poo-flow-module-extension-contribution-operations contribution)))

;;; Fixed-point fast paths only use local contribution batches when every
;;; contribution is local; mixed graph operations must fall back to iteration.
;; : (-> [PooModuleExtensionContribution] Boolean)
(def (poo-flow-module-extension-local-contributions? contributions)
  (andmap poo-flow-module-extension-local-contribution? contributions))

;;; Root slot append fast path is valid only for the current root identity and
;;; pure slot append payloads, avoiding child traversal.
;; : (-> Symbol PooModuleExtensionContribution Boolean)
(def (poo-flow-module-extension-root-slot-append-contribution? node-identity
                                                              contribution)
  (and (equal? (poo-flow-module-extension-contribution-target contribution)
               node-identity)
       (andmap poo-flow-module-extension-slot-append-operation?
               (poo-flow-module-extension-contribution-operations
                contribution))))

;;; All root append contributions must satisfy the same identity guard before
;;; the batch can bypass fixed-point graph traversal.
;; : (-> Symbol [PooModuleExtensionContribution] Boolean)
(def (poo-flow-module-extension-root-slot-append-contributions?/loop
      node-identity
      contributions)
  (cond
   ((null? contributions) #t)
   ((poo-flow-module-extension-root-slot-append-contribution?
     node-identity
     (car contributions))
    (poo-flow-module-extension-root-slot-append-contributions?/loop
     node-identity
     (cdr contributions)))
   (else #f)))

;; : (-> Symbol [PooModuleExtensionContribution] Boolean)
(def (poo-flow-module-extension-root-slot-append-contributions? node-identity
                                                                contributions)
  (poo-flow-module-extension-root-slot-append-contributions?/loop
   node-identity
   contributions))

;; poo-flow-module-extension-fast-slot-append-slots
;;   : (-> PooModuleSlotMap (List PooModuleExtensionContribution) Pair)
;;   | doc m%
;;       `poo-flow-module-extension-fast-slot-append-slots` materializes the
;;       root-only slot append fast path by indexing existing values once,
;;       collecting new additions in reverse, and preserving slot order.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-fast-slot-append-slots slots contributions)
;;       ;; => pair of updated slots and changed? flag
;;       ```
;;     %
(def (poo-flow-module-extension-fast-slot-append-slots slots contributions)
  (let ((base-seen (make-hash-table))
        (new-seen (make-hash-table))
        (active (make-hash-table))
        (bases (make-hash-table))
        (additions (make-hash-table))
        (value-indexes (make-hash-table)))
    (for-each
     (lambda (entry)
       (hash-put! base-seen
                  (poo-flow-module-extension-entry-key entry)
                  #t))
     slots)
    (def (slot-base key)
      (poo-flow-module-extension-list-value
       (poo-flow-module-extension-alist-ref/default slots key '())))
    (def (base-slot? key) (hash-get base-seen key))
    (def (new-slot-seen? key) (hash-get new-seen key))
    (def (new-slot? key)
      (and (not (base-slot? key))
           (not (new-slot-seen? key))))
    (def (remember-new-slot! key)
      (hash-put! new-seen key #t))
    (def (slot-active? key) (hash-get active key))
    (def (slot-base-list key) (hash-get bases key))
    (def (slot-additions key) (hash-get additions key))
    (def (set-slot-additions! key values)
      (hash-put! additions key values))
    (def (slot-value-index key) (hash-get value-indexes key))
    (def (append-operation-slot operation)
      (poo-flow-module-extension-operation-slot operation))
    (def (append-operation-value-list operation)
      (poo-flow-module-extension-list-value
       (poo-flow-module-extension-operation-value operation)))
    (def (activate-slot! key)
      (if (slot-active? key)
        #f
        (let (base (slot-base key))
          (hash-put! active key #t)
          (hash-put! bases key base)
          (hash-put! additions key '())
          (hash-put! value-indexes
                     key
                     (poo-flow-module-extension-value-index base)))))
    (def (append-operation-values! operation)
      (let* ((key (append-operation-slot operation))
             (values (append-operation-value-list operation))
             (operation-new-slot? (new-slot? key)))
        (activate-slot! key)
        (if operation-new-slot?
          (remember-new-slot! key))
        (let (seen (slot-value-index key))
          (let loop ((remaining values)
                     (next-additions (slot-additions key))
                     (changed? operation-new-slot?))
            (cond
             ((null? remaining)
              (set-slot-additions! key next-additions)
              changed?)
             ((hash-get seen (car remaining))
              (loop (cdr remaining) next-additions changed?))
             (else
              (hash-put! seen (car remaining) #t)
              (loop (cdr remaining)
                    (cons (car remaining) next-additions)
                    #t)))))))
    (def (materialize-slot key)
      (let ((base (slot-base-list key))
            (extra (slot-additions key)))
        (if (null? extra)
          base
          (append base (reverse extra)))))
    (def (materialize-existing-slots/rev remaining result-rev)
      (if (null? remaining)
        result-rev
        (let* ((entry (car remaining))
               (key (poo-flow-module-extension-entry-key entry)))
          (materialize-existing-slots/rev
           (cdr remaining)
           (cons (if (slot-active? key)
                   (poo-flow-module-extension-entry
                    key
                    (materialize-slot key))
                   entry)
                 result-rev)))))
    (def (materialize-new-slots/rev remaining-new-order result-rev)
      (if (null? remaining-new-order)
        result-rev
        (let (key (car remaining-new-order))
          (materialize-new-slots/rev
           (cdr remaining-new-order)
           (cons (poo-flow-module-extension-entry key (materialize-slot key))
                 result-rev)))))
    (def (materialize-slots new-order)
      (reverse
       (materialize-new-slots/rev
        (reverse new-order)
        (materialize-existing-slots/rev slots '()))))
    (let loop-contributions ((remaining-contributions contributions)
                             (new-order '())
                             (changed? #f))
      (if (null? remaining-contributions)
        (if (and (not changed?) (null? new-order))
          (cons slots #f)
          (cons (materialize-slots new-order) #t))
        (let loop-operations
            ((remaining-operations
              (poo-flow-module-extension-contribution-operations
               (car remaining-contributions)))
             (next-new-order new-order)
             (next-changed? changed?))
          (if (null? remaining-operations)
            (loop-contributions (cdr remaining-contributions)
                                next-new-order
                                next-changed?)
            (let* ((operation (car remaining-operations))
                   (key (append-operation-slot operation))
                   (operation-new-slot? (new-slot? key))
                   (operation-changed?
                    (append-operation-values! operation)))
              (loop-operations
               (cdr remaining-operations)
               (if operation-new-slot?
                 (cons key next-new-order)
                 next-new-order)
               (or next-changed? operation-changed?)))))))))

;;; This root-only shortcut converts the slot append pair into a stable result
;;; without walking children, preserving the iteration count contract.
;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] MaybePooModuleExtensionResult)
(def (poo-flow-module-extension-fast-root-slot-append-result base contributions)
  (let ((node-identity (poo-flow-module-extension-node-identity base))
        (children (poo-flow-module-extension-node-children base)))
    (and (null? children)
         (poo-flow-module-extension-root-slot-append-contributions?
          node-identity
          contributions)
         (let (state
               (poo-flow-module-extension-fast-slot-append-slots
                (poo-flow-module-extension-node-slots base)
                contributions))
           (poo-flow-module-extension-result
            (poo-flow-module-extension-replace-node base
                                                    (car state)
                                                    children)
            (if (cdr state) 1 0)
            #t)))))

;;; Fast local evaluation returns a result only when local checks prove that one
;;; non-recursive application is equivalent to the fixed-point loop.
;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] MaybePooModuleExtensionResult)
(def (poo-flow-module-extension-fast-local-result base contributions)
  (or (poo-flow-module-extension-fast-root-slot-append-result base
                                                             contributions)
      (and (poo-flow-module-extension-local-contributions? contributions)
           (let (next (poo-flow-module-extension-apply-contributions
                       base
                       contributions))
             (poo-flow-module-extension-result
              next
              (if (equal? (poo-flow-module-extension-node-snapshot base)
                          (poo-flow-module-extension-node-snapshot next))
                0
                1)
              #t)))))

;; poo-flow-module-extension-fixed-point-step
;;   : (-> PooModuleExtensionNode (List PooModuleExtensionContribution) Integer PooModuleExtensionResult)
;;   | doc m%
;;       `poo-flow-module-extension-fixed-point-step` performs one bounded
;;       fixed-point pass and recurs only when the node snapshot changes,
;;       returning an unstable result after the iteration cap.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-fixed-point-step node contributions 0)
;;       ;; => extension result with stable? reflecting the bounded pass
;;       ```
;;     %
(def (poo-flow-module-extension-fixed-point-step current contributions iteration)
  (let (next (poo-flow-module-extension-apply-contributions current contributions))
    (cond
     ((equal? (poo-flow-module-extension-node-snapshot current)
              (poo-flow-module-extension-node-snapshot next))
      (poo-flow-module-extension-result next iteration #t))
     ((>= iteration 16)
      (poo-flow-module-extension-result next iteration #f))
     (else
      (poo-flow-module-extension-fixed-point-step
       next
       contributions
       (+ iteration 1))))))

;; poo-flow-module-extension-fixed-point
;;   : (-> PooModuleExtensionNode [PooModuleExtensionContribution] PooModuleExtensionResult)
;;   | contract: applies extension contributions until the graph snapshot is stable
;;   | warning: stops after 16 iterations and marks the result unstable
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-extension-fixed-point root contributions)
;;       ;; => extension result with root, iteration count, and stable? flag
;;       ```
;;     %
(def (poo-flow-module-extension-fixed-point base contributions)
  (or (poo-flow-module-extension-fast-local-result base contributions)
      (poo-flow-module-extension-fixed-point-step base contributions 0)))
