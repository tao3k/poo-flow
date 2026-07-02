(import :poo-flow/src/modules/session/config-session-runtime)

(export session-agent-node
        session-agent-graph
        session-agent-param-contract)

;; session-agent-node
;;   : (-> Syntax PooSessionAgentNode)
;;   | doc m%
;;       Agent nodes bind session topology to policy refs without dispatching
;;       providers, tools, memory, or sandboxes.
;;     %
(defrules session-agent-node
  (project root parent system input output peers channels model prompt tools hook-tools resources durable tool-refs memory sandbox role result metadata)
  ((_ agent-id
      (project project-ref)
      (root root-session-ref)
      (parent parent-session-ref)
      (system agent-system-session-ref)
      (input input-session-ref)
      (output output-session-ref)
      (peers peer-session-ref ...)
      (channels communication-channel ...)
      (model model-policy-ref)
      (prompt prompt-policy-ref)
      (tools tool-permission-policy-ref)
      (hook-tools hook-tool-permission-policy-ref)
      (resources resource-sharing-policy-ref)
      (durable durable-policy-ref)
      (tool-refs tool-ref ...)
      (memory memory-ref ...)
      (sandbox sandbox-profile-ref)
      (role role-value)
      (result result-contract)
      (metadata metadata-entry ...))
   (poo-flow-session-syntax-agent-node
    'agent-id
    'project-ref
    'root-session-ref
    'parent-session-ref
    'agent-system-session-ref
    'input-session-ref
    'output-session-ref
    '(peer-session-ref ...)
    '(communication-channel ...)
    'model-policy-ref
    'prompt-policy-ref
    'tool-permission-policy-ref
    'hook-tool-permission-policy-ref
    'resource-sharing-policy-ref
    'durable-policy-ref
    '(tool-ref ...)
    '(memory-ref ...)
    'sandbox-profile-ref
    'role-value
    'result-contract
    '(metadata-entry ...)))
  ((_ agent-id
      (project project-ref)
      (root root-session-ref)
      (parent parent-session-ref)
      (system agent-system-session-ref)
      (input input-session-ref)
      (output output-session-ref)
      (peers peer-session-ref ...)
      (channels communication-channel ...)
      (model model-policy-ref)
      (prompt prompt-policy-ref)
      (tools tool-permission-policy-ref)
      (hook-tools hook-tool-permission-policy-ref)
      (resources resource-sharing-policy-ref)
      (durable durable-policy-ref)
      (tool-refs tool-ref ...)
      (memory memory-ref ...)
      (sandbox sandbox-profile-ref)
      (role role-value)
      (result result-contract))
   (poo-flow-session-syntax-agent-node
    'agent-id
    'project-ref
    'root-session-ref
    'parent-session-ref
    'agent-system-session-ref
    'input-session-ref
    'output-session-ref
    '(peer-session-ref ...)
    '(communication-channel ...)
    'model-policy-ref
    'prompt-policy-ref
    'tool-permission-policy-ref
    'hook-tool-permission-policy-ref
    'resource-sharing-policy-ref
    'durable-policy-ref
    '(tool-ref ...)
    '(memory-ref ...)
    'sandbox-profile-ref
    'role-value
    'result-contract)))

;; : (-> PooSessionAgentNode PooSession PooSessionRegistryEntry)
;; session-agent-graph
;;   : (-> Syntax PooSessionAgentGraph)
;;   | doc m%
;;       Graph rows compose sessions, agent nodes, registry receipts, and
;;       communication receipts into one report-only topology object.
;;     %
(defrules session-agent-graph ()
  ((_ project-id
      root-session-ref
      agent-nodes
      session-values
      registry-receipt
      communication-receipts
      metadata)
   (poo-flow-session-syntax-agent-graph
    'project-id
    'root-session-ref
    agent-nodes
    session-values
    registry-receipt
    communication-receipts
    metadata))
  ((_ project-id
      root-session-ref
      agent-nodes
      session-values
      registry-receipt
      communication-receipts)
   (poo-flow-session-syntax-agent-graph
    'project-id
    'root-session-ref
    agent-nodes
    session-values
    registry-receipt
    communication-receipts)))

;; session-agent-param-contract
;;   : (-> Syntax PooSessionAgentParamContract)
;;   | doc m%
;;       AgentParam declarations bind an agent node to validated effective
;;       policy without starting a provider or stream.
;;     %
(defrules session-agent-param-contract ()
  ((_ contract-id
      agent-node
      validation-receipt
      provider-ref
      streaming-policy
      event-policy
      metadata)
   (poo-flow-session-syntax-agent-param-contract
    'contract-id
    agent-node
    validation-receipt
    'provider-ref
    'streaming-policy
    'event-policy
    metadata))
  ((_ contract-id
      agent-node
      validation-receipt
      provider-ref
      streaming-policy
      event-policy)
   (poo-flow-session-syntax-agent-param-contract
    'contract-id
    agent-node
    validation-receipt
    'provider-ref
    'streaming-policy
    'event-policy)))

;; : (-> PooSessionAgentParamContract Alist)
