;;; -*- Gerbil -*-
;;; Contract: graph objects expose utilities-backed type contracts.

(eval '(import "./src/graph/types.ss"))
(eval '(import "./src/graph/algorithms.ss"))

;; : (-> PooFlowGraphExpr PooFlowGraphValue)
(def (graph-eval expr)
  (eval expr))

;; : (-> Alist Symbol Object Object)
(def (alist-ref/default entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;; : (-> Alist [Symbol])
(def (contract-slot-names row)
  (map (lambda (slot-row)
         (alist-ref/default slot-row 'slot #f))
       (alist-ref/default row 'slots '())))

(let (node-row
      (graph-eval '(poo-flow-graph-node-type-contract->alist)))
  (unless (and (eq? (alist-ref/default node-row 'object-kind #f)
                    'PooFlowGraphNode)
               (equal? (contract-slot-names node-row)
                       '(id payload metadata)))
    (error "graph node contract should expose node slots")))

(let (edge-row
      (graph-eval '(poo-flow-graph-edge-type-contract->alist)))
  (unless (and (eq? (alist-ref/default edge-row 'object-kind #f)
                    'PooFlowGraphEdge)
               (equal? (contract-slot-names edge-row)
                       '(from to edge-kind metadata)))
    (error "graph edge contract should expose edge slots")))

(let (graph-row
      (graph-eval '(poo-flow-graph-type-contract->alist)))
  (unless (and (eq? (alist-ref/default graph-row 'object-kind #f)
                    'PooFlowGraph)
               (equal? (contract-slot-names graph-row)
                       '(graph-id nodes edges metadata)))
    (error "graph contract should expose aggregate slots")))

(when (graph-eval
       '(with-catch
         (lambda (_failure) #f)
         (lambda ()
           (poo-flow-graph-edge 'a 'b "not-a-symbol")
           #t)))
  (error "graph edge constructor should reject non-symbol edge kinds"))

(def analysis
  (graph-eval
   '(poo-flow-graph-analysis-receipt
     (poo-flow-graph
      'graph-contract-test
      (list (poo-flow-graph-node 'start)
            (poo-flow-graph-node 'finish))
      (list (poo-flow-graph-edge 'start 'finish))))))

(unless (graph-eval `(poo-flow-graph-analysis? ',analysis))
  (error "graph analysis receipt should be a graph analysis object"))

(let (analysis-row
      (graph-eval '(poo-flow-graph-analysis-type-contract->alist)))
  (unless (and (eq? (alist-ref/default analysis-row 'object-kind #f)
                    'PooFlowGraphAnalysis)
               (member 'diagnostics (contract-slot-names analysis-row)))
    (error "graph analysis contract should expose analysis slots")))
