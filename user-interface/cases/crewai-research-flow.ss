(use-composition crewai-research-flow-composition
  (modules
    (use-profile crewai #:as crew))
  (stage production
    (compose
      (profile crew agent)
      (profile crew task)
      (profile crew crew)
      (profile crew sequential-process)
      (profile crew flow-state)
      (profile crew flow-router)
      (profile crew flow-persist)
      (profile crew guardrail)
      (profile crew human-input)
      (profile crew observability)
      (profile crew runtime-handoff))
    (graph crewai-research-flow-graph)
    (loop #:fuel 6 #:exit final-output)
    (prove agent-tool-scope-contained
           task-dependencies-closed
           crew-members-declared
           task-order-respects-dependencies
           router-targets-declared
           checkpoint-before-resume
           guardrail-before-downstream-task
           human-review-before-final-output
           trace-covers-agent-task-flow
           handoff-after-proof-gate)
    (handoff marlin-control-plane)))
