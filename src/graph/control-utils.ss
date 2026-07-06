;;; -*- Gerbil -*-
;;; Boundary: pure helpers for graph control proof projections.
;;; Invariant: no runtime execution; helpers only shape graph facts.

(import :poo-flow/src/graph/types
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
  (cond
   ((null? metadata) default)
   ((eq? key (caar metadata)) (cdar metadata))
   (else (metadata-ref/default key (cdr metadata) default))))

;; : (-> PooFlowGraph [Symbol] [[Object Object]])
(def (edge-pairs-by-kinds graph-value edge-kinds)
  (reverse
   (edge-pairs-by-kinds/rev (poo-flow-graph-edges graph-value)
                            edge-kinds
                            '())))

;; : (-> [PooFlowGraphEdge] [Symbol] [[Object Object]] [[Object Object]])
(def (edge-pairs-by-kinds/rev edges edge-kinds pairs-rev)
  (cond
   ((null? edges) pairs-rev)
   ((symbol-member? (poo-flow-graph-edge-kind (car edges)) edge-kinds)
    (edge-pairs-by-kinds/rev
     (cdr edges)
     edge-kinds
     (cons (list (poo-flow-graph-edge-from (car edges))
                 (poo-flow-graph-edge-to (car edges)))
           pairs-rev)))
   (else
    (edge-pairs-by-kinds/rev (cdr edges) edge-kinds pairs-rev))))

;; : (-> PooFlowGraph [Symbol] [Object])
(def (edge-targets-by-kinds graph-value edge-kinds)
  (reverse
   (edge-targets-by-kinds/rev (poo-flow-graph-edges graph-value)
                              edge-kinds
                              '())))

;; : (-> [PooFlowGraphEdge] [Symbol] [Object] [Object])
(def (edge-targets-by-kinds/rev edges edge-kinds ids-rev)
  (cond
   ((null? edges) ids-rev)
   ((symbol-member? (poo-flow-graph-edge-kind (car edges)) edge-kinds)
    (edge-targets-by-kinds/rev
     (cdr edges)
     edge-kinds
     (cons (poo-flow-graph-edge-to (car edges)) ids-rev)))
   (else
    (edge-targets-by-kinds/rev (cdr edges) edge-kinds ids-rev))))

;; : (-> [PooFlowGraphEdge] [Object] [[Object Object]] [[Object Object]])
(def (undeclared-edge-pairs/rev edges node-ids pairs-rev)
  (cond
   ((null? edges) pairs-rev)
   ((and (id-member? (poo-flow-graph-edge-from (car edges)) node-ids)
         (id-member? (poo-flow-graph-edge-to (car edges)) node-ids))
    (undeclared-edge-pairs/rev (cdr edges) node-ids pairs-rev))
   (else
    (undeclared-edge-pairs/rev
     (cdr edges)
     node-ids
     (cons (list (poo-flow-graph-edge-from (car edges))
                 (poo-flow-graph-edge-to (car edges)))
           pairs-rev)))))

;; : (-> Predicate [Object] [Object])
(def (select-ids predicate ids)
  (cond
   ((null? ids) '())
   ((predicate (car ids))
    (cons (car ids)
          (select-ids predicate (cdr ids))))
   (else
    (select-ids predicate (cdr ids)))))

;; : (-> [Object] [Object] [Object])
(def (remove-ids ids-to-remove ids)
  (cond
   ((null? ids) '())
   ((id-member? (car ids) ids-to-remove)
    (remove-ids ids-to-remove (cdr ids)))
   (else
    (cons (car ids)
          (remove-ids ids-to-remove (cdr ids))))))

;; : (-> [Object] [Object] [Object])
(def (intersection-ids ids candidates)
  (cond
   ((null? ids) '())
   ((id-member? (car ids) candidates)
    (cons (car ids)
          (intersection-ids (cdr ids) candidates)))
   (else
    (intersection-ids (cdr ids) candidates))))

;; : (-> [Object] [Object] Boolean)
(def (ids-subset? subset ids)
  (cond
   ((null? subset) #t)
   ((id-member? (car subset) ids)
    (ids-subset? (cdr subset) ids))
   (else #f)))

;; : (-> Object [Object] Boolean)
(def (id-member? id ids)
  (cond
   ((null? ids) #f)
   ((equal? id (car ids)) #t)
   (else (id-member? id (cdr ids)))))

;; : (-> Symbol [Symbol] Boolean)
(def (symbol-member? id ids)
  (cond
   ((null? ids) #f)
   ((eq? id (car ids)) #t)
   (else (symbol-member? id (cdr ids)))))
