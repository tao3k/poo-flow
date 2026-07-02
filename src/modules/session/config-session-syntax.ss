;;; -*- Gerbil -*-
;;; Boundary: user-facing session topology facade forms.
;;; Invariant: macros lower to report-only session, registry, communication,
;;; selector, materialization, and agent graph values.

(import (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-default-sandbox-profiles)
        :poo-flow/src/modules/session/agent
        :poo-flow/src/modules/session/agent-param
        :poo-flow/src/modules/session/communication
        :poo-flow/src/modules/session/materialization
        :poo-flow/src/modules/session/objects-core
        :poo-flow/src/modules/session/objects-handoff
        :poo-flow/src/modules/session/objects-graph
        :poo-flow/src/modules/session/registry
        :poo-flow/src/modules/session/selector)

(export (import: :poo-flow/src/modules/session/agent)
        (import: :poo-flow/src/modules/session/agent-param)
        (import: :poo-flow/src/modules/session/communication)
        (import: :poo-flow/src/modules/session/materialization)
        (import: :poo-flow/src/modules/session/objects-core)
        (import: :poo-flow/src/modules/session/objects-handoff)
        (import: :poo-flow/src/modules/session/objects-graph)
        (import: :poo-flow/src/modules/session/registry)
        (import: :poo-flow/src/modules/session/selector)
        poo-flow-session-syntax-chunk
        poo-flow-session-syntax-lineage
        poo-flow-session-syntax-default-placement
        poo-flow-session-syntax-value
        poo-flow-session-default-placement
        session
        session-graph
        session-registry-entry
        session-registry
        session-communication-channel
        session-communication-channel-row
        session-communication-channel-rows
        session-communication
        session-communication-row
        session-communication-rows
        session-selector-candidate
        session-selector
        session-selector-row
        session-materialization
        session-materialization-row
        session-agent-node
        session-agent-node-registry-entry
        session-agent-graph
        session-agent-param-contract
        session-agent-param-row)

;; : (-> Symbol Symbol String Alist)
(def (poo-flow-session-syntax-chunk chunk-id role content)
  (poo-flow-session-chunk chunk-id role content))

;; : (-> Symbol [Symbol] Symbol PooSessionLineage)
(def (poo-flow-session-syntax-lineage session-id parent-session-ids branch-kind)
  (poo-flow-session-lineage session-id parent-session-ids branch-kind))

;; : (-> Symbol [Alist] PooSessionPlacement)
(def (poo-flow-session-syntax-default-placement profile-ref . maybe-metadata)
  (apply poo-flow-session-default-placement profile-ref maybe-metadata))

;; : (-> Symbol [Alist] PooSessionLineage PooSessionPlacement [Alist] PooSessionValue)
(def (poo-flow-session-syntax-value session-id chunks lineage placement . metadata)
  (apply poo-flow-session-value session-id chunks lineage placement metadata))

;;; The default user-facing placement resolves against the maintained sandbox
;;; catalog. It remains report-only and never realizes a runtime descriptor.
;; : (-> Symbol [Alist] PooSessionPlacement)
(def (poo-flow-session-default-placement profile-ref . maybe-metadata)
  (apply poo-flow-session-placement-resolve
         profile-ref
         poo-flow-default-sandbox-profiles
         maybe-metadata))

;; session
;;   : (-> Syntax PooSessionValue)
;;   | doc m%
;;       `session` keeps user-facing session declarations close to the
;;       OpenRath tutorial shape while expanding to ordinary POO session
;;       objects.
;;
;;       # Examples
;;       ```scheme
;;       (session custom/root
;;         (chunk request user "Run checks.")
;;         (lineage root)
;;         (placement agent/nono)
;;         (metadata (source . user-interface)))
;;       ;; => poo-session-value
;;       ```
;;     %
(defrules session (chunk lineage placement metadata)
  ((_ session-id
      (chunk chunk-id role content)
      ...
      (lineage branch-kind parent-id ...)
      (placement profile-ref)
      (metadata metadata-entry ...))
   (poo-flow-session-syntax-value
    'session-id
    (list (poo-flow-session-syntax-chunk 'chunk-id 'role content) ...)
    (poo-flow-session-syntax-lineage
     'session-id
     '(parent-id ...)
     'branch-kind)
    (poo-flow-session-syntax-default-placement
     'profile-ref
     '(metadata-entry ...))
    '(metadata-entry ...)))
  ((_ session-id
      (chunk chunk-id role content)
      ...
      (lineage branch-kind parent-id ...)
      (placement profile-ref))
   (poo-flow-session-syntax-value
    'session-id
    (list (poo-flow-session-syntax-chunk 'chunk-id 'role content) ...)
    (poo-flow-session-syntax-lineage
     'session-id
     '(parent-id ...)
     'branch-kind)
    (poo-flow-session-syntax-default-placement 'profile-ref))))

;; session-graph
;;   : (-> Syntax PooSessionGraphPresentation)
;;   | doc m%
;;       `session-graph` mirrors the declaration form: users list session values
;;       and receive the existing report-only graph receipt.
;;
;;       # Examples
;;       ```scheme
;;       (session-graph root-session branch-session)
;;       ;; => pooFlowSessionGraphPresentation receipt
;;       ```
;;     %
(defrules session-graph ()
  ((_ session-value ...)
   (pooFlowSessionGraphPresentation
    (list session-value ...))))

;; session-registry-entry
;;   : (-> Syntax PooSessionRegistryEntry)
;;   | doc m%
;;       User-facing registry entries describe the session address space without
;;       exposing the lower-level registry constructor.
;;     %
(defrules session-registry-entry (agent channels policies metadata)
  ((_ session-value
      (agent agent-id)
      (channels channel-id ...)
      (policies (policy-kind policy-summary) ...)
      (metadata metadata-entry ...))
   (poo-flow-session-registry-entry
    session-value
    'agent-id
    '(channel-id ...)
    '((policy-kind . policy-summary) ...)
    '(metadata-entry ...)))
  ((_ session-value
      (agent agent-id)
      (channels channel-id ...)
      (policies (policy-kind policy-summary) ...))
   (poo-flow-session-registry-entry
    session-value
    'agent-id
    '(channel-id ...)
    '((policy-kind . policy-summary) ...))))

;; session-registry
;;   : (-> Syntax PooSessionRegistryReceipt)
;;   | doc m%
;;       Registry declarations keep project/root/child topology visible at the
;;       module facade and leave live runtime state to Marlin.
;;     %
(defrules session-registry (roots children active entries metadata)
  ((_ project-id
      (roots root-session-id ...)
      (children child-session-id ...)
      (active active-session-ref)
      (entries entry ...)
      (metadata metadata-entry ...))
   (poo-flow-session-registry-receipt
    'project-id
    '(root-session-id ...)
    '(child-session-id ...)
    'active-session-ref
    (list entry ...)
    '(metadata-entry ...)))
  ((_ project-id
      (roots root-session-id ...)
      (children child-session-id ...)
      (active active-session-ref)
      (entries entry ...))
   (poo-flow-session-registry-receipt
    'project-id
    '(root-session-id ...)
    '(child-session-id ...)
    'active-session-ref
    (list entry ...))))

;; session-communication-channel
;;   : (-> Syntax PooSessionCommunicationChannelReceipt)
;;   | doc m%
;;       Channel declarations are first-class route capability receipts. They
;;       describe which sessions and agents may communicate over a channel,
;;       but Scheme never opens or delivers that channel.
;;     %
(defrules session-communication-channel
  (relation sessions agents messages delivery metadata)
  ((_ project-id channel-id
      (relation relation-kind)
      (sessions source-session-id target-session-id)
      (agents source-agent-id target-agent-id)
      (messages message-kind ...)
      (delivery delivery-policy ...)
      (metadata metadata-entry ...))
   (poo-flow-session-communication-channel-receipt
    'project-id
    'channel-id
    'relation-kind
    'source-session-id
    'target-session-id
    'source-agent-id
    'target-agent-id
    '(message-kind ...)
    '(delivery-policy ...)
    '(metadata-entry ...)))
  ((_ project-id channel-id
      (relation relation-kind)
      (sessions source-session-id target-session-id)
      (agents source-agent-id target-agent-id)
      (messages message-kind ...)
      (delivery delivery-policy ...))
   (poo-flow-session-communication-channel-receipt
    'project-id
    'channel-id
    'relation-kind
    'source-session-id
    'target-session-id
    'source-agent-id
    'target-agent-id
    '(message-kind ...)
    '(delivery-policy ...))))

;; : (-> PooSessionCommunicationChannelReceipt Alist)
(def (session-communication-channel-row receipt)
  (poo-flow-session-communication-channel-receipt->alist receipt))

(defrules session-communication-channel-rows ()
  ((_ receipt ...)
   (poo-flow-session-communication-channel-receipts->alists
    (list receipt ...))))

;; session-communication
;;   : (-> Syntax PooSessionCommunicationReceipt)
;;   | doc m%
;;       Communication declarations are report-only route receipts. They never
;;       deliver messages from Scheme.
;;     %
(defrules session-communication
  (relation roots sessions agents channel message delivery metadata)
  ((_ project-id
      (relation relation-kind)
      (roots source-root-session-id target-root-session-id)
      (sessions source-session-id target-session-id)
      (agents source-agent-id target-agent-id)
      (channel channel-id)
      (message message-kind payload-summary)
      (delivery delivery-policy)
      (metadata metadata-entry ...))
   (poo-flow-session-communication-receipt
    'project-id
    'relation-kind
    'source-root-session-id
    'target-root-session-id
    'source-session-id
    'target-session-id
    'source-agent-id
    'target-agent-id
    'channel-id
    'message-kind
    'payload-summary
    'delivery-policy
    '(metadata-entry ...)))
  ((_ project-id
      (relation relation-kind)
      (roots source-root-session-id target-root-session-id)
      (sessions source-session-id target-session-id)
      (agents source-agent-id target-agent-id)
      (channel channel-id)
      (message message-kind payload-summary)
      (delivery delivery-policy))
   (poo-flow-session-communication-receipt
    'project-id
    'relation-kind
    'source-root-session-id
    'target-root-session-id
    'source-session-id
    'target-session-id
    'source-agent-id
    'target-agent-id
    'channel-id
    'message-kind
    'payload-summary
    'delivery-policy)))

;; session-communication-rows
;;   : (-> Syntax [Alist])
;;   | doc m%
;;       Bounded projection helper for module rows.
;;     %
(def (session-communication-row receipt)
  (poo-flow-session-communication-receipt->alist receipt))

(defrules session-communication-rows ()
  ((_ receipt ...)
   (poo-flow-session-communication-receipts->alists
    (list receipt ...))))

;; session-selector-candidate
;;   : (-> Syntax PooSessionSelectorCandidate)
;;   | doc m%
;;       Selector candidates are declarative routing choices, not model calls.
;;     %
(defrules session-selector-candidate
  (kind target description requires metadata)
  ((_ candidate-id
      (kind candidate-kind)
      (target target-ref)
      (description description-value)
      (requires required-receipt-field ...)
      (metadata metadata-entry ...))
   (poo-flow-session-selector-candidate
    'candidate-id
    'candidate-kind
    'target-ref
    'description-value
    '(required-receipt-field ...)
    '(metadata-entry ...)))
  ((_ candidate-id
      (kind candidate-kind)
      (target target-ref)
      (description description-value)
      (requires required-receipt-field ...))
   (poo-flow-session-selector-candidate
    'candidate-id
    'candidate-kind
    'target-ref
    'description-value
    '(required-receipt-field ...))))

;; session-selector
;;   : (-> Syntax PooSessionSelectorReceipt)
;;   | doc m%
;;       Selector declarations stay pending receipts; scoring and dispatch are
;;       runtime responsibilities.
;;     %
(defrules session-selector
  (project root input candidates policy fallback metadata)
  ((_ selector-id
      (project project-id)
      (root root-session-ref)
      (input input-session-ref)
      (candidates candidate ...)
      (policy policy-entry ...)
      (fallback fallback-ref)
      (metadata metadata-entry ...))
   (poo-flow-session-selector-receipt
    'selector-id
    'project-id
    'root-session-ref
    'input-session-ref
    (list candidate ...)
    '(policy-entry ...)
    'fallback-ref
    '(metadata-entry ...)))
  ((_ selector-id
      (project project-id)
      (root root-session-ref)
      (input input-session-ref)
      (candidates candidate ...)
      (policy policy-entry ...)
      (fallback fallback-ref))
   (poo-flow-session-selector-receipt
    'selector-id
    'project-id
    'root-session-ref
    'input-session-ref
    (list candidate ...)
    '(policy-entry ...)
    'fallback-ref)))

;; : (-> PooSessionSelectorReceipt Alist)
(def (session-selector-row receipt)
  (poo-flow-session-selector-receipt->alist receipt))

;; session-materialization
;;   : (-> Syntax PooSessionMaterializationReceipt)
;;   | doc m%
;;       Materialization rows record runtime handoff state only; they do not
;;       await futures or open sandboxes.
;;     %
(defrules session-materialization
  (project root session parents state pending-runtime sandbox-handle tokens error metadata)
  ((_ request-id
      (project project-id)
      (root root-session-ref)
      (session session-ref)
      (parents parent-session-ref ...)
      (state materialization-state)
      (pending-runtime pending-runtime-ref)
      (sandbox-handle sandbox-handle-ref)
      (tokens token-summary-entry ...)
      (error error-summary)
      (metadata metadata-entry ...))
   (poo-flow-session-runtime-materialization-receipt
    'request-id
    'project-id
    'root-session-ref
    'session-ref
    '(parent-session-ref ...)
    'materialization-state
    'pending-runtime-ref
    'sandbox-handle-ref
    '(token-summary-entry ...)
    'error-summary
    '(metadata-entry ...)))
  ((_ request-id
      (project project-id)
      (root root-session-ref)
      (session session-ref)
      (parents parent-session-ref ...)
      (state materialization-state)
      (pending-runtime pending-runtime-ref)
      (sandbox-handle sandbox-handle-ref)
      (tokens token-summary-entry ...)
      (error error-summary))
   (poo-flow-session-runtime-materialization-receipt
    'request-id
    'project-id
    'root-session-ref
    'session-ref
    '(parent-session-ref ...)
    'materialization-state
    'pending-runtime-ref
    'sandbox-handle-ref
    '(token-summary-entry ...)
    'error-summary)))

;; : (-> PooSessionMaterializationReceipt Alist)
(def (session-materialization-row receipt)
  (poo-flow-session-materialization-receipt->alist receipt))

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
   (poo-flow-session-agent-node
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
   (poo-flow-session-agent-node
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
(def (session-agent-node-registry-entry node session-value)
  (poo-flow-session-agent-node->registry-entry node session-value))

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
   (poo-flow-session-agent-graph
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
   (poo-flow-session-agent-graph
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
   (poo-flow-session-agent-param-contract
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
   (poo-flow-session-agent-param-contract
    'contract-id
    agent-node
    validation-receipt
    'provider-ref
    'streaming-policy
    'event-policy)))

;; : (-> PooSessionAgentParamContract Alist)
(def (session-agent-param-row contract)
  (poo-flow-session-agent-param-contract->alist contract))
