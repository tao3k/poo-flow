;;; -*- Gerbil -*-
;;; Boundary: POO-native session, agent, hook, and tool policy objects.
;;; Invariant: policy objects describe authorization and sharing intent only;
;;; they never execute tools, hooks, providers, or sandbox runtimes.

(import (only-in :clan/poo/object .o .ref .slot? object? object<-alist)
        :poo-flow/src/module-system/durable-policy
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy-syntax)

(export poo-flow-session-policy?
        poo-flow-session-policy-kind
        poo-flow-session-policy-name
        poo-flow-session-policy-scope-ref
        poo-flow-session-policy-default-action
        poo-flow-session-policy->alist
        poo-flow-session-policy-attach-durable
        poo-flow-session-policy-durable-receipt
        poo-flow-session-tool-grant
        poo-flow-session-tool-grant?
        poo-flow-session-tool-grant-id
        poo-flow-session-tool-grant-tool-ref
        poo-flow-session-tool-grant-actions
        poo-flow-session-tool-grant-resource-refs
        poo-flow-session-tool-grant-trigger-refs
        poo-flow-session-tool-grant-allows?
        poo-flow-session-isolation-policy
        poo-flow-session-sandbox-policy
        poo-flow-session-context-policy
        poo-flow-session-history-policy
        poo-flow-session-communication-policy
        poo-flow-session-sharing-policy
        poo-flow-session-resource-policy
        poo-flow-session-model-policy
        poo-flow-session-prompt-policy
        poo-flow-session-tool-permission-policy
        poo-flow-session-hook-tool-permission-policy
        poo-flow-session-resource-sharing-policy
        poo-flow-session-agent-execution-policy
        poo-flow-session-tool-permission-policy-allows?
        poo-flow-session-hook-tool-permission-policy-allows?)

;; : (-> Any Boolean)
(def (poo-flow-session-policy-ref? value)
  (or (symbol? value) (string? value)))

;; : (-> [Any] Boolean)
(def (poo-flow-session-policy-ref-list? values)
  (and (list? values)
       (poo-flow-session-every? poo-flow-session-policy-ref? values)))

;; : (-> [Any] Boolean)
(def (poo-flow-session-symbol-list? values)
  (and (list? values)
       (poo-flow-session-every? symbol? values)))

;; : (-> Any [Any] Boolean)
(def (poo-flow-session-policy-member? value values)
  (if (member value values) #t #f))

;; : (-> Any [Any] Boolean)
(def (poo-flow-session-policy-match? value values)
  (or (poo-flow-session-policy-member? value values)
      (poo-flow-session-policy-member? '* values)))

;; : (-> POOObject Symbol Value Value)
(def (poo-flow-session-policy-slot policy key default)
  (with-catch
   (lambda (_failure) default)
   (lambda ()
     (.ref policy key))))

;; : (-> POOObject Boolean)
(def (poo-flow-session-policy? value)
  (and (object? value)
       (eq? (poo-flow-session-policy-slot value 'kind #f)
            'poo-flow.session.policy)))

;; : PooSessionPolicy -> Value accessors
(defpoo-session-policy-slot-accessors
  poo-flow-session-policy-slot
  (poo-flow-session-policy-kind policy-kind #f)
  (poo-flow-session-policy-name policy-name #f)
  (poo-flow-session-policy-scope-ref scope-ref #f)
  (poo-flow-session-policy-default-action default-action 'deny))

;; : (-> PooSessionPolicy PooDurablePolicy PooSessionPolicy)
(def (poo-flow-session-policy-attach-durable policy durable-policy)
  (poo-flow-session-require "session durable attach requires a session policy"
                            (poo-flow-session-policy? policy)
                            policy)
  (poo-flow-session-require "session durable attach requires a durable policy"
                            (poo-flow-durable-policy? durable-policy)
                            durable-policy)
  (.o (:: @ [policy durable-policy])))

;; : (-> PooSessionPolicy [Alist] MaybePooDurablePolicyReceipt)
(def (poo-flow-session-policy-durable-receipt policy . maybe-identity)
  (if (poo-flow-durable-policy? policy)
    (apply poo-flow-durable-policy->receipt policy maybe-identity)
    #f))

;; : (-> PooSessionPolicy [Pair])
(def +poo-flow-session-policy-no-durable-rows+
  '((durable-policy . #f)
    (durable-policy-ref . #f)
    (durable-valid? . #f)
    (durable-diagnostic-count . 0)))

;; : (-> PooSessionPolicy [Pair])
(def (poo-flow-session-policy-durable-rows policy)
  (let (receipt (poo-flow-session-policy-durable-receipt policy))
    (if receipt
      (list
       (cons 'durable-policy
             (poo-flow-durable-policy-receipt->alist receipt))
       (cons 'durable-policy-ref
             (poo-flow-durable-policy-receipt-policy-id receipt))
       (cons 'durable-valid?
             (poo-flow-durable-policy-receipt-valid? receipt))
       (cons 'durable-diagnostic-count
             (length
              (poo-flow-durable-policy-receipt-diagnostics receipt))))
      +poo-flow-session-policy-no-durable-rows+)))

;; : (-> Any Boolean)
(def (poo-flow-session-policy-fast-policy? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) 'poo-flow.session.policy)))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-session-policy-slot-row policy-slots key default)
  (poo-flow-session-alist-ref policy-slots key default))

;; : (-> PooSessionPolicy Alist)
(def (poo-flow-session-policy->alist policy)
  (poo-flow-session-require
   "session policy projection requires a policy"
   (poo-flow-session-policy-fast-policy? policy)
   policy)
  (let* ((policy-slots
          (.ref policy 'policy-slots))
         (tool-grants
          (poo-flow-session-policy-slot-row policy-slots
                                            'tool-grants
                                            '())))
    (poo-flow-session-policy-rows/tail
     (list
      (cons 'kind (.ref policy 'kind))
      (cons 'schema (.ref policy 'schema))
      (cons 'policy-kind (.ref policy 'policy-kind))
      (cons 'policy-name (.ref policy 'policy-name))
      (cons 'scope-ref (.ref policy 'scope-ref))
      (cons 'default-action (.ref policy 'default-action))
      (cons 'policy-slots policy-slots)
      (cons 'agent-ref
            (poo-flow-session-policy-slot-row policy-slots 'agent-ref #f))
      (cons 'session-ref
            (poo-flow-session-policy-slot-row policy-slots 'session-ref #f))
      (cons 'provider-ref
            (poo-flow-session-policy-slot-row policy-slots 'provider-ref #f))
      (cons 'model-ref
            (poo-flow-session-policy-slot-row policy-slots 'model-ref #f))
      (cons 'prompt-session-ref
            (poo-flow-session-policy-slot-row
             policy-slots
             'prompt-session-ref
             #f))
      (cons 'prompt-chunk-refs
            (poo-flow-session-policy-slot-row
             policy-slots
             'prompt-chunk-refs
             '()))
      (cons 'context-mode
            (poo-flow-session-policy-slot-row
             policy-slots
             'context-mode
             'isolated))
      (cons 'model-policy-ref
            (poo-flow-session-policy-slot-row
             policy-slots
             'model-policy-ref
             #f))
      (cons 'prompt-policy-ref
            (poo-flow-session-policy-slot-row
             policy-slots
             'prompt-policy-ref
             #f))
      (cons 'tool-policy-ref
            (poo-flow-session-policy-slot-row
             policy-slots
             'tool-policy-ref
             #f))
      (cons 'hook-policy-ref
            (poo-flow-session-policy-slot-row
             policy-slots
             'hook-policy-ref
             #f))
      (cons 'context-policy-ref
            (poo-flow-session-policy-slot-row
             policy-slots
             'context-policy-ref
             #f))
      (cons 'resource-policy-ref
            (poo-flow-session-policy-slot-row
             policy-slots
             'resource-policy-ref
             #f))
      (cons 'tool-grants tool-grants)
      (cons 'tool-grant-count (length tool-grants))
      (cons 'denied-tool-refs
            (poo-flow-session-policy-slot-row
             policy-slots
             'denied-tool-refs
             '()))
      (cons 'hook-events
            (poo-flow-session-policy-slot-row policy-slots
                                              'hook-events
                                              '()))
      (cons 'resource-grants
            (poo-flow-session-policy-slot-row
             policy-slots
             'resource-grants
             '()))
      (cons 'metadata (.ref policy 'metadata))
      (cons 'runtime-owner (.ref policy 'runtime-owner))
      (cons 'runtime-executed (.ref policy 'runtime-executed)))
     (poo-flow-session-policy-durable-rows policy))))

;; : (-> Alist Alist Alist)
(def (poo-flow-session-policy-rows/tail rows tail)
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

;; : (-> Alist Alist Alist)
(def (poo-flow-session-policy-slots/tail policy-slots tail)
  (poo-flow-session-policy-rows/tail policy-slots tail))

;; : (-> Symbol Symbol Symbol Symbol Symbol Alist Alist Alist)
(def (poo-flow-session-policy-object-rows policy-kind
                                          schema
                                          policy-name
                                          scope-ref
                                          default-action
                                          policy-slots
                                          metadata)
  (poo-flow-session-policy-rows/tail
   (list
    (cons 'kind 'poo-flow.session.policy)
    (cons 'schema schema)
    (cons 'policy-kind policy-kind)
    (cons 'policy-name policy-name)
    (cons 'scope-ref scope-ref)
    (cons 'default-action default-action)
    (cons 'policy-slots policy-slots))
   (poo-flow-session-policy-slots/tail
    policy-slots
    (list
     (cons 'metadata metadata)
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f)))))

;; : (-> Symbol Symbol Symbol Symbol Symbol Alist [Alist] PooSessionPolicy)
(def (poo-flow-session-policy-object policy-kind
                                     schema
                                     policy-name
                                     scope-ref
                                     default-action
                                     policy-slots
                                     . maybe-metadata)
  (poo-flow-session-require "session policy kind must be a symbol"
                            (symbol? policy-kind)
                            policy-kind)
  (poo-flow-session-require "session policy schema must be a symbol"
                            (symbol? schema)
                            schema)
  (poo-flow-session-require "session policy name must be a symbol"
                            (symbol? policy-name)
                            policy-name)
  (poo-flow-session-require "session policy scope ref must be a symbol"
                            (symbol? scope-ref)
                            scope-ref)
  (poo-flow-session-require "session policy default action must be a symbol"
                            (symbol? default-action)
                            default-action)
  (poo-flow-session-require "session policy slots must be an alist"
                            (list? policy-slots)
                            policy-slots)
  (object<-alist
   (poo-flow-session-policy-object-rows
    policy-kind
    schema
    policy-name
    scope-ref
    default-action
    policy-slots
    (if (null? maybe-metadata)
      '()
      (car maybe-metadata)))))

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-isolation-policy
  poo-flow-session-policy-object
  (kind 'session-isolation)
  (schema 'poo-flow.modules.session.policy.isolation.v1)
  (default-action 'deny)
  (parameters (policy-name scope-ref mode sibling-context parent-write
                           peer-communication . maybe-metadata))
  (slots (('mode mode)
          ('sibling-context sibling-context)
          ('parent-write parent-write)
          ('peer-communication peer-communication)))
  (validate))

;; : (-> Symbol Symbol Symbol Symbol Symbol [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-sandbox-policy
  poo-flow-session-policy-object
  (kind 'session-sandbox)
  (schema 'poo-flow.modules.session.policy.sandbox.v1)
  (default-action 'deny)
  (parameters (policy-name scope-ref profile-ref inheritance-mode
                           sharing-mode . maybe-metadata))
  (slots (('profile-ref profile-ref)
          ('inheritance-mode inheritance-mode)
          ('sharing-mode sharing-mode)))
  (validate))

;; : (-> Symbol Symbol Symbol [Symbol] [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-context-policy
  poo-flow-session-policy-object
  (kind 'session-context)
  (schema 'poo-flow.modules.session.policy.context.v1)
  (default-action 'deny)
  (parameters (policy-name scope-ref visibility allowed-session-refs
                           . maybe-metadata))
  (slots (('visibility visibility)
          ('allowed-session-refs allowed-session-refs)))
  (validate
   (poo-flow-session-require "session context allowed refs must be symbols"
                             (poo-flow-session-symbol-list?
                              allowed-session-refs)
                             allowed-session-refs)))

;; : (-> Symbol Symbol Symbol [Symbol] [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-history-policy
  poo-flow-session-policy-object
  (kind 'session-history)
  (schema 'poo-flow.modules.session.policy.history.v1)
  (default-action 'deny)
  (parameters (policy-name scope-ref retention allowed-records
                           . maybe-metadata))
  (slots (('retention retention)
          ('allowed-records allowed-records)))
  (validate
   (poo-flow-session-require "session history records must be symbols"
                             (poo-flow-session-symbol-list?
                              allowed-records)
                             allowed-records)))

;; : (-> Symbol Symbol [Symbol] [Symbol] [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-communication-policy
  poo-flow-session-policy-object
  (kind 'session-communication)
  (schema 'poo-flow.modules.session.policy.communication.v1)
  (default-action 'deny)
  (parameters (policy-name scope-ref channel-refs target-session-refs
                           . maybe-metadata))
  (slots (('channel-refs channel-refs)
          ('target-session-refs target-session-refs)))
  (validate
   (poo-flow-session-require "session communication channels must be symbols"
                             (poo-flow-session-symbol-list?
                              channel-refs)
                             channel-refs)
   (poo-flow-session-require "session communication targets must be symbols"
                             (poo-flow-session-symbol-list?
                              target-session-refs)
                             target-session-refs)))

;; : (-> Symbol Symbol [Symbol] [Symbol] [Symbol] [Symbol/String] [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-sharing-policy
  poo-flow-session-policy-object
  (kind 'session-sharing)
  (schema 'poo-flow.modules.session.policy.sharing.v1)
  (default-action 'deny)
  (parameters (policy-name scope-ref memory-refs artifact-refs
                           tool-result-refs workspace-paths
                           . maybe-metadata))
  (slots (('memory-refs memory-refs)
          ('artifact-refs artifact-refs)
          ('tool-result-refs tool-result-refs)
          ('workspace-paths workspace-paths)))
  (validate
   (poo-flow-session-require "session sharing memory refs must be symbols"
                             (poo-flow-session-symbol-list? memory-refs)
                             memory-refs)
   (poo-flow-session-require "session sharing artifact refs must be symbols"
                             (poo-flow-session-symbol-list? artifact-refs)
                             artifact-refs)
   (poo-flow-session-require
    "session sharing tool result refs must be symbols"
    (poo-flow-session-symbol-list? tool-result-refs)
    tool-result-refs)
   (poo-flow-session-require
    "session sharing workspace paths must be symbols or strings"
    (poo-flow-session-policy-ref-list? workspace-paths)
    workspace-paths)))

;; : (-> Symbol Symbol [Symbol] [Symbol] Symbol [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-resource-policy
  poo-flow-session-policy-object
  (kind 'session-resource)
  (schema 'poo-flow.modules.session.policy.resource.v1)
  (default-action 'deny)
  (parameters (policy-name scope-ref budget-refs capability-refs
                           accounting-owner . maybe-metadata))
  (slots (('budget-refs budget-refs)
          ('capability-refs capability-refs)
          ('accounting-owner accounting-owner)))
  (validate
   (poo-flow-session-require "session resource budget refs must be symbols"
                             (poo-flow-session-symbol-list? budget-refs)
                             budget-refs)
   (poo-flow-session-require
    "session resource capability refs must be symbols"
    (poo-flow-session-symbol-list? capability-refs)
    capability-refs)
   (poo-flow-session-require
    "session resource accounting owner must be a symbol"
    (symbol? accounting-owner)
    accounting-owner)))

;; : (-> Symbol Symbol [Symbol] [Symbol/String] [Symbol] [Alist] PooSessionToolGrant)
(def (poo-flow-session-tool-grant grant-id
                                  tool-ref
                                  actions
                                  resource-refs
                                  trigger-refs
                                  . maybe-metadata)
  (poo-flow-session-require "session tool grant id must be a symbol"
                            (symbol? grant-id)
                            grant-id)
  (poo-flow-session-require "session tool grant tool ref must be a symbol"
                            (symbol? tool-ref)
                            tool-ref)
  (poo-flow-session-require "session tool grant actions must be symbols"
                            (poo-flow-session-symbol-list? actions)
                            actions)
  (poo-flow-session-require
   "session tool grant resource refs must be symbols or strings"
   (poo-flow-session-policy-ref-list? resource-refs)
   resource-refs)
  (poo-flow-session-require "session tool grant trigger refs must be symbols"
                            (poo-flow-session-symbol-list? trigger-refs)
                            trigger-refs)
  (list
   (cons 'kind 'poo-flow.session.tool-grant)
   (cons 'schema 'poo-flow.modules.session.tool-grant.v1)
   (cons 'grant-id grant-id)
   (cons 'tool-ref tool-ref)
   (cons 'actions actions)
   (cons 'resource-refs resource-refs)
   (cons 'trigger-refs trigger-refs)
   (cons 'metadata (if (null? maybe-metadata) '() (car maybe-metadata)))
   (cons 'runtime-executed #f)))

;; : (-> Any Boolean)
(def (poo-flow-session-tool-grant? value)
  (and (list? value)
       (eq? (poo-flow-session-alist-ref value 'kind #f)
            'poo-flow.session.tool-grant)))

;; : PooSessionToolGrant -> Value accessors
(defpoo-session-alist-accessors
  poo-flow-session-alist-ref
  (poo-flow-session-tool-grant-id grant-id #f)
  (poo-flow-session-tool-grant-tool-ref tool-ref #f)
  (poo-flow-session-tool-grant-actions actions '())
  (poo-flow-session-tool-grant-resource-refs resource-refs '())
  (poo-flow-session-tool-grant-trigger-refs trigger-refs '()))

;; : (-> PooSessionToolGrant Symbol Symbol Boolean)
(def (poo-flow-session-tool-grant-allows? grant tool-ref action)
  (and (poo-flow-session-tool-grant? grant)
       (poo-flow-session-policy-match?
        tool-ref
        (list (poo-flow-session-tool-grant-tool-ref grant)))
       (poo-flow-session-policy-match?
        action
        (poo-flow-session-tool-grant-actions grant))))

;; : (-> Symbol Symbol Symbol Symbol [Symbol] Symbol [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-model-policy
  poo-flow-session-policy-object
  (kind 'agent-model)
  (schema 'poo-flow.modules.session.policy.model.v1)
  (default-action 'deny)
  (parameters (policy-name scope-ref provider-ref model-ref
                           model-capabilities budget-ref
                           . maybe-metadata))
  (slots (('provider-ref provider-ref)
          ('model-ref model-ref)
          ('model-capabilities model-capabilities)
          ('budget-ref budget-ref)))
  (validate
   (poo-flow-session-require "session model policy provider must be a symbol"
                             (symbol? provider-ref)
                             provider-ref)
   (poo-flow-session-require "session model policy model must be a symbol"
                             (symbol? model-ref)
                             model-ref)
   (poo-flow-session-require "session model capabilities must be symbols"
                             (poo-flow-session-symbol-list?
                              model-capabilities)
                             model-capabilities)
   (poo-flow-session-require "session model budget ref must be a symbol"
                             (symbol? budget-ref)
                             budget-ref)))

;; : (-> Symbol Symbol Symbol [Symbol] Symbol [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-prompt-policy
  poo-flow-session-policy-object
  (kind 'agent-prompt)
  (schema 'poo-flow.modules.session.policy.prompt.v1)
  (default-action 'deny)
  (parameters (policy-name scope-ref prompt-session-ref prompt-chunk-refs
                           context-mode . maybe-metadata))
  (slots (('prompt-session-ref prompt-session-ref)
          ('prompt-chunk-refs prompt-chunk-refs)
          ('context-mode context-mode)))
  (validate
   (poo-flow-session-require
    "session prompt policy prompt session ref must be a symbol"
    (symbol? prompt-session-ref)
    prompt-session-ref)
   (poo-flow-session-require "session prompt chunk refs must be symbols"
                             (poo-flow-session-symbol-list?
                              prompt-chunk-refs)
                             prompt-chunk-refs)
   (poo-flow-session-require "session prompt context mode must be a symbol"
                             (symbol? context-mode)
                             context-mode)))

;; : (-> Symbol Symbol [PooSessionToolGrant] [Symbol] Symbol [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-tool-permission-policy
  poo-flow-session-policy-object
  (kind 'agent-tool-permission)
  (schema 'poo-flow.modules.session.policy.tool-permission.v1)
  (default-action default-action)
  (parameters (policy-name scope-ref tool-grants denied-tool-refs
                           default-action . maybe-metadata))
  (slots (('tool-grants tool-grants)
          ('denied-tool-refs denied-tool-refs)))
  (validate
   (poo-flow-session-require "session tool grants must be a list"
                             (list? tool-grants)
                             tool-grants)
   (poo-flow-session-require "session tool grants must contain only grants"
                             (poo-flow-session-every?
                              poo-flow-session-tool-grant?
                              tool-grants)
                             tool-grants)
   (poo-flow-session-require "session denied tools must be symbols"
                             (poo-flow-session-symbol-list?
                              denied-tool-refs)
                             denied-tool-refs)
   (poo-flow-session-require
    "session tool policy default action must be a symbol"
    (symbol? default-action)
    default-action)))

;; : (-> Symbol Symbol [Symbol] [PooSessionToolGrant] Symbol Symbol [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-hook-tool-permission-policy
  poo-flow-session-policy-object
  (kind 'hook-tool-permission)
  (schema 'poo-flow.modules.session.policy.hook-tool-permission.v1)
  (default-action default-action)
  (parameters (policy-name scope-ref hook-events tool-grants
                           escalation-policy default-action
                           . maybe-metadata))
  (slots (('hook-events hook-events)
          ('tool-grants tool-grants)
          ('escalation-policy escalation-policy)))
  (validate
   (poo-flow-session-require "session hook events must be symbols"
                             (poo-flow-session-symbol-list?
                              hook-events)
                             hook-events)
   (poo-flow-session-require "session hook tool grants must be a list"
                             (list? tool-grants)
                             tool-grants)
   (poo-flow-session-require
    "session hook tool grants must contain only grants"
    (poo-flow-session-every? poo-flow-session-tool-grant?
                             tool-grants)
    tool-grants)
   (poo-flow-session-require "session hook escalation must be a symbol"
                             (symbol? escalation-policy)
                             escalation-policy)
   (poo-flow-session-require "session hook default action must be a symbol"
                             (symbol? default-action)
                             default-action)))

;; : (-> Symbol Symbol [Alist] Symbol [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-resource-sharing-policy
  poo-flow-session-policy-object
  (kind 'resource-sharing)
  (schema 'poo-flow.modules.session.policy.resource-sharing.v1)
  (default-action default-action)
  (parameters (policy-name scope-ref resource-grants default-action
                           . maybe-metadata))
  (slots (('resource-grants resource-grants)))
  (validate
   (poo-flow-session-require "session resource grants must be a list"
                             (list? resource-grants)
                             resource-grants)
   (poo-flow-session-require
    "session resource default action must be a symbol"
    (symbol? default-action)
    default-action)))

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol Symbol Symbol Symbol [Alist] PooSessionPolicy)
(defpoo-session-policy-family
  poo-flow-session-agent-execution-policy
  poo-flow-session-policy-object
  (kind 'agent-execution)
  (schema 'poo-flow.modules.session.policy.agent-execution.v1)
  (default-action 'deny)
  (scope-ref session-ref)
  (parameters (policy-name agent-ref session-ref model-policy-ref
                           prompt-policy-ref tool-policy-ref hook-policy-ref
                           context-policy-ref resource-policy-ref
                           . maybe-metadata))
  (slots (('agent-ref agent-ref)
          ('session-ref session-ref)
          ('model-policy-ref model-policy-ref)
          ('prompt-policy-ref prompt-policy-ref)
          ('tool-policy-ref tool-policy-ref)
          ('hook-policy-ref hook-policy-ref)
          ('context-policy-ref context-policy-ref)
          ('resource-policy-ref resource-policy-ref)))
  (validate
   (poo-flow-session-require "session agent execution agent ref must be a symbol"
                             (symbol? agent-ref)
                             agent-ref)
   (poo-flow-session-require "session agent execution session ref must be a symbol"
                             (symbol? session-ref)
                             session-ref)
   (poo-flow-session-require "session agent model policy ref must be a symbol"
                             (symbol? model-policy-ref)
                             model-policy-ref)
   (poo-flow-session-require "session agent prompt policy ref must be a symbol"
                             (symbol? prompt-policy-ref)
                             prompt-policy-ref)
   (poo-flow-session-require "session agent tool policy ref must be a symbol"
                             (symbol? tool-policy-ref)
                             tool-policy-ref)
   (poo-flow-session-require "session agent hook policy ref must be a symbol"
                             (symbol? hook-policy-ref)
                             hook-policy-ref)
   (poo-flow-session-require "session agent context policy ref must be a symbol"
                             (symbol? context-policy-ref)
                             context-policy-ref)
   (poo-flow-session-require "session agent resource policy ref must be a symbol"
                             (symbol? resource-policy-ref)
                             resource-policy-ref)))

;; : (-> [PooSessionToolGrant] Symbol Symbol Boolean)
(def (poo-flow-session-tool-grants-allow? grants tool-ref action)
  (cond
   ((null? grants) #f)
   ((poo-flow-session-tool-grant-allows? (car grants) tool-ref action) #t)
   (else
    (poo-flow-session-tool-grants-allow? (cdr grants) tool-ref action))))

;; : (-> PooSessionPolicy Symbol Symbol Boolean)
(def (poo-flow-session-tool-permission-policy-allows? policy
                                                      tool-ref
                                                      action)
  (poo-flow-session-require "session tool permission requires a policy"
                            (poo-flow-session-policy? policy)
                            policy)
  (and (eq? (poo-flow-session-policy-kind policy)
            'agent-tool-permission)
       (not (poo-flow-session-policy-match?
             tool-ref
             (poo-flow-session-policy-slot policy
                                           'denied-tool-refs
                                           '())))
       (poo-flow-session-tool-grants-allow?
        (poo-flow-session-policy-slot policy 'tool-grants '())
        tool-ref
        action)))

;; : (-> PooSessionPolicy Symbol Symbol Symbol Boolean)
(def (poo-flow-session-hook-tool-permission-policy-allows? policy
                                                           hook-event
                                                           tool-ref
                                                           action)
  (poo-flow-session-require "session hook tool permission requires a policy"
                            (poo-flow-session-policy? policy)
                            policy)
  (and (eq? (poo-flow-session-policy-kind policy)
            'hook-tool-permission)
       (poo-flow-session-policy-match?
        hook-event
        (poo-flow-session-policy-slot policy 'hook-events '()))
       (poo-flow-session-tool-grants-allow?
        (poo-flow-session-policy-slot policy 'tool-grants '())
        tool-ref
        action)))
