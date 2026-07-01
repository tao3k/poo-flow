;;; -*- Gerbil -*-
;;; Boundary: user-facing session object module facade.
;;; Invariant: session declarations are report-only until a runtime bridge
;;; consumes their handoff receipts.

(import (only-in :std/sugar filter)
        (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-default-sandbox-profiles)
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/config-prototype-syntax
        :poo-flow/src/module-system/durable-policy
        :poo-flow/src/modules/session/agent
        :poo-flow/src/modules/session/agent-param
        :poo-flow/src/modules/session/communication
        :poo-flow/src/modules/session/materialization
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy
        :poo-flow/src/modules/session/policy-validation
        :poo-flow/src/modules/session/registry
        :poo-flow/src/modules/session/selector
        :poo-flow/src/modules/session/transform)

(export (import: :poo-flow/src/module-system/durable-policy)
        (import: :poo-flow/src/modules/session/agent)
        (import: :poo-flow/src/modules/session/agent-param)
        (import: :poo-flow/src/modules/session/communication)
        (import: :poo-flow/src/modules/session/materialization)
        (import: :poo-flow/src/modules/session/objects)
        (import: :poo-flow/src/modules/session/policy)
        (import: :poo-flow/src/modules/session/policy-validation)
        (import: :poo-flow/src/modules/session/registry)
        (import: :poo-flow/src/modules/session/selector)
        (import: :poo-flow/src/modules/session/transform)
        poo-flow-session-memory-intent
        poo-flow-session-memory-intent?
        poo-flow-session-memory-intent-name
        poo-flow-session-memory-intent-store-ref
        poo-flow-session-memory-intent-scope
        poo-flow-session-memory-intent-recall
        poo-flow-session-memory-intent-commit-policy
        poo-flow-session-memory-intent-runtime-owner
        poo-flow-session-memory-intent-metadata
        +poo-flow-session-core-config-kind+
        session-config
        poo-flow-session-core-poo-config?
        poo-flow-session-core-poo-config->rows
        poo-flow-session-core-poo-configs->rows
        poo-flow-session-core-poo-config-flags
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
        session-agent-param-row
        session-tool-grant
        session-tool-policy
        session-hook-tool-policy
        session-model-policy
        session-prompt-policy
        session-isolation-policy
        session-sandbox-policy
        session-context-policy
        session-history-policy
        session-communication-policy
        session-sharing-policy
        session-resource-policy
        session-resource-sharing-policy
        session-agent-execution-policy
        session-policy-with-durable
        session-policy-row
        session-policy-tool-attempt
        session-policy-validation
        session-policy-validation-row
        session-memory-intent
        session-transform
        transform-session)

;; : (-> List List List)
(def (poo-flow-session-core-config-rows/tail rows tail)
  (let loop ((remaining-rows rows)
             (rows-rev '()))
    (if (null? remaining-rows)
      (let restore ((remaining-rev rows-rev)
                    (result tail))
        (if (null? remaining-rev)
          result
          (restore (cdr remaining-rev)
                   (cons (car remaining-rev) result))))
      (loop (cdr remaining-rows)
            (cons (car remaining-rows) rows-rev)))))

;; : Symbol
(def +poo-flow-session-core-config-kind+ 'poo-flow.session-core.config)

;; : PooSessionCoreConfigPrototype
(defpoo-module-config-prototype
  session-config
  (slots ((kind +poo-flow-session-core-config-kind+)
          (rows '())
          (metadata '())
          (runtime-owner "marlin-agent-core")
          (runtime-executed #f))))

;; : (-> POOObject Boolean)
(defpoo-module-config-kind-predicate
  poo-flow-session-core-poo-config?
  +poo-flow-session-core-config-kind+)

;; : (-> PooSessionCoreConfigPrototype [Alist])
(def (poo-flow-session-core-poo-config->rows config)
  (let (rows (.ref config 'rows))
    (if (list? rows)
      rows
      (error "session-core config rows must be a list" rows))))

;; : (-> [PooSessionCoreConfigPrototype] [Alist])
(def (poo-flow-session-core-poo-configs->rows configs)
  (cond
   ((null? configs) '())
   ((pair? configs)
    (poo-flow-session-core-config-rows/tail
     (poo-flow-session-core-poo-config->rows (car configs))
     (poo-flow-session-core-poo-configs->rows (cdr configs))))
   (else
    (error "session-core POO configs must be a list" configs))))

;; : (-> [POOObject] [UserModuleFlagEntry])
(def (poo-flow-session-core-poo-config-flags prototypes user-config)
  (let* ((configs (filter poo-flow-session-core-poo-config? prototypes))
         (rows (poo-flow-session-core-poo-configs->rows configs)))
    (list '+policy
          '+typed-receipts
          (cons ':config rows)
          (cons ':session-rows rows)
          (cons ':session-config-prototypes configs)
          (cons ':user-config user-config))))

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
   (poo-flow-session-value
    'session-id
    (list (poo-flow-session-chunk 'chunk-id 'role content) ...)
    (poo-flow-session-lineage 'session-id '(parent-id ...) 'branch-kind)
    (poo-flow-session-default-placement
     'profile-ref
     '(metadata-entry ...))
    '(metadata-entry ...)))
  ((_ session-id
      (chunk chunk-id role content)
      ...
      (lineage branch-kind parent-id ...)
      (placement profile-ref))
   (poo-flow-session-value
    'session-id
    (list (poo-flow-session-chunk 'chunk-id 'role content) ...)
    (poo-flow-session-lineage 'session-id '(parent-id ...) 'branch-kind)
    (poo-flow-session-default-placement 'profile-ref))))

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

;; session-tool-grant
;;   : (-> Syntax PooSessionToolGrant)
;;   | doc m%
;;       Tool grants are declaration rows. They name actions, resources, and
;;       triggers only; tool-core owns concrete tool specs.
;;     %
(defrules session-tool-grant ()
  ((_ grant-id tool-ref
      (action ...)
      (resource-ref ...)
      (trigger-ref ...)
      (metadata-entry ...))
   (poo-flow-session-tool-grant
    'grant-id
    'tool-ref
    '(action ...)
    '(resource-ref ...)
    '(trigger-ref ...)
    '(metadata-entry ...))))

;; session-tool-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-tool-policy ()
  ((_ policy-name scope-ref
      (grant ...)
      (denied-tool-ref ...)
      default-action
      (metadata-entry ...))
   (poo-flow-session-tool-permission-policy
    'policy-name
    'scope-ref
    (list grant ...)
    '(denied-tool-ref ...)
    'default-action
    '(metadata-entry ...))))

;; session-hook-tool-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-hook-tool-policy ()
  ((_ policy-name scope-ref
      (hook-event ...)
      (grant ...)
      escalation-policy
      default-action
      (metadata-entry ...))
   (poo-flow-session-hook-tool-permission-policy
    'policy-name
    'scope-ref
    '(hook-event ...)
    (list grant ...)
    'escalation-policy
    'default-action
    '(metadata-entry ...))))

;; session-model-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-model-policy ()
  ((_ policy-name scope-ref provider-ref model-ref
      (model-capability ...)
      budget-ref
      (metadata-entry ...))
   (poo-flow-session-model-policy
    'policy-name
    'scope-ref
    'provider-ref
    'model-ref
    '(model-capability ...)
    'budget-ref
    '(metadata-entry ...))))

;; session-prompt-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-prompt-policy ()
  ((_ policy-name scope-ref prompt-session-ref
      (prompt-chunk-ref ...)
      context-mode
      (metadata-entry ...))
   (poo-flow-session-prompt-policy
    'policy-name
    'scope-ref
    'prompt-session-ref
    '(prompt-chunk-ref ...)
    'context-mode
    '(metadata-entry ...))))

;; session-isolation-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-isolation-policy ()
  ((_ policy-name scope-ref mode sibling-context parent-write
      peer-communication
      (metadata-entry ...))
   (poo-flow-session-isolation-policy
    'policy-name
    'scope-ref
    'mode
    'sibling-context
    'parent-write
    'peer-communication
    '(metadata-entry ...))))

;; session-sandbox-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-sandbox-policy ()
  ((_ policy-name scope-ref profile-ref inheritance-mode sharing-mode
      (metadata-entry ...))
   (poo-flow-session-sandbox-policy
    'policy-name
    'scope-ref
    'profile-ref
    'inheritance-mode
    'sharing-mode
    '(metadata-entry ...))))

;; session-context-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-context-policy ()
  ((_ policy-name scope-ref visibility
      (allowed-session-ref ...)
      (metadata-entry ...))
   (poo-flow-session-context-policy
    'policy-name
    'scope-ref
    'visibility
    '(allowed-session-ref ...)
    '(metadata-entry ...))))

;; session-history-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-history-policy ()
  ((_ policy-name scope-ref retention
      (allowed-record ...)
      (metadata-entry ...))
   (poo-flow-session-history-policy
    'policy-name
    'scope-ref
    'retention
    '(allowed-record ...)
    '(metadata-entry ...))))

;; session-communication-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-communication-policy ()
  ((_ policy-name scope-ref
      (channel-ref ...)
      (target-session-ref ...)
      (metadata-entry ...))
   (poo-flow-session-communication-policy
    'policy-name
    'scope-ref
    '(channel-ref ...)
    '(target-session-ref ...)
    '(metadata-entry ...))))

;; session-sharing-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-sharing-policy ()
  ((_ policy-name scope-ref
      (memory-ref ...)
      (artifact-ref ...)
      (tool-result-ref ...)
      (workspace-path ...)
      (metadata-entry ...))
   (poo-flow-session-sharing-policy
    'policy-name
    'scope-ref
    '(memory-ref ...)
    '(artifact-ref ...)
    '(tool-result-ref ...)
    '(workspace-path ...)
    '(metadata-entry ...))))

;; session-resource-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-resource-policy ()
  ((_ policy-name scope-ref
      (budget-ref ...)
      (capability-ref ...)
      accounting-owner
      (metadata-entry ...))
   (poo-flow-session-resource-policy
    'policy-name
    'scope-ref
    '(budget-ref ...)
    '(capability-ref ...)
    'accounting-owner
    '(metadata-entry ...))))

;; session-resource-sharing-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-resource-sharing-policy ()
  ((_ policy-name scope-ref
      (resource-grant ...)
      default-action
      (metadata-entry ...))
   (poo-flow-session-resource-sharing-policy
    'policy-name
    'scope-ref
    '(resource-grant ...)
    'default-action
    '(metadata-entry ...))))

;; session-agent-execution-policy
;;   : (-> Syntax PooSessionPolicy)
(defrules session-agent-execution-policy ()
  ((_ policy-name agent-ref session-ref model-policy-ref prompt-policy-ref
      tool-policy-ref hook-policy-ref context-policy-ref resource-policy-ref
      (metadata-entry ...))
   (poo-flow-session-agent-execution-policy
    'policy-name
    'agent-ref
    'session-ref
    'model-policy-ref
    'prompt-policy-ref
    'tool-policy-ref
    'hook-policy-ref
    'context-policy-ref
    'resource-policy-ref
    '(metadata-entry ...))))

;; : (-> PooSessionPolicy PooDurablePolicy PooSessionPolicy)
(def (session-policy-with-durable policy durable-policy)
  (poo-flow-session-policy-attach-durable policy durable-policy))

;; : (-> PooSessionPolicy Alist)
(def (session-policy-row policy)
  (poo-flow-session-policy->alist policy))

;; session-policy-tool-attempt
;;   : (-> Syntax PooSessionToolAttempt)
(defrules session-policy-tool-attempt ()
  ((_ attempt-id trigger-ref tool-ref action resource-ref principal-ref
      (metadata-entry ...))
   (poo-flow-session-policy-tool-attempt
    'attempt-id
    'trigger-ref
    'tool-ref
    'action
    'resource-ref
    'principal-ref
    '(metadata-entry ...)))
  ((_ attempt-id trigger-ref tool-ref action resource-ref principal-ref)
   (poo-flow-session-policy-tool-attempt
    'attempt-id
    'trigger-ref
    'tool-ref
    'action
    'resource-ref
    'principal-ref)))

;; session-policy-validation
;;   : (-> Syntax PooSessionPolicyValidationReceipt)
;;   | doc m%
;;       Validation receipts bind effective policy, requested refs, attempts,
;;       and owner metadata. They never execute the allowed operation.
;;     %
(defrules session-policy-validation ()
  ((_ validation-id scope-ref
      model-policy prompt-policy isolation-policy sandbox-policy
      context-policy history-policy communication-policy
      sharing-policy resource-policy agent-tool-policy hook-tool-policy
      (requested-context-ref ...)
      (requested-history-record ...)
      (requested-channel-ref ...)
      (requested-resource-ref ...)
      (agent-tool-attempt ...)
      (hook-tool-attempt ...)
      metadata)
   (poo-flow-session-policy-validation-receipt
    'validation-id
    'scope-ref
    model-policy
    prompt-policy
    isolation-policy
    sandbox-policy
    context-policy
    history-policy
    communication-policy
    sharing-policy
    resource-policy
    agent-tool-policy
    hook-tool-policy
    '(requested-context-ref ...)
    '(requested-history-record ...)
    '(requested-channel-ref ...)
    '(requested-resource-ref ...)
    (list agent-tool-attempt ...)
    (list hook-tool-attempt ...)
    metadata)))

;; : (-> PooSessionPolicyValidationReceipt Alist)
(def (session-policy-validation-row receipt)
  (poo-flow-session-policy-validation-receipt->alist receipt))

;; session-memory-intent
;;   : (-> Syntax PooSessionMemoryIntent)
;;   | doc m%
;;       `session-memory-intent` describes runtime memory recall or commit
;;       requests without reaching into a memory backend from Scheme.
;;
;;       # Examples
;;       ```scheme
;;       (session-memory-intent recall-plan
;;         (store session-store)
;;         (scope current-session)
;;         (recall prior-task)
;;         (commit review-only))
;;       ;; => poo-flow-session-memory-intent
;;       ```
;;     %
(defrules session-memory-intent (store scope recall commit metadata)
  ((_ intent-name
      (store store-ref)
      (scope scope-value)
      (recall recall-key ...)
      (commit commit-policy)
      (metadata metadata-entry ...))
   (poo-flow-session-memory-intent
    'intent-name
    'store-ref
    'scope-value
    '(recall-key ...)
    'commit-policy
    '(metadata-entry ...)))
  ((_ intent-name
      (store store-ref)
      (scope scope-value)
      (recall recall-key ...)
      (commit commit-policy))
   (poo-flow-session-memory-intent
    'intent-name
    'store-ref
    'scope-value
    '(recall-key ...)
    'commit-policy)))

;; session-transform
;;   : (-> Syntax PooSessionTransform)
;;   | doc m%
;;       `session-transform` keeps the agent-flow layer declarative. It creates
;;       a POO transform spec and never invokes a provider.
;;
;;       # Examples
;;       ```scheme
;;       (session-transform review
;;         (intent review-session)
;;         (description "Review the session")
;;         (capabilities search query))
;;       ;; => poo-flow-session-transform
;;       ```
;;     %
(defrules session-transform (intent description capabilities memory-intents metadata)
  ((_ transform-name
      (intent intent-value)
      (description description-value)
      (capabilities capability ...)
      (memory-intents memory-intent ...)
      (metadata metadata-entry ...))
   (poo-flow-session-transform
    'transform-name
    'intent-value
    description-value
    '(capability ...)
    '(metadata-entry ...)
    (list memory-intent ...)))
  ((_ transform-name
      (intent intent-value)
      (description description-value)
      (capabilities capability ...)
      (memory-intents memory-intent ...))
   (poo-flow-session-transform
    'transform-name
    'intent-value
    description-value
    '(capability ...)
    (list memory-intent ...)))
  ((_ transform-name
      (intent intent-value)
      (description description-value)
      (capabilities capability ...)
      (metadata metadata-entry ...))
   (poo-flow-session-transform
    'transform-name
    'intent-value
    description-value
    '(capability ...)
    '(metadata-entry ...)))
  ((_ transform-name
      (intent intent-value)
      (description description-value)
      (capabilities capability ...))
   (poo-flow-session-transform
    'transform-name
    'intent-value
    description-value
    '(capability ...))))

;; transform-session
;;   : (-> Syntax PooSessionTransformReceipt)
;;   | doc m%
;;       `transform-session` derives a new session value and receipt. Runtime
;;       work remains in the handoff intent emitted by the receipt.
;;
;;       # Examples
;;       ```scheme
;;       (transform-session review root-session reviewed-session
;;         (chunk review assistant "Reviewed."))
;;       ;; => poo-flow-session-transform-receipt
;;       ```
;;     %
(defrules transform-session (chunk metadata)
  ((_ transform source-session derived-session-id
      (chunk chunk-id role content)
      ...
      (metadata metadata-entry ...))
   (poo-flow-session-transform-apply
    transform
    source-session
    'derived-session-id
    (list (poo-flow-session-chunk 'chunk-id 'role content) ...)
    '(metadata-entry ...)))
  ((_ transform source-session derived-session-id
      (chunk chunk-id role content)
      ...)
   (poo-flow-session-transform-apply
    transform
    source-session
    'derived-session-id
    (list (poo-flow-session-chunk 'chunk-id 'role content) ...))))
