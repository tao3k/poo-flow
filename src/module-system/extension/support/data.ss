;;; -*- Gerbil -*-
;;; Boundary: extension graph records, list helpers, and child lookup.

(import (only-in :clan/poo/object
                 .o
                 .ref
                 object?)
        (only-in :std/sugar filter filter-map))

(export poo-flow-module-extension-node-kind
        poo-flow-module-extension-operation-kind
        poo-flow-module-extension-contribution-kind
        poo-flow-module-extension-result-kind
        poo-flow-module-extension-kind?
        poo-flow-module-extension-node
        poo-flow-module-extension-node?
        poo-flow-module-extension-node-identity
        poo-flow-module-extension-node-slots
        poo-flow-module-extension-node-children
        poo-flow-module-extension-operation
        poo-flow-module-extension-operation-action
        poo-flow-module-extension-operation-slot
        poo-flow-module-extension-operation-value
        poo-flow-module-extension-operation-node
        poo-flow-module-extension-operation-target
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
        poo-flow-module-extension-result
        poo-flow-module-extension-result?
        poo-flow-module-extension-result-root
        poo-flow-module-extension-result-iterations
        poo-flow-module-extension-result-stable?
        poo-flow-module-extension-member?
        poo-flow-module-extension-value-index
        poo-flow-module-extension-append-distinct
        poo-flow-module-extension-append-distinct/indexed
        poo-flow-module-extension-remove-elements
        poo-flow-module-extension-list-value
        poo-flow-module-extension-entry-key
        poo-flow-module-extension-entry-value
        poo-flow-module-extension-entry
        poo-flow-module-extension-alist-set
        poo-flow-module-extension-alist-ref/default
        poo-flow-module-extension-replace-node
        poo-flow-module-extension-child-ref)


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

;;; Boundary: module extension value index is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
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

;;; Boundary: module extension append distinct indexed is the policy-visible
;;; edge for module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [PooModuleSlotValue] HashTable [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-extension-append-distinct-added/rev
      extra
      seen
      added-rev)
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
(def (poo-flow-module-extension-append-distinct/indexed base extra seen)
  (let (added
        (poo-flow-module-extension-append-distinct-added/rev
         extra
         seen
         '()))
    (if (null? added)
      base
      (append base (reverse added)))))

;;; Remove is value-based rather than positional so downstream patches can
;;; delete inherited list elements without knowing the upstream list index.
;; : (-> [PooModuleSlotValue] HashTable [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-extension-remove-elements/rev values removed-index kept-rev)
  (cond
   ((null? values) kept-rev)
   ((hash-get removed-index (car values))
    (poo-flow-module-extension-remove-elements/rev
     (cdr values)
     removed-index
     kept-rev))
   (else
    (poo-flow-module-extension-remove-elements/rev
     (cdr values)
     removed-index
     (cons (car values) kept-rev)))))

;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-extension-remove-elements values removed)
  (if (null? removed)
    values
    (let (removed-index (poo-flow-module-extension-value-index removed))
      (filter (lambda (value)
                (not (hash-get removed-index value)))
              values))))

;;; Boundary: module extension list value is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
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

;;; Boundary: module extension alist set is the policy-visible edge for module-
;;; system behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> PooModuleSlotMap Symbol PooModuleSlotValue PooModuleSlotMap)
(def (poo-flow-module-extension-alist-set entries key value)
  (cond ((null? entries)
         (list (poo-flow-module-extension-entry key value)))
        ((equal? (poo-flow-module-extension-entry-key (car entries)) key)
         (cons (poo-flow-module-extension-entry key value)
               (cdr entries)))
        (else (cons (car entries)
                    (poo-flow-module-extension-alist-set (cdr entries) key value)))))

;;; Boundary: module extension alist ref default is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
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

;;; Boundary: module extension child ref is the policy-visible edge for module-
;;; system behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
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
