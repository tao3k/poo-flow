;;; -*- Gerbil -*-
;;; Owner: agent-sandbox request builders live here.
;;; Boundary:
;;; - Field and profile validation happen before normalized request assembly.
;;; - Final request validation remains delegated to request-validation.
;;; Runtime contract:
;;; - Builders return inert request alists for adapter handoff.
;;; Policy evidence:
;;; - The named-field macro and profiled flow both call these constructors.

(import :core/api
        :extensions/agent-sandbox-util
        :extensions/agent-sandbox-profile
        :extensions/agent-sandbox-request-field
        :extensions/agent-sandbox-request-validation)

(export make-agent-sandbox-request
        make-agent-sandbox-request-with
        make-agent-sandbox-request-from-fields)

;;; Normalized assembly is concrete: one validated profile plus one validated
;;; field alist becomes the bridge-stable request shape consumed by adapters.
;; AgentSandboxRequest <- AgentSandboxProfile AgentSandboxRequestFields
(def (agent-sandbox-normalized-request profile fields)
  (let* ((valid-profile (agent-sandbox-validate-profile profile))
         (request-fields (agent-sandbox-validate-request-fields fields)))
    (agent-sandbox-validate-request
     (list (cons 'schema +agent-sandbox-request-schema+)
           (cons 'backend-kind
                 (agent-sandbox-profile-backend-kind valid-profile))
           (cons 'backend-ref
                 (agent-sandbox-profile-backend-ref valid-profile))
           (cons 'command (agent-sandbox-option request-fields 'command #f))
           (cons 'args (agent-sandbox-option request-fields 'args '()))
           (cons 'env (agent-sandbox-option request-fields 'env '()))
           (cons 'workdir (agent-sandbox-option request-fields 'workdir #f))
           (cons 'mounts (agent-sandbox-option request-fields 'mounts '()))
           (cons 'network-policy
                 (agent-sandbox-override
                  (agent-sandbox-option request-fields 'network-policy #f)
                  (agent-sandbox-profile-network-policy valid-profile)))
           (cons 'capabilities
                 (agent-sandbox-merge-alists
                  (agent-sandbox-option request-fields 'capabilities #f)
                  (agent-sandbox-profile-capabilities valid-profile)))
           (cons 'resource-policy
                 (agent-sandbox-merge-alists
                  (agent-sandbox-option request-fields 'resource-policy #f)
                  (agent-sandbox-profile-resource-policy valid-profile)))
           (cons 'output-policy
                 (agent-sandbox-option request-fields 'output-policy #f))
           (cons 'metadata
                 (agent-sandbox-merge-alists
                  (agent-sandbox-option request-fields 'metadata '())
                  (agent-sandbox-profile-metadata valid-profile)))))))

;;; Macro entry point: generated code supplies a thunk that materializes field
;;; data once, while the builder owns validation and request assembly.
;; AgentSandboxRequest <- AgentSandboxProfile (AgentSandboxRequestFields <- Unit)
(def (make-agent-sandbox-request-with profile fields-thunk)
  (agent-sandbox-normalized-request profile (fields-thunk)))

;;; Positional construction is compatibility glue for older call sites. New
;;; code should prefer named fields or the request macro.
;; AgentSandboxRequest <- AgentSandboxProfile Command [Arg] Env Workdir Mounts NetworkPolicy Capabilities ResourcePolicy OutputPolicy Metadata
(def (make-agent-sandbox-request profile
                                 command
                                 args
                                 env
                                 workdir
                                 mounts
                                 network-policy
                                 capabilities
                                 resource-policy
                                 output-policy
                                 metadata)
  (make-agent-sandbox-request-from-fields
   profile
   (list (cons 'command command)
         (cons 'args args)
         (cons 'env env)
         (cons 'workdir workdir)
         (cons 'mounts mounts)
         (cons 'network-policy network-policy)
         (cons 'capabilities capabilities)
         (cons 'resource-policy resource-policy)
         (cons 'output-policy output-policy)
         (cons 'metadata metadata))))

;;; Named-field construction is the preferred typed contract for callers.
;;; Missing optional fields receive deterministic defaults during assembly.
;; AgentSandboxRequest <- AgentSandboxProfile AgentSandboxRequestFields
(def (make-agent-sandbox-request-from-fields profile fields)
  (agent-sandbox-normalized-request profile fields))
