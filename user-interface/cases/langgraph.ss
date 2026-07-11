;;; -*- Gerbil -*-
;;; User Interface reusable case fragment: LangGraph-style state graph.
;;; Invariant: included by load!; the loader owns binding and export.

(use-composition langgraph
  (use-module langgraph as graph
    (profiles
      session
      state
      router
      agent-node
      tool-node
      bounded-loop
      runtime-handoff))
  (compose
   (profiles graph
     session
     state
     router
     agent-node
     tool-node
     bounded-loop
     runtime-handoff))
  (stage production
    (graph langgraph-state-graph)
    (loop #:fuel 8 #:exit terminal-edge)
    (prove declared-branch-targets
           typed-state-merge
           bounded-loop-progress
           explicit-runtime-handoff)
    (handoff marlin-control-plane)))
