;;; -*- Gerbil -*-
;;; Boundary: POO-native AgentParam contract objects.
;;; Invariant: AgentParam contracts bind agent topology to effective policy
;;; validation; they never run providers, tools, memory stores, or streams.

(import (only-in :clan/poo/object .ref object? object<-alist)
        :poo-flow/src/modules/session/agent
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy-validation
        :poo-flow/src/modules/session/receipt-syntax)

(export poo-flow-session-agent-param-contract
        poo-flow-session-agent-param-contract?
        poo-flow-session-agent-param-contract-id
        poo-flow-session-agent-param-contract-agent-id
        poo-flow-session-agent-param-contract-provider-ref
        poo-flow-session-agent-param-contract-effective-model-ref
        poo-flow-session-agent-param-contract-validation-valid?
        poo-flow-session-agent-param-contract->alist)

;; : (-> POOObject Symbol Value Value)
(def (poo-flow-session-agent-param-slot object key default)
  (with-catch
   (lambda (_failure) default)
   (lambda ()
     (.ref object key))))

;; : (-> Symbol PooSessionAgentNode PooSessionPolicyValidationReceipt Symbol Symbol Symbol [Alist] PooSessionAgentParamContract)
(def (poo-flow-session-agent-param-contract contract-id
                                            agent-node
                                            validation-receipt
                                            provider-ref
                                            streaming-policy
                                            event-policy
                                            . maybe-metadata)
  (poo-flow-session-require "session AgentParam contract id must be a symbol"
                            (symbol? contract-id)
                            contract-id)
  (poo-flow-session-require "session AgentParam requires an agent node"
                            (poo-flow-session-agent-node? agent-node)
                            agent-node)
  (poo-flow-session-require
   "session AgentParam requires a policy validation receipt"
   (poo-flow-session-policy-validation-receipt? validation-receipt)
   validation-receipt)
  (poo-flow-session-require "session AgentParam provider ref must be a symbol"
                            (symbol? provider-ref)
                            provider-ref)
  (poo-flow-session-require "session AgentParam streaming policy must be a symbol"
                            (symbol? streaming-policy)
                            streaming-policy)
  (poo-flow-session-require "session AgentParam event policy must be a symbol"
                            (symbol? event-policy)
                            event-policy)
  (object<-alist
   (list
    (cons 'kind 'poo-flow.session.agent-param-contract)
    (cons 'schema 'poo-flow.modules.session.agent-param-contract.v1)
    (cons 'contract-id contract-id)
    (cons 'project-ref (.ref agent-node 'project-ref))
    (cons 'agent-id
          (poo-flow-session-agent-node-agent-id agent-node))
    (cons 'root-session-ref (.ref agent-node 'root-session-ref))
    (cons 'parent-session-ref
          (poo-flow-session-agent-node-parent-session-ref agent-node))
    (cons 'agent-system-session-ref
          (.ref agent-node 'agent-system-session-ref))
    (cons 'input-session-ref (.ref agent-node 'input-session-ref))
    (cons 'output-session-ref
          (poo-flow-session-agent-node-output-session-ref agent-node))
    (cons 'provider-ref provider-ref)
    (cons 'effective-model-ref
          (.ref validation-receipt 'effective-model-ref))
    (cons 'effective-prompt-session-ref
          (.ref validation-receipt 'effective-prompt-session-ref))
    (cons 'effective-prompt-chunk-refs
          (.ref validation-receipt 'effective-prompt-chunk-refs))
    (cons 'model-policy-ref (.ref agent-node 'model-policy-ref))
    (cons 'prompt-policy-ref (.ref agent-node 'prompt-policy-ref))
    (cons 'tool-permission-policy-ref
          (.ref agent-node 'tool-permission-policy-ref))
    (cons 'hook-tool-permission-policy-ref
          (.ref agent-node 'hook-tool-permission-policy-ref))
    (cons 'resource-sharing-policy-ref
          (.ref agent-node 'resource-sharing-policy-ref))
    (cons 'durable-policy-ref
          (poo-flow-session-agent-node-durable-policy-ref agent-node))
    (cons 'tool-refs (.ref agent-node 'tool-refs))
    (cons 'memory-refs (.ref agent-node 'memory-refs))
    (cons 'sandbox-profile-ref (.ref agent-node 'sandbox-profile-ref))
    (cons 'streaming-policy streaming-policy)
    (cons 'event-policy event-policy)
    (cons 'validation-id (.ref validation-receipt 'validation-id))
    (cons 'validation-valid?
          (poo-flow-session-policy-validation-receipt-valid?
           validation-receipt))
    (cons 'validation-diagnostic-count
          (.ref validation-receipt 'diagnostic-count))
    (cons 'runtime-owner "marlin-agent-core")
    (cons 'runtime-executed #f)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata))))))

;; : (-> POOObject Boolean)
(def (poo-flow-session-agent-param-contract? value)
  (and (object? value)
       (eq? (poo-flow-session-agent-param-slot value 'kind #f)
            'poo-flow.session.agent-param-contract)))

;; : (-> PooSessionAgentParamContract Symbol)
(def (poo-flow-session-agent-param-contract-id contract)
  (.ref contract 'contract-id))

;; : (-> PooSessionAgentParamContract Symbol)
(def (poo-flow-session-agent-param-contract-agent-id contract)
  (.ref contract 'agent-id))

;; : (-> PooSessionAgentParamContract Symbol)
(def (poo-flow-session-agent-param-contract-provider-ref contract)
  (.ref contract 'provider-ref))

;; : (-> PooSessionAgentParamContract Symbol)
(def (poo-flow-session-agent-param-contract-effective-model-ref contract)
  (.ref contract 'effective-model-ref))

;; : (-> PooSessionAgentParamContract Boolean)
(def (poo-flow-session-agent-param-contract-validation-valid? contract)
  (.ref contract 'validation-valid?))

;; : (-> PooSessionAgentParamContract Alist)
(defpoo-session-receipt-projection
  poo-flow-session-agent-param-contract->alist
  (contract)
  (require poo-flow-session-require
           "session AgentParam projection requires an AgentParam contract"
           (poo-flow-session-agent-param-contract? contract)
           contract)
  (bindings ())
  (fields
   (('kind (.ref contract 'kind))
    ('schema (.ref contract 'schema))
    ('contract-id (.ref contract 'contract-id))
    ('project-ref (.ref contract 'project-ref))
    ('agent-id (.ref contract 'agent-id))
    ('root-session-ref (.ref contract 'root-session-ref))
    ('parent-session-ref (.ref contract 'parent-session-ref))
    ('agent-system-session-ref (.ref contract 'agent-system-session-ref))
    ('input-session-ref (.ref contract 'input-session-ref))
    ('output-session-ref (.ref contract 'output-session-ref))
    ('provider-ref (.ref contract 'provider-ref))
    ('effective-model-ref (.ref contract 'effective-model-ref))
    ('effective-prompt-session-ref
     (.ref contract 'effective-prompt-session-ref))
    ('effective-prompt-chunk-refs
     (.ref contract 'effective-prompt-chunk-refs))
    ('model-policy-ref (.ref contract 'model-policy-ref))
    ('prompt-policy-ref (.ref contract 'prompt-policy-ref))
    ('tool-permission-policy-ref
     (.ref contract 'tool-permission-policy-ref))
    ('hook-tool-permission-policy-ref
     (.ref contract 'hook-tool-permission-policy-ref))
    ('resource-sharing-policy-ref
     (.ref contract 'resource-sharing-policy-ref))
    ('durable-policy-ref (.ref contract 'durable-policy-ref))
    ('tool-refs (.ref contract 'tool-refs))
    ('memory-refs (.ref contract 'memory-refs))
    ('sandbox-profile-ref (.ref contract 'sandbox-profile-ref))
    ('streaming-policy (.ref contract 'streaming-policy))
    ('event-policy (.ref contract 'event-policy))
    ('validation-id (.ref contract 'validation-id))
    ('validation-valid? (.ref contract 'validation-valid?))
    ('validation-diagnostic-count
     (.ref contract 'validation-diagnostic-count))
    ('runtime-owner (.ref contract 'runtime-owner))
    ('runtime-executed (.ref contract 'runtime-executed))
    ('metadata (.ref contract 'metadata)))))
