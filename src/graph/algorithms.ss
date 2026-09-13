;;; -*- Gerbil -*-

;;; Boundary: pure graph algorithms over composed POO graph facts.
;;; Invariant: algorithms emit analysis facts only; runtime execution is out.

(import (only-in :std/misc/hash hash-ensure-modify!)
        (only-in :std/misc/queue
                 dequeue!
                 enqueue!
                 make-queue
                 queue-empty?)
        (only-in :std/srfi/1 filter)
        :poo-flow/src/graph/types-core)

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

(import :poo-flow/src/graph/algorithms-list-support)

(def (graph-adjacency-ref index id)
  (or (hash-get index id) '()))

(def (ids->adjacency-map ids index)
  (map (lambda (id)
         (cons id (graph-adjacency-ref index id)))
       ids))

(def (poo-flow-graph-outgoing-ids graph-value id)
  (graph-adjacency-ref (poo-flow-graph-outgoing-index graph-value) id))

;; : (-> PooFlowGraph Object [Object])
(def (poo-flow-graph-incoming-ids graph-value id)
  (graph-adjacency-ref (poo-flow-graph-incoming-index graph-value) id))

;; : (-> PooFlowGraph Alist)
(def (poo-flow-graph-outgoing-map graph-value)
  (ids->adjacency-map
   (poo-flow-graph-node-ids graph-value)
   (poo-flow-graph-outgoing-index graph-value)))

;; : (-> PooFlowGraph Alist)
(def (poo-flow-graph-incoming-map graph-value)
  (ids->adjacency-map
   (poo-flow-graph-node-ids graph-value)
   (poo-flow-graph-incoming-index graph-value)))

;; : (-> PooFlowGraph [Object])
(def (poo-flow-graph-root-ids graph-value)
  (let (incoming-index (poo-flow-graph-incoming-index graph-value))
    (filter
     (lambda (id)
       (null? (graph-adjacency-ref incoming-index id)))
     (poo-flow-graph-node-ids graph-value))))

;; : (-> PooFlowGraph [Object])
(def (poo-flow-graph-terminal-ids graph-value)
  (let (outgoing-index (poo-flow-graph-outgoing-index graph-value))
    (filter
     (lambda (id)
       (null? (graph-adjacency-ref outgoing-index id)))
     (poo-flow-graph-node-ids graph-value))))

;; : (-> PooFlowGraph [Object] [Object])
(def (poo-flow-graph-reachable-ids graph-value start-ids)
  (walk-adjacency/indexed
   (poo-flow-graph-outgoing-index graph-value)
   start-ids))

;; : (-> PooFlowGraph [Object] [Object])
(def (poo-flow-graph-dependency-cone graph-value target-ids)
  (walk-adjacency/indexed
   (poo-flow-graph-incoming-index graph-value)
   target-ids))

;; : (-> PooFlowGraph MaybeList)
(def (cycle-dfs/indexed outgoing-index id stack states)
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
                outgoing-index
                (or (hash-get outgoing-index id) '())
                (cons id stack)
                states)))
        (hash-put! states id 'visited)
        cycle)))))

(def (cycle-dfs-neighbors/indexed outgoing-index ids stack states)
  (cond
   ((null? ids) #f)
   (else
    (or (cycle-dfs/indexed outgoing-index
                           (car ids)
                           stack
                           states)
        (cycle-dfs-neighbors/indexed outgoing-index
                                     (cdr ids)
                                     stack
                                     states)))))

(def (find-cycle-from-nodes/indexed outgoing-index ids states)
  (cond
   ((null? ids) #f)
   (else
    (or (cycle-dfs/indexed outgoing-index
                           (car ids)
                           '()
                           states)
        (find-cycle-from-nodes/indexed outgoing-index
                                       (cdr ids)
                                       states)))))

(def (edge-pairs->outgoing-index edge-pairs outgoing-index)
  (if (null? edge-pairs)
    outgoing-index
    (let* ((edge-pair (car edge-pairs))
           (source (car edge-pair))
           (target (cadr edge-pair)))
      (hash-ensure-modify! outgoing-index
                           source
                           (lambda () '())
                           (lambda (targets) (cons target targets)))
      (edge-pairs->outgoing-index (cdr edge-pairs) outgoing-index))))

(def (poo-flow-graph-outgoing-index graph-value)
  (edge-pairs->outgoing-index
   (reverse (poo-flow-graph-edge-pairs graph-value))
   (make-hash-table)))

(def (edge-pairs->incoming-index edge-pairs incoming-index)
  (if (null? edge-pairs)
    incoming-index
    (let* ((edge-pair (car edge-pairs))
           (source (car edge-pair))
           (target (cadr edge-pair)))
      (hash-ensure-modify! incoming-index
                           target
                           (lambda () '())
                           (lambda (sources) (cons source sources)))
      (edge-pairs->incoming-index (cdr edge-pairs) incoming-index))))

(def (poo-flow-graph-incoming-index graph-value)
  (edge-pairs->incoming-index
   (reverse (poo-flow-graph-edge-pairs graph-value))
   (make-hash-table)))

(def (graph-adjacency-indexes edge-pairs)
  (let ((outgoing-index (make-hash-table))
        (incoming-index (make-hash-table)))
    (for-each
     (lambda (edge-pair)
       (let ((source (car edge-pair))
             (target (cadr edge-pair)))
         (hash-ensure-modify! outgoing-index
                              source
                              (lambda () '())
                              (lambda (targets) (cons target targets)))
         (hash-ensure-modify! incoming-index
                              target
                              (lambda () '())
                              (lambda (sources) (cons source sources)))))
     (reverse edge-pairs))
    (values outgoing-index incoming-index)))

(def (walk-adjacency/indexed adjacency-index start-ids)
  (let ((visited (make-hash-table))
        (pending (make-queue)))
    (for-each (lambda (id) (enqueue! pending id)) start-ids)
    (let loop ((result-rev '()))
      (if (queue-empty? pending)
        (reverse result-rev)
        (let (id (dequeue! pending))
          (if (hash-key? visited id)
            (loop result-rev)
            (begin
              (hash-put! visited id #t)
              (for-each
               (lambda (neighbor) (enqueue! pending neighbor))
               (graph-adjacency-ref adjacency-index id))
              (loop (cons id result-rev)))))))))

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

(def (graph-strong-components/indexed node-ids outgoing-index)
  (let ((indices (make-hash-table))
        (lowlinks (make-hash-table))
        (on-stack (make-hash-table))
        (stack (vector '()))
        (next-index (vector 0))
        (components (vector '())))
    (strong-components-walk-nodes!
     node-ids
     outgoing-index
     indices
     lowlinks
     on-stack
     stack
     next-index
     components)
    (reverse (vector-ref components 0))))

(def (poo-flow-graph-cycle-path graph-value)
  (find-cycle-from-nodes/indexed
   (poo-flow-graph-outgoing-index graph-value)
   (poo-flow-graph-node-ids graph-value)
   (make-hash-table)))

;; : (-> PooFlowGraph Boolean)
(def (poo-flow-graph-acyclic? graph-value)
  (not (poo-flow-graph-cycle-path graph-value)))

;; : (-> PooFlowGraph MaybeList)
(def (poo-flow-graph-topological-order graph-value)
  (poo-flow-graph-topological-order/acyclic graph-value))

;; : (-> PooFlowGraph MaybeList)
(def (poo-flow-graph-topological-order/acyclic graph-value)
  (let* ((node-ids (poo-flow-graph-node-ids graph-value))
         (edge-pairs (poo-flow-graph-edge-pairs graph-value))
         (outgoing-index (poo-flow-graph-outgoing-index graph-value)))
    (topological-order/indexed node-ids edge-pairs outgoing-index)))

;; : (-> [Object] [Object] [Object])
(def (poo-flow-graph-analysis-start-ids roots maybe-start+target)
  (if (or (null? maybe-start+target)
          (not (car maybe-start+target)))
    roots
    (car maybe-start+target)))

;; : (-> [Object] [Object] [Object])
(def (poo-flow-graph-analysis-target-ids terminals maybe-start+target)
  (if (or (null? maybe-start+target)
          (null? (cdr maybe-start+target))
          (not (cadr maybe-start+target)))
    terminals
    (cadr maybe-start+target)))

;; : (-> PooFlowGraph MaybeList MaybeList)
(def (poo-flow-graph-analysis-topological-order*
      node-ids edge-pairs outgoing-index cycle-path)
  (if cycle-path
    #f
    (topological-order/indexed node-ids edge-pairs outgoing-index)))

;; : (-> MaybeList Alist)
(def (poo-flow-graph-analysis-diagnostics cycle-path)
  (if cycle-path
    (list (cons 'cycle-path cycle-path))
    '()))

;; : (-> PooFlowGraph PooFlowGraphAnalysis)
(def (poo-flow-graph-analysis-receipt graph-value . maybe-start+target)
  (let* ((node-ids (poo-flow-graph-node-ids graph-value))
         (edge-pairs (poo-flow-graph-edge-pairs graph-value)))
    (let-values (((outgoing-index incoming-index)
                  (graph-adjacency-indexes edge-pairs)))
      (let* ((roots
              (filter
               (lambda (id)
                 (null? (graph-adjacency-ref incoming-index id)))
               node-ids))
             (terminals
              (filter
               (lambda (id)
                 (null? (graph-adjacency-ref outgoing-index id)))
               node-ids))
             (start-ids
              (poo-flow-graph-analysis-start-ids roots maybe-start+target))
             (target-ids
              (poo-flow-graph-analysis-target-ids terminals maybe-start+target))
             (cycle-path
              (find-cycle-from-nodes/indexed
               outgoing-index node-ids (make-hash-table)))
             (topological-order
              (poo-flow-graph-analysis-topological-order*
               node-ids edge-pairs outgoing-index cycle-path))
             (diagnostics
              (poo-flow-graph-analysis-diagnostics cycle-path)))
        (poo-flow-graph-analysis
         (poo-flow-graph-id graph-value)
         (length node-ids)
         (length edge-pairs)
         roots
         terminals
         (walk-adjacency/indexed outgoing-index start-ids)
         (walk-adjacency/indexed incoming-index target-ids)
         topological-order
         cycle-path
         diagnostics)))))

;; : (-> PooFlowGraph PooFlowGraphLoopAnalysis)
(def (poo-flow-graph-loop-analysis-receipt graph-value)
  (let* ((outgoing-index (poo-flow-graph-outgoing-index graph-value))
         (node-ids (poo-flow-graph-node-ids graph-value)))
    (let-values (((components component-index)
                  (order-components/indexed
                   node-ids
                   (graph-strong-components/indexed node-ids outgoing-index))))
      (let* ((cyclic-components
              (select-cyclic-components components outgoing-index))
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
         diagnostics)))))

(def (poo-flow-graph-loop-analysis-diagnostics cyclic-components)
  (if (null? cyclic-components)
    '()
    (list (cons 'cyclic-components cyclic-components))))

(def (index-component-members! members membership component-id)
  (for-each
   (lambda (member) (hash-put! membership member component-id))
   members))

(def (components->membership components)
  (let (membership (make-hash-table))
    (let loop ((remaining components) (component-id 0))
      (unless (null? remaining)
        (index-component-members! (car remaining) membership component-id)
        (loop (cdr remaining) (+ component-id 1))))
    membership))

;; Preserve declared node order without repeatedly scanning every component.
;; Returns both ordered components and the node -> ordered component projection.
(def (order-components/indexed node-ids components)
  (let ((membership (components->membership components))
        (raw->ordered (make-hash-table))
        (members-rev (make-hash-table))
        (component-index (make-hash-table))
        (raw-order-rev '())
        (next-ordered-id 0))
    (for-each
     (lambda (node-id)
       (let (raw-id (hash-get membership node-id))
         (unless (hash-key? raw->ordered raw-id)
           (hash-put! raw->ordered raw-id next-ordered-id)
           (set! raw-order-rev (cons raw-id raw-order-rev))
           (set! next-ordered-id (+ next-ordered-id 1)))
         (hash-put! component-index node-id (hash-get raw->ordered raw-id))
         (hash-ensure-modify! members-rev
                              raw-id
                              (lambda () '())
                              (lambda (members) (cons node-id members)))))
     node-ids)
    (values
     (map (lambda (raw-id) (reverse (hash-get members-rev raw-id)))
          (reverse raw-order-rev))
     component-index)))

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
      (member (car component)
              (graph-adjacency-ref outgoing-index (car component)))))

(def (graph-condensation-edges edge-pairs component-index)
  (reverse
   (graph-condensation-edges/rev
    edge-pairs component-index (make-hash-table) '())))

(def (graph-condensation-edges/rev edge-pairs component-index seen edges-rev)
  (cond
   ((null? edge-pairs) edges-rev)
   (else
    (let* ((edge-pair (car edge-pairs))
           (source-component (hash-get component-index (car edge-pair)))
           (target-component (hash-get component-index (cadr edge-pair)))
           (component-edge (list source-component target-component)))
      (if (or (= source-component target-component)
              (hash-key? seen component-edge))
        (graph-condensation-edges/rev (cdr edge-pairs)
                                      component-index
                                      seen
                                      edges-rev)
        (begin
          (hash-put! seen component-edge #t)
          (graph-condensation-edges/rev (cdr edge-pairs)
                                        component-index
                                        seen
                                        (cons component-edge edges-rev))))))))

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

(def (graph-indegrees node-ids edge-pairs)
  (let (indegrees (make-hash-table))
    (for-each (lambda (id) (hash-put! indegrees id 0)) node-ids)
    (for-each
     (lambda (edge-pair)
       (let (target (cadr edge-pair))
         (when (hash-key? indegrees target)
           (hash-put! indegrees target
                      (+ 1 (hash-get indegrees target))))))
     edge-pairs)
    indegrees))

(def (topological-enqueue-targets! targets indegrees pending)
  (for-each
   (lambda (target)
     (when (hash-key? indegrees target)
       (let (next-indegree (- (hash-get indegrees target) 1))
         (hash-put! indegrees target next-indegree)
         (when (zero? next-indegree)
           (enqueue! pending target)))))
   targets))

(def (topological-order/indexed node-ids edge-pairs outgoing-index)
  (let* ((indegrees (graph-indegrees node-ids edge-pairs))
         (ready-ids
          (filter
           (lambda (id) (zero? (hash-get indegrees id)))
           node-ids))
         (node-count (length node-ids))
         (pending (make-queue)))
    (for-each (lambda (id) (enqueue! pending id)) ready-ids)
    (let loop ((order-rev '())
               (visited-count 0))
      (if (queue-empty? pending)
        (if (= visited-count node-count)
          (reverse order-rev)
          #f)
        (let (id (dequeue! pending))
          (topological-enqueue-targets!
           (graph-adjacency-ref outgoing-index id)
           indegrees
           pending)
          (loop (cons id order-rev) (+ visited-count 1)))))))
