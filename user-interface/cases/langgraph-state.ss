;;; -*- Gerbil -*-
;;; User Interface reusable case fragment: LangGraph-style state graph.
;;; Invariant: included by load!; the loader owns binding and export.

(use-composition langgraph-state-composition
  (modules
   (use-profile langgraph #:as graph))
  (stage production
    (compose
     (profile graph session)
     (profile graph state)
     (profile graph router)
     (profile graph agent-node)
     (profile graph tool-node)
     (profile graph bounded-loop)
     (profile graph runtime-handoff))
    (graph langgraph-state-graph)
    (loop #:fuel 8 #:exit terminal-edge)
    (prove declared-branch-targets
           typed-state-merge
           bounded-loop-progress
           explicit-runtime-handoff)
    (handoff marlin-control-plane)))
