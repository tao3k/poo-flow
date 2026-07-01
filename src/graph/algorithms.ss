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
        poo-flow-graph-analysis-receipt)

;; : (-> PooFlowGraph [Object])
(def (poo-flow-graph-node-ids graph-value)
  (map poo-flow-graph-node-id
       (poo-flow-graph-nodes graph-value)))

;; : (-> PooFlowGraph [[Object Object]])
(def (poo-flow-graph-edge-pairs graph-value)
  (map (lambda (edge)
         (list (poo-flow-graph-edge-from edge)
               (poo-flow-graph-edge-to edge)))
       (poo-flow-graph-edges graph-value)))

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
(def (poo-flow-graph-cycle-path graph-value)
  (find-cycle-from-nodes graph-value
                         (poo-flow-graph-node-ids graph-value)
                         '()))

;; : (-> PooFlowGraph Boolean)
(def (poo-flow-graph-acyclic? graph-value)
  (not (poo-flow-graph-cycle-path graph-value)))

;; : (-> PooFlowGraph MaybeList)
(def (poo-flow-graph-topological-order graph-value)
  (let ((cycle-path (poo-flow-graph-cycle-path graph-value)))
    (if cycle-path
      #f
      (topological-walk (poo-flow-graph-node-ids graph-value)
                        (poo-flow-graph-edges graph-value)
                        '()))))

;; : (-> PooFlowGraph PooFlowGraphAnalysis)
(def (poo-flow-graph-analysis-receipt graph-value . maybe-start+target)
  (let* ((roots (poo-flow-graph-root-ids graph-value))
         (terminals (poo-flow-graph-terminal-ids graph-value))
         (start-ids (if (null? maybe-start+target)
                      roots
                      (car maybe-start+target)))
         (target-ids (if (or (null? maybe-start+target)
                             (null? (cdr maybe-start+target)))
                       terminals
                       (cadr maybe-start+target)))
         (cycle-path (poo-flow-graph-cycle-path graph-value))
         (topological-order (if cycle-path
                              #f
                              (poo-flow-graph-topological-order
                               graph-value)))
         (diagnostics (if cycle-path
                        (list (cons 'cycle-path cycle-path))
                        '())))
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
  (let loop ((remaining stack)
             (path-tail '()))
    (cond
     ((null? remaining)
      (list id))
     ((equal? id (car remaining))
      (cons id (cycle-path-close path-tail id)))
     (else
      (loop (cdr remaining)
            (cons (car remaining) path-tail))))))

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
