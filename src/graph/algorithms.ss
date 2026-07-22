;;; -*- Gerbil -*-
;;; Boundary: pure graph algorithms over composed POO graph facts.
;;; Invariant: algorithms emit analysis facts only; runtime execution is out.

(import :poo-flow/src/graph/types)

(export poo-flow-graph-node-ids
        poo-flow-graph-edge-pairs
        poo-flow-graph-outgoing-ids
        poo-flow-graph-incoming-ids
        poo-flow-graph-outgoing-map
        poo-flow-graph-incoming-map
        poo-flow-graph-root-ids
        poo-flow-graph-terminal-ids
        poo-flow-graph-reachable-ids
        poo-flow-graph-dependency-cone
        poo-flow-graph-cycle-path
        poo-flow-graph-acyclic?
        poo-flow-graph-topological-order
        poo-flow-graph-topological-order/acyclic
        poo-flow-graph-analysis-receipt
        poo-flow-graph-loop-analysis-receipt)

;; : (-> [PooFlowGraphNode] [Object] [Object])
(def (poo-flow-graph-node-ids/rev nodes ids-rev)
  (if (null? nodes)
    ids-rev
    (poo-flow-graph-node-ids/rev
     (cdr nodes)
     (cons (poo-flow-graph-node-id (car nodes)) ids-rev))))

;; : (-> PooFlowGraph [Object])
(def (poo-flow-graph-node-ids graph-value)
  (reverse
   (poo-flow-graph-node-ids/rev
    (poo-flow-graph-nodes graph-value)
    '())))

;; : (-> [PooFlowGraphEdge] [[Object Object]] [[Object Object]])
(def (poo-flow-graph-edge-pairs/rev edges pairs-rev)
  (if (null? edges)
    pairs-rev
    (poo-flow-graph-edge-pairs/rev
     (cdr edges)
     (cons (list (poo-flow-graph-edge-from (car edges))
                 (poo-flow-graph-edge-to (car edges)))
           pairs-rev))))

;; : (-> PooFlowGraph [[Object Object]])
(def (poo-flow-graph-edge-pairs graph-value)
  (reverse
   (poo-flow-graph-edge-pairs/rev
    (poo-flow-graph-edges graph-value)
    '())))

;; : (-> PooFlowGraph Object [Object])
(def (poo-flow-graph-outgoing-ids graph-value id)
  (edge-targets-from id (poo-flow-graph-edges graph-value)))

;; : (-> PooFlowGraph Object [Object])
(def (poo-flow-graph-incoming-ids graph-value id)
  (edge-sources-to id (poo-flow-graph-edges graph-value)))

;; : (-> PooFlowGraph Alist)
(def (poo-flow-graph-outgoing-map graph-value)
  (ids->outgoing-map graph-value
                     (poo-flow-graph-node-ids graph-value)))

;; : (-> PooFlowGraph Alist)
(def (poo-flow-graph-incoming-map graph-value)
  (ids->incoming-map graph-value
                     (poo-flow-graph-node-ids graph-value)))

;; : (-> PooFlowGraph [Object])
(def (poo-flow-graph-root-ids graph-value)
  (select-ids
   (lambda (id)
     (null? (poo-flow-graph-incoming-ids graph-value id)))
   (poo-flow-graph-node-ids graph-value)))

;; : (-> PooFlowGraph [Object])
(def (poo-flow-graph-terminal-ids graph-value)
  (select-ids
   (lambda (id)
     (null? (poo-flow-graph-outgoing-ids graph-value id)))
   (poo-flow-graph-node-ids graph-value)))

;; : (-> PooFlowGraph [Object] [Object])
(def (poo-flow-graph-reachable-ids graph-value start-ids)
  (reverse (walk-reachable graph-value start-ids '())))

;; : (-> PooFlowGraph [Object] [Object])
(def (poo-flow-graph-dependency-cone graph-value target-ids)
  (reverse (walk-dependency-cone graph-value target-ids '())))

;; : (-> PooFlowGraph MaybeList)
(def (cycle-dfs/indexed graph-value outgoing-index id stack states)
  (let ((state (hash-get states id)))
    (cond
     ((eq? state 'visiting)
      (cycle-path-from id stack))
     ((eq? state 'visited)
      #f)
     (else
      (hash-put! states id 'visiting)
        (let ((cycle
               (cycle-dfs-neighbors/indexed
                graph-value
                outgoing-index
                (or (hash-get outgoing-index id) '())
                (cons id stack)
                states)))
        (hash-put! states id 'visited)
        cycle)))))

(def (cycle-dfs-neighbors/indexed
      graph-value outgoing-index ids stack states)
  (cond
   ((null? ids) #f)
   (else
    (or (cycle-dfs/indexed graph-value
                           outgoing-index
                           (car ids)
                           stack
                           states)
        (cycle-dfs-neighbors/indexed graph-value
                                     outgoing-index
                                     (cdr ids)
                                     stack
                                     states)))))

(def (find-cycle-from-nodes/indexed graph-value outgoing-index ids states)
  (cond
   ((null? ids) #f)
   (else
    (or (cycle-dfs/indexed graph-value
                           outgoing-index
                           (car ids)
                           '()
                           states)
        (find-cycle-from-nodes/indexed graph-value
                                       outgoing-index
                                       (cdr ids)
                                       states)))))

(def (edge-pairs->outgoing-index edge-pairs outgoing-index)
  (if (null? edge-pairs)
    outgoing-index
    (let* ((edge-pair (car edge-pairs))
           (source (car edge-pair))
           (target (cadr edge-pair))
           (targets (hash-get outgoing-index source)))
      (hash-put! outgoing-index
                 source
                 (cons target (or targets '())))
      (edge-pairs->outgoing-index (cdr edge-pairs) outgoing-index))))

(def (poo-flow-graph-outgoing-index graph-value)
  (edge-pairs->outgoing-index
   (reverse (poo-flow-graph-edge-pairs graph-value))
   (make-hash-table)))

(def (strong-components-pop! root-id stack on-stack component)
  (let* ((members (vector-ref stack 0))
         (member (car members)))
    (vector-set! stack 0 (cdr members))
    (hash-put! on-stack member #f)
    (let ((component* (cons member component)))
      (if (equal? member root-id)
        component*
        (strong-components-pop! root-id
                                stack
                                on-stack
                                component*)))))

(def (strong-components-connect-neighbors!
      ids outgoing-index indices lowlinks on-stack
      stack next-index components id)
  (unless (null? ids)
    (let ((neighbor (car ids)))
      (cond
       ((not (hash-get indices neighbor))
        (strong-components-connect! neighbor
                                    outgoing-index
                                    indices
                                    lowlinks
                                    on-stack
                                    stack
                                    next-index
                                    components)
        (hash-put! lowlinks
                   id
                   (min (hash-get lowlinks id)
                        (hash-get lowlinks neighbor))))
       ((hash-get on-stack neighbor)
        (hash-put! lowlinks
                   id
                   (min (hash-get lowlinks id)
                        (hash-get indices neighbor)))))
      (strong-components-connect-neighbors!
       (cdr ids)
       outgoing-index
       indices
       lowlinks
       on-stack
       stack
       next-index
       components
       id))))

(def (strong-components-connect!
      id outgoing-index indices lowlinks on-stack
      stack next-index components)
  (let ((index (vector-ref next-index 0)))
    (vector-set! next-index 0 (+ index 1))
    (hash-put! indices id index)
    (hash-put! lowlinks id index)
    (hash-put! on-stack id #t)
    (vector-set! stack 0 (cons id (vector-ref stack 0)))
    (strong-components-connect-neighbors!
     (or (hash-get outgoing-index id) '())
     outgoing-index
     indices
     lowlinks
     on-stack
     stack
     next-index
     components
     id)
    (when (= (hash-get lowlinks id) (hash-get indices id))
      (let ((component
             (strong-components-pop! id stack on-stack '())))
        (vector-set! components
                     0
                     (cons component (vector-ref components 0)))))))

(def (strong-components-walk-nodes!
      ids outgoing-index indices lowlinks on-stack
      stack next-index components)
  (unless (null? ids)
    (unless (hash-get indices (car ids))
      (strong-components-connect! (car ids)
                                  outgoing-index
                                  indices
                                  lowlinks
                                  on-stack
                                  stack
                                  next-index
                                  components))
    (strong-components-walk-nodes! (cdr ids)
                                   outgoing-index
                                   indices
                                   lowlinks
                                   on-stack
                                   stack
                                   next-index
                                   components)))

(def (graph-strong-components/indexed graph-value outgoing-index)
  (let ((indices (make-hash-table))
        (lowlinks (make-hash-table))
        (on-stack (make-hash-table))
        (stack (vector '()))
        (next-index (vector 0))
        (components (vector '())))
    (strong-components-walk-nodes!
     (poo-flow-graph-node-ids graph-value)
     outgoing-index
     indices
     lowlinks
     on-stack
     stack
     next-index
     components)
    (reverse (vector-ref components 0))))

(def (graph-strong-components/internal graph-value)
  (graph-strong-components/indexed
   graph-value
   (poo-flow-graph-outgoing-index graph-value)))

(def (poo-flow-graph-cycle-path graph-value)
  (find-cycle-from-nodes/indexed
   graph-value
   (poo-flow-graph-outgoing-index graph-value)
   (poo-flow-graph-node-ids graph-value)
   (make-hash-table)))

;; : (-> PooFlowGraph Boolean)
(def (poo-flow-graph-acyclic? graph-value)
  (not (poo-flow-graph-cycle-path graph-value)))

;; : (-> PooFlowGraph MaybeList)
(def (poo-flow-graph-topological-order graph-value)
  (let ((cycle-path (poo-flow-graph-cycle-path graph-value)))
    (if cycle-path
      #f
      (poo-flow-graph-topological-order/acyclic graph-value))))

;; : (-> PooFlowGraph MaybeList)
(def (poo-flow-graph-topological-order/acyclic graph-value)
  ;; Caller already established that no cycle path exists.
  (topological-walk (poo-flow-graph-node-ids graph-value)
                    (poo-flow-graph-edges graph-value)
                    '()))

;; : (-> [Object] [Object] [Object])
(def (poo-flow-graph-analysis-start-ids roots maybe-start+target)
  (if (null? maybe-start+target)
    roots
    (car maybe-start+target)))

;; : (-> [Object] [Object] [Object])
(def (poo-flow-graph-analysis-target-ids terminals maybe-start+target)
  (if (or (null? maybe-start+target)
          (null? (cdr maybe-start+target)))
    terminals
    (cadr maybe-start+target)))

;; : (-> PooFlowGraph MaybeList MaybeList)
(def (poo-flow-graph-analysis-topological-order* graph-value cycle-path)
  (if cycle-path
    #f
    (poo-flow-graph-topological-order/acyclic graph-value)))

;; : (-> MaybeList Alist)
(def (poo-flow-graph-analysis-diagnostics cycle-path)
  (if cycle-path
    (list (cons 'cycle-path cycle-path))
    '()))

;; : (-> PooFlowGraph PooFlowGraphAnalysis)
(def (poo-flow-graph-analysis-receipt graph-value . maybe-start+target)
  (let* ((roots (poo-flow-graph-root-ids graph-value))
         (terminals (poo-flow-graph-terminal-ids graph-value))
         (start-ids
          (poo-flow-graph-analysis-start-ids roots maybe-start+target))
         (target-ids
          (poo-flow-graph-analysis-target-ids terminals maybe-start+target))
         (cycle-path (poo-flow-graph-cycle-path graph-value))
         (topological-order
          (poo-flow-graph-analysis-topological-order* graph-value
                                                      cycle-path))
         (diagnostics
          (poo-flow-graph-analysis-diagnostics cycle-path)))
    (poo-flow-graph-analysis
     (poo-flow-graph-id graph-value)
     (length (poo-flow-graph-nodes graph-value))
     (length (poo-flow-graph-edges graph-value))
     roots
     terminals
     (poo-flow-graph-reachable-ids graph-value start-ids)
     (poo-flow-graph-dependency-cone graph-value target-ids)
     topological-order
     cycle-path
     diagnostics)))

;; : (-> PooFlowGraph PooFlowGraphLoopAnalysis)
(def (poo-flow-graph-loop-analysis-receipt graph-value)
  (let* ((outgoing-index (poo-flow-graph-outgoing-index graph-value))
         (node-ids (poo-flow-graph-node-ids graph-value))
         (components
          (ordered-components-from-nodes
           node-ids
           (graph-strong-components/indexed graph-value outgoing-index)))
         (cyclic-components
          (select-cyclic-components components outgoing-index))
         (component-index
          (components->component-index components (make-hash-table) 0))
         (condensation-edges
          (graph-condensation-edges
           (poo-flow-graph-edge-pairs graph-value)
           component-index))
         (diagnostics
          (poo-flow-graph-loop-analysis-diagnostics cyclic-components)))
    (poo-flow-graph-loop-analysis
     (poo-flow-graph-id graph-value)
     components
     cyclic-components
     condensation-edges
     diagnostics)))

(def (poo-flow-graph-loop-analysis-diagnostics cyclic-components)
  (if (null? cyclic-components)
    '()
    (list (cons 'cyclic-components cyclic-components))))

(def (ordered-components-from-nodes node-ids components)
  (cond
   ((null? node-ids) '())
   (else
    (let ((component (component-containing (car node-ids) components)))
      (if component
        (cons (order-component-members component node-ids)
              (ordered-components-from-nodes
               (cdr node-ids)
               (remove-component component components)))
        (ordered-components-from-nodes (cdr node-ids) components))))))

(def (component-containing id components)
  (cond
   ((null? components) #f)
   ((id-member? id (car components)) (car components))
   (else (component-containing id (cdr components)))))

(def (remove-component component components)
  (cond
   ((null? components) '())
   ((equal? component (car components))
    (remove-component component (cdr components)))
   (else
    (cons (car components)
          (remove-component component (cdr components))))))

(def (order-component-members component node-ids)
  (cond
   ((null? node-ids) '())
   ((id-member? (car node-ids) component)
    (cons (car node-ids)
          (order-component-members component (cdr node-ids))))
   (else
    (order-component-members component (cdr node-ids)))))

(def (select-cyclic-components components outgoing-index)
  (cond
   ((null? components) '())
   ((component-cyclic? (car components) outgoing-index)
    (cons (car components)
          (select-cyclic-components (cdr components) outgoing-index)))
   (else
    (select-cyclic-components (cdr components) outgoing-index))))

(def (component-cyclic? component outgoing-index)
  (or (not (null? (cdr component)))
      (id-member? (car component)
                  (or (hash-get outgoing-index (car component)) '()))))

(def (components->component-index components component-index next-id)
  (if (null? components)
    component-index
    (begin
      (component-index-put-members! (car components)
                                    component-index
                                    next-id)
      (components->component-index (cdr components)
                                   component-index
                                   (+ next-id 1)))))

(def (component-index-put-members! members component-index component-id)
  (unless (null? members)
    (hash-put! component-index (car members) component-id)
    (component-index-put-members! (cdr members)
                                  component-index
                                  component-id)))

(def (graph-condensation-edges edge-pairs component-index)
  (reverse
   (graph-condensation-edges/rev edge-pairs component-index '() '())))

(def (graph-condensation-edges/rev edge-pairs component-index seen edges-rev)
  (cond
   ((null? edge-pairs) edges-rev)
   (else
    (let* ((edge-pair (car edge-pairs))
           (source-component (hash-get component-index (car edge-pair)))
           (target-component (hash-get component-index (cadr edge-pair)))
           (component-edge (list source-component target-component)))
      (if (or (= source-component target-component)
              (id-member? component-edge seen))
        (graph-condensation-edges/rev (cdr edge-pairs)
                                      component-index
                                      seen
                                      edges-rev)
        (graph-condensation-edges/rev (cdr edge-pairs)
                                      component-index
                                      (cons component-edge seen)
                                      (cons component-edge edges-rev)))))))

;; : (-> Object [PooFlowGraphEdge] [Object])
(def (edge-targets-from id edges)
  (cond
   ((null? edges) '())
   ((equal? id (poo-flow-graph-edge-from (car edges)))
    (cons (poo-flow-graph-edge-to (car edges))
          (edge-targets-from id (cdr edges))))
   (else
    (edge-targets-from id (cdr edges)))))

;; : (-> Object [PooFlowGraphEdge] [Object])
(def (edge-sources-to id edges)
  (cond
   ((null? edges) '())
   ((equal? id (poo-flow-graph-edge-to (car edges)))
    (cons (poo-flow-graph-edge-from (car edges))
          (edge-sources-to id (cdr edges))))
   (else
    (edge-sources-to id (cdr edges)))))

;; : (-> PooFlowGraph [Object] Alist)
(def (ids->outgoing-map graph-value ids)
  (cond
   ((null? ids) '())
   (else
    (cons (cons (car ids)
                (poo-flow-graph-outgoing-ids graph-value (car ids)))
          (ids->outgoing-map graph-value (cdr ids))))))

;; : (-> PooFlowGraph [Object] Alist)
(def (ids->incoming-map graph-value ids)
  (cond
   ((null? ids) '())
   (else
    (cons (cons (car ids)
                (poo-flow-graph-incoming-ids graph-value (car ids)))
          (ids->incoming-map graph-value (cdr ids))))))

;; : (-> Predicate [Object] [Object])
(def (select-ids predicate ids)
  (cond
   ((null? ids) '())
   ((predicate (car ids))
    (cons (car ids)
          (select-ids predicate (cdr ids))))
   (else
    (select-ids predicate (cdr ids)))))

;; : (-> PooFlowGraph [Object] [Object] [Object])
(def (walk-reachable graph-value pending visited)
  (cond
   ((null? pending) visited)
   ((id-member? (car pending) visited)
    (walk-reachable graph-value (cdr pending) visited))
   (else
    (walk-reachable graph-value
                    (append (cdr pending)
                            (poo-flow-graph-outgoing-ids graph-value
                                                         (car pending)))
                    (cons (car pending) visited)))))

;; : (-> PooFlowGraph [Object] [Object] [Object])
(def (walk-dependency-cone graph-value pending visited)
  (cond
   ((null? pending) visited)
   ((id-member? (car pending) visited)
    (walk-dependency-cone graph-value (cdr pending) visited))
   (else
    (walk-dependency-cone graph-value
                          (append (cdr pending)
                                  (poo-flow-graph-incoming-ids graph-value
                                                               (car pending)))
                          (cons (car pending) visited)))))

;; : (-> PooFlowGraph [Object] [Object] MaybeList)
(def (find-cycle-from-nodes graph-value ids visited)
  (cond
   ((null? ids) #f)
   ((id-member? (car ids) visited)
    (find-cycle-from-nodes graph-value (cdr ids) visited))
   (else
    (let* ((result (cycle-dfs graph-value (car ids) '() visited))
           (cycle-path (car result))
           (visited* (cadr result)))
      (if cycle-path
        cycle-path
        (find-cycle-from-nodes graph-value (cdr ids) visited*))))))

;; : (-> PooFlowGraph Object [Object] [Object] [MaybeList [Object]])
(def (cycle-dfs graph-value id stack visited)
  (cond
   ((id-member? id stack)
    (list (cycle-path-from id stack) visited))
   ((id-member? id visited)
    (list #f visited))
   (else
    (cycle-dfs-neighbors graph-value
                         (poo-flow-graph-outgoing-ids graph-value id)
                         (cons id stack)
                         (cons id visited)))))

;; : (-> PooFlowGraph [Object] [Object] [Object] [MaybeList [Object]])
(def (cycle-dfs-neighbors graph-value neighbors stack visited)
  (cond
   ((null? neighbors) (list #f visited))
   (else
    (let* ((result (cycle-dfs graph-value
                              (car neighbors)
                              stack
                              visited))
           (cycle-path (car result))
           (visited* (cadr result)))
      (if cycle-path
        (list cycle-path visited*)
        (cycle-dfs-neighbors graph-value
                             (cdr neighbors)
                             stack
                             visited*))))))

;; : (-> Object [Object] [Object])
(def (cycle-path-from id stack)
  (call/cc
   (lambda (return)
     (foldl
      (lambda (node path-tail)
        (if (equal? id node)
          (return (cons id (cycle-path-close path-tail id)))
          (cons node path-tail)))
      '()
      stack)
     (list id))))

;; : (-> [Object] Object [Object])
(def (cycle-path-close path-tail id)
  (cond
   ((null? path-tail) (list id))
   (else
    (cons (car path-tail)
          (cycle-path-close (cdr path-tail) id)))))

;; : (-> [Object] [PooFlowGraphEdge] [Object] [Object])
(def (topological-walk remaining-ids remaining-edges order)
  (cond
   ((null? remaining-ids) order)
   (else
    (let ((ready-ids (ids-without-incoming remaining-ids
                                           remaining-edges)))
      (if (null? ready-ids)
        #f
        (topological-walk (remove-ids ready-ids remaining-ids)
                          (remove-edges-from ready-ids remaining-edges)
                          (append order ready-ids)))))))

;; : (-> [Object] [PooFlowGraphEdge] [Object])
(def (ids-without-incoming ids edges)
  (select-ids
   (lambda (id)
     (not (edge-target-member? id edges)))
   ids))

;; : (-> [Object] [Object] [Object])
(def (remove-ids ids-to-remove ids)
  (cond
   ((null? ids) '())
   ((id-member? (car ids) ids-to-remove)
    (remove-ids ids-to-remove (cdr ids)))
   (else
    (cons (car ids)
          (remove-ids ids-to-remove (cdr ids))))))

;; : (-> [Object] [PooFlowGraphEdge] [PooFlowGraphEdge])
(def (remove-edges-from source-ids edges)
  (cond
   ((null? edges) '())
   ((id-member? (poo-flow-graph-edge-from (car edges)) source-ids)
    (remove-edges-from source-ids (cdr edges)))
   (else
    (cons (car edges)
          (remove-edges-from source-ids (cdr edges))))))

;; : (-> Object [PooFlowGraphEdge] Boolean)
(def (edge-target-member? id edges)
  (cond
   ((null? edges) #f)
   ((equal? id (poo-flow-graph-edge-to (car edges))) #t)
   (else (edge-target-member? id (cdr edges)))))

;; : (-> Object [Object] Boolean)
(def (id-member? id ids)
  (cond
   ((null? ids) #f)
   ((equal? id (car ids)) #t)
   (else (id-member? id (cdr ids)))))
