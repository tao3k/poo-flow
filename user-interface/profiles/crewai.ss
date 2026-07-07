(.o (agent
     (.o (name 'crewai-agent)
         (contract 'role-goal-tool-memory-agent)
         (policy 'agent-tool-scope-contained)))
    (task
     (.o (name 'crewai-task)
         (contract 'expected-output-task)
         (policy 'task-dependencies-closed)))
    (crew
     (.o (name 'crewai-crew)
         (contract 'agent-task-team)
         (policy 'crew-members-declared)))
    (planning
     (.o (name 'crewai-planning)
         (contract 'crew-planning-steps)
         (policy 'planning-before-task-dispatch)))
    (memory
     (.o (name 'crewai-memory)
         (contract 'crew-memory-scope)
         (policy 'memory-scope-contained)))
    (knowledge
     (.o (name 'crewai-knowledge)
         (contract 'crew-knowledge-source)
         (policy 'knowledge-sources-declared)))
    (sequential-process
     (.o (name 'crewai-sequential-process)
         (contract 'ordered-task-process)
         (policy 'task-order-respects-dependencies)))
    (hierarchical-process
     (.o (name 'crewai-hierarchical-process)
         (contract 'manager-delegates-to-agents)
         (policy 'delegation-targets-declared)))
    (flow-state
     (.o (name 'crewai-flow-state)
         (contract 'shared-flow-state)
         (policy 'state-updates-owned-by-step)))
    (flow-router
     (.o (name 'crewai-flow-router)
         (contract 'start-listen-router-control)
         (policy 'router-targets-declared)))
    (flow-persist
     (.o (name 'crewai-flow-persist)
         (contract 'persist-resume-flow-state)
         (policy 'checkpoint-before-resume)))
    (guardrail
     (.o (name 'crewai-guardrail)
         (contract 'task-output-guardrail)
         (policy 'guardrail-before-downstream-task)))
    (human-input
     (.o (name 'crewai-human-input)
         (contract 'human-review-trigger)
         (policy 'human-review-before-final-output)))
    (observability
     (.o (name 'crewai-observability)
         (contract 'flow-usage-and-trace)
         (policy 'trace-covers-agent-task-flow)))
    (runtime-handoff
     (.o (name 'crewai-runtime-handoff)
         (contract 'external-runtime-execution)
         (policy 'handoff-after-proof-gate))))
