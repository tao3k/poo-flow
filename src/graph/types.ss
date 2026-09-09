;;; -*- Gerbil -*-
;;; Boundary: graph facts are POO-native control-plane values.
;;; Invariant: graph objects describe topology; they never schedule or run it.

(import (only-in :clan/poo/object .ref .slot? object? object<-alist)
        (only-in "../module-system/descriptor/contracts.ss"
                 poo-flow-contract-slot
                 poo-flow-contract-value-type
                 poo-flow-native-contract
                 poo-flow-native-contract->alist)
        :poo-flow/src/module-system/projection/syntax)

(export +poo-flow-graph-node-prototype-kind+
        +poo-flow-graph-edge-prototype-kind+
        +poo-flow-graph-prototype-kind+
        +poo-flow-graph-analysis-prototype-kind+
        +poo-flow-graph-loop-analysis-prototype-kind+
        graph-node
        graph-edge
        graph
        graph-analysis
        graph-loop-analysis
        PooFlowGraphNodeContract
        PooFlowGraphEdgeContract
        PooFlowGraphContract
        PooFlowGraphAnalysisContract
        PooFlowGraphLoopAnalysisContract
        poo-flow-graph-node-type-contract->alist
        poo-flow-graph-edge-type-contract->alist
        poo-flow-graph-type-contract->alist
        poo-flow-graph-analysis-type-contract->alist
        poo-flow-graph-loop-analysis-type-contract->alist
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
        poo-flow-graph-analysis->alist
        poo-flow-graph-loop-analysis
        poo-flow-graph-loop-analysis?
        poo-flow-graph-loop-analysis->alist)

(import :poo-flow/src/graph/types-core
        :poo-flow/src/graph/types-contracts)
