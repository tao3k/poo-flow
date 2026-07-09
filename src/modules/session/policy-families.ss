;;; -*- Gerbil -*-
;;; Boundary: declared POO session policy families.

(import :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy-syntax
        :poo-flow/src/modules/session/policy-core
        :poo-flow/src/modules/session/policy-tool-grant)

(export poo-flow-session-isolation-policy
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
        poo-flow-session-agent-execution-policy)

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
