;;; -*- Gerbil -*-
;;; Boundary: generic POO module extension graph and fixed-point convergence.

(import (only-in :clan/poo/object
                 .o
                 .ref
                 object?)
        (only-in :std/sugar foldl))

(export poo-flow-module-extension-node-kind
        poo-flow-module-extension-operation-kind
        poo-flow-module-extension-contribution-kind
        poo-flow-module-extension-result-kind
        poo-flow-module-extension-node
        poo-flow-module-extension-node?
        poo-flow-module-extension-node-identity
        poo-flow-module-extension-node-slots
        poo-flow-module-extension-node-children
        poo-flow-module-extension-child-ref
        poo-flow-module-extension-slot-override
        poo-flow-module-extension-slot-append
        poo-flow-module-extension-slot-prepend
        poo-flow-module-extension-slot-remove
        poo-flow-module-extension-node-extend
        poo-flow-module-extension-node-remove
        poo-flow-module-extension-contribution
        poo-flow-module-extension-contribution?
        poo-flow-module-extension-contribution-target
        poo-flow-module-extension-contribution-operations
        poo-flow-module-extension-apply-contribution
        poo-flow-module-extension-apply-contributions
        poo-flow-module-extension-fixed-point
        poo-flow-module-extension-result
        poo-flow-module-extension-result?
        poo-flow-module-extension-result-root
        poo-flow-module-extension-result-iterations
        poo-flow-module-extension-result-stable?
        poo-flow-module-extension-node-snapshot)

;; : PooModuleExtensionNodeKindId
;; | PooModuleExtensionNodeKindId = String
(def poo-flow-module-extension-node-kind "poo-flow.modules.extension.node.v1")
;; : PooModuleExtensionOperationKindId
;; | PooModuleExtensionOperationKindId = String
(def poo-flow-module-extension-operation-kind "poo-flow.modules.extension.operation.v1")
;; : PooModuleExtensionContributionKindId
;; | PooModuleExtensionContributionKindId = String
(def poo-flow-module-extension-contribution-kind "poo-flow.modules.extension.contribution.v1")
;; : PooModuleExtensionResultKindId
;; | PooModuleExtensionResultKindId = String
(def poo-flow-module-extension-result-kind "poo-flow.modules.extension.result.v1")

;;; Kind checks are slot-based so POO extension objects can evolve without
;;; exposing constructor identity to downstream module configs.
;; : (-> PooModuleValueCandidate PooModuleKindId Boolean)
(def (poo-flow-module-extension-kind? value kind)
  (and (object? value) (equal? (.ref value 'kind) kind)))

;;; Nodes are inert POO graph data; extension operations transform this graph
;;; before any loader or runtime code sees module configuration.
;; : (-> Symbol Alist [PooModuleExtensionNode] PooModuleExtensionNode)
(def (poo-flow-module-extension-node identity slots children)
  (let ((identity-value identity) (slots-value slots) (children-value children))
    (.o kind: poo-flow-module-extension-node-kind
        identity: identity-value
        slots: slots-value
        children: children-value)))

;; : (-> PooModuleExtensionNodeCandidate Boolean)
(def (poo-flow-module-extension-node? value)
  (poo-flow-module-extension-kind? value poo-flow-module-extension-node-kind))

;; : (-> PooModuleExtensionNode Symbol)
(def (poo-flow-module-extension-node-identity node) (.ref node 'identity))
;; : (-> PooModuleExtensionNode PooModuleSlotMap)
(def (poo-flow-module-extension-node-slots node) (.ref node 'slots))
;; : (-> PooModuleExtensionNode [PooModuleExtensionNode])
(def (poo-flow-module-extension-node-children node) (.ref node 'children))

;;; Operations are normalized to one POO value so module objects, field
;;; contracts, and direct graph edits share a single merge path.
;; : (-> Symbol MaybeSymbol PooModuleSlotValue MaybePooModuleExtensionNode MaybeSymbol PooModuleExtensionOperation)
(def (poo-flow-module-extension-operation action slot value node target)
  (let ((action-value action)
        (slot-value slot)
        (value-value value)
        (node-value node)
        (target-value target))
    (.o kind: poo-flow-module-extension-operation-kind
        action: action-value
        slot: slot-value
        value: value-value
        node: node-value
        target: target-value)))

;; : (-> PooModuleExtensionOperation Symbol)
(def (poo-flow-module-extension-operation-action operation) (.ref operation 'action))
;; : (-> PooModuleExtensionOperation MaybeSymbol)
(def (poo-flow-module-extension-operation-slot operation) (.ref operation 'slot))
;; : (-> PooModuleExtensionOperation PooModuleSlotValue)
(def (poo-flow-module-extension-operation-value operation) (.ref operation 'value))
;; : (-> PooModuleExtensionOperation MaybePooModuleExtensionNode)
(def (poo-flow-module-extension-operation-node operation) (.ref operation 'node))
;; : (-> PooModuleExtensionOperation MaybeSymbol)
(def (poo-flow-module-extension-operation-target operation) (.ref operation 'target))

;; : (-> Symbol PooModuleSlotValue PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-override slot value)
  (poo-flow-module-extension-operation 'slot-override slot value #f #f))
;; : (-> Symbol [PooModuleSlotValue] PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-append slot values)
  (poo-flow-module-extension-operation 'slot-append slot values #f #f))
;; : (-> Symbol [PooModuleSlotValue] PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-prepend slot values)
  (poo-flow-module-extension-operation 'slot-prepend slot values #f #f))
;; : (-> Symbol [PooModuleSlotValue] PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-remove slot values)
  (poo-flow-module-extension-operation 'slot-remove slot values #f #f))
;; : (-> PooModuleExtensionNode PooModuleExtensionOperation)
(def (poo-flow-module-extension-node-extend node)
  (poo-flow-module-extension-operation 'node-extend #f #f node #f))
;; : (-> Symbol PooModuleExtensionOperation)
(def (poo-flow-module-extension-node-remove target)
  (poo-flow-module-extension-operation 'node-remove #f #f #f target))

;;; Contributions keep the target identity outside individual operations so a
;;; profile can patch one node with several ordered edits.
;; : (-> Symbol [PooModuleExtensionOperation] PooModuleExtensionContribution)
(def (poo-flow-module-extension-contribution target operations)
  (let ((target-value target) (operations-value operations))
    (.o kind: poo-flow-module-extension-contribution-kind
        target: target-value
        operations: operations-value)))

;; : (-> PooModuleExtensionContributionCandidate Boolean)
(def (poo-flow-module-extension-contribution? value)
  (poo-flow-module-extension-kind? value poo-flow-module-extension-contribution-kind))
;; : (-> PooModuleExtensionContribution Symbol)
(def (poo-flow-module-extension-contribution-target contribution) (.ref contribution 'target))
;; : (-> PooModuleExtensionContribution [PooModuleExtensionOperation])
(def (poo-flow-module-extension-contribution-operations contribution) (.ref contribution 'operations))

;;; Fixed-point results report convergence explicitly; unstable results are
;;; evidence for the doctor path instead of hidden runtime failures.
;; : (-> PooModuleExtensionNode Integer Boolean PooModuleExtensionResult)
(def (poo-flow-module-extension-result root iterations stable?)
  (let ((root-value root) (iterations-value iterations) (stable-value stable?))
    (.o kind: poo-flow-module-extension-result-kind
        root: root-value
        iterations: iterations-value
        stable?: stable-value)))

;; : (-> PooModuleResultCandidate Boolean)
(def (poo-flow-module-extension-result? value)
  (poo-flow-module-extension-kind? value poo-flow-module-extension-result-kind))
;; : (-> PooModuleExtensionResult PooModuleExtensionNode)
(def (poo-flow-module-extension-result-root result) (.ref result 'root))
;; : (-> PooModuleExtensionResult Integer)
(def (poo-flow-module-extension-result-iterations result) (.ref result 'iterations))
;; : (-> PooModuleExtensionResult Boolean)
(def (poo-flow-module-extension-result-stable? result) (.ref result 'stable?))

;; : (-> PooModuleSlotValue [PooModuleSlotValue] Boolean)
(def (poo-flow-module-extension-member? value values)
  (and (member value values) #t))

;; : (-> [PooModuleSlotValue] HashTable)
(def (poo-flow-module-extension-value-index values)
  (let (index (make-hash-table))
    (for-each
     (lambda (value)
       (hash-put! index value #t))
     values)
    index))

;;; Append keeps the base order stable and filters only duplicate extras, which
;;; makes agent-authored list extensions deterministic across fixed-point runs.
;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-extension-append-distinct base extra)
  (if (null? extra)
    base
    (poo-flow-module-extension-append-distinct/indexed
     base
     extra
     (poo-flow-module-extension-value-index base))))

;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] HashTable [PooModuleSlotValue])
(def (poo-flow-module-extension-append-distinct/indexed base extra seen)
  (let (added
        (foldl (lambda (value result)
                 (if (hash-get seen value)
                   result
                   (begin
                     (hash-put! seen value #t)
                     (cons value result))))
               '()
               extra))
    (if (null? added)
      base
      (append base (reverse added)))))

;;; Remove is value-based rather than positional so downstream patches can
;;; delete inherited list elements without knowing the upstream list index.
;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-extension-remove-elements values removed)
  (if (null? removed)
    values
    (let (removed-index (poo-flow-module-extension-value-index removed))
      (reverse
       (foldl (lambda (value kept)
                (if (hash-get removed-index value)
                  kept
                  (cons value kept)))
              '()
              values)))))

;; : (-> PooModuleSlotValue [PooModuleSlotValue])
(def (poo-flow-module-extension-list-value value)
  (cond ((null? value) '())
        ((list? value) value)
        (else (list value))))

;; : (-> PooModuleSlotEntry Symbol)
(def (poo-flow-module-extension-entry-key entry)
  (car entry))

;; : (-> PooModuleSlotEntry PooModuleSlotValue)
(def (poo-flow-module-extension-entry-value entry)
  (cdr entry))

;; : (-> Symbol PooModuleSlotValue PooModuleSlotEntry)
(def (poo-flow-module-extension-entry key value)
  (cons key value))

;; : (-> PooModuleSlotMap Symbol PooModuleSlotValue PooModuleSlotMap)
(def (poo-flow-module-extension-alist-set entries key value)
  (cond ((null? entries)
         (list (poo-flow-module-extension-entry key value)))
        ((equal? (poo-flow-module-extension-entry-key (car entries)) key)
         (cons (poo-flow-module-extension-entry key value)
               (cdr entries)))
        (else (cons (car entries)
                    (poo-flow-module-extension-alist-set (cdr entries) key value)))))

;; : (-> PooModuleSlotMap Symbol PooModuleSlotValue PooModuleSlotValue)
(def (poo-flow-module-extension-alist-ref/default entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;; : (-> PooModuleExtensionNode PooModuleSlotMap [PooModuleExtensionNode] PooModuleExtensionNode)
(def (poo-flow-module-extension-replace-node node slots children)
  (poo-flow-module-extension-node
   (poo-flow-module-extension-node-identity node)
   slots
   children))

;; : (-> [PooModuleExtensionNode] Symbol MaybePooModuleExtensionNode)
(def (poo-flow-module-extension-child-ref children identity)
  (cond ((null? children) #f)
        ((equal? (poo-flow-module-extension-node-identity (car children)) identity)
         (car children))
        (else (poo-flow-module-extension-child-ref (cdr children) identity))))

;; poo-flow-module-extension-slots-merge
;;   : (-> PooModuleSlotMap PooModuleSlotMap PooModuleSlotMap)
;;   | doc m%
;;       `poo-flow-module-extension-slots-merge base extra` overlays slot
;;       values from `extra` while preserving the first-seen slot order from
;;       `base`; new slot keys are appended in first override order.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-slots-merge
;;        '((mode . dev) (features . (base)))
;;        '((mode . prod) (extra . #t)))
;;       ;; => ((mode . prod) (features base) (extra . #t))
;;       ```
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
  (cond ((null? operations) #t)
        ((poo-flow-module-extension-local-operation? (car operations))
         (poo-flow-module-extension-local-operations? (cdr operations)))
        (else #f)))

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
  (let loop ((remaining contributions)
             (pending? #f)
             (pending-target #f)
             (pending-operations '())
             (output '()))
    (if (null? remaining)
      (reverse
       (poo-flow-module-extension-flush-coalesced pending?
                                                  pending-target
                                                  pending-operations
                                                  output))
      (let* ((contribution (car remaining))
             (target (poo-flow-module-extension-contribution-target contribution))
             (operations
              (poo-flow-module-extension-contribution-operations contribution)))
        (if (poo-flow-module-extension-local-operations? operations)
          (if (and pending?
                   (equal? pending-target target))
            (loop (cdr remaining)
                  #t
                  pending-target
                  (poo-flow-module-extension-reverse-onto operations
                                                          pending-operations)
                  output)
            (loop (cdr remaining)
                  #t
                  target
                  (reverse operations)
                  (poo-flow-module-extension-flush-coalesced pending?
                                                             pending-target
                                                             pending-operations
                                                             output)))
          (loop (cdr remaining)
                #f
                #f
                '()
                (cons contribution
                      (poo-flow-module-extension-flush-coalesced
                       pending?
                       pending-target
                       pending-operations
                       output))))))))

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
  (cond ((null? contributions) node)
        (else
         (poo-flow-module-extension-apply-contributions/coalesced
          (poo-flow-module-extension-apply-contribution node (car contributions))
          (cdr contributions)))))

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
  (poo-flow-module-extension-fixed-point-step base contributions 0))
