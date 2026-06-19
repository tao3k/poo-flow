;;; -*- Gerbil -*-
;;; Owner: agent-sandbox bridge envelope projection lives in this module.
;;; Boundary: core runtime adapters provide the generic Rust envelope contract.
;;; Boundary: this module adds extension fields for Marlin-compatible runtimes.
;;; Import contract: the facade re-exports this bridge surface for opt-in users.
;;; Runtime contract: bridge envelopes are data only.
;;; Runtime contract: real sandbox execution stays behind runtime commands.
;;; Policy evidence: runtime command tests should assert this projection surface.

(import :core/api
        :modules/agent-sandbox/alist
        :modules/agent-sandbox/request)

(export +agent-sandbox-bridge-schema+
        +agent-sandbox-runtime-manifest-schema+
        agent-sandbox-execution-request-config
        agent-sandbox-execution-request?
        agent-sandbox-validate-execution-request
        agent-sandbox-request->runtime-manifest
        make-agent-sandbox-bridge-envelope
        agent-sandbox-runtime-command-result
        agent-sandbox-command-submit)

;;; The bridge schema marks extension-aware envelopes without changing the
;;; stable core runtime request schema used by existing adapters.
;; : (-> Unit Symbol)
(def +agent-sandbox-bridge-schema+ 'poo-flow.agent-sandbox-bridge.v1)

;;; Runtime manifests are the bridge-facing request contract for Marlin. They
;;; regroup the normalized request without choosing a backend implementation.
;; : (-> Unit Symbol)
(def +agent-sandbox-runtime-manifest-schema+
  'poo-flow.agent-sandbox-runtime-manifest.v1)

;;; Execution request projection is intentionally narrow: only agent-sandbox
;;; tasks expose the normalized sandbox request to runtime bridge helpers.
;; : (-> ExecutionRequest (U AgentSandboxRequest #f))
(def (agent-sandbox-execution-request-config request)
  (if (and (execution-request? request)
           (eq? (execution-request-kind request) 'agent-sandbox))
    (let (payload (execution-request-request request))
      (if (and (pair? payload)
               (pair? (cdr payload)))
        (cadr payload)
        #f))
    #f))

;;; The execution request predicate checks the task family and normalized
;;; request schema, leaving per-backend interpretation to the runtime owner.
;; : (-> ExecutionRequestCandidate Boolean)
(def (agent-sandbox-execution-request? request)
  (and (execution-request? request)
       (agent-sandbox-request?
        (agent-sandbox-execution-request-config request))))

;;; Bridge validation is the final Scheme contract before Marlin or another
;;; runtime command receives an agent-sandbox envelope.
;;; Boundary:
;;; - Non-agent execution requests must fail here instead of projecting #f fields.
;;; - Backend-specific policy validation still belongs to the runtime owner.
;; : (-> ExecutionRequest ExecutionRequest)
(def (agent-sandbox-validate-execution-request request)
  (if (agent-sandbox-execution-request? request)
    request
    (raise-control-plane-failure
     'agent-sandbox
     'invalid-agent-sandbox-execution-request
     "invalid agent sandbox execution request"
     (list (cons 'request request)))))

;;; Runtime manifest projection keeps Marlin and C/R bindings away from the
;;; raw request alist while preserving all backend-neutral policy data.
;;; Boundary:
;;; - Process, filesystem, network, resource, and output fields are grouped.
;;; - Real nono/Cube execution still belongs to runtime commands.
;; : (-> AgentSandboxRequest AgentSandboxRuntimeManifest)
(def (agent-sandbox-request->runtime-manifest request)
  (let (sandbox (agent-sandbox-validate-request request))
    (let* ((command (agent-sandbox-request-ref sandbox 'command #f))
           (args (agent-sandbox-request-ref sandbox 'args '())))
      (list (cons 'schema +agent-sandbox-runtime-manifest-schema+)
            (cons 'backend
                  (list (cons 'kind
                              (agent-sandbox-request-ref sandbox
                                                         'backend-kind
                                                         #f))
                        (cons 'ref
                              (agent-sandbox-request-ref sandbox
                                                         'backend-ref
                                                         #f))))
            (cons 'process
                  (list (cons 'command command)
                        (cons 'args args)
                        (cons 'argv (cons command args))
                        (cons 'env
                              (agent-sandbox-request-ref sandbox 'env '()))
                        (cons 'workdir
                              (agent-sandbox-request-ref sandbox
                                                         'workdir
                                                         #f))))
            (cons 'filesystem
                  (list (cons 'mounts
                              (agent-sandbox-request-ref sandbox
                                                         'mounts
                                                         '()))))
            (cons 'network-policy
                  (agent-sandbox-request-ref sandbox 'network-policy '()))
            (cons 'capabilities
                  (agent-sandbox-request-ref sandbox 'capabilities '()))
            (cons 'resource-policy
                  (agent-sandbox-request-ref sandbox 'resource-policy '()))
            (cons 'output-policy
                  (agent-sandbox-request-ref sandbox 'output-policy #f))
            (cons 'metadata
                  (agent-sandbox-request-ref sandbox 'metadata '()))))))

;;; Intent: extend the core Rust request envelope at the bridge edge, not in
;;; core task structs. Marlin can consume these projection fields without
;;; depending on Gerbil's internal =('agent-sandbox request)= pair shape.
;; : (-> ExecutionRequest [Symbol] Alist)
(def (make-agent-sandbox-bridge-envelope request . maybe-operation)
  (let* ((operation (if (null? maybe-operation) 'submit (car maybe-operation)))
         (valid-request (agent-sandbox-validate-execution-request request))
         (sandbox (agent-sandbox-execution-request-config valid-request)))
    (append
     (rust-request-envelope valid-request operation)
     (list (cons 'extension-schema +agent-sandbox-bridge-schema+)
           (cons 'extension 'agent-sandbox)
           (cons 'request-schema
                 (agent-sandbox-request-ref sandbox 'schema #f))
           (cons 'backend-kind
                 (agent-sandbox-request-ref sandbox 'backend-kind #f))
           (cons 'backend-ref
                 (agent-sandbox-request-ref sandbox 'backend-ref #f))
           (cons 'command
                 (agent-sandbox-request-ref sandbox 'command #f))
           (cons 'runtime-manifest
                 (agent-sandbox-request->runtime-manifest sandbox))
           (cons 'sandbox sandbox)))))

;;; Runtime command errors keep the bridge envelope identifiers, so Marlin-side
;;; failures can be correlated without knowing the underlying Gerbil task.
;; : (-> RuntimeCommand Alist AdapterResult)
(def (agent-sandbox-runtime-command-result command envelope)
  (with-catch
   (lambda (failure)
     (make-adapter-result
      (agent-sandbox-alist-ref envelope 'request-id #f)
      'failed
      #f
      (agent-sandbox-alist-ref envelope 'artifact-handle #f)
      (list (cons 'code 'agent-sandbox-runtime-command-error)
            (cons 'error failure))))
   (lambda ()
     (normalize-runtime-response envelope
                                 (runtime-command-call command envelope)))))

;;; Agent-sandbox command submission swaps in the extension bridge envelope.
;;; The command still returns the same runtime response schema as core adapters.
;; : (-> RuntimeCommand ExecutionRequest AdapterResult)
(def (agent-sandbox-command-submit command request)
  (agent-sandbox-runtime-command-result
   command
   (make-agent-sandbox-bridge-envelope request)))
