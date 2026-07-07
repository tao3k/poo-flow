(use-composition crewai
  (use-module crew
    (profiles crewai
      agent
      task
      crew
      planning
      memory
      knowledge
      sequential-process
      flow-state
      flow-router
      flow-persist
      guardrail
      human-input
      observability
      runtime-handoff))
  (stage production
    (compose
      (profiles crew
        agent
        task
        crew
        planning
        memory
        knowledge
        sequential-process
        flow-state
        flow-router
        flow-persist
        guardrail
        human-input
        observability
        runtime-handoff))
    (graph crewai-flow-graph)
    (loop #:fuel 6 #:exit final-output)
    (prove agent-tool-scope-contained
           task-dependencies-closed
           crew-members-declared
           planning-before-task-dispatch
           memory-scope-contained
           knowledge-sources-declared
           task-order-respects-dependencies
           router-targets-declared
           checkpoint-before-resume
           guardrail-before-downstream-task
           human-review-before-final-output
           trace-covers-agent-task-flow
           handoff-after-proof-gate)
    (handoff marlin-control-plane)))
