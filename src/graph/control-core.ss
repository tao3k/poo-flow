;;; -*- Gerbil -*-
;;; Boundary: graph control analysis implementation.
;;; Invariant: graph walks happen once per analysis receipt; runtime execution is out.

(import :poo-flow/src/graph/types
        :poo-flow/src/graph/algorithms
        :poo-flow/src/graph/control-utils)

(export poo-flow-graph-entry-ids
        poo-flow-graph-finish-ids
        poo-flow-graph-conditional-edge-pairs
        poo-flow-graph-loop-edge-pairs
        poo-flow-graph-undeclared-edge-pairs
        poo-flow-graph-unreachable-ids
        poo-flow-graph-dead-end-ids
        poo-flow-graph-finish-reachable-ids
        poo-flow-graph-branch-targets-declared?
        poo-flow-graph-finish-total?
        poo-flow-graph-control-diagnostics
        poo-flow-graph-control-analysis-receipt)

;; : (-> PooFlowGraph [Object])
(def (poo-flow-graph-entry-ids graph-value)
  (graph-entry-ids graph-value
                   (poo-flow-graph-root-ids graph-value)))

;; : (-> PooFlowGraph [Object])
(def (poo-flow-graph-finish-ids graph-value)
  (graph-finish-ids graph-value
                    (poo-flow-graph-terminal-ids graph-value)))

;; : (-> PooFlowGraph [[Object Object]])
(def (poo-flow-graph-conditional-edge-pairs graph-value)
  (edge-pairs-by-kinds graph-value +poo-flow-graph-conditional-edge-kinds+))

;; : (-> PooFlowGraph [[Object Object]])
(def (poo-flow-graph-loop-edge-pairs graph-value)
  (edge-pairs-by-kinds graph-value +poo-flow-graph-loop-edge-kinds+))

;; : (-> PooFlowGraph [[Object Object]])
(def (poo-flow-graph-undeclared-edge-pairs graph-value)
  (reverse
   (undeclared-edge-pairs/rev
    (poo-flow-graph-edges graph-value)
    (poo-flow-graph-node-ids graph-value)
    '())))

;; : (-> PooFlowGraph [Object] [Object])
(def (poo-flow-graph-unreachable-ids graph-value . maybe-start)
  (let* ((start-ids (if (null? maybe-start)
                      (poo-flow-graph-entry-ids graph-value)
                      (car maybe-start)))
         (reachable-ids (poo-flow-graph-reachable-ids graph-value
                                                       start-ids)))
    (remove-ids reachable-ids
                (poo-flow-graph-node-ids graph-value))))

;; : (-> PooFlowGraph [Object] [Object] [Object])
(def (poo-flow-graph-dead-end-ids graph-value . maybe-entry+finish)
  (let* ((entry-ids (if (null? maybe-entry+finish)
                      (poo-flow-graph-entry-ids graph-value)
                      (car maybe-entry+finish)))
         (finish-ids (if (or (null? maybe-entry+finish)
                             (null? (cdr maybe-entry+finish)))
                       (poo-flow-graph-finish-ids graph-value)
                       (cadr maybe-entry+finish)))
         (reachable-ids (poo-flow-graph-reachable-ids graph-value
                                                       entry-ids)))
    (graph-dead-end-ids graph-value reachable-ids finish-ids)))

;; : (-> PooFlowGraph [Object] [Object])
(def (poo-flow-graph-finish-reachable-ids graph-value . maybe-finish)
  (let* ((finish-ids (if (null? maybe-finish)
                       (poo-flow-graph-finish-ids graph-value)
                       (car maybe-finish)))
         (dependency-cone (poo-flow-graph-dependency-cone graph-value
                                                          finish-ids)))
    (intersection-ids (poo-flow-graph-node-ids graph-value)
                      dependency-cone)))

;; : (-> PooFlowGraph Boolean)
(def (poo-flow-graph-branch-targets-declared? graph-value)
  (ids-subset? (edge-targets-by-kinds graph-value
                                      +poo-flow-graph-conditional-edge-kinds+)
               (poo-flow-graph-node-ids graph-value)))

;; : (-> PooFlowGraph [Object] [Object] Boolean)
(def (poo-flow-graph-finish-total? graph-value . maybe-entry+finish)
  (let* ((node-ids (poo-flow-graph-node-ids graph-value))
         (entry-ids (if (null? maybe-entry+finish)
                      (poo-flow-graph-entry-ids graph-value)
                      (car maybe-entry+finish)))
         (finish-ids (if (or (null? maybe-entry+finish)
                             (null? (cdr maybe-entry+finish)))
                       (poo-flow-graph-finish-ids graph-value)
                       (cadr maybe-entry+finish)))
         (reachable-ids (poo-flow-graph-reachable-ids graph-value
                                                       entry-ids))
         (finish-reachable-ids (poo-flow-graph-finish-reachable-ids
                                graph-value
                                finish-ids))
         (undeclared-edge-pairs
          (poo-flow-graph-undeclared-edge-pairs graph-value))
         (dead-end-ids
          (graph-dead-end-ids graph-value reachable-ids finish-ids)))
    (control-finish-total? node-ids
                           entry-ids
                           finish-ids
                           reachable-ids
                           finish-reachable-ids
                           undeclared-edge-pairs
                           dead-end-ids)))

;; : (-> PooFlowGraph [Object] [Object] Alist)
(def (poo-flow-graph-control-diagnostics graph-value . maybe-entry+finish)
  (let* ((node-ids (poo-flow-graph-node-ids graph-value))
         (entry-ids (if (null? maybe-entry+finish)
                      (poo-flow-graph-entry-ids graph-value)
                      (car maybe-entry+finish)))
         (finish-ids (if (or (null? maybe-entry+finish)
                             (null? (cdr maybe-entry+finish)))
                       (poo-flow-graph-finish-ids graph-value)
                       (cadr maybe-entry+finish)))
         (reachable-ids (poo-flow-graph-reachable-ids graph-value
                                                       entry-ids))
         (dependency-cone (poo-flow-graph-dependency-cone graph-value
                                                          finish-ids))
         (finish-reachable-ids (intersection-ids node-ids dependency-cone))
         (undeclared-edge-pairs
          (poo-flow-graph-undeclared-edge-pairs graph-value))
         (branch-target-ids
          (edge-targets-by-kinds graph-value
                                 +poo-flow-graph-conditional-edge-kinds+))
         (unreachable-ids (remove-ids reachable-ids node-ids))
         (dead-end-ids (graph-dead-end-ids graph-value
                                           reachable-ids
                                           finish-ids))
         (finish-unreachable-ids
          (remove-ids finish-reachable-ids reachable-ids))
         (cycle-path (poo-flow-graph-cycle-path graph-value))
         (loop-edge-pairs (poo-flow-graph-loop-edge-pairs graph-value))
         (unexpected-cycle-path
          (if (and cycle-path (null? loop-edge-pairs))
            cycle-path
            #f)))
    (control-diagnostic-rows node-ids
                             entry-ids
                             finish-ids
                             undeclared-edge-pairs
                             branch-target-ids
                             unreachable-ids
                             dead-end-ids
                             finish-unreachable-ids
                             unexpected-cycle-path)))

;; : (-> PooFlowGraph [Object] [Object] PooFlowGraphAnalysis)
(def (poo-flow-graph-control-analysis-receipt graph-value
                                             . maybe-entry+finish)
  (let* ((node-ids (poo-flow-graph-node-ids graph-value))
         (root-ids (poo-flow-graph-root-ids graph-value))
         (terminal-ids (poo-flow-graph-terminal-ids graph-value))
         (entry-ids (if (null? maybe-entry+finish)
                      (graph-entry-ids graph-value root-ids)
                      (car maybe-entry+finish)))
         (finish-ids (if (or (null? maybe-entry+finish)
                             (null? (cdr maybe-entry+finish)))
                       (graph-finish-ids graph-value terminal-ids)
                       (cadr maybe-entry+finish)))
         (cycle-path (poo-flow-graph-cycle-path graph-value))
         (topological-order (if cycle-path
                              #f
                              (poo-flow-graph-topological-order/acyclic
                               graph-value)))
         (reachable-ids (poo-flow-graph-reachable-ids graph-value
                                                       entry-ids))
         (dependency-cone (poo-flow-graph-dependency-cone graph-value
                                                          finish-ids))
         (conditional-edge-pairs
          (edge-pairs-by-kinds graph-value
                               +poo-flow-graph-conditional-edge-kinds+))
         (loop-edge-pairs
          (edge-pairs-by-kinds graph-value
                               +poo-flow-graph-loop-edge-kinds+))
         (undeclared-edge-pairs
          (reverse
           (undeclared-edge-pairs/rev
            (poo-flow-graph-edges graph-value)
            node-ids
            '())))
         (unreachable-ids (remove-ids reachable-ids node-ids))
         (dead-end-ids (graph-dead-end-ids graph-value
                                           reachable-ids
                                           finish-ids))
         (finish-reachable-ids (intersection-ids node-ids dependency-cone))
         (branch-target-ids
          (edge-targets-by-kinds graph-value
                                 +poo-flow-graph-conditional-edge-kinds+))
         (branch-targets-declared?
          (ids-subset? branch-target-ids node-ids))
         (finish-unreachable-ids
          (remove-ids finish-reachable-ids reachable-ids))
         (unexpected-cycle-path
          (if (and cycle-path (null? loop-edge-pairs))
            cycle-path
            #f))
         (finish-total?
          (control-finish-total? node-ids
                                 entry-ids
                                 finish-ids
                                 reachable-ids
                                 finish-reachable-ids
                                 undeclared-edge-pairs
                                 dead-end-ids))
         (diagnostics
          (control-diagnostic-rows node-ids
                                   entry-ids
                                   finish-ids
                                   undeclared-edge-pairs
                                   branch-target-ids
                                   unreachable-ids
                                   dead-end-ids
                                   finish-unreachable-ids
                                   unexpected-cycle-path))
         (metadata
          (list
           (control-row 'entry-ids entry-ids)
           (control-row 'finish-ids finish-ids)
           (control-row 'conditional-edge-pairs conditional-edge-pairs)
           (control-row 'loop-edge-pairs loop-edge-pairs)
           (control-row 'undeclared-edge-pairs undeclared-edge-pairs)
           (control-row 'unreachable-ids unreachable-ids)
           (control-row 'dead-end-ids dead-end-ids)
           (control-row 'finish-reachable-ids finish-reachable-ids)
           (control-row 'branch-targets-declared? branch-targets-declared?)
           (control-row 'finish-total? finish-total?))))
    (poo-flow-graph-analysis
     (poo-flow-graph-id graph-value)
     (length node-ids)
     (length (poo-flow-graph-edges graph-value))
     root-ids
     terminal-ids
     reachable-ids
     dependency-cone
     topological-order
     cycle-path
     diagnostics
     metadata)))
