;;; -*- Gerbil -*-
;;; Boundary: public graph control analysis facade.
;;; Invariant: keep the stable import path light; implementation lives in control-core.

(import :poo-flow/src/graph/control-core)

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
