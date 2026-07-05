;;; -*- Gerbil -*-
;;; Boundary: lightweight loop-engine session-agent graph projection.
;;; Invariant: this owner builds report-only graph rows without importing the
;;; full runtime handoff stack or user config facades.

(import (only-in :poo-flow/src/modules/session/agent
                 poo-flow-session-agent-graph
                 poo-flow-session-agent-graph->alist
                 poo-flow-session-agent-node
                 poo-flow-session-agent-node->alist)
        (only-in :poo-flow/src/modules/session/communication
                 poo-flow-session-communication-channel-receipt
                 poo-flow-session-communication-receipt)
        (only-in :poo-flow/src/modules/session/objects
                 poo-flow-session-alist-ref
                 poo-flow-session-chunk
                 poo-flow-session-lineage
                 poo-flow-session-placement
                 poo-flow-session-value)
        (only-in :poo-flow/src/modules/session/registry
                 poo-flow-session-registry-entry
                 poo-flow-session-registry-receipt)
        :poo-flow/src/module-system/loop-engine-intent-utils)

(export poo-flow-user-loop-engine-intent-session-agent-graph)

;; : Symbol
(def +poo-flow-loop-engine-default-result-contract+
  'poo-flow.loop-governor.node-result.v1)

;; : (-> AgentJudgeRow Symbol)
(def (poo-flow-loop-engine-agent-judge-role row)
  (car row))

;; : (-> AgentJudgeRow AgentJudgeTail)
(def (poo-flow-loop-engine-agent-judge-tail row)
  (cdr row))

;; : (-> AgentJudgeTail AgentJudgeValue)
(def (poo-flow-loop-engine-agent-judge-value tail)
  (if (pair? tail) (car tail) tail))

;; : (-> Value MaybeAgentJudgeRef)
(def (poo-flow-loop-engine-agent-judge-pair row)
  (and (pair? row)
       (symbol? (poo-flow-loop-engine-agent-judge-role row))
       (let (tail (poo-flow-loop-engine-agent-judge-tail row))
         (and (not (null? tail))
              (cons (poo-flow-loop-engine-agent-judge-role row)
                    (poo-flow-loop-engine-agent-judge-value tail))))))

;; : (-> [Value] [AgentProfileRef] [AgentProfileRef])
(def (poo-flow-loop-engine-agent-judge-pairs/rev agent-judges refs-rev)
  (cond
   ((null? agent-judges) refs-rev)
   ((poo-flow-loop-engine-agent-judge-pair (car agent-judges))
    => (lambda (role-ref)
         (poo-flow-loop-engine-agent-judge-pairs/rev
          (cdr agent-judges)
          (cons role-ref refs-rev))))
   (else
    (poo-flow-loop-engine-agent-judge-pairs/rev (cdr agent-judges)
                                                refs-rev))))

;; : (-> Alist [AgentProfileRef])
(def (poo-flow-loop-engine-intent-agent-profile-refs intent)
  (let* ((refs-rev
          (poo-flow-loop-engine-agent-judge-pairs/rev
           (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '())
           '()))
         (refs-rev*
          (if (null? (poo-flow-user-loop-engine-intent-ref
                      intent
                      'human-audit
                      '()))
            refs-rev
            (cons (cons 'human-audit 'human-audit) refs-rev))))
    (reverse refs-rev*)))

;; : (-> Alist MaybeSymbol)
(def (poo-flow-loop-engine-intent-primary-sandbox-profile intent)
  (let (refs (poo-flow-user-loop-engine-intent-ref
              intent
              'sandbox-profile-refs
              '()))
    (if (null? refs) #f (car refs))))

;; : (-> Alist Symbol Symbol)
(def (poo-flow-loop-engine-intent-role-result-contract intent role)
  (let (result-rows
        (poo-flow-user-loop-engine-intent-ref intent 'result '()))
    (poo-flow-user-loop-engine-section-ref
     result-rows
     role
     (poo-flow-user-loop-engine-section-ref
      result-rows
      'default
      +poo-flow-loop-engine-default-result-contract+))))

;; : (-> Alist Symbol)
(def (poo-flow-loop-engine-first-parent-session-ref intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (lineage-policy
          (poo-flow-user-loop-engine-intent-ref intent 'lineage-policy '()))
         (parent-refs
          (poo-flow-user-loop-engine-intent-ref
           lineage-policy
           'parent-session-refs
           '())))
    (if (null? parent-refs)
      (poo-flow-user-loop-engine-runtime-id use-case-name "root-session")
      (car parent-refs))))

;; : (-> Symbol String Symbol)
(def (poo-flow-loop-engine-symbol-suffix prefix suffix)
  (string->symbol
   (string-append
    (symbol->string prefix)
    "/"
    suffix)))

;; : (-> Alist [Symbol])
(def (poo-flow-loop-engine-memory-store-refs intent)
  (let loop ((policies
              (poo-flow-user-loop-engine-intent-ref
               intent
               'memory-policies
               '())))
    (cond
     ((null? policies) '())
     (else
      (let ((store-ref
             (poo-flow-user-loop-engine-intent-ref
              (car policies)
              'store
              #f)))
        (if store-ref
          (cons store-ref (loop (cdr policies)))
          (loop (cdr policies))))))))

;; : (-> Alist [Symbol])
(def (poo-flow-loop-engine-tool-refs intent)
  (poo-flow-user-loop-engine-intent-ref
   (poo-flow-user-loop-engine-intent-ref intent 'resource-policy '())
   'tool-refs
   '()))

;; : (-> Alist [Pair] [Symbol] [Symbol])
(def (poo-flow-loop-engine-agent-output-session-refs/rev intent
                                                         role-refs
                                                         output-session-refs)
  (if (null? role-refs)
    output-session-refs
    (poo-flow-loop-engine-agent-output-session-refs/rev
     intent
     (cdr role-refs)
     (cons
      (poo-flow-user-loop-engine-runtime-id
       (poo-flow-user-loop-engine-intent-use-case-name intent)
       (string-append (symbol->string (caar role-refs)) "-session"))
      output-session-refs))))

;; : (-> Alist [Symbol])
(def (poo-flow-loop-engine-agent-output-session-refs intent)
  (reverse
   (poo-flow-loop-engine-agent-output-session-refs/rev
    intent
    (poo-flow-loop-engine-intent-agent-profile-refs intent)
    '())))

;; : (-> Symbol [Symbol] [Symbol])
(def (poo-flow-loop-engine-peer-session-refs session-id session-ids)
  (cond
   ((null? session-ids) '())
   ((eq? session-id (car session-ids))
    (poo-flow-loop-engine-peer-session-refs session-id (cdr session-ids)))
   (else
    (cons (car session-ids)
          (poo-flow-loop-engine-peer-session-refs
           session-id
           (cdr session-ids))))))

;; : (-> Alist Symbol PooSession)
(def (poo-flow-loop-engine-session-value intent session-id)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (root-session-ref
          (poo-flow-loop-engine-first-parent-session-ref intent))
         (loop-session-ref
          (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
         (sandbox-profile-ref
          (or (poo-flow-loop-engine-intent-primary-sandbox-profile intent)
              'sandbox/unspecified))
         (parent-session-ids
          (cond
           ((eq? session-id root-session-ref) '())
           ((eq? session-id loop-session-ref) (list root-session-ref))
           (else (list loop-session-ref)))))
    (poo-flow-session-value
     session-id
     (list
      (poo-flow-session-chunk
       (poo-flow-loop-engine-symbol-suffix session-id "summary")
       'system
       "Loop-engine report-only session topology node."))
     (poo-flow-session-lineage
      session-id
      parent-session-ids
      'loop-engine-topology)
     (poo-flow-session-placement sandbox-profile-ref)
     (list (cons 'source 'loop-engine-session-agent-graph)
           (cons 'use-case use-case-name)
           (cons 'runtime-owner "marlin-agent-core")
           (cons 'runtime-executed #f)))))

;; : (-> Alist Pair [Symbol] PooSessionAgentNode)
(def (poo-flow-loop-engine-session-agent-node intent
                                              role-ref
                                              output-session-refs)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (role (car role-ref))
         (agent-id (cdr role-ref))
         (project-ref 'loop-engine/project)
         (root-session-ref
          (poo-flow-loop-engine-first-parent-session-ref intent))
         (loop-session-ref
          (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
         (output-session-ref
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-session")))
         (system-session-ref
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-system-session")))
         (channel-ref
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-channel")))
         (sandbox-profile-ref
          (or (poo-flow-loop-engine-intent-primary-sandbox-profile intent)
              'sandbox/unspecified)))
    (poo-flow-session-agent-node
     agent-id
     project-ref
     root-session-ref
     loop-session-ref
     system-session-ref
     loop-session-ref
     output-session-ref
     (poo-flow-loop-engine-peer-session-refs
      output-session-ref
      output-session-refs)
     (list channel-ref)
     (poo-flow-loop-engine-symbol-suffix agent-id "model-policy")
     (poo-flow-loop-engine-symbol-suffix agent-id "prompt-policy")
     (poo-flow-loop-engine-symbol-suffix agent-id "tool-policy")
     (poo-flow-loop-engine-symbol-suffix agent-id "hook-tool-policy")
     (poo-flow-loop-engine-symbol-suffix agent-id "resource-policy")
     (poo-flow-loop-engine-symbol-suffix agent-id "durable-policy")
     (poo-flow-loop-engine-tool-refs intent)
     (poo-flow-loop-engine-memory-store-refs intent)
     sandbox-profile-ref
     role
     (poo-flow-loop-engine-intent-role-result-contract intent role)
     (list (cons 'source 'loop-engine-session-agent-graph)
           (cons 'use-case use-case-name)
           (cons 'runtime-owner "marlin-agent-core")
           (cons 'runtime-executed #f)))))

;; : (-> Alist [Pair] [Symbol] [PooSessionAgentNode] [PooSessionAgentNode])
(def (poo-flow-loop-engine-session-agent-nodes/rev intent
                                                   role-refs
                                                   output-session-refs
                                                   agent-nodes)
  (if (null? role-refs)
    agent-nodes
    (poo-flow-loop-engine-session-agent-nodes/rev
     intent
     (cdr role-refs)
     output-session-refs
     (cons (poo-flow-loop-engine-session-agent-node
            intent
            (car role-refs)
            output-session-refs)
           agent-nodes))))

;; : (-> Alist [Pair] [Symbol] [PooSessionAgentNode])
(def (poo-flow-loop-engine-session-agent-nodes intent
                                               role-refs
                                               output-session-refs)
  (reverse
   (poo-flow-loop-engine-session-agent-nodes/rev
    intent
    role-refs
    output-session-refs
    '())))

;; : (-> Alist Pair PooSessionCommunicationChannelReceipt)
(def (poo-flow-loop-engine-session-agent-communication-channel-receipt
      intent
      role-ref)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (role (car role-ref))
         (agent-id (cdr role-ref))
         (loop-session-ref
          (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
         (output-session-ref
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-session")))
         (channel-ref
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-channel")))
         (metadata
          (list (cons 'source 'loop-engine-session-agent-graph)
                (cons 'use-case use-case-name)
                (cons 'role role)
                (cons 'runtime-owner "marlin-agent-core")
                (cons 'runtime-executed #f))))
    (poo-flow-session-communication-channel-receipt
     'loop-engine/project
     channel-ref
     'parent-child
     loop-session-ref
     output-session-ref
     'loop-engine
     agent-id
     '(request receipt)
     '(declared-channel-only receipt-only)
     metadata)))

;; : (-> Alist [Pair] [PooSessionCommunicationChannelReceipt])
(def (poo-flow-loop-engine-session-agent-communication-channel-receipts
      intent
      role-refs)
  (let loop ((remaining-role-refs role-refs)
             (receipt-values '()))
    (if (null? remaining-role-refs)
      (reverse receipt-values)
      (loop
       (cdr remaining-role-refs)
       (cons
        (poo-flow-loop-engine-session-agent-communication-channel-receipt
         intent
         (car remaining-role-refs))
        receipt-values)))))

;; : (-> Alist Pair [PooSessionCommunicationReceipt])
(def (poo-flow-loop-engine-session-agent-communication-receipts/rev
      intent
      role-ref
      receipt-values)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (role (car role-ref))
         (agent-id (cdr role-ref))
         (root-session-ref
          (poo-flow-loop-engine-first-parent-session-ref intent))
         (loop-session-ref
          (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
         (output-session-ref
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-session")))
         (channel-ref
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-channel")))
         (metadata
          (list (cons 'source 'loop-engine-session-agent-graph)
                (cons 'use-case use-case-name)
                (cons 'role role)
                (cons 'runtime-owner "marlin-agent-core")
                (cons 'runtime-executed #f))))
    (let ((request-receipt
           (poo-flow-session-communication-receipt
            'loop-engine/project
            'parent-child
            root-session-ref
            root-session-ref
            loop-session-ref
            output-session-ref
            'loop-engine
            agent-id
            channel-ref
            'request
            (list (cons 'operation 'delegate-agent-turn)
                  (cons 'role role))
            'declared-channel-only
            metadata))
          (result-receipt
           (poo-flow-session-communication-receipt
            'loop-engine/project
            'child-parent
            root-session-ref
            root-session-ref
            output-session-ref
            loop-session-ref
            agent-id
            'loop-engine
            channel-ref
            'receipt
            (list (cons 'operation 'agent-turn-result)
                  (cons 'role role))
            'receipt-only
            metadata)))
      (cons result-receipt
            (cons request-receipt receipt-values)))))

;; : (-> Alist Pair [PooSessionCommunicationReceipt])
(def (poo-flow-loop-engine-session-agent-communication-receipts intent
                                                               role-ref)
  (reverse
   (poo-flow-loop-engine-session-agent-communication-receipts/rev
    intent
    role-ref
    '())))

;; : (-> Alist [Pair] [PooSessionCommunicationReceipt])
(def (poo-flow-loop-engine-session-agent-communication-receipts* intent
                                                                 role-refs)
  (let loop ((remaining-role-refs role-refs)
             (receipt-values '()))
    (if (null? remaining-role-refs)
      (reverse receipt-values)
      (loop
       (cdr remaining-role-refs)
       (poo-flow-loop-engine-session-agent-communication-receipts/rev
        intent
        (car remaining-role-refs)
        receipt-values)))))

;; : (-> Alist Alist)
(def (poo-flow-loop-engine-root-registry-entry intent session agent-id)
  (poo-flow-session-registry-entry
   session
   agent-id
   '()
   '((isolation . ((default . root-owned)))
     (context . ((default . root-summary)))
     (sharing . ((default . explicit-grants-only)))
     (resource . ((accounting-owner . root-session))))
  '((source . loop-engine-session-agent-graph)
     (runtime-executed . #f))))

;; : (-> PooSessionAgentNode PooSessionValue Alist)
(def (poo-flow-loop-engine-session-agent-registry-entry node session)
  (let (node-row (poo-flow-session-agent-node->alist node))
    (poo-flow-session-registry-entry
     session
     (poo-flow-session-alist-ref
      node-row
      'agent-id
      'unknown-agent)
     (poo-flow-session-alist-ref
      node-row
      'communication-channels
      '())
     (list
      (cons 'context
            (poo-flow-session-alist-ref
             node-row
             'prompt-policy-ref
             #f))
      (cons 'sharing
            (poo-flow-session-alist-ref
             node-row
             'resource-sharing-policy-ref
             #f))
      (cons 'resource
            (poo-flow-session-alist-ref
             node-row
             'resource-sharing-policy-ref
             #f))
      (cons 'durable
            (list
             (cons 'policy-id
                   (poo-flow-session-alist-ref
                    node-row
                    'durable-policy-ref
                    #f))
             (cons 'source 'loop-engine-session-agent-graph))))
     (list (cons 'source 'loop-engine-session-agent-graph)
           (cons 'runtime-executed #f)))))

;; : (-> Alist [Symbol] [PooSessionValue])
(def (poo-flow-loop-engine-session-values intent session-refs)
  (let loop ((remaining-session-refs session-refs)
             (session-values '()))
    (if (null? remaining-session-refs)
      (reverse session-values)
      (loop (cdr remaining-session-refs)
            (cons (poo-flow-loop-engine-session-value
                   intent
                   (car remaining-session-refs))
                  session-values)))))

;; : (-> Alist PooSessionValue PooSessionValue [PooSessionAgentNode] [PooSessionValue] [Alist])
(def (poo-flow-loop-engine-session-agent-registry-entries intent
                                                          root-session
                                                          loop-session
                                                          agent-nodes
                                                          agent-sessions)
  (let loop ((remaining-nodes agent-nodes)
             (remaining-sessions agent-sessions)
             (registry-values
              (list (poo-flow-loop-engine-root-registry-entry
                     intent
                     loop-session
                     'loop-engine)
                    (poo-flow-loop-engine-root-registry-entry
                     intent
                     root-session
                     'project-root))))
    (if (or (null? remaining-nodes) (null? remaining-sessions))
      (reverse registry-values)
      (loop (cdr remaining-nodes)
            (cdr remaining-sessions)
            (cons (poo-flow-loop-engine-session-agent-registry-entry
                   (car remaining-nodes)
                   (car remaining-sessions))
                  registry-values)))))

;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-session-agent-graph intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (role-refs
          (poo-flow-loop-engine-intent-agent-profile-refs intent))
         (root-session-ref
          (poo-flow-loop-engine-first-parent-session-ref intent))
         (loop-session-ref
          (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
         (output-session-refs
          (poo-flow-loop-engine-agent-output-session-refs intent))
         (agent-nodes
          (poo-flow-loop-engine-session-agent-nodes intent
                                                    role-refs
                                                    output-session-refs))
         (communication-receipts
          (poo-flow-loop-engine-session-agent-communication-receipts*
           intent
           role-refs))
         (communication-channel-receipts
          (poo-flow-loop-engine-session-agent-communication-channel-receipts
           intent
           role-refs))
         (root-session
          (poo-flow-loop-engine-session-value intent root-session-ref))
         (loop-session
          (poo-flow-loop-engine-session-value intent loop-session-ref))
         (agent-sessions
          (poo-flow-loop-engine-session-values intent output-session-refs))
         (sessions
          (cons root-session (cons loop-session agent-sessions)))
         (registry-entries
          (poo-flow-loop-engine-session-agent-registry-entries
           intent
           root-session
           loop-session
           agent-nodes
           agent-sessions))
         (registry-receipt
          (poo-flow-session-registry-receipt
           'loop-engine/project
           (list root-session-ref)
           (cons loop-session-ref output-session-refs)
           loop-session-ref
           registry-entries
           (list (cons 'source 'loop-engine-session-agent-graph)
                 (cons 'use-case use-case-name)
                 (cons 'runtime-owner "marlin-agent-core")
                 (cons 'runtime-executed #f)))))
    (poo-flow-session-agent-graph->alist
     (poo-flow-session-agent-graph
      'loop-engine/project
      root-session-ref
      agent-nodes
      sessions
      registry-receipt
      communication-receipts
      (list (cons 'source 'loop-engine-session-agent-graph)
            (cons 'use-case use-case-name)
            (cons 'communication-channel-receipts
                  communication-channel-receipts)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))
