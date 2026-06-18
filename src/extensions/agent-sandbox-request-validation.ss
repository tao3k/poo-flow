;;; -*- Gerbil -*-
;;; Owner: agent-sandbox normalized request validation lives here.
;;; Boundary:
;;; - Request builders assemble data before calling this module.
;;; - Backend-specific policy payloads remain runtime-owned.
;;; Import contract:
;;; - Request owner re-exports these validators through the facade.
;;; Runtime contract:
;;; - Validation raises typed control-plane failures before bridge projection.
;;; - Predicate and lookup helpers never execute sandbox backends.
;;; Policy evidence:
;;; - Profile and bridge tests assert both valid requests and failure codes.

(import :core/api
        :extensions/agent-sandbox-util
        :extensions/agent-sandbox-profile
        :extensions/agent-sandbox-request-field)

(export agent-sandbox-request-validation-errors
        agent-sandbox-validate-request
        agent-sandbox-request?
        agent-sandbox-request-ref)

;;; Request validation covers the bridge-stable fields that every backend needs
;;; before runtime dispatch. Policy payloads stay backend-owned alists.
;; [ValidationError] <- AgentSandboxRequest
(def (agent-sandbox-request-validation-errors request)
  (append
   (if (eq? (agent-sandbox-request-ref request 'schema #f)
            +agent-sandbox-request-schema+)
     '()
     (list '((field . schema) (code . schema-mismatch))))
   (agent-sandbox-required-field-errors
    request
    (list (cons 'backend-kind (lambda (value) (and value #t)))
          (cons 'backend-ref (lambda (value) (and value #t)))
          (cons 'command (lambda (value) (and value #t)))))))

;;; Request validation is the last Scheme-side gate before a runtime adapter or
;;; bridge envelope sees the normalized sandbox request.
;; AgentSandboxRequest <- AgentSandboxRequest
(def (agent-sandbox-validate-request request)
  (let (errors (agent-sandbox-request-validation-errors request))
    (if (null? errors)
      request
      (raise-control-plane-failure
       'agent-sandbox
       'invalid-agent-sandbox-request
       "invalid agent sandbox request"
       (list (cons 'errors errors)
             (cons 'request request))))))

;;; Request predicates keep bridge code honest without making Scheme validate
;;; backend-specific policy details that Marlin or Cube/nono integrations own.
;; Boolean <- AgentSandboxRequestCandidate
(def (agent-sandbox-request? value)
  (and (list? value)
       (let (schema (assoc 'schema value))
         (and schema
              (eq? (cdr schema) +agent-sandbox-request-schema+)))))

;;; Public request lookup gives bridge tests and future bindings one stable
;;; reader instead of duplicating raw alist access at every integration point.
;; Value <- AgentSandboxRequest Symbol Value
(def (agent-sandbox-request-ref request key default)
  (agent-sandbox-alist-ref request key default))
