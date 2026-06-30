;;; -*- Gerbil -*-
;;; Boundary: report-only multi-agent session topology objects.
;;; Invariant: agent topology names sessions, policies, and channels; it never
;;; dispatches providers, tools, memory stores, or messages.

(import (only-in :clan/poo/object .ref object? object<-alist)
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/registry)

(export poo-flow-session-agent-node
        poo-flow-session-agent-node?
        poo-flow-session-agent-node-agent-id
        poo-flow-session-agent-node-output-session-ref
        poo-flow-session-agent-node-parent-session-ref
        poo-flow-session-agent-node-durable-policy-ref
        poo-flow-session-agent-node->alist
        poo-flow-session-agent-node->registry-entry
        poo-flow-session-agent-graph
        poo-flow-session-agent-graph?
        poo-flow-session-agent-graph-agent-ids
        poo-flow-session-agent-graph-session-ids
        poo-flow-session-agent-graph-registry-receipt
        poo-flow-session-agent-graph->alist)

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol Symbol [Symbol] [Symbol] Symbol Symbol Symbol Symbol Symbol Symbol [Symbol] [Symbol] Symbol Symbol Symbol [Alist] PooSessionAgentNode)
(def (poo-flow-session-agent-node agent-id
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
                                  role
                                  result-contract
                                  . maybe-metadata)
  (poo-flow-session-require "session agent id must be a symbol"
                            (symbol? agent-id)
                            agent-id)
  (poo-flow-session-require "session agent project ref must be a symbol"
                            (symbol? project-ref)
                            project-ref)
  (poo-flow-session-require "session agent root ref must be a symbol"
                            (symbol? root-session-ref)
                            root-session-ref)
  (poo-flow-session-require "session agent parent ref must be a symbol"
                            (symbol? parent-session-ref)
                            parent-session-ref)
  (poo-flow-session-require "session agent system ref must be a symbol"
                            (symbol? agent-system-session-ref)
                            agent-system-session-ref)
  (poo-flow-session-require "session agent input ref must be a symbol"
                            (symbol? input-session-ref)
                            input-session-ref)
  (poo-flow-session-require "session agent output ref must be a symbol"
                            (symbol? output-session-ref)
                            output-session-ref)
  (poo-flow-session-require "session agent peer refs must be symbols"
                            (poo-flow-session-every? symbol?
                                                     peer-session-refs)
                            peer-session-refs)
  (poo-flow-session-require "session agent channels must be symbols"
                            (poo-flow-session-every?
                             symbol?
                             communication-channels)
                            communication-channels)
  (poo-flow-session-require "session agent model policy ref must be a symbol"
                            (symbol? model-policy-ref)
                            model-policy-ref)
  (poo-flow-session-require "session agent prompt policy ref must be a symbol"
                            (symbol? prompt-policy-ref)
                            prompt-policy-ref)
  (poo-flow-session-require "session agent tool policy ref must be a symbol"
                            (symbol? tool-permission-policy-ref)
                            tool-permission-policy-ref)
  (poo-flow-session-require "session agent hook policy ref must be a symbol"
                            (symbol? hook-tool-permission-policy-ref)
                            hook-tool-permission-policy-ref)
  (poo-flow-session-require "session agent resource policy ref must be a symbol"
                            (symbol? resource-sharing-policy-ref)
                            resource-sharing-policy-ref)
  (poo-flow-session-require "session agent durable policy ref must be a symbol"
                            (symbol? durable-policy-ref)
                            durable-policy-ref)
  (poo-flow-session-require "session agent tool refs must be symbols"
                            (poo-flow-session-every? symbol? tool-refs)
                            tool-refs)
  (poo-flow-session-require "session agent memory refs must be symbols"
                            (poo-flow-session-every? symbol? memory-refs)
                            memory-refs)
  (poo-flow-session-require "session agent sandbox profile ref must be a symbol"
                            (symbol? sandbox-profile-ref)
                            sandbox-profile-ref)
  (poo-flow-session-require "session agent role must be a symbol"
                            (symbol? role)
                            role)
  (poo-flow-session-require "session agent result contract must be a symbol"
                            (symbol? result-contract)
                            result-contract)
  (object<-alist
   (list
    (cons 'kind 'poo-flow.session.agent-node)
    (cons 'schema 'poo-flow.modules.session.agent-node.v1)
    (cons 'agent-id agent-id)
    (cons 'project-ref project-ref)
    (cons 'root-session-ref root-session-ref)
    (cons 'parent-session-ref parent-session-ref)
    (cons 'agent-system-session-ref agent-system-session-ref)
    (cons 'input-session-ref input-session-ref)
    (cons 'output-session-ref output-session-ref)
    (cons 'peer-session-refs peer-session-refs)
    (cons 'communication-channels communication-channels)
    (cons 'model-policy-ref model-policy-ref)
    (cons 'prompt-policy-ref prompt-policy-ref)
    (cons 'tool-permission-policy-ref tool-permission-policy-ref)
    (cons 'hook-tool-permission-policy-ref hook-tool-permission-policy-ref)
    (cons 'resource-sharing-policy-ref resource-sharing-policy-ref)
    (cons 'durable-policy-ref durable-policy-ref)
    (cons 'tool-refs tool-refs)
    (cons 'memory-refs memory-refs)
    (cons 'sandbox-profile-ref sandbox-profile-ref)
    (cons 'role role)
    (cons 'result-contract result-contract)
    (cons 'runtime-owner "marlin-agent-core")
    (cons 'runtime-executed #f)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata))))))

;; : (-> POOObject Boolean)
(def (poo-flow-session-agent-node? value)
  (and (object? value)
       (eq? (.ref value 'kind)
            'poo-flow.session.agent-node)))

;; : (-> PooSessionAgentNode Symbol)
(def (poo-flow-session-agent-node-agent-id node)
  (.ref node 'agent-id))

;; : (-> PooSessionAgentNode Symbol)
(def (poo-flow-session-agent-node-output-session-ref node)
  (.ref node 'output-session-ref))

;; : (-> PooSessionAgentNode Symbol)
(def (poo-flow-session-agent-node-parent-session-ref node)
  (.ref node 'parent-session-ref))

;; : (-> PooSessionAgentNode Symbol)
(def (poo-flow-session-agent-node-durable-policy-ref node)
  (.ref node 'durable-policy-ref))

;; : (-> PooSessionAgentNode Alist)
(def (poo-flow-session-agent-node->alist node)
  (poo-flow-session-require "session agent node projection requires a node"
                            (poo-flow-session-agent-node? node)
                            node)
  (list
   (cons 'kind (.ref node 'kind))
   (cons 'schema (.ref node 'schema))
   (cons 'agent-id (.ref node 'agent-id))
   (cons 'project-ref (.ref node 'project-ref))
   (cons 'root-session-ref (.ref node 'root-session-ref))
   (cons 'parent-session-ref (.ref node 'parent-session-ref))
   (cons 'agent-system-session-ref (.ref node 'agent-system-session-ref))
   (cons 'input-session-ref (.ref node 'input-session-ref))
   (cons 'output-session-ref (.ref node 'output-session-ref))
   (cons 'peer-session-refs (.ref node 'peer-session-refs))
   (cons 'communication-channels (.ref node 'communication-channels))
   (cons 'model-policy-ref (.ref node 'model-policy-ref))
   (cons 'prompt-policy-ref (.ref node 'prompt-policy-ref))
   (cons 'tool-permission-policy-ref
         (.ref node 'tool-permission-policy-ref))
   (cons 'hook-tool-permission-policy-ref
         (.ref node 'hook-tool-permission-policy-ref))
   (cons 'resource-sharing-policy-ref
         (.ref node 'resource-sharing-policy-ref))
   (cons 'durable-policy-ref (.ref node 'durable-policy-ref))
   (cons 'tool-refs (.ref node 'tool-refs))
   (cons 'memory-refs (.ref node 'memory-refs))
   (cons 'sandbox-profile-ref (.ref node 'sandbox-profile-ref))
   (cons 'role (.ref node 'role))
   (cons 'result-contract (.ref node 'result-contract))
   (cons 'runtime-owner (.ref node 'runtime-owner))
   (cons 'runtime-executed (.ref node 'runtime-executed))
   (cons 'metadata (.ref node 'metadata))))

;; : (-> PooSessionAgentNode PooSession PooSessionRegistryEntry)
(def (poo-flow-session-agent-node->registry-entry node session)
  (poo-flow-session-registry-entry
   session
   (poo-flow-session-agent-node-agent-id node)
   (.ref node 'communication-channels)
   (list
    (cons 'context (.ref node 'prompt-policy-ref))
    (cons 'sharing (.ref node 'resource-sharing-policy-ref))
    (cons 'resource (.ref node 'resource-sharing-policy-ref))
    (cons 'durable
          (list (cons 'policy-id
                      (poo-flow-session-agent-node-durable-policy-ref node))
                (cons 'source 'agent-node))))
   (list (cons 'source 'agent-node)
         (cons 'role (.ref node 'role)))))

;; : (-> [PooSessionAgentNode] [Symbol])
(def (poo-flow-session-agent-node-ids nodes)
  (map poo-flow-session-agent-node-agent-id nodes))

;; : (-> [PooSessionAgentNode] [Pair])
(def (poo-flow-session-agent-node-edge-pairs nodes)
  (map (lambda (node)
         (cons (poo-flow-session-agent-node-parent-session-ref node)
               (poo-flow-session-agent-node-output-session-ref node)))
       nodes))

;; : (-> [PooSessionAgentNode] [Symbol])
(def (poo-flow-session-agent-node-durable-policy-refs nodes)
  (map poo-flow-session-agent-node-durable-policy-ref nodes))

;; : (-> Symbol Symbol [PooSessionAgentNode] [PooSession] PooSessionRegistryReceipt [Alist] PooSessionAgentGraph)
(def (poo-flow-session-agent-graph project-id
                                   root-session-ref
                                   agent-nodes
                                   sessions
                                   registry-receipt
                                   . maybe-metadata)
  (poo-flow-session-require "session agent graph project id must be a symbol"
                            (symbol? project-id)
                            project-id)
  (poo-flow-session-require "session agent graph root ref must be a symbol"
                            (symbol? root-session-ref)
                            root-session-ref)
  (poo-flow-session-require "session agent graph nodes must be agent nodes"
                            (poo-flow-session-every?
                             poo-flow-session-agent-node?
                             agent-nodes)
                            agent-nodes)
  (poo-flow-session-require "session agent graph sessions must be sessions"
                            (poo-flow-session-every?
                             poo-flow-session?
                             sessions)
                            sessions)
  (poo-flow-session-require "session agent graph registry must be a receipt"
                            (poo-flow-session-registry-receipt?
                             registry-receipt)
                            registry-receipt)
  (object<-alist
   (list
    (cons 'kind 'poo-flow.session.agent-graph)
    (cons 'schema 'poo-flow.modules.session.agent-graph.v1)
    (cons 'project-id project-id)
    (cons 'root-session-ref root-session-ref)
    (cons 'agent-count (length agent-nodes))
    (cons 'session-count (length sessions))
    (cons 'agent-ids (poo-flow-session-agent-node-ids agent-nodes))
    (cons 'session-ids (map poo-flow-session-id sessions))
    (cons 'lineage-edge-pairs
          (poo-flow-session-agent-node-edge-pairs agent-nodes))
    (cons 'durable-policy-refs
          (poo-flow-session-agent-node-durable-policy-refs agent-nodes))
    (cons 'agent-nodes agent-nodes)
    (cons 'registry-receipt registry-receipt)
    (cons 'runtime-owner "marlin-agent-core")
    (cons 'runtime-executed #f)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata))))))

;; : (-> POOObject Boolean)
(def (poo-flow-session-agent-graph? value)
  (and (object? value)
       (eq? (.ref value 'kind)
            'poo-flow.session.agent-graph)))

;; : (-> PooSessionAgentGraph [Symbol])
(def (poo-flow-session-agent-graph-agent-ids graph)
  (.ref graph 'agent-ids))

;; : (-> PooSessionAgentGraph [Symbol])
(def (poo-flow-session-agent-graph-session-ids graph)
  (.ref graph 'session-ids))

;; : (-> PooSessionAgentGraph PooSessionRegistryReceipt)
(def (poo-flow-session-agent-graph-registry-receipt graph)
  (.ref graph 'registry-receipt))

;; : (-> PooSessionAgentGraph Alist)
(def (poo-flow-session-agent-graph->alist graph)
  (poo-flow-session-require "session agent graph projection requires a graph"
                            (poo-flow-session-agent-graph? graph)
                            graph)
  (list
   (cons 'kind (.ref graph 'kind))
   (cons 'schema (.ref graph 'schema))
   (cons 'project-id (.ref graph 'project-id))
   (cons 'root-session-ref (.ref graph 'root-session-ref))
   (cons 'agent-count (.ref graph 'agent-count))
   (cons 'session-count (.ref graph 'session-count))
   (cons 'agent-ids (.ref graph 'agent-ids))
   (cons 'session-ids (.ref graph 'session-ids))
   (cons 'lineage-edge-pairs (.ref graph 'lineage-edge-pairs))
   (cons 'durable-policy-refs (.ref graph 'durable-policy-refs))
   (cons 'agent-nodes
         (map poo-flow-session-agent-node->alist
              (.ref graph 'agent-nodes)))
   (cons 'registry-receipt
         (let (receipt (.ref graph 'registry-receipt))
           (list
            (cons 'kind (.ref receipt 'kind))
            (cons 'schema (.ref receipt 'schema))
            (cons 'project-id (.ref receipt 'project-id))
            (cons 'root-session-ids (.ref receipt 'root-session-ids))
            (cons 'child-session-ids (.ref receipt 'child-session-ids))
            (cons 'session-ids (.ref receipt 'session-ids))
            (cons 'active-session-ref (.ref receipt 'active-session-ref))
            (cons 'durable-policy-refs (.ref receipt 'durable-policy-refs))
            (cons 'entry-count (.ref receipt 'entry-count))
            (cons 'entries (.ref receipt 'entries))
            (cons 'runtime-owner (.ref receipt 'runtime-owner))
            (cons 'runtime-executed (.ref receipt 'runtime-executed))
            (cons 'metadata (.ref receipt 'metadata)))))
   (cons 'runtime-owner (.ref graph 'runtime-owner))
   (cons 'runtime-executed (.ref graph 'runtime-executed))
   (cons 'metadata (.ref graph 'metadata))))
