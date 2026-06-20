;;; -*- Gerbil -*-
;;; Owner: nono profile alignment lives in this backend module.
;;; Boundary: core provides schema, task, envelope, and adapter protocols.
;;; Import contract: users opt in through =:poo-flow/src/modules/agent-sandbox/nono= for profile defaults.
;;; Runtime contract: this module emits profile data only.
;;; Runtime contract: nono session startup stays behind Marlin runtime commands.
;;; Runtime contract: credentials and LLM calls stay out of Scheme.
;;; Policy evidence: tests should import this module when they assert nono defaults.

(import :poo-flow/src/modules/agent-sandbox/profile
        :poo-flow/src/modules/agent-sandbox/nono-profile-candidate)

(export make-nono-agent-sandbox-profile-descriptor
        make-nono-agent-sandbox-profile
        (import: :poo-flow/src/modules/agent-sandbox/nono-profile-candidate))

;;; nono profile defaults model local zero-setup agent sandboxing. The ordinary
;;; helper form keeps backend defaults explicit and avoids macro-only evidence.
;; : (-> BackendRef [Alist] AgentSandboxProfileDescriptor)
(def (make-nono-agent-sandbox-profile-descriptor backend-ref . maybe-options)
  (make-agent-sandbox-backend-profile-descriptor
   'nono-profile
   'nono
   backend-ref
   '((mode . proxy-only))
   '((filesystem . scoped)
     (credentials . injected))
   '((filesystem
      (scope . runtime)
      (materialized-by . runtime)
      (mounts . runtime))
     (startup . zero-latency))
   (lambda (profile-ref)
     (list (cons 'backend 'nono)
           (cons 'profile profile-ref)))
   (if (null? maybe-options) '() (car maybe-options))))

;; : (-> BackendRef [Alist] AgentSandboxBackendProfile)
(def (make-nono-agent-sandbox-profile backend-ref . maybe-options)
  (agent-sandbox-profile-descriptor->profile
   (make-nono-agent-sandbox-profile-descriptor
    backend-ref
    (if (null? maybe-options) '() (car maybe-options)))))
