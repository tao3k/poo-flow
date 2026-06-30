;;; -*- Gerbil -*-
;;; Boundary: loop-engine agent/profile/session runtime projection rows.
;;; Invariant: projections describe Marlin-owned work and never open sessions.

(import (only-in :poo-flow/src/core/agent-harness
                 make-poo-flow-agent-harness
                 make-poo-flow-agent-operation
                 make-poo-flow-agent-profile
                 make-poo-flow-agent-session
                 make-poo-flow-dispatch-receipt
                 make-poo-flow-workflow-run
                 poo-flow-agent-harness->alist
                 poo-flow-agent-operation->alist
                 poo-flow-agent-profile->alist
                 poo-flow-agent-session->alist
                 poo-flow-dispatch-receipt->alist
                 poo-flow-workflow-run->alist)
        (only-in :poo-flow/src/modules/session/agent
                 poo-flow-session-agent-graph
                 poo-flow-session-agent-graph->alist
                 poo-flow-session-agent-node
                 poo-flow-session-agent-node->alist)
        (only-in :poo-flow/src/modules/session/objects
                 poo-flow-session-alist-ref
                 poo-flow-session-chunk
                 poo-flow-session-lineage
                 poo-flow-session-placement
                 poo-flow-session-value)
        (only-in :poo-flow/src/modules/session/registry
                 poo-flow-session-registry-entry
                 poo-flow-session-registry-receipt)
        :poo-flow/src/module-system/loop-engine-core
        :poo-flow/src/module-system/loop-engine-result-contract
        :poo-flow/src/module-system/loop-engine-runtime-base)

(export poo-flow-user-loop-engine-intent-agent-profile
        poo-flow-user-loop-engine-intent-agent-profiles
        poo-flow-user-loop-engine-intent-agent-harness
        poo-flow-user-loop-engine-intent-agent-harnesses
        poo-flow-user-loop-engine-intent-agent-session
        poo-flow-user-loop-engine-intent-agent-sessions
        poo-flow-user-loop-engine-intent-session-agent-graph
        poo-flow-user-loop-engine-intent-workflow-run
        poo-flow-user-loop-engine-intent-dispatch-receipt
        poo-flow-user-loop-engine-intent-agent-operation
        poo-flow-user-loop-engine-intent-delegated-operation)

;;; Agent profiles are shallow policy rows. They name the selected reviewer or
;;; governor role but leave model choice, tool execution, and sandbox startup to
;;; the runtime handoff.
;; : (-> Alist Pair Alist)
(def (poo-flow-user-loop-engine-intent-agent-profile intent role-ref)
  (let ((role (car role-ref))
        (profile-name (cdr role-ref)))
    (poo-flow-agent-profile->alist
     (make-poo-flow-agent-profile
      profile-name
      'runtime-selected
      (list 'loop-engine role)
      '()
      '(loop-engine)
      (poo-flow-user-loop-engine-intent-primary-sandbox-profile intent)
      (list (cons 'role role)
            (cons 'governor
                  (poo-flow-user-loop-engine-intent-ref intent 'governor '()))
            (cons 'result-contract
                  (poo-flow-user-loop-engine-intent-role-result-contract
                   intent
                   role))
            (cons 'human-audit
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'human-audit
                   '())))
      '()
      (poo-flow-user-loop-engine-intent-ref intent 'budget '())
      (poo-flow-user-loop-engine-intent-ref intent 'observability '())
      (list (cons 'source 'user-config-loop-engine)
            (cons 'profile-role role)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Profile projection preserves user declaration order so presentation output
;;; and runtime manifests can be compared without sorting.
;; : (-> Alist [Alist])
(def (poo-flow-user-loop-engine-intent-agent-profiles intent)
  (map (lambda (role-ref)
         (poo-flow-user-loop-engine-intent-agent-profile intent role-ref))
       (poo-flow-user-loop-engine-intent-agent-profile-refs intent)))

;;; Harness rows describe an initialized-agent boundary without constructing
;;; it. They carry runtime intent and sandbox policy references as receipt data.
;; : (-> Alist Pair Alist)
(def (poo-flow-user-loop-engine-intent-agent-harness intent role-ref)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (role (car role-ref))
         (profile-name (cdr role-ref))
         (harness-id
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-harness"))))
    (poo-flow-agent-harness->alist
     (make-poo-flow-agent-harness
      harness-id
      profile-name
      (poo-flow-user-loop-engine-intent-primary-sandbox-profile intent)
      (poo-flow-user-loop-engine-intent-runtime-intent intent)
      '(execute-agent-operation stream-events read-runtime-snapshot)
      (list 'loop-engine use-case-name role)
      (poo-flow-user-loop-engine-intent-ref intent 'observability '())
      #f
      (list (cons 'source 'user-config-loop-engine)
            (cons 'profile-role role)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Harness projection is one row per named profile so multi-agent governor
;;; configurations remain explicit in the handoff packet.
;; : (-> Alist [Alist])
(def (poo-flow-user-loop-engine-intent-agent-harnesses intent)
  (map (lambda (role-ref)
         (poo-flow-user-loop-engine-intent-agent-harness intent role-ref))
       (poo-flow-user-loop-engine-intent-agent-profile-refs intent)))

;;; Session rows keep delegated work separate from workflow runs. The active
;;; operation ref points at the control-plane operation, not an executed turn.
;; : (-> Alist Pair Alist)
(def (poo-flow-user-loop-engine-intent-agent-session intent role-ref)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (role (car role-ref))
         (session-name
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-session")))
         (harness-id
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-harness")))
         (operation-id
          (poo-flow-user-loop-engine-runtime-id use-case-name "operation")))
    (poo-flow-agent-session->alist
     (make-poo-flow-agent-session
      session-name
      harness-id
      (poo-flow-user-loop-engine-intent-status intent)
      operation-id
      (list 'loop-engine-conversation use-case-name role)
      '((retention . parent-owned))
      (list operation-id)
      (list (cons 'source 'user-config-loop-engine)
            (cons 'profile-role role)
            (cons 'workflow-run-ref
                  (poo-flow-user-loop-engine-runtime-id
                   use-case-name
                   "workflow-run"))
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Session projection gives every named profile a stable namespace that agents
;;; can audit before a backend opens durable conversation state.
;; : (-> Alist [Alist])
(def (poo-flow-user-loop-engine-intent-agent-sessions intent)
  (map (lambda (role-ref)
         (poo-flow-user-loop-engine-intent-agent-session intent role-ref))
       (poo-flow-user-loop-engine-intent-agent-profile-refs intent)))

;; : (-> Alist Symbol Value)
(def (poo-flow-user-loop-engine-intent-first-parent-session-ref intent)
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
(def (poo-flow-user-loop-engine-symbol-suffix prefix suffix)
  (string->symbol
   (string-append
    (symbol->string prefix)
    "/"
    suffix)))

;; : (-> Alist Symbol PooSession)
(def (poo-flow-user-loop-engine-session-value intent session-id)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (root-session-ref
          (poo-flow-user-loop-engine-intent-first-parent-session-ref intent))
         (loop-session-ref
          (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
         (sandbox-profile-ref
          (or (poo-flow-user-loop-engine-intent-primary-sandbox-profile intent)
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
       (poo-flow-user-loop-engine-symbol-suffix session-id "summary")
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

;; : (-> Alist [Symbol])
(def (poo-flow-user-loop-engine-memory-store-refs intent)
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
(def (poo-flow-user-loop-engine-tool-refs intent)
  (poo-flow-user-loop-engine-intent-ref
   (poo-flow-user-loop-engine-intent-ref intent 'resource-policy '())
   'tool-refs
   '()))

;; : (-> Alist [Symbol])
(def (poo-flow-user-loop-engine-agent-output-session-refs intent)
  (map (lambda (role-ref)
         (poo-flow-user-loop-engine-runtime-id
          (poo-flow-user-loop-engine-intent-use-case-name intent)
          (string-append (symbol->string (car role-ref)) "-session")))
       (poo-flow-user-loop-engine-intent-agent-profile-refs intent)))

;; : (-> Symbol [Symbol] [Symbol])
(def (poo-flow-user-loop-engine-peer-session-refs session-id session-ids)
  (cond
   ((null? session-ids) '())
   ((eq? session-id (car session-ids))
    (poo-flow-user-loop-engine-peer-session-refs session-id (cdr session-ids)))
   (else
    (cons (car session-ids)
          (poo-flow-user-loop-engine-peer-session-refs
           session-id
           (cdr session-ids))))))

;; : (-> Alist Pair [Symbol] PooSessionAgentNode)
(def (poo-flow-user-loop-engine-intent-session-agent-node intent
                                                          role-ref
                                                          output-session-refs)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (role (car role-ref))
         (agent-id (cdr role-ref))
         (project-ref 'loop-engine/project)
         (root-session-ref
          (poo-flow-user-loop-engine-intent-first-parent-session-ref intent))
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
          (or (poo-flow-user-loop-engine-intent-primary-sandbox-profile intent)
              'sandbox/unspecified)))
    (poo-flow-session-agent-node
     agent-id
     project-ref
     root-session-ref
     loop-session-ref
     system-session-ref
     loop-session-ref
     output-session-ref
     (poo-flow-user-loop-engine-peer-session-refs
      output-session-ref
      output-session-refs)
     (list channel-ref)
     (poo-flow-user-loop-engine-symbol-suffix agent-id "model-policy")
     (poo-flow-user-loop-engine-symbol-suffix agent-id "prompt-policy")
     (poo-flow-user-loop-engine-symbol-suffix agent-id "tool-policy")
     (poo-flow-user-loop-engine-symbol-suffix agent-id "hook-tool-policy")
     (poo-flow-user-loop-engine-symbol-suffix agent-id "resource-policy")
     (poo-flow-user-loop-engine-symbol-suffix agent-id "durable-policy")
     (poo-flow-user-loop-engine-tool-refs intent)
     (poo-flow-user-loop-engine-memory-store-refs intent)
     sandbox-profile-ref
     role
     (poo-flow-user-loop-engine-intent-role-result-contract intent role)
     (list (cons 'source 'loop-engine-session-agent-graph)
           (cons 'use-case use-case-name)
           (cons 'runtime-owner "marlin-agent-core")
           (cons 'runtime-executed #f)))))

;; : (-> Alist PooSessionRegistryEntry)
(def (poo-flow-user-loop-engine-root-registry-entry intent session agent-id)
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

;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-session-agent-graph intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (role-refs
          (poo-flow-user-loop-engine-intent-agent-profile-refs intent))
         (root-session-ref
          (poo-flow-user-loop-engine-intent-first-parent-session-ref intent))
         (loop-session-ref
          (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
         (output-session-refs
          (poo-flow-user-loop-engine-agent-output-session-refs intent))
         (agent-nodes
          (map (lambda (role-ref)
                 (poo-flow-user-loop-engine-intent-session-agent-node
                  intent
                  role-ref
                  output-session-refs))
               role-refs))
         (root-session
          (poo-flow-user-loop-engine-session-value intent root-session-ref))
         (loop-session
          (poo-flow-user-loop-engine-session-value intent loop-session-ref))
         (agent-sessions
          (map (lambda (session-id)
                 (poo-flow-user-loop-engine-session-value intent session-id))
               output-session-refs))
         (sessions
          (append (list root-session loop-session) agent-sessions))
         (registry-entries
          (append
           (list
            (poo-flow-user-loop-engine-root-registry-entry
             intent
             root-session
             'project-root)
            (poo-flow-user-loop-engine-root-registry-entry
             intent
             loop-session
             'loop-engine))
           (map (lambda (node session)
                  (poo-flow-session-registry-entry
                   session
                   (poo-flow-session-alist-ref
                    (poo-flow-session-agent-node->alist node)
                    'agent-id
                    'unknown-agent)
                   (poo-flow-session-alist-ref
                    (poo-flow-session-agent-node->alist node)
                    'communication-channels
                    '())
                   (list
                    (cons 'context
                          (poo-flow-session-alist-ref
                           (poo-flow-session-agent-node->alist node)
                           'prompt-policy-ref
                           #f))
                    (cons 'sharing
                          (poo-flow-session-alist-ref
                           (poo-flow-session-agent-node->alist node)
                           'resource-sharing-policy-ref
                           #f))
                    (cons 'resource
                          (poo-flow-session-alist-ref
                           (poo-flow-session-agent-node->alist node)
                           'resource-sharing-policy-ref
                           #f))
                    (cons 'durable
                          (list
                           (cons 'policy-id
                                 (poo-flow-session-alist-ref
                                  (poo-flow-session-agent-node->alist node)
                                  'durable-policy-ref
                                  #f))
                           (cons 'source 'loop-engine-session-agent-graph))))
                   (list (cons 'source 'loop-engine-session-agent-graph)
                         (cons 'runtime-executed #f))))
                agent-nodes
                agent-sessions)))
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
      (list (cons 'source 'loop-engine-runtime-agent)
            (cons 'use-case use-case-name)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; The workflow-run projection is an admission plan for runtime lowering. It
;;; is not evidence that a workflow has started.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-workflow-run intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (run-id
          (poo-flow-user-loop-engine-runtime-id use-case-name "workflow-run")))
    (poo-flow-workflow-run->alist
     (make-poo-flow-workflow-run
      run-id
      (poo-flow-user-loop-engine-intent-workflow-ref intent)
      (list (cons 'use-case
                  (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
            (cons 'use-cases
                  (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))
      (poo-flow-user-loop-engine-intent-status intent)
      (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '())
      (list 'loop-engine-events use-case-name)
      '()
      #f
      #f
      #f
      (list (cons 'source 'user-config-loop-engine)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Dispatch receipts are projected separately from workflow runs so async
;;; agent input does not pretend to be a terminal workflow result.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-dispatch-receipt intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (target-agent
          (poo-flow-user-loop-engine-primary-agent
           (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '()))))
    (poo-flow-dispatch-receipt->alist
     (make-poo-flow-dispatch-receipt
      (poo-flow-user-loop-engine-runtime-id use-case-name "dispatch")
      target-agent
      (poo-flow-user-loop-engine-runtime-id use-case-name "runtime-instance")
      (poo-flow-user-loop-engine-runtime-id use-case-name "session")
      (list 'loop-engine-payload use-case-name)
      #f
      'admitted
      (poo-flow-user-loop-engine-intent-runtime-intent intent)
      (list (cons 'source 'user-config-loop-engine)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Agent operations capture the node-level action: governor judge by default,
;;; or human-audit when the user declares a manual loop gate.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-agent-operation intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (operation-kind
          (poo-flow-user-loop-engine-intent-operation-kind intent)))
    (poo-flow-agent-operation->alist
     (make-poo-flow-agent-operation
      (poo-flow-user-loop-engine-runtime-id use-case-name "operation")
      operation-kind
      (poo-flow-user-loop-engine-runtime-id use-case-name "session")
      (poo-flow-user-loop-engine-runtime-id use-case-name "workflow-run")
      (list (cons 'use-case
                  (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
            (cons 'governor
                  (poo-flow-user-loop-engine-intent-ref intent 'governor '()))
            (cons 'agent-judges
                  (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '()))
            (cons 'human-audit
                  (poo-flow-user-loop-engine-intent-ref intent 'human-audit '())))
      (poo-flow-user-loop-engine-intent-operation-result-contract intent)
      (poo-flow-user-loop-engine-intent-runtime-intent intent)
      (poo-flow-user-loop-engine-intent-status intent)
      #f
      (list (cons 'source 'user-config-loop-engine)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Delegated operations are the Flue-style readable view over the canonical
;;; agent-operation row. They name the governor, reviewer, and human audit gate
;;; without claiming Scheme has executed the node.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-delegated-operation intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (agent-judges
          (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '()))
         (governor-agent
          (poo-flow-user-loop-engine-agent-judge-ref
           agent-judges
           'governor
           'loop-governor-agent))
         (explicit-reviewer-agent
          (poo-flow-user-loop-engine-agent-judge-ref
           agent-judges
           'reviewer
           #f))
         (reviewer-agent
          (if explicit-reviewer-agent
            explicit-reviewer-agent
            (poo-flow-user-loop-engine-agent-judge-ref
             agent-judges
             'verifier
             (poo-flow-user-loop-engine-agent-judge-ref
              agent-judges
              'auditor
              'loop-reviewer-agent))))
         (auditor-agent
          (poo-flow-user-loop-engine-agent-judge-ref
           agent-judges
           'auditor
           reviewer-agent))
         (human-audit
          (poo-flow-user-loop-engine-intent-ref intent 'human-audit '())))
    (list
     (cons 'kind 'delegated-operation)
     (cons 'contract 'poo-flow.loop-engine.delegated-operation.v1)
     (cons 'source 'user-config-loop-engine)
     (cons 'object-family 'agent-operation)
     (cons 'operation-ref
           (poo-flow-user-loop-engine-runtime-id use-case-name "operation"))
     (cons 'operation-kind
           (poo-flow-user-loop-engine-intent-operation-kind intent))
     (cons 'workflow-run-ref
           (poo-flow-user-loop-engine-runtime-id use-case-name "workflow-run"))
     (cons 'session-ref
           (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
     (cons 'child-session-ref
           (poo-flow-user-loop-engine-runtime-id
            use-case-name
            "delegate-session"))
     (cons 'workflow-ref
           (poo-flow-user-loop-engine-intent-workflow-ref intent))
     (cons 'governor-agent governor-agent)
     (cons 'reviewer-agent reviewer-agent)
     (cons 'reviewer-role
           (if explicit-reviewer-agent 'reviewer 'verifier))
     (cons 'auditor-agent auditor-agent)
     (cons 'human-audit human-audit)
     (cons 'human-audit-profile
           (if (null? human-audit) #f 'human-audit))
     (cons 'human-audit-required?
           (not (null? human-audit)))
     (cons 'result-contract
           (poo-flow-user-loop-engine-intent-result-contract intent))
     (cons 'structured-result-contract
           (poo-flow-user-loop-engine-intent-operation-result-contract
            intent))
     (cons 'runtime-intent
           (poo-flow-user-loop-engine-intent-runtime-intent intent))
     (cons 'status
           (poo-flow-user-loop-engine-intent-status intent))
     (cons 'descriptor-realized? #f)
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))
