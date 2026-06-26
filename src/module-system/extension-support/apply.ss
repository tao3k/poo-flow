;;; -*- Gerbil -*-
;;; Boundary: extension contribution coalescing and fixed-point application.

(import (only-in :clan/poo/object
                 .o
                 .ref
                 object?)
        (only-in :std/sugar foldl)
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

;; : (-> PooModuleExtensionNode [PooModuleExtensionOperation] PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-operations node operations)
  (match (foldl poo-flow-module-extension-operation-state
                [node '() '()]
                (poo-flow-module-extension-coalesce-slot-appends operations))
    ([current pending-node-extends pending-slot-overrides]
     (poo-flow-module-extension-flush-pending current
                                              pending-node-extends
                                              pending-slot-overrides))))

;; : (-> PooModuleExtensionOperation Boolean)
(def (poo-flow-module-extension-local-operation? operation)
  (let (action (poo-flow-module-extension-operation-action operation))
    (or (eq? action 'slot-override)
        (eq? action 'slot-append)
        (eq? action 'slot-prepend)
        (eq? action 'slot-remove))))

;; : (-> [PooModuleExtensionOperation] Boolean)
(def (poo-flow-module-extension-local-operations? operations)
  (andmap poo-flow-module-extension-local-operation? operations))

;; : (forall (a) (-> (List a) (List a) (List a)))
(def (poo-flow-module-extension-reverse-onto values tail)
  (foldl cons tail values))

;; : (-> Boolean MaybeSymbol [PooModuleExtensionOperation] [PooModuleExtensionContribution] [PooModuleExtensionContribution])
(def (poo-flow-module-extension-flush-coalesced pending? target reversed-operations output)
  (if pending?
    (cons (poo-flow-module-extension-contribution
           target
           (reverse reversed-operations))
          output)
    output))

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
;;       (map (lambda (contribution)
;;              (list (poo-flow-module-extension-contribution-target contribution)
;;                    (map poo-flow-module-extension-operation-action
;;                         (poo-flow-module-extension-contribution-operations
;;                          contribution))))
;;            (poo-flow-module-extension-coalesce-local-contributions
;;             (list
;;              (poo-flow-module-extension-contribution
;;               'root
;;               (list (poo-flow-module-extension-slot-override 'mode 'strict)))
;;              (poo-flow-module-extension-contribution
;;               'root
;;               (list (poo-flow-module-extension-slot-append 'features
;;                                                           '(extra)))))))
;;       ;; => ((root (slot-override slot-append)))
;;       ```
;;     %
(def (poo-flow-module-extension-coalesce-local-contributions contributions)
  (poo-flow-module-extension-coalesce-state-output
   (foldl (lambda (contribution state)
            (poo-flow-module-extension-coalesce-contribution-state
             state
             contribution))
          [#f #f '() '()]
          contributions)))

;;; Contribution application recurses through children after the current target
;;; has been patched, which keeps parent and child updates in one graph walk.
;; : (-> PooModuleExtensionNode PooModuleExtensionContribution PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-contribution node contribution)
  (let* ((target (poo-flow-module-extension-contribution-target contribution))
         (current
          (if (equal? target (poo-flow-module-extension-node-identity node))
            (poo-flow-module-extension-apply-operations
             node
             (poo-flow-module-extension-contribution-operations contribution))
            node)))
    (poo-flow-module-extension-replace-node
     current
     (poo-flow-module-extension-node-slots current)
     (map (lambda (child)
            (poo-flow-module-extension-apply-contribution child contribution))
          (poo-flow-module-extension-node-children current)))))

;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-contributions/coalesced node contributions)
  (foldl (lambda (contribution current)
           (poo-flow-module-extension-apply-contribution current contribution))
         node
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

;; : (-> [PooModuleExtensionContribution] Boolean)
(def (poo-flow-module-extension-local-contributions? contributions)
  (andmap poo-flow-module-extension-local-contribution? contributions))

;; : (-> Symbol PooModuleExtensionContribution Boolean)
(def (poo-flow-module-extension-root-slot-append-contribution? node-identity
                                                              contribution)
  (and (equal? (poo-flow-module-extension-contribution-target contribution)
               node-identity)
       (andmap poo-flow-module-extension-slot-append-operation?
               (poo-flow-module-extension-contribution-operations
                contribution))))

;; : (-> Symbol [PooModuleExtensionContribution] Boolean)
(def (poo-flow-module-extension-root-slot-append-contributions? node-identity
                                                                contributions)
  (andmap (lambda (contribution)
            (poo-flow-module-extension-root-slot-append-contribution?
             node-identity
             contribution))
          contributions))

;; : (-> PooModuleSlotMap [PooModuleExtensionContribution] Pair)
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
    (let loop-contributions ((remaining-contributions contributions)
                             (new-order '())
                             (changed? #f))
      (if (null? remaining-contributions)
        (if (and (not changed?) (null? new-order))
          (cons slots #f)
          (cons
           (append
            (map (lambda (entry)
                   (let (key (poo-flow-module-extension-entry-key entry))
                     (if (slot-active? key)
                       (poo-flow-module-extension-entry
                        key
                        (materialize-slot key))
                       entry)))
                 slots)
            (map (lambda (key)
                   (poo-flow-module-extension-entry key (materialize-slot key)))
                 (reverse new-order)))
           #t))
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

;;; Fixed-point stepping is isolated so policy can see bounded recursion without
;;; mistaking it for a general-purpose list transform.
;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] Integer PooModuleExtensionResult)
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
