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

(import :poo-flow/src/graph/types-core)

(export #t)

(def PooFlowGraphIdType
  (poo-flow-contract-value-type
   'PooFlowGraphId poo-flow-graph-id? 'PooFlowGraphId))
(def PooFlowGraphAnyType
  (poo-flow-contract-value-type 'Object (lambda (_value) #t) 'Object))
(def PooFlowGraphMetadataType
  (poo-flow-contract-value-type
   'PooFlowGraphMetadata poo-flow-graph-metadata? 'Alist))

(def PooFlowGraphNodeIdSlot
  (poo-flow-contract-slot
   'graph.node/id 'id PooFlowGraphIdType #t
   '((scope . graph) (slot . id))))
(def PooFlowGraphNodePayloadSlot
  (poo-flow-contract-slot
   'graph.node/payload 'payload PooFlowGraphAnyType #f
   '((scope . graph) (slot . payload) (optional . #t))))
(def PooFlowGraphNodeMetadataSlot
  (poo-flow-contract-slot
   'graph.node/metadata 'metadata PooFlowGraphMetadataType #t
   '((scope . graph) (slot . metadata))))
(def PooFlowGraphNodeSlots
  (list PooFlowGraphNodeIdSlot
        PooFlowGraphNodePayloadSlot
        PooFlowGraphNodeMetadataSlot))
(def PooFlowGraphNodeContract
  (poo-flow-native-contract
   'graph/node 'graph 'PooFlowGraphNode poo-flow-graph-node?
   PooFlowGraphNodeSlots
   (lambda (candidate slot) (.slot? candidate slot))
   (lambda (candidate slot) (.ref candidate slot))
   '((scope . graph) (projection . graph-node))))

(def (poo-flow-graph-node-type-contract->alist)
  (poo-flow-native-contract->alist PooFlowGraphNodeContract))

(def PooFlowGraphSymbolType
  (poo-flow-contract-value-type 'Symbol symbol? 'Symbol))
(def PooFlowGraphEdgeFromSlot
  (poo-flow-contract-slot
   'graph.edge/from 'from PooFlowGraphIdType #t
   '((scope . graph) (slot . from))))
(def PooFlowGraphEdgeToSlot
  (poo-flow-contract-slot
   'graph.edge/to 'to PooFlowGraphIdType #t
   '((scope . graph) (slot . to))))
(def PooFlowGraphEdgeKindSlot
  (poo-flow-contract-slot
   'graph.edge/edge-kind 'edge-kind PooFlowGraphSymbolType #t
   '((scope . graph) (slot . edge-kind))))
(def PooFlowGraphEdgeMetadataSlot
  (poo-flow-contract-slot
   'graph.edge/metadata 'metadata PooFlowGraphMetadataType #t
   '((scope . graph) (slot . metadata))))
(def PooFlowGraphEdgeSlots
  (list PooFlowGraphEdgeFromSlot
        PooFlowGraphEdgeToSlot
        PooFlowGraphEdgeKindSlot
        PooFlowGraphEdgeMetadataSlot))
(def PooFlowGraphEdgeContract
  (poo-flow-native-contract
   'graph/edge 'graph 'PooFlowGraphEdge poo-flow-graph-edge?
   PooFlowGraphEdgeSlots
   (lambda (candidate slot) (.slot? candidate slot))
   (lambda (candidate slot) (.ref candidate slot))
   '((scope . graph) (projection . graph-edge))))

(def (poo-flow-graph-edge-type-contract->alist)
  (poo-flow-native-contract->alist PooFlowGraphEdgeContract))

(def PooFlowGraphNodeListType
  (poo-flow-contract-value-type
   '[PooFlowGraphNode] poo-flow-graph-node-list? '[PooFlowGraphNode]))
(def PooFlowGraphEdgeListType
  (poo-flow-contract-value-type
   '[PooFlowGraphEdge] poo-flow-graph-edge-list? '[PooFlowGraphEdge]))
(def PooFlowGraphIdSlot
  (poo-flow-contract-slot
   'graph/graph-id 'graph-id PooFlowGraphIdType #t
   '((scope . graph) (slot . graph-id))))
(def PooFlowGraphNodesSlot
  (poo-flow-contract-slot
   'graph/nodes 'nodes PooFlowGraphNodeListType #t
   '((scope . graph) (slot . nodes))))
(def PooFlowGraphEdgesSlot
  (poo-flow-contract-slot
   'graph/edges 'edges PooFlowGraphEdgeListType #t
   '((scope . graph) (slot . edges))))
(def PooFlowGraphMetadataSlot
  (poo-flow-contract-slot
   'graph/metadata 'metadata PooFlowGraphMetadataType #t
   '((scope . graph) (slot . metadata))))
(def PooFlowGraphSlots
  (list PooFlowGraphIdSlot
        PooFlowGraphNodesSlot
        PooFlowGraphEdgesSlot
        PooFlowGraphMetadataSlot))
(def PooFlowGraphContract
  (poo-flow-native-contract
   'graph 'graph 'PooFlowGraph poo-flow-graph?
   PooFlowGraphSlots
   (lambda (candidate slot) (.slot? candidate slot))
   (lambda (candidate slot) (.ref candidate slot))
   '((scope . graph) (projection . graph))))

(def (poo-flow-graph-type-contract->alist)
  (poo-flow-native-contract->alist PooFlowGraphContract))

(def PooFlowGraphNumberType
  (poo-flow-contract-value-type 'Number number? 'Number))
(def PooFlowGraphIdListType
  (poo-flow-contract-value-type
   '[PooFlowGraphId] poo-flow-graph-analysis-id-list? '[PooFlowGraphId]))
(def PooFlowGraphMaybeListType
  (poo-flow-contract-value-type
   'MaybeList poo-flow-graph-analysis-maybe-list? 'MaybeList))

;; : (-> PooFlowGraphContractKey Symbol PooFlowContractValueType PooFlowSlotContract)
(def (poo-flow-graph-analysis-slot key slot value-type)
  (poo-flow-contract-slot
   key slot value-type #t
   (map cons '(scope slot) (list 'graph slot))))

(def PooFlowGraphAnalysisSlots
  (list
   (poo-flow-graph-analysis-slot
    'graph.analysis/graph-id 'graph-id PooFlowGraphIdType)
   (poo-flow-graph-analysis-slot
    'graph.analysis/node-count 'node-count PooFlowGraphNumberType)
   (poo-flow-graph-analysis-slot
    'graph.analysis/edge-count 'edge-count PooFlowGraphNumberType)
   (poo-flow-graph-analysis-slot
    'graph.analysis/root-ids 'root-ids PooFlowGraphIdListType)
   (poo-flow-graph-analysis-slot
    'graph.analysis/terminal-ids 'terminal-ids PooFlowGraphIdListType)
   (poo-flow-graph-analysis-slot
    'graph.analysis/reachable-ids 'reachable-ids PooFlowGraphIdListType)
   (poo-flow-graph-analysis-slot
    'graph.analysis/dependency-cone 'dependency-cone PooFlowGraphIdListType)
   (poo-flow-graph-analysis-slot
    'graph.analysis/topological-order 'topological-order PooFlowGraphMaybeListType)
   (poo-flow-graph-analysis-slot
    'graph.analysis/cycle-path 'cycle-path PooFlowGraphMaybeListType)
   (poo-flow-graph-analysis-slot
    'graph.analysis/diagnostics 'diagnostics PooFlowGraphMetadataType)
   (poo-flow-graph-analysis-slot
    'graph.analysis/metadata 'metadata PooFlowGraphMetadataType)))
(def PooFlowGraphAnalysisContract
  (poo-flow-native-contract
   'graph/analysis 'graph 'PooFlowGraphAnalysis poo-flow-graph-analysis?
   PooFlowGraphAnalysisSlots
   (lambda (candidate slot) (.slot? candidate slot))
   (lambda (candidate slot) (.ref candidate slot))
   '((scope . graph) (projection . graph-analysis))))

(def (poo-flow-graph-analysis-type-contract->alist)
  (poo-flow-native-contract->alist PooFlowGraphAnalysisContract))

(def PooFlowGraphComponentListType
  (poo-flow-contract-value-type
   '[[PooFlowGraphId]] list? '[[PooFlowGraphId]]))
(def PooFlowGraphCondensationEdgeListType
  (poo-flow-contract-value-type
   '[[Number Number]] list? '[[Number Number]]))

;; : (-> PooFlowGraphContractKey Symbol PooFlowContractValueType PooFlowSlotContract)
(def (poo-flow-graph-loop-analysis-slot key slot value-type)
  (poo-flow-contract-slot
   key slot value-type #t
   (map cons '(scope slot) (list 'graph slot))))

(def PooFlowGraphLoopAnalysisSlots
  (list
   (poo-flow-graph-loop-analysis-slot
    'graph.loop-analysis/graph-id 'graph-id PooFlowGraphIdType)
   (poo-flow-graph-loop-analysis-slot
    'graph.loop-analysis/component-count 'component-count PooFlowGraphNumberType)
   (poo-flow-graph-loop-analysis-slot
    'graph.loop-analysis/cyclic-component-count
    'cyclic-component-count
    PooFlowGraphNumberType)
   (poo-flow-graph-loop-analysis-slot
    'graph.loop-analysis/components 'components PooFlowGraphComponentListType)
   (poo-flow-graph-loop-analysis-slot
    'graph.loop-analysis/cyclic-components
    'cyclic-components
    PooFlowGraphComponentListType)
   (poo-flow-graph-loop-analysis-slot
    'graph.loop-analysis/condensation-edges
    'condensation-edges
    PooFlowGraphCondensationEdgeListType)
   (poo-flow-graph-loop-analysis-slot
    'graph.loop-analysis/diagnostics 'diagnostics PooFlowGraphMetadataType)
   (poo-flow-graph-loop-analysis-slot
    'graph.loop-analysis/metadata 'metadata PooFlowGraphMetadataType)))
(def PooFlowGraphLoopAnalysisContract
  (poo-flow-native-contract
   'graph/loop-analysis 'graph 'PooFlowGraphLoopAnalysis
   poo-flow-graph-loop-analysis?
   PooFlowGraphLoopAnalysisSlots
   (lambda (candidate slot) (.slot? candidate slot))
   (lambda (candidate slot) (.ref candidate slot))
   '((scope . graph) (projection . graph-loop-analysis))))

(def (poo-flow-graph-loop-analysis-type-contract->alist)
  (poo-flow-native-contract->alist PooFlowGraphLoopAnalysisContract))
