;;; -*- Gerbil -*-
;;; Boundary: pure graph algorithms over composed POO graph facts.
;;; Invariant: algorithms emit analysis facts only; runtime execution is out.

(import :poo-flow/src/graph/types)

(export poo-flow-graph-node-ids/rev
        poo-flow-graph-node-ids
        poo-flow-graph-edge-pairs/rev
        poo-flow-graph-edge-pairs)

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
