;;; -*- Gerbil -*-
;;; Boundary: pure helpers for graph control proof projections.
;;; Invariant: no runtime execution; helpers only shape graph facts.

(import (only-in :std/srfi/1 any every filter fold)
        :poo-flow/src/graph/types
        :poo-flow/src/graph/algorithms)

(export +poo-flow-graph-conditional-edge-kinds+
        +poo-flow-graph-loop-edge-kinds+
        control-row
        control-row-if
        graph-entry-ids
        graph-finish-ids
        graph-dead-end-ids
        control-finish-total?
        control-diagnostic-rows
        graph-metadata-ref/default
        metadata-ref/default
        edge-pairs-by-kinds
        edge-targets-by-kinds
        undeclared-edge-pairs/rev
        remove-ids
        intersection-ids
        ids-subset?)

;; : [Symbol]
(def +poo-flow-graph-conditional-edge-kinds+
  '(conditional branch router))

;; : [Symbol]
(def +poo-flow-graph-loop-edge-kinds+
  '(loop back-edge retry self-loop))

;; : (-> Symbol Object Pair)
(def (control-row key value)
  (cons key value))

;; : (-> Boolean Symbol Object Alist Alist)
(def (control-row-if condition key value rows)
  (if condition
    (cons (cons key value) rows)
    rows))

;; : (-> PooFlowGraph [Object] [Object])
(def (graph-entry-ids graph-value root-ids)
  (let ((explicit-ids (graph-metadata-ref/default graph-value
                                                  'entry-ids
                                                  #f)))
    (if explicit-ids
      explicit-ids
      (let ((explicit-id (graph-metadata-ref/default graph-value
                                                     'entry-id
                                                     #f)))
        (if explicit-id
          (list explicit-id)
          root-ids)))))

;; : (-> PooFlowGraph [Object] [Object])
(def (graph-finish-ids graph-value terminal-ids)
  (let ((explicit-ids (graph-metadata-ref/default graph-value
                                                  'finish-ids
                                                  #f)))
    (if explicit-ids
      explicit-ids
      (let ((explicit-id (graph-metadata-ref/default graph-value
                                                     'finish-id
                                                     #f)))
        (if explicit-id
          (list explicit-id)
          terminal-ids)))))

;; : (-> PooFlowGraph [Object] [Object] [Object])
(def (graph-dead-end-ids graph-value reachable-ids finish-ids)
  (select-ids
   (lambda (id)
     (and (not (id-member? id finish-ids))
          (null? (poo-flow-graph-outgoing-ids graph-value id))))
   reachable-ids))

;; : (-> [Object] [Object] [Object] [Object] [Object] [[Object Object]] [Object] Boolean)
(def (control-finish-total? node-ids
                            entry-ids
                            finish-ids
                            reachable-ids
                            finish-reachable-ids
                            undeclared-edge-pairs
                            dead-end-ids)
  (and (not (null? entry-ids))
       (not (null? finish-ids))
       (ids-subset? entry-ids node-ids)
       (ids-subset? finish-ids node-ids)
       (null? undeclared-edge-pairs)
       (null? dead-end-ids)
       (ids-subset? reachable-ids finish-reachable-ids)))

;; : (-> [Object] [Object] [Object] [[Object Object]] [Object] [Object] [Object] [Object] MaybeList Alist)
(def (control-diagnostic-rows node-ids
                              entry-ids
                              finish-ids
                              undeclared-edge-pairs
                              branch-target-ids
                              unreachable-ids
                              dead-end-ids
                              finish-unreachable-ids
                              unexpected-cycle-path)
  (reverse
   (let* ((rows '())
          (rows (control-row-if (null? entry-ids)
                                'missing-entry #t rows))
          (rows (control-row-if (null? finish-ids)
                                'missing-finish #t rows))
          (rows (control-row-if (not (ids-subset? entry-ids node-ids))
                                'undeclared-entry-ids
                                (remove-ids node-ids entry-ids)
                                rows))
          (rows (control-row-if (not (ids-subset? finish-ids node-ids))
                                'undeclared-finish-ids
                                (remove-ids node-ids finish-ids)
                                rows))
          (rows (control-row-if (not (null? undeclared-edge-pairs))
                                'undeclared-edge-pairs
                                undeclared-edge-pairs
                                rows))
          (rows (control-row-if (not (ids-subset? branch-target-ids node-ids))
                                'undeclared-branch-targets
                                (remove-ids node-ids branch-target-ids)
                                rows))
          (rows (control-row-if (not (null? unreachable-ids))
                                'unreachable-ids
                                unreachable-ids
                                rows))
          (rows (control-row-if (not (null? dead-end-ids))
                                'dead-end-ids
                                dead-end-ids
                                rows))
          (rows (control-row-if (not (null? finish-unreachable-ids))
                                'finish-unreachable-ids
                                finish-unreachable-ids
                                rows))
          (rows (control-row-if unexpected-cycle-path
                                'unexpected-cycle-path
                                unexpected-cycle-path
                                rows)))
     rows)))

;; : (-> PooFlowGraph Symbol Object)
(def (graph-metadata-ref/default graph-value key default)
  (metadata-ref/default key
                        (poo-flow-graph-metadata graph-value)
                        default))

;; : (-> Symbol Alist Object Object)
(def (metadata-ref/default key metadata default)
  (let (entry (assoc key metadata))
    (if entry
      (cdr entry)
      default)))

;; : (-> PooFlowGraph [Symbol] [[Object Object]])
(def (edge-pairs-by-kinds graph-value edge-kinds)
  (reverse
   (edge-pairs-by-kinds/rev (poo-flow-graph-edges graph-value)
                            edge-kinds
                            '())))

;; : (-> [PooFlowGraphEdge] [Symbol] [[Object Object]] [[Object Object]])
(def (edge-pairs-by-kinds/rev edges edge-kinds pairs-rev)
  (fold
   (lambda (edge pairs)
     (if (symbol-member? (poo-flow-graph-edge-kind edge) edge-kinds)
       (cons (list (poo-flow-graph-edge-from edge)
                   (poo-flow-graph-edge-to edge))
             pairs)
       pairs))
   pairs-rev
   edges))

;; : (-> PooFlowGraph [Symbol] [Object])
(def (edge-targets-by-kinds graph-value edge-kinds)
  (reverse
   (edge-targets-by-kinds/rev (poo-flow-graph-edges graph-value)
                              edge-kinds
                              '())))

;; : (-> [PooFlowGraphEdge] [Symbol] [Object] [Object])
(def (edge-targets-by-kinds/rev edges edge-kinds ids-rev)
  (fold
   (lambda (edge ids)
     (if (symbol-member? (poo-flow-graph-edge-kind edge) edge-kinds)
       (cons (poo-flow-graph-edge-to edge) ids)
       ids))
   ids-rev
   edges))

;; : (-> [PooFlowGraphEdge] [Object] [[Object Object]] [[Object Object]])
(def (undeclared-edge-pairs/rev edges node-ids pairs-rev)
  (fold
   (lambda (edge pairs)
     (if (and (id-member? (poo-flow-graph-edge-from edge) node-ids)
              (id-member? (poo-flow-graph-edge-to edge) node-ids))
       pairs
       (cons (list (poo-flow-graph-edge-from edge)
                   (poo-flow-graph-edge-to edge))
             pairs)))
   pairs-rev
   edges))

;; : (-> Predicate [Object] [Object])
(def (select-ids predicate ids)
  (filter predicate ids))

;; : (-> [Object] [Object] [Object])
(def (remove-ids ids-to-remove ids)
  (filter
   (lambda (id)
     (not (id-member? id ids-to-remove)))
   ids))

;; : (-> [Object] [Object] [Object])
(def (intersection-ids ids candidates)
  (filter
   (lambda (id)
     (id-member? id candidates))
   ids))

;; : (-> [Object] [Object] Boolean)
(def (ids-subset? subset ids)
  (if (every (lambda (id) (id-member? id ids)) subset) #t #f))

;; : (-> Object [Object] Boolean)
(def (id-member? id ids)
  (if (any (lambda (candidate) (equal? id candidate)) ids) #t #f))

;; : (-> Symbol [Symbol] Boolean)
(def (symbol-member? id ids)
  (if (any (lambda (candidate) (eq? id candidate)) ids) #t #f))
