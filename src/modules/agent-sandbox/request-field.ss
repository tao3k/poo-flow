;;; -*- Gerbil -*-
;;; Owner: agent-sandbox request field contracts live here.
;;; Boundary: this module validates named builder fields, not normalized requests.
;;; Runtime contract: accepted field names are inert data until request assembly.
;;; Policy evidence: request facade re-exports these constants for stable callers.

(import :poo-flow/src/core/api
        :poo-flow/src/modules/agent-sandbox/alist)

(export +agent-sandbox-request-schema+
        +agent-sandbox-request-field-names+
        agent-sandbox-request-builder-field?
        agent-sandbox-request-field-contract-errors
        agent-sandbox-validate-request-fields)

;; : (-> Unit Symbol)
(def +agent-sandbox-request-schema+ 'poo-flow.agent-sandbox-request.v1)

;;; Named request fields are the typed public surface for macro builders. They
;;; deliberately exclude profile-derived backend fields, which stay descriptor-owned.
;; : (-> Unit [Symbol])
(def +agent-sandbox-request-field-names+
  '(command
    args
    env
    workdir
    mounts
    network-policy
    capabilities
    resource-policy
    output-policy
    metadata))

;; : (-> Symbol Boolean)
(def (agent-sandbox-request-builder-field? field)
  (and (memq field +agent-sandbox-request-field-names+) #t))

;;; Field contract errors catch typo-level interface mistakes before request
;;; normalization merges profile defaults into the runtime-facing shape.
;; : (-> FieldAlist [ValidationError])
(def (agent-sandbox-request-field-contract-errors fields)
  (cond
   ((null? fields) '())
   ((and (pair? (car fields))
         (agent-sandbox-request-builder-field? (car (car fields))))
    (agent-sandbox-request-field-contract-errors (cdr fields)))
   ((pair? (car fields))
    (cons (list (cons 'field (car (car fields)))
                (cons 'code 'unsupported-field))
          (agent-sandbox-request-field-contract-errors (cdr fields))))
   (else
    (cons (list (cons 'field (car fields))
                (cons 'code 'malformed-field))
          (agent-sandbox-request-field-contract-errors (cdr fields))))))

;;; Field validation is the first gate for the higher-level request macro:
;;; accepted fields are explicit, but value-level semantics remain request-owned.
;; : (-> FieldAlist FieldAlist)
(def (agent-sandbox-validate-request-fields fields)
  (let (errors (agent-sandbox-request-field-contract-errors fields))
    (if (null? errors)
      fields
      (raise-control-plane-failure
       'agent-sandbox
       'invalid-agent-sandbox-request-fields
       "invalid agent sandbox request fields"
       (list (cons 'errors errors)
             (cons 'fields fields))))))
