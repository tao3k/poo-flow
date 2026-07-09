;;; -*- Gerbil -*-
;;; Boundary: runtime helpers for user-facing session topology syntax.
;;; Invariant: syntax modules expand to these pure constructors, not directly
;;; to the wider session object graph.

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

(export poo-flow-session-syntax-chunk
        poo-flow-session-syntax-lineage
        poo-flow-session-syntax-default-placement
        poo-flow-session-syntax-value
        poo-flow-session-default-placement
        poo-flow-session-syntax-graph-presentation
        poo-flow-session-syntax-registry-entry
        poo-flow-session-syntax-registry
        session-communication-channel-row
        poo-flow-session-syntax-communication-channel-rows
        poo-flow-session-syntax-communication-channel
        session-communication-row
        poo-flow-session-syntax-communication-rows
        poo-flow-session-syntax-communication
        poo-flow-session-syntax-selector-candidate
        session-selector-row
        poo-flow-session-syntax-selector
        session-materialization-row
        poo-flow-session-syntax-materialization
        poo-flow-session-syntax-agent-node
        session-agent-node-registry-entry
        poo-flow-session-syntax-agent-graph
        poo-flow-session-syntax-agent-param-contract
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

;; : (-> [PooSessionValue] PooSessionGraphPresentation)
(def (poo-flow-session-syntax-graph-presentation session-values)
  (pooFlowSessionGraphPresentation session-values))

;; : (-> PooSession Symbol [Symbol] Alist [Alist] PooSessionRegistryEntry)
(def (poo-flow-session-syntax-registry-entry session-value
                                             agent-id
                                             channel-ids
                                             policies
                                             .
                                             maybe-metadata)
  (apply poo-flow-session-registry-entry
         session-value
         agent-id
         channel-ids
         policies
         maybe-metadata))

;; : (-> Symbol [Symbol] [Symbol] Symbol [PooSessionRegistryEntry] [Alist] PooSessionRegistryReceipt)
(def (poo-flow-session-syntax-registry project-id
                                       root-session-ids
                                       child-session-ids
                                       active-session-ref
                                       entries
                                       .
                                       maybe-metadata)
  (apply poo-flow-session-registry-receipt
         project-id
         root-session-ids
         child-session-ids
         active-session-ref
         entries
         maybe-metadata))

;; : (-> PooSessionCommunicationChannelReceipt Alist)
(def (session-communication-channel-row receipt)
  (poo-flow-session-communication-channel-receipt->alist receipt))

;; : (-> [PooSessionCommunicationChannelReceipt] [Alist])
(def (poo-flow-session-syntax-communication-channel-rows receipts)
  (poo-flow-session-communication-channel-receipts->alists receipts))

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol Symbol [Symbol] [Symbol] [Alist] PooSessionCommunicationChannelReceipt)
(def (poo-flow-session-syntax-communication-channel project-id
                                                    channel-id
                                                    relation-kind
                                                    source-session-id
                                                    target-session-id
                                                    source-agent-id
                                                    target-agent-id
                                                    message-kinds
                                                    delivery-policies
                                                    .
                                                    maybe-metadata)
  (apply poo-flow-session-communication-channel-receipt
         project-id
         channel-id
         relation-kind
         source-session-id
         target-session-id
         source-agent-id
         target-agent-id
         message-kinds
         delivery-policies
         maybe-metadata))

;; : (-> PooSessionCommunicationReceipt Alist)
(def (session-communication-row receipt)
  (poo-flow-session-communication-receipt->alist receipt))

;; : (-> [PooSessionCommunicationReceipt] [Alist])
(def (poo-flow-session-syntax-communication-rows receipts)
  (poo-flow-session-communication-receipts->alists receipts))

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol Symbol Symbol Symbol Symbol Symbol Symbol [Alist] PooSessionCommunicationReceipt)
(def (poo-flow-session-syntax-communication project-id
                                            relation-kind
                                            source-root-session-id
                                            target-root-session-id
                                            source-session-id
                                            target-session-id
                                            source-agent-id
                                            target-agent-id
                                            channel-id
                                            message-kind
                                            payload-summary
                                            delivery-policy
                                            .
                                            maybe-metadata)
  (apply poo-flow-session-communication-receipt
         project-id
         relation-kind
         source-root-session-id
         target-root-session-id
         source-session-id
         target-session-id
         source-agent-id
         target-agent-id
         channel-id
         message-kind
         payload-summary
         delivery-policy
         maybe-metadata))

;; : (-> Symbol Symbol Symbol Symbol [Symbol] [Alist] PooSessionSelectorCandidate)
(def (poo-flow-session-syntax-selector-candidate candidate-id
                                                 candidate-kind
                                                 target-ref
                                                 description-value
                                                 required-receipt-fields
                                                 .
                                                 maybe-metadata)
  (apply poo-flow-session-selector-candidate
         candidate-id
         candidate-kind
         target-ref
         description-value
         required-receipt-fields
         maybe-metadata))

;; : (-> PooSessionSelectorReceipt Alist)
(def (session-selector-row receipt)
  (poo-flow-session-selector-receipt->alist receipt))

;; : (-> Symbol Symbol Symbol Symbol [PooSessionSelectorCandidate] Alist Symbol [Alist] PooSessionSelectorReceipt)
(def (poo-flow-session-syntax-selector selector-id
                                       project-id
                                       root-session-ref
                                       input-session-ref
                                       candidates
                                       policy
                                       fallback-ref
                                       .
                                       maybe-metadata)
  (apply poo-flow-session-selector-receipt
         selector-id
         project-id
         root-session-ref
         input-session-ref
         candidates
         policy
         fallback-ref
         maybe-metadata))

;; : (-> PooSessionMaterializationReceipt Alist)
(def (session-materialization-row receipt)
  (poo-flow-session-materialization-receipt->alist receipt))

;; : (-> Symbol Symbol Symbol Symbol [Symbol] Symbol Symbol Symbol Alist Symbol [Alist] PooSessionMaterializationReceipt)
(def (poo-flow-session-syntax-materialization request-id
                                             project-id
                                             root-session-ref
                                             session-ref
                                             parent-session-refs
                                             materialization-state
                                             pending-runtime-ref
                                             sandbox-handle-ref
                                             token-summary-entries
                                             error-summary
                                             .
                                             maybe-metadata)
  (apply poo-flow-session-runtime-materialization-receipt
         request-id
         project-id
         root-session-ref
         session-ref
         parent-session-refs
         materialization-state
         pending-runtime-ref
         sandbox-handle-ref
         token-summary-entries
         error-summary
         maybe-metadata))

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol Symbol [Symbol] [Symbol] Symbol Symbol Symbol Symbol Symbol Symbol [Symbol] [Symbol] Symbol Symbol Symbol [Alist] PooSessionAgentNode)
(def (poo-flow-session-syntax-agent-node agent-id
                                        project-ref
                                        root-session-ref
                                        parent-session-ref
                                        agent-system-session-ref
                                        input-session-ref
                                        output-session-ref
                                        peer-session-refs
                                        communication-channels
                                        model-policy-ref
                                        prompt-policy-ref
                                        tool-permission-policy-ref
                                        hook-tool-permission-policy-ref
                                        resource-sharing-policy-ref
                                        durable-policy-ref
                                        tool-refs
                                        memory-refs
                                        sandbox-profile-ref
                                        role-value
                                        result-contract
                                        .
                                        maybe-metadata)
  (apply poo-flow-session-agent-node
         agent-id
         project-ref
         root-session-ref
         parent-session-ref
         agent-system-session-ref
         input-session-ref
         output-session-ref
         peer-session-refs
         communication-channels
         model-policy-ref
         prompt-policy-ref
         tool-permission-policy-ref
         hook-tool-permission-policy-ref
         resource-sharing-policy-ref
         durable-policy-ref
         tool-refs
         memory-refs
         sandbox-profile-ref
         role-value
         result-contract
         maybe-metadata))

;; : (-> PooSessionAgentNode PooSession PooSessionRegistryEntry)
(def (session-agent-node-registry-entry node session-value)
  (poo-flow-session-agent-node->registry-entry node session-value))

;; : (-> Alist Symbol Object Object)
(def (poo-flow-session-syntax-agent-graph-metadata-ref metadata
                                                        key
                                                        default-value)
  (if (list? metadata)
    (let (entry (assoc key metadata))
      (if entry (cdr entry) default-value))
    default-value))

;; : (-> [Object] Alist Alist)
(def (poo-flow-session-syntax-agent-graph-topology-metadata agent-nodes
                                                            metadata)
  (let (channel-receipts
        (poo-flow-session-syntax-agent-graph-metadata-ref
         metadata
         'communication-channel-receipts
         '()))
    (poo-flow-session-topology->handoff-metadata
     (list
      (cons 'agent-registered?
            (and (pair? agent-nodes) #t))
      (cons 'subagent-registered?
            (and (pair? agent-nodes)
                 (pair? (cdr agent-nodes))
                 #t))
      (cons 'channel-authorized?
            (and (pair? channel-receipts) #t)))
     metadata)))

;; : (-> Symbol Symbol [PooSessionAgentNode] [PooSession] PooSessionRegistryReceipt [PooSessionCommunicationReceipt] [Alist] PooSessionAgentGraph)
(def (poo-flow-session-syntax-agent-graph project-id
                                          root-session-ref
                                          agent-nodes
                                          session-values
                                          registry-receipt
                                          communication-receipts
                                          .
                                          maybe-metadata)
  (let* ((metadata (if (null? maybe-metadata)
                     '()
                     (car maybe-metadata)))
         (handoff-metadata
          (poo-flow-session-syntax-agent-graph-topology-metadata
           agent-nodes
           metadata)))
    (poo-flow-session-agent-graph
     project-id
     root-session-ref
     agent-nodes
     session-values
     registry-receipt
     communication-receipts
     handoff-metadata)))

;; : (-> Symbol PooSessionAgentNode PooSessionAgentParamValidationReceipt Symbol Symbol Symbol [Alist] PooSessionAgentParamContract)
(def (poo-flow-session-syntax-agent-param-contract contract-id
                                                   agent-node
                                                   validation-receipt
                                                   provider-ref
                                                   streaming-policy
                                                   event-policy
                                                   .
                                                   maybe-metadata)
  (apply poo-flow-session-agent-param-contract
         contract-id
         agent-node
         validation-receipt
         provider-ref
         streaming-policy
         event-policy
         maybe-metadata))

;; : (-> PooSessionAgentParamContract Alist)
(def (session-agent-param-row contract)
  (poo-flow-session-agent-param-contract->alist contract))
