;;; -*- Gerbil -*-
;;; Boundary: downstream AgentParam contract case loaded by
;;; custom/my-module/config.ss.
;;; Invariant: this binds session topology to effective policy validation;
;;; provider, tool, memory, stream, and sandbox runtime stay behind Marlin.

(let* ((read-grant
        (poo-flow-session-tool-grant
         'grant/agent-param-read
         'read-workspace-file
         '(read)
         '(project-workspace)
         '(agent-turn hook/pre-check)))
       (build-grant
        (poo-flow-session-tool-grant
         'grant/agent-param-build
         'run-build-command
         '(run)
         '(project-workspace build-cache)
         '(agent-turn)))
       (build-node
        (poo-flow-session-agent-node
         'agent/build
         'custom/project
         'custom/root-session
         'custom/root-session
         'custom/build-system
         'custom/root-session
         'custom/build-session
         '(custom/audit-session)
         '(channel/build-audit)
         'policy/build-agent-model
         'policy/build-agent-prompt
         'policy/build-agent-tools
         'policy/pre-check-hook-tools
         'policy/build-agent-resources
         'durable/custom-project
         '(read-workspace-file run-build-command)
         '(session/memory)
         'agent/nono
         'builder
         'poo-flow.session.agent.build-result.v1
         '((source . user-interface)
           (case . session-agent-param))))
       (model-policy
        (poo-flow-session-model-policy
         'policy/build-agent-model
         'custom/build-session
         'marlin/provider
         'marlin/model/build-review
         '(tool-calling structured-output)
         'budget/build-agent))
       (prompt-policy
        (poo-flow-session-prompt-policy
         'policy/build-agent-prompt
         'custom/build-session
         'custom/build-system
         '(system-instruction build-contract)
         'parent-summary-only))
       (context-policy
        (poo-flow-session-context-policy
         'policy/build-agent-context
         'custom/build-session
         'parent-summary
         '(custom/root-session)))
       (history-policy
        (poo-flow-session-history-policy
         'policy/build-agent-history
         'custom/build-session
         'bounded
         '(record/last-failure)))
       (communication-policy
        (poo-flow-session-communication-policy
         'policy/build-agent-communication
         'custom/build-session
         '(channel/build-root)
         '(custom/root-session)))
       (sharing-policy
        (poo-flow-session-resource-sharing-policy
         'policy/build-agent-resources
         'custom/build-session
         '((project-workspace
            (access . read)
            (accounting . custom/root-session))
           (build-cache
            (access . read-write)
            (accounting . custom/build-session)))
         'deny))
       (resource-policy
        (poo-flow-session-resource-policy
         'policy/build-agent-capabilities
         'custom/build-session
         '(budget/build-agent)
         '(project-workspace build-cache)
         'custom/build-session))
       (agent-tool-policy
        (poo-flow-session-tool-permission-policy
         'policy/build-agent-tools
         'custom/build-session
         (list read-grant build-grant)
         '(write-workspace-file)
         'deny))
       (hook-tool-policy
        (poo-flow-session-hook-tool-permission-policy
         'policy/pre-check-hook-tools
         'custom/build-session
         '(hook/pre-check)
         (list read-grant)
         'human-approval-on-escalation
         'deny))
       (validation
        (poo-flow-session-policy-validation-receipt
         'validation/custom-agent-param
         'custom/build-session
         model-policy
         prompt-policy
         context-policy
         history-policy
         communication-policy
         sharing-policy
         resource-policy
         agent-tool-policy
         hook-tool-policy
         '(custom/root-session)
         '(record/last-failure)
         '(channel/build-root)
         '(project-workspace build-cache)
         (list
          (poo-flow-session-policy-tool-attempt
           'attempt/custom-agent-param-build
           'agent-turn
           'run-build-command
           'run
           'build-cache
           'agent/build))
         (list
          (poo-flow-session-policy-tool-attempt
           'attempt/custom-agent-param-hook-read
           'hook/pre-check
           'read-workspace-file
           'read
           'project-workspace
           'hook/pre-check))
         '((source . user-interface)
           (case . session-agent-param))))
       (contract
        (poo-flow-session-agent-param-contract
         'agent-param/custom-build
         build-node
         validation
         'marlin/provider
         'streaming-disabled
         'events-receipt-only
         '((source . user-interface)
           (case . session-agent-param)))))
  (poo-flow-session-agent-param-contract->alist contract))
