;;; -*- Gerbil -*-
;;; Boundary: downstream multi-agent session graph case loaded by
;;; custom/my-module/config.ss.
;;; Invariant: this is declarative graph/registry data; message delivery,
;;; providers, tools, and sandbox runtime stay behind Marlin handoff.

(let* ((project-id 'custom/project)
       (root-session
        (poo-flow-session-value
         'custom/root-session
         (list (poo-flow-session-chunk
                'request
                'user
                "Coordinate build and audit sub-agents."))
         (poo-flow-session-lineage 'custom/root-session '() 'root)
         (poo-flow-session-placement 'agent/nono)
         '((source . user-interface)
           (case . session-agent-graph))))
       (build-session
        (poo-flow-session-value
         'custom/build-session
         (list (poo-flow-session-chunk
                'build
                'assistant
                "Run the report-only build verification branch."))
         (poo-flow-session-lineage
          'custom/build-session
          '(custom/root-session)
          'child-agent)
         (poo-flow-session-placement 'agent/nono)
         '((agent . build-agent))))
       (audit-session
        (poo-flow-session-value
         'custom/audit-session
         (list (poo-flow-session-chunk
                'audit
                'assistant
                "Audit the build result through a declared channel."))
         (poo-flow-session-lineage
          'custom/audit-session
          '(custom/root-session)
          'child-agent)
         (poo-flow-session-placement 'agent/nono)
         '((agent . audit-agent))))
       (build-node
        (poo-flow-session-agent-node
         'agent/build
         project-id
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
         'poo-flow.session.agent.build-result.v1))
       (audit-node
        (poo-flow-session-agent-node
         'agent/audit
         project-id
         'custom/root-session
         'custom/root-session
         'custom/audit-system
         'custom/build-session
         'custom/audit-session
         '(custom/build-session)
         '(channel/build-audit)
         'policy/audit-agent-model
         'policy/audit-agent-prompt
         'policy/audit-agent-tools
         'policy/pre-check-hook-tools
         'policy/audit-agent-resources
         'durable/custom-project
         '(read-workspace-file)
         '(session/memory)
         'agent/nono
         'auditor
         'poo-flow.session.agent.audit-result.v1))
       (root-entry
        (poo-flow-session-registry-entry
         root-session
         'agent/root
         '()
         '((isolation . root))))
       (build-entry
        (poo-flow-session-agent-node->registry-entry
         build-node
         build-session))
       (audit-entry
        (poo-flow-session-agent-node->registry-entry
         audit-node
         audit-session))
       (registry
        (poo-flow-session-registry-receipt
         project-id
         '(custom/root-session)
         '(custom/build-session custom/audit-session)
         'custom/root-session
         (list root-entry build-entry audit-entry)))
       (graph
        (poo-flow-session-agent-graph
         project-id
         'custom/root-session
         (list build-node audit-node)
         (list root-session build-session audit-session)
         registry
         '((source . user-interface)
           (case . session-agent-graph))))
       (build-audit-message
        (poo-flow-session-communication-receipt
         project-id
         'sibling
         'custom/root-session
         'custom/root-session
         'custom/build-session
         'custom/audit-session
         'agent/build
         'agent/audit
         'channel/build-audit
         'artifact
         '((artifact . build-report))
         'declared-channel-only
         '((source . user-interface)
           (case . session-agent-graph))))
       (audit-root-message
        (poo-flow-session-communication-receipt
         project-id
         'child-parent
         'custom/root-session
         'custom/root-session
         'custom/audit-session
         'custom/root-session
         'agent/audit
         'agent/root
         'channel/audit-root
         'receipt
         '((receipt . audit-result))
         'receipt-only
         '((source . user-interface)
           (case . session-agent-graph))))
       (communication-rows
        (poo-flow-session-communication-receipts->alists
         (list build-audit-message audit-root-message))))
  (list registry graph build-audit-message audit-root-message communication-rows))
