;;; -*- Gerbil -*-
;;; Boundary: graph facts are POO-native control-plane values.
;;; Invariant: graph objects describe topology; they never schedule or run it.

(import (only-in :clan/poo/object .ref .slot? object? object<-alist)
        (only-in "../utilities/contracts.ss"
                 poo-flow-object-type-contract->alist
                 poo-flow-contract-alist?
                 poo-flow-contract-list-of?)
        (only-in "../utilities/contract-syntax.ss"
                 defcontract-family)
        :poo-flow/src/module-system/projection-syntax)

(export +poo-flow-graph-node-prototype-kind+
        +poo-flow-graph-edge-prototype-kind+
        +poo-flow-graph-prototype-kind+
        +poo-flow-graph-analysis-prototype-kind+
        graph-node
        graph-edge
        graph
        graph-analysis
        +poo-flow-graph-node-slot-contracts+
        +poo-flow-graph-edge-slot-contracts+
        +poo-flow-graph-slot-contracts+
        +poo-flow-graph-analysis-slot-contracts+
        +poo-flow-graph-node-type-contract+
        +poo-flow-graph-edge-type-contract+
        +poo-flow-graph-type-contract+
        +poo-flow-graph-analysis-type-contract+
        poo-flow-graph-node-type-contract->alist
        poo-flow-graph-edge-type-contract->alist
        poo-flow-graph-type-contract->alist
        poo-flow-graph-analysis-type-contract->alist
        poo-flow-graph-id?
        poo-flow-graph-require
        poo-flow-graph-every?
        poo-flow-graph-node
        poo-flow-graph-node?
        poo-flow-graph-node-id
        poo-flow-graph-node-payload
        poo-flow-graph-node-metadata
        poo-flow-graph-node->alist
        poo-flow-graph-edge
        poo-flow-graph-edge?
        poo-flow-graph-edge-from
        poo-flow-graph-edge-to
        poo-flow-graph-edge-kind
        poo-flow-graph-edge-metadata
        poo-flow-graph-edge->alist
        poo-flow-graph
        poo-flow-graph?
        poo-flow-graph-id
        poo-flow-graph-nodes
        poo-flow-graph-edges
        poo-flow-graph-metadata
        poo-flow-graph->alist
        poo-flow-graph-analysis
        poo-flow-graph-analysis?
        poo-flow-graph-analysis->alist)

;; : Symbol
(def +poo-flow-graph-node-prototype-kind+
  'poo-flow.graph.node.prototype)

;; : Symbol
(def +poo-flow-graph-edge-prototype-kind+
  'poo-flow.graph.edge.prototype)

;; : Symbol
(def +poo-flow-graph-prototype-kind+
  'poo-flow.graph.prototype)

;; : Symbol
(def +poo-flow-graph-analysis-prototype-kind+
  'poo-flow.graph.analysis.prototype)

;; : PooFlowGraphNodePrototype
(def graph-node
  (object<-alist
   (list
    (cons 'kind +poo-flow-graph-node-prototype-kind+)
    (cons 'schema 'poo-flow.graph.node.v1)
    (cons 'id #f)
    (cons 'payload #f)
    (cons 'metadata '())
    (cons 'runtime-executed #f))))

;; : PooFlowGraphEdgePrototype
(def graph-edge
  (object<-alist
   (list
    (cons 'kind +poo-flow-graph-edge-prototype-kind+)
    (cons 'schema 'poo-flow.graph.edge.v1)
    (cons 'from #f)
    (cons 'to #f)
    (cons 'edge-kind 'dependency)
    (cons 'metadata '())
    (cons 'runtime-executed #f))))

;; : PooFlowGraphPrototype
(def graph
  (object<-alist
   (list
    (cons 'kind +poo-flow-graph-prototype-kind+)
    (cons 'schema 'poo-flow.graph.v1)
    (cons 'graph-id #f)
    (cons 'nodes '())
    (cons 'edges '())
    (cons 'metadata '())
    (cons 'runtime-executed #f))))

;; : PooFlowGraphAnalysisPrototype
(def graph-analysis
  (object<-alist
   (list
    (cons 'kind +poo-flow-graph-analysis-prototype-kind+)
    (cons 'schema 'poo-flow.graph.analysis.v1)
    (cons 'graph-id #f)
    (cons 'node-count 0)
    (cons 'edge-count 0)
    (cons 'root-ids '())
    (cons 'terminal-ids '())
    (cons 'reachable-ids '())
    (cons 'dependency-cone '())
    (cons 'topological-order #f)
    (cons 'cycle-path #f)
    (cons 'acyclic? #t)
    (cons 'diagnostics '())
    (cons 'metadata '())
    (cons 'runtime-executed #f))))

;; : (-> Object Boolean)
(def (poo-flow-graph-id? value)
  (or (symbol? value)
      (string? value)
      (number? value)
      (pair? value)))

;; : (-> String Boolean Object Object)
(def (poo-flow-graph-require message ok? value)
  (if ok?
    value
    (error message value)))

;; : (-> (-> Object Boolean) List Boolean)
(def (poo-flow-graph-every? predicate values)
  (cond
   ((null? values) #t)
   ((predicate (car values))
    (poo-flow-graph-every? predicate (cdr values)))
   (else #f)))

;; : (-> Object Boolean)
(def (poo-flow-graph-metadata? value)
  (poo-flow-contract-alist? value))

;; : (-> Object [Object] [Alist] PooFlowGraphNode)
(def (poo-flow-graph-node id . maybe-payload+metadata)
  (poo-flow-graph-require "graph node id must be a stable id"
                          (poo-flow-graph-id? id)
                          id)
  (let* ((payload (if (null? maybe-payload+metadata)
                    #f
                    (car maybe-payload+metadata)))
         (metadata (if (or (null? maybe-payload+metadata)
                           (null? (cdr maybe-payload+metadata)))
                     '()
                     (cadr maybe-payload+metadata))))
    (object<-alist
     (list
      (cons 'kind +poo-flow-graph-node-prototype-kind+)
      (cons 'schema 'poo-flow.graph.node.v1)
      (cons 'id id)
      (cons 'payload payload)
      (cons 'metadata metadata)
      (cons 'runtime-executed #f)))))

;; : (-> Object Boolean)
(def (poo-flow-graph-node? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind)
            +poo-flow-graph-node-prototype-kind+)))

;; : (-> Object Boolean)
(def (poo-flow-graph-node-list? value)
  (poo-flow-contract-list-of? poo-flow-graph-node? value))

;; : (-> PooFlowGraphNode Object)
(def (poo-flow-graph-node-id node)
  (.ref node 'id))

;; : (-> PooFlowGraphNode Object)
(def (poo-flow-graph-node-payload node)
  (.ref node 'payload))

;; : (-> PooFlowGraphNode [Alist])
(def (poo-flow-graph-node-metadata node)
  (.ref node 'metadata))

;; : (-> PooFlowGraphNode Alist)
(defpoo-module-final-projection
  poo-flow-graph-node->alist (node)
  (bindings ((checked-node
              (poo-flow-graph-require
               "graph node projection requires a graph node"
               (poo-flow-graph-node? node)
               node))))
  (fields ((kind (.ref checked-node 'kind))
           (schema (.ref checked-node 'schema))
           (id (.ref checked-node 'id))
           (payload (.ref checked-node 'payload))
           (metadata (.ref checked-node 'metadata))
           (runtime-executed (.ref checked-node 'runtime-executed)))))

;; : (-> [PooFlowGraphNode] [Alist])
(defpoo-module-final-projection-batch
  poo-flow-graph-nodes->alists (nodes)
  (projector poo-flow-graph-node->alist)
  (error-message "graph node projection requires a list"))

;; : (-> Object Object Symbol [Alist] PooFlowGraphEdge)
(def (poo-flow-graph-edge from to . maybe-kind+metadata)
  (poo-flow-graph-require "graph edge from must be a stable id"
                          (poo-flow-graph-id? from)
                          from)
  (poo-flow-graph-require "graph edge to must be a stable id"
                          (poo-flow-graph-id? to)
                          to)
  (let* ((edge-kind (if (null? maybe-kind+metadata)
                     'dependency
                     (car maybe-kind+metadata)))
         (metadata (if (or (null? maybe-kind+metadata)
                           (null? (cdr maybe-kind+metadata)))
                     '()
                     (cadr maybe-kind+metadata))))
    (poo-flow-graph-require "graph edge kind must be a symbol"
                            (symbol? edge-kind)
                            edge-kind)
    (object<-alist
     (list
      (cons 'kind +poo-flow-graph-edge-prototype-kind+)
      (cons 'schema 'poo-flow.graph.edge.v1)
      (cons 'from from)
      (cons 'to to)
      (cons 'edge-kind edge-kind)
      (cons 'metadata metadata)
      (cons 'runtime-executed #f)))))

;; : (-> Object Boolean)
(def (poo-flow-graph-edge? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind)
            +poo-flow-graph-edge-prototype-kind+)))

;; : (-> Object Boolean)
(def (poo-flow-graph-edge-list? value)
  (poo-flow-contract-list-of? poo-flow-graph-edge? value))

;; : (-> PooFlowGraphEdge Object)
(def (poo-flow-graph-edge-from edge)
  (.ref edge 'from))

;; : (-> PooFlowGraphEdge Object)
(def (poo-flow-graph-edge-to edge)
  (.ref edge 'to))

;; : (-> PooFlowGraphEdge Symbol)
(def (poo-flow-graph-edge-kind edge)
  (.ref edge 'edge-kind))

;; : (-> PooFlowGraphEdge [Alist])
(def (poo-flow-graph-edge-metadata edge)
  (.ref edge 'metadata))

;; : (-> PooFlowGraphEdge Alist)
(defpoo-module-final-projection
  poo-flow-graph-edge->alist (edge)
  (bindings ((checked-edge
              (poo-flow-graph-require
               "graph edge projection requires a graph edge"
               (poo-flow-graph-edge? edge)
               edge))))
  (fields ((kind (.ref checked-edge 'kind))
           (schema (.ref checked-edge 'schema))
           (from (.ref checked-edge 'from))
           (to (.ref checked-edge 'to))
           (edge-kind (.ref checked-edge 'edge-kind))
           (metadata (.ref checked-edge 'metadata))
           (runtime-executed (.ref checked-edge 'runtime-executed)))))

;; : (-> [PooFlowGraphEdge] [Alist])
(defpoo-module-final-projection-batch
  poo-flow-graph-edges->alists (edges)
  (projector poo-flow-graph-edge->alist)
  (error-message "graph edge projection requires a list"))

;; : (-> Object [PooFlowGraphNode] [PooFlowGraphEdge] [Alist] PooFlowGraph)
(def (poo-flow-graph graph-id nodes edges . maybe-metadata)
  (poo-flow-graph-require "graph id must be a stable id"
                          (poo-flow-graph-id? graph-id)
                          graph-id)
  (poo-flow-graph-require "graph nodes must be graph nodes"
                          (poo-flow-graph-every? poo-flow-graph-node?
                                                 nodes)
                          nodes)
  (poo-flow-graph-require "graph edges must be graph edges"
                          (poo-flow-graph-every? poo-flow-graph-edge?
                                                 edges)
                          edges)
  (object<-alist
   (list
    (cons 'kind +poo-flow-graph-prototype-kind+)
    (cons 'schema 'poo-flow.graph.v1)
    (cons 'graph-id graph-id)
    (cons 'nodes nodes)
    (cons 'edges edges)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata)))
    (cons 'runtime-executed #f))))

;; : (-> Object Boolean)
(def (poo-flow-graph? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind)
            +poo-flow-graph-prototype-kind+)))

;; : (-> PooFlowGraph Object)
(def (poo-flow-graph-id graph-value)
  (.ref graph-value 'graph-id))

;; : (-> PooFlowGraph [PooFlowGraphNode])
(def (poo-flow-graph-nodes graph-value)
  (.ref graph-value 'nodes))

;; : (-> PooFlowGraph [PooFlowGraphEdge])
(def (poo-flow-graph-edges graph-value)
  (.ref graph-value 'edges))

;; : (-> PooFlowGraph [Alist])
(def (poo-flow-graph-metadata graph-value)
  (.ref graph-value 'metadata))

;; : (-> PooFlowGraph Alist)
(defpoo-module-final-projection
  poo-flow-graph->alist (graph-value)
  (bindings ((checked-graph
              (poo-flow-graph-require
               "graph projection requires a graph"
               (poo-flow-graph? graph-value)
               graph-value))))
  (fields ((kind (.ref checked-graph 'kind))
           (schema (.ref checked-graph 'schema))
           (graph-id (.ref checked-graph 'graph-id))
           (nodes
            (poo-flow-graph-nodes->alists (.ref checked-graph 'nodes)))
           (edges
            (poo-flow-graph-edges->alists (.ref checked-graph 'edges)))
           (metadata (.ref checked-graph 'metadata))
           (runtime-executed (.ref checked-graph 'runtime-executed)))))

;; : (-> Object Nat Nat [Object] [Object] [Object] [Object] MaybeList MaybeList [Alist] [Alist] PooFlowGraphAnalysis)
(def (poo-flow-graph-analysis graph-id
                              node-count
                              edge-count
                              root-ids
                              terminal-ids
                              reachable-ids
                              dependency-cone
                              topological-order
                              cycle-path
                              diagnostics
                              . maybe-metadata)
  (poo-flow-graph-require "graph analysis id must be a stable id"
                          (poo-flow-graph-id? graph-id)
                          graph-id)
  (object<-alist
   (list
    (cons 'kind +poo-flow-graph-analysis-prototype-kind+)
    (cons 'schema 'poo-flow.graph.analysis.v1)
    (cons 'graph-id graph-id)
    (cons 'node-count node-count)
    (cons 'edge-count edge-count)
    (cons 'root-ids root-ids)
    (cons 'terminal-ids terminal-ids)
    (cons 'reachable-ids reachable-ids)
    (cons 'dependency-cone dependency-cone)
    (cons 'topological-order topological-order)
    (cons 'cycle-path cycle-path)
    (cons 'acyclic? (not cycle-path))
    (cons 'diagnostics diagnostics)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata)))
    (cons 'runtime-executed #f))))

;; : (-> Object Boolean)
(def (poo-flow-graph-analysis? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind)
            +poo-flow-graph-analysis-prototype-kind+)))

;; : (-> Object Boolean)
(def (poo-flow-graph-analysis-id-list? value)
  (list? value))

;; : (-> Object Boolean)
(def (poo-flow-graph-analysis-maybe-list? value)
  (or (not value)
      (list? value)))

;; : (-> PooFlowGraphAnalysis Alist)
(defpoo-module-final-projection
  poo-flow-graph-analysis->alist (analysis)
  (bindings ((checked-analysis
              (poo-flow-graph-require
               "graph analysis projection requires graph analysis"
               (poo-flow-graph-analysis? analysis)
               analysis))))
  (fields ((kind (.ref checked-analysis 'kind))
           (schema (.ref checked-analysis 'schema))
           (graph-id (.ref checked-analysis 'graph-id))
           (node-count (.ref checked-analysis 'node-count))
           (edge-count (.ref checked-analysis 'edge-count))
           (root-ids (.ref checked-analysis 'root-ids))
           (terminal-ids (.ref checked-analysis 'terminal-ids))
           (reachable-ids (.ref checked-analysis 'reachable-ids))
           (dependency-cone (.ref checked-analysis 'dependency-cone))
           (topological-order (.ref checked-analysis 'topological-order))
           (cycle-path (.ref checked-analysis 'cycle-path))
           (acyclic? (.ref checked-analysis 'acyclic?))
           (diagnostics (.ref checked-analysis 'diagnostics))
           (metadata (.ref checked-analysis 'metadata))
           (runtime-executed (.ref checked-analysis 'runtime-executed)))))

;; : (-> ContractFamilyDeclaration ContractFamilyDefinitions)
;;   | doc m%
;;       Declare graph node contracts as structured data while graph topology
;;       semantics remain in the graph owner.
;;
;;       # Examples
;;       ```scheme
;;       +poo-flow-graph-node-slot-contracts+
;;       ;; => graph-node-slot-contract-list
;;       ```
;;     %
(defcontract-family
  +poo-flow-graph-node-slot-contracts+
  +poo-flow-graph-node-type-contract+
  'graph/node
  'graph
  'PooFlowGraphNode
  '((scope . graph) (projection . graph-node))
  ((+poo-flow-graph-node-id-slot-contract+
    'graph.node/id
    'id
    'PooFlowGraphId
    'poo-flow-graph-id?
    poo-flow-graph-id?
    #t
    '((scope . graph) (slot . id)))
   (+poo-flow-graph-node-payload-slot-contract+
    'graph.node/payload
    'payload
    'Object
    'any
    (lambda (_value) #t)
    #f
    '((scope . graph) (slot . payload) (optional . #t)))
   (+poo-flow-graph-node-metadata-slot-contract+
    'graph.node/metadata
    'metadata
    'Alist
    'poo-flow-graph-metadata?
    poo-flow-graph-metadata?
    #t
    '((scope . graph) (slot . metadata)))))

;; : (-> Alist)
(def (poo-flow-graph-node-type-contract->alist)
  (poo-flow-object-type-contract->alist
   +poo-flow-graph-node-type-contract+))

;; : (-> ContractFamilyDeclaration ContractFamilyDefinitions)
;;   | doc m%
;;       Declare graph edge contracts as structured data for topology checks.
;;
;;       # Examples
;;       ```scheme
;;       +poo-flow-graph-edge-slot-contracts+
;;       ;; => graph-edge-slot-contract-list
;;       ```
;;     %
(defcontract-family
  +poo-flow-graph-edge-slot-contracts+
  +poo-flow-graph-edge-type-contract+
  'graph/edge
  'graph
  'PooFlowGraphEdge
  '((scope . graph) (projection . graph-edge))
  ((+poo-flow-graph-edge-from-slot-contract+
    'graph.edge/from
    'from
    'PooFlowGraphId
    'poo-flow-graph-id?
    poo-flow-graph-id?
    #t
    '((scope . graph) (slot . from)))
   (+poo-flow-graph-edge-to-slot-contract+
    'graph.edge/to
    'to
    'PooFlowGraphId
    'poo-flow-graph-id?
    poo-flow-graph-id?
    #t
    '((scope . graph) (slot . to)))
   (+poo-flow-graph-edge-kind-slot-contract+
    'graph.edge/edge-kind
    'edge-kind
    'Symbol
    'symbol?
    symbol?
    #t
    '((scope . graph) (slot . edge-kind)))
   (+poo-flow-graph-edge-metadata-slot-contract+
    'graph.edge/metadata
    'metadata
    'Alist
    'poo-flow-graph-metadata?
    poo-flow-graph-metadata?
    #t
    '((scope . graph) (slot . metadata)))))

;; : (-> Alist)
(def (poo-flow-graph-edge-type-contract->alist)
  (poo-flow-object-type-contract->alist
   +poo-flow-graph-edge-type-contract+))

;; : (-> ContractFamilyDeclaration ContractFamilyDefinitions)
;;   | doc m%
;;       Declare graph aggregate contracts using node and edge list predicates.
;;
;;       # Examples
;;       ```scheme
;;       +poo-flow-graph-slot-contracts+
;;       ;; => graph-slot-contract-list
;;       ```
;;     %
(defcontract-family
  +poo-flow-graph-slot-contracts+
  +poo-flow-graph-type-contract+
  'graph
  'graph
  'PooFlowGraph
  '((scope . graph) (projection . graph))
  ((+poo-flow-graph-id-slot-contract+
    'graph/graph-id
    'graph-id
    'PooFlowGraphId
    'poo-flow-graph-id?
    poo-flow-graph-id?
    #t
    '((scope . graph) (slot . graph-id)))
   (+poo-flow-graph-nodes-slot-contract+
    'graph/nodes
    'nodes
    '[PooFlowGraphNode]
    'poo-flow-graph-node-list?
    poo-flow-graph-node-list?
    #t
    '((scope . graph) (slot . nodes)))
   (+poo-flow-graph-edges-slot-contract+
    'graph/edges
    'edges
    '[PooFlowGraphEdge]
    'poo-flow-graph-edge-list?
    poo-flow-graph-edge-list?
    #t
    '((scope . graph) (slot . edges)))
   (+poo-flow-graph-metadata-slot-contract+
    'graph/metadata
    'metadata
    'Alist
    'poo-flow-graph-metadata?
    poo-flow-graph-metadata?
    #t
    '((scope . graph) (slot . metadata)))))

;; : (-> Alist)
(def (poo-flow-graph-type-contract->alist)
  (poo-flow-object-type-contract->alist
   +poo-flow-graph-type-contract+))

;; : (-> ContractFamilyDeclaration ContractFamilyDefinitions)
;;   | doc m%
;;       Declare graph analysis contracts for algorithm receipts.
;;
;;       # Examples
;;       ```scheme
;;       +poo-flow-graph-analysis-slot-contracts+
;;       ;; => graph-analysis-slot-contract-list
;;       ```
;;     %
(defcontract-family
  +poo-flow-graph-analysis-slot-contracts+
  +poo-flow-graph-analysis-type-contract+
  'graph/analysis
  'graph
  'PooFlowGraphAnalysis
  '((scope . graph) (projection . graph-analysis))
  ((+poo-flow-graph-analysis-graph-id-slot-contract+
    'graph.analysis/graph-id
    'graph-id
    'PooFlowGraphId
    'poo-flow-graph-id?
    poo-flow-graph-id?
    #t
    '((scope . graph) (slot . graph-id)))
   (+poo-flow-graph-analysis-node-count-slot-contract+
    'graph.analysis/node-count
    'node-count
    'Number
    'number?
    number?
    #t
    '((scope . graph) (slot . node-count)))
   (+poo-flow-graph-analysis-edge-count-slot-contract+
    'graph.analysis/edge-count
    'edge-count
    'Number
    'number?
    number?
    #t
    '((scope . graph) (slot . edge-count)))
   (+poo-flow-graph-analysis-root-ids-slot-contract+
    'graph.analysis/root-ids
    'root-ids
    '[PooFlowGraphId]
    'list?
    list?
    #t
    '((scope . graph) (slot . root-ids)))
   (+poo-flow-graph-analysis-terminal-ids-slot-contract+
    'graph.analysis/terminal-ids
    'terminal-ids
    '[PooFlowGraphId]
    'list?
    list?
    #t
    '((scope . graph) (slot . terminal-ids)))
   (+poo-flow-graph-analysis-reachable-ids-slot-contract+
    'graph.analysis/reachable-ids
    'reachable-ids
    '[PooFlowGraphId]
    'list?
    list?
    #t
    '((scope . graph) (slot . reachable-ids)))
   (+poo-flow-graph-analysis-dependency-cone-slot-contract+
    'graph.analysis/dependency-cone
    'dependency-cone
    '[PooFlowGraphId]
    'list?
    list?
    #t
    '((scope . graph) (slot . dependency-cone)))
   (+poo-flow-graph-analysis-topological-order-slot-contract+
    'graph.analysis/topological-order
    'topological-order
    'MaybeList
    'poo-flow-graph-analysis-maybe-list?
    poo-flow-graph-analysis-maybe-list?
    #t
    '((scope . graph) (slot . topological-order)))
   (+poo-flow-graph-analysis-cycle-path-slot-contract+
    'graph.analysis/cycle-path
    'cycle-path
    'MaybeList
    'poo-flow-graph-analysis-maybe-list?
    poo-flow-graph-analysis-maybe-list?
    #t
    '((scope . graph) (slot . cycle-path)))
   (+poo-flow-graph-analysis-diagnostics-slot-contract+
    'graph.analysis/diagnostics
    'diagnostics
    'Alist
    'poo-flow-graph-metadata?
    poo-flow-graph-metadata?
    #t
    '((scope . graph) (slot . diagnostics)))
   (+poo-flow-graph-analysis-metadata-slot-contract+
    'graph.analysis/metadata
    'metadata
    'Alist
    'poo-flow-graph-metadata?
    poo-flow-graph-metadata?
    #t
    '((scope . graph) (slot . metadata)))))

;; : (-> Alist)
(def (poo-flow-graph-analysis-type-contract->alist)
  (poo-flow-object-type-contract->alist
   +poo-flow-graph-analysis-type-contract+))
