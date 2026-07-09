;;; -*- Gerbil -*-
;;; Boundary: report-only multi-agent session topology objects.
;;; Invariant: agent topology names sessions, policies, and channels; it never
;;; dispatches providers, tools, memory stores, or messages.

(import (only-in :clan/poo/object .ref object? object<-alist)
        :poo-flow/src/modules/session/communication
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/objects-handoff
        :poo-flow/src/modules/session/registry
        :poo-flow/src/modules/session/receipt-syntax)

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
        poo-flow-session-agent-graph-communication-channel-receipts
        poo-flow-session-agent-graph-communication-receipts
        poo-flow-session-agent-graph-registry-receipt
        poo-flow-session-agent-graph->alist)

;;; Boundary: session agent field rows keep agent object slots stable across
;;; parent and child session graph materialization.
;; poo-flow-session-agent-field-rows
;; : (-> SessionAgentFieldRowsClauseSyntax SessionAgentFieldRowsExpansionSyntax)
;; | doc m%
;;   Expands session agent field clauses into stable node projection rows.
;;   # Examples
;;   ```scheme
;;   (poo-flow-session-agent-field-rows (session-id 'child))
;;   ;; => ((session-id . child))
;;   ```
(defrules poo-flow-session-agent-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

;;; Boundary: session agent nodes preserve parent/child session identity and
;;; sandbox policy refs as inert POO values.
;; poo-flow-session-agent-node
;;   | contract: adjacent signature fixes the agent graph node constructor.
;;   | doc m%
;;       Create one inert session agent node for graph, sandbox, and policy
;;       validation. The node records session links and policy refs; it does
;;       not start an agent or execute runtime work.
;;       # Examples
;;       (poo-flow-session-agent-node 'agent 'project 'root 'parent 'system
;;                                    'input 'output '() '() 'model 'prompt
;;                                    'tool 'hook 'sharing 'durable '() '()
;;                                    'sandbox 'worker 'result)
;;       # Result
;;       A POO object whose slots can be projected into session graph receipts.
;;     %
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
   (poo-flow-session-agent-field-rows
    (kind 'poo-flow.session.agent-node)
    (schema 'poo-flow.modules.session.agent-node.v1)
    (agent-id agent-id)
    (project-ref project-ref)
    (root-session-ref root-session-ref)
    (parent-session-ref parent-session-ref)
    (agent-system-session-ref agent-system-session-ref)
    (input-session-ref input-session-ref)
    (output-session-ref output-session-ref)
    (peer-session-refs peer-session-refs)
    (communication-channels communication-channels)
    (model-policy-ref model-policy-ref)
    (prompt-policy-ref prompt-policy-ref)
    (tool-permission-policy-ref tool-permission-policy-ref)
    (hook-tool-permission-policy-ref hook-tool-permission-policy-ref)
    (resource-sharing-policy-ref resource-sharing-policy-ref)
    (durable-policy-ref durable-policy-ref)
    (tool-refs tool-refs)
    (memory-refs memory-refs)
    (sandbox-profile-ref sandbox-profile-ref)
    (role role)
    (result-contract result-contract)
    (runtime-owner "marlin-agent-core")
    (runtime-executed #f)
    (metadata (if (null? maybe-metadata)
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

;; poo-flow-session-agent-node->alist
;;   | contract: adjacent projection signature defines the receipt boundary.
;;   | doc m%
;;       Project an inert agent node into a stable receipt row for registry,
;;       graph, and policy validation. Projection reads slots only and does not
;;       execute agent runtime behavior.
;;       # Examples
;;       (poo-flow-session-agent-node->alist node)
;;       # Result
;;       An alist containing session identity, policy refs, sandbox ref, and
;;       runtime handoff metadata.
;;     %
;; : (-> PooSessionAgentNode Alist)
(defpoo-session-receipt-projection
  poo-flow-session-agent-node->alist
  (node)
  (require poo-flow-session-require
           "session agent node projection requires a node"
           (poo-flow-session-agent-node? node)
           node)
  (bindings ())
  (fields
   (('kind (.ref node 'kind))
    ('schema (.ref node 'schema))
    ('agent-id (.ref node 'agent-id))
    ('project-ref (.ref node 'project-ref))
    ('root-session-ref (.ref node 'root-session-ref))
    ('parent-session-ref (.ref node 'parent-session-ref))
    ('agent-system-session-ref (.ref node 'agent-system-session-ref))
    ('input-session-ref (.ref node 'input-session-ref))
    ('output-session-ref (.ref node 'output-session-ref))
    ('peer-session-refs (.ref node 'peer-session-refs))
    ('communication-channels (.ref node 'communication-channels))
    ('model-policy-ref (.ref node 'model-policy-ref))
    ('prompt-policy-ref (.ref node 'prompt-policy-ref))
    ('tool-permission-policy-ref
     (.ref node 'tool-permission-policy-ref))
    ('hook-tool-permission-policy-ref
     (.ref node 'hook-tool-permission-policy-ref))
    ('resource-sharing-policy-ref
     (.ref node 'resource-sharing-policy-ref))
    ('durable-policy-ref (.ref node 'durable-policy-ref))
    ('tool-refs (.ref node 'tool-refs))
    ('memory-refs (.ref node 'memory-refs))
    ('sandbox-profile-ref (.ref node 'sandbox-profile-ref))
    ('role (.ref node 'role))
    ('result-contract (.ref node 'result-contract))
    ('runtime-owner (.ref node 'runtime-owner))
    ('runtime-executed (.ref node 'runtime-executed))
    ('metadata (.ref node 'metadata)))))

;; poo-flow-session-agent-nodes->alists
;;   | contract: adjacent batch signature defines list projection.
;;   | doc m%
;;       Project a list of inert agent nodes into receipt rows while preserving
;;       the same runtime handoff boundary as the single-node projector.
;;       # Examples
;;       (poo-flow-session-agent-nodes->alists nodes)
;;       # Result
;;       A list of agent-node receipt alists.
;;     %
;; : (-> [PooSessionAgentNode] [Alist])
(defpoo-session-receipt-projection-batch
  poo-flow-session-agent-nodes->alists (nodes)
  (projector poo-flow-session-agent-node->alist)
  (error-message "session agent node serialization requires a list"))

;; poo-flow-session-agent-node->registry-entry
;;   | contract: adjacent signature fixes the node-to-registry projection.
;;   | doc m%
;;       Convert one inert agent node plus its session into a registry entry for
;;       lifecycle, policy, and communication validation. The helper preserves
;;       durable policy, communication channel, prompt, and resource-sharing
;;       refs without starting or resuming an agent.
;;       # Examples
;;       (poo-flow-session-agent-node->registry-entry node session)
;;       # Result
;;       A session registry entry whose metadata records the agent-node source
;;       and role for downstream handoff checks.
;;     %
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

;; poo-flow-session-agent-node-topology-summary
;;   | contract: adjacent signature fixes the node topology summary projection.
;;   | doc m%
;;       Summarize session agent nodes into agent ids, lineage edge pairs, and
;;       durable policy refs for graph-level policy validation. The helper walks
;;       inert POO node values only; it does not inspect runtime state or start
;;       agent processes.
;;       # Examples
;;       (poo-flow-session-agent-node-topology-summary agent-nodes)
;;       # Result
;;       A three-part topology summary: agent ids, parent/output edge pairs, and
;;       durable policy refs.
;;     %
;; : (-> [PooSessionAgentNode] [Symbol])
(def (poo-flow-session-agent-node-topology-summary nodes)
  (let loop ((remaining-nodes nodes)
             (agent-ids-rev '())
             (edge-pairs-rev '())
             (durable-policy-refs-rev '()))
    (if (null? remaining-nodes)
      (list
       (reverse agent-ids-rev)
       (reverse edge-pairs-rev)
       (reverse durable-policy-refs-rev))
      (let (node (car remaining-nodes))
        (loop
         (cdr remaining-nodes)
         (cons (poo-flow-session-agent-node-agent-id node)
               agent-ids-rev)
         (cons (cons (poo-flow-session-agent-node-parent-session-ref node)
                     (poo-flow-session-agent-node-output-session-ref node))
               edge-pairs-rev)
         (cons (poo-flow-session-agent-node-durable-policy-ref node)
               durable-policy-refs-rev))))))

;; : (-> [PooSessionAgentNode] [Symbol])
(def (poo-flow-session-agent-node-ids nodes)
  (car (poo-flow-session-agent-node-topology-summary nodes)))

;; : (-> [PooSessionAgentNode] [Pair])
(def (poo-flow-session-agent-node-edge-pairs nodes)
  (cadr (poo-flow-session-agent-node-topology-summary nodes)))

;; : (-> [PooSessionAgentNode] [Symbol])
(def (poo-flow-session-agent-node-durable-policy-refs nodes)
  (caddr (poo-flow-session-agent-node-topology-summary nodes)))

;; : (-> [PooSession] (Cons [Symbol] Integer))
(def (poo-flow-session-agent-graph-session-summary sessions)
  (cons (map poo-flow-session-id sessions)
        (length sessions)))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-session-agent-graph-metadata-ref metadata key default-value)
  (if (list? metadata)
    (let (entry (assoc key metadata))
      (if entry (cdr entry) default-value))
    default-value))

;; : (-> Alist [PooSessionCommunicationChannelReceipt])
(def (poo-flow-session-agent-graph-metadata-channel-receipts metadata)
  (poo-flow-session-agent-graph-metadata-ref
   metadata
   'communication-channel-receipts
   '()))

;; : (-> PooSessionCommunicationChannelReceipt [Symbol] Boolean)
(def (poo-flow-session-agent-channel-receipt-authorized? receipt agent-ids)
  (let* ((row
          (and
           (poo-flow-session-communication-channel-receipt? receipt)
           (poo-flow-session-communication-channel-receipt->alist receipt)))
         (source-cell (and row (assoc 'source-agent-id row)))
         (target-cell (and row (assoc 'target-agent-id row)))
         (source-agent-id (and source-cell (cdr source-cell)))
         (target-agent-id (and target-cell (cdr target-cell))))
    (and
     (or (memq source-agent-id agent-ids)
         (eq? source-agent-id 'loop-engine))
     (or (memq target-agent-id agent-ids)
         (eq? target-agent-id 'loop-engine))
     (or (memq source-agent-id agent-ids)
         (memq target-agent-id agent-ids)))))

;; : (-> [PooSessionCommunicationChannelReceipt] [Symbol] Boolean)
(def (poo-flow-session-agent-channel-receipts-authorized? receipts agent-ids)
  (and
   (pair? receipts)
   (andmap
    (lambda (receipt)
      (poo-flow-session-agent-channel-receipt-authorized? receipt agent-ids))
    receipts)))

;;; Boundary: session agent graphs join nodes, registry, and communication
;;; receipts without sharing mutable runtime context.
;; poo-flow-session-agent-graph
;;   | contract: adjacent signature fixes the session agent graph constructor.
;;   | doc m%
;;       Build the session agent graph that the control plane hands to policy,
;;       sandbox, and communication gates. The graph is a POO object receipt: it
;;       records agent node ids, session ids, communication receipts, and
;;       registry receipt metadata without starting any agent runtime.
;;       # Examples
;;       (poo-flow-session-agent-graph 'project 'root agent-nodes sessions
;;                                     registry-receipt communication-receipts)
;;       # Result
;;       A POO graph object with stable agent, session, communication, and
;;       registry receipt slots for downstream validation.
;;     %
;; : (-> Symbol Symbol [PooFlowSessionAgentNode] [PooFlowSession] PooFlowRegistryReceipt [PooFlowCommunicationReceipt] [Alist] PooSessionAgentGraph)
(def (poo-flow-session-agent-graph project-id
                                   root-session-ref
                                   agent-nodes
                                   sessions
                                   registry-receipt
                                   communication-receipts
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
  (poo-flow-session-require
   "session agent graph communication receipts must be receipts"
   (poo-flow-session-every?
    poo-flow-session-communication-receipt?
    communication-receipts)
   communication-receipts)
  (let* ((metadata (if (null? maybe-metadata)
                     '()
                     (car maybe-metadata)))
         (communication-channel-receipts
          (poo-flow-session-agent-graph-metadata-channel-receipts metadata))
         (agent-topology-summary
          (poo-flow-session-agent-node-topology-summary agent-nodes))
         (agent-ids (car agent-topology-summary))
         (lineage-edge-pairs (cadr agent-topology-summary))
         (durable-policy-refs (caddr agent-topology-summary))
         (channel-authorized?
          (poo-flow-session-agent-channel-receipts-authorized?
           communication-channel-receipts
           agent-ids))
         (handoff-metadata
          (poo-flow-session-topology->handoff-metadata
           (list
            (cons 'agent-registered?
                  (and (pair? agent-ids) #t))
            (cons 'subagent-registered?
                  (and (pair? lineage-edge-pairs) #t))
            (cons 'channel-authorized?
                  channel-authorized?))
           metadata))
         (session-summary
          (poo-flow-session-agent-graph-session-summary sessions))
         (session-ids (car session-summary))
         (session-count (cdr session-summary)))
    (poo-flow-session-require
     "session agent graph communication channel receipts must be receipts"
     (and (list? communication-channel-receipts)
          (poo-flow-session-every?
           poo-flow-session-communication-channel-receipt?
           communication-channel-receipts))
     communication-channel-receipts)
    (object<-alist
     (list
      (cons 'kind 'poo-flow.session.agent-graph)
      (cons 'schema 'poo-flow.modules.session.agent-graph.v1)
      (cons 'project-id project-id)
      (cons 'root-session-ref root-session-ref)
      (cons 'agent-count (length agent-nodes))
      (cons 'session-count session-count)
      (cons 'agent-ids agent-ids)
      (cons 'session-ids session-ids)
      (cons 'lineage-edge-pairs lineage-edge-pairs)
      (cons 'durable-policy-refs durable-policy-refs)
      (cons 'agent-nodes agent-nodes)
      (cons 'registry-receipt registry-receipt)
      (cons 'communication-receipt-count
            (length communication-receipts))
      (cons 'communication-receipts communication-receipts)
      (cons 'communication-channel-receipt-count
            (length communication-channel-receipts))
      (cons 'communication-channel-receipts communication-channel-receipts)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f)
      (cons 'metadata handoff-metadata)))))

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

;; : (-> PooSessionAgentGraph [PooSessionCommunicationChannelReceipt])
(def (poo-flow-session-agent-graph-communication-channel-receipts graph)
  (.ref graph 'communication-channel-receipts))

;; : (-> PooSessionAgentGraph [PooSessionCommunicationReceipt])
(def (poo-flow-session-agent-graph-communication-receipts graph)
  (.ref graph 'communication-receipts))

;; : (-> PooSessionAgentGraph PooSessionRegistryReceipt)
(def (poo-flow-session-agent-graph-registry-receipt graph)
  (.ref graph 'registry-receipt))

;; : (-> PooSessionAgentGraph Alist)
(defpoo-session-receipt-projection
  poo-flow-session-agent-graph->alist
  (graph)
  (require poo-flow-session-require
           "session agent graph projection requires a graph"
           (poo-flow-session-agent-graph? graph)
           graph)
  (bindings
   ((agent-nodes (.ref graph 'agent-nodes))
    (registry-receipt (.ref graph 'registry-receipt))
    (communication-channel-receipts
     (.ref graph 'communication-channel-receipts))
    (communication-receipts (.ref graph 'communication-receipts))))
  (fields
   (('kind (.ref graph 'kind))
    ('schema (.ref graph 'schema))
    ('project-id (.ref graph 'project-id))
    ('root-session-ref (.ref graph 'root-session-ref))
    ('agent-count (.ref graph 'agent-count))
    ('session-count (.ref graph 'session-count))
    ('agent-ids (.ref graph 'agent-ids))
    ('session-ids (.ref graph 'session-ids))
    ('lineage-edge-pairs (.ref graph 'lineage-edge-pairs))
    ('durable-policy-refs (.ref graph 'durable-policy-refs))
    ('agent-nodes
     (poo-flow-session-agent-nodes->alists agent-nodes))
    ('registry-receipt
     (poo-flow-session-registry-receipt->alist registry-receipt))
    ('communication-receipt-count
     (.ref graph 'communication-receipt-count))
    ('communication-receipts
     (poo-flow-session-communication-receipts->alists
      communication-receipts))
    ('communication-channel-receipt-count
     (.ref graph 'communication-channel-receipt-count))
    ('communication-channel-receipts
     (poo-flow-session-communication-channel-receipts->alists
      communication-channel-receipts))
    ('runtime-owner (.ref graph 'runtime-owner))
    ('runtime-executed (.ref graph 'runtime-executed))
    ('metadata (.ref graph 'metadata)))))
