;;; -*- Gerbil -*-
;;; Owner: nono profile alignment lives in this backend module.
;;; Boundary: core provides schema, task, envelope, and adapter protocols.
;;; Import contract: users opt in through =:extensions/agent-sandbox-nono=.
;;; Runtime contract: this module emits profile data only.
;;; Runtime contract: nono session startup stays behind Marlin runtime commands.
;;; Runtime contract: credentials and LLM calls stay out of Scheme.
;;; Policy evidence: tests should import this module when they assert nono defaults.

(import :extensions/agent-sandbox-profile
        :extensions/agent-sandbox-nono-c-binding)

(export make-nono-agent-sandbox-profile-descriptor
        make-nono-agent-sandbox-profile
        (import: :extensions/agent-sandbox-nono-c-binding))

;;; nono profile defaults model local zero-setup agent sandboxing. The macro
;;; keeps backend declaration compact while preserving the POO override seam.
;; AgentSandboxBackendProfile <- BackendRef [Alist]
(defagent-sandbox-backend-profile
  make-nono-agent-sandbox-profile-descriptor
  make-nono-agent-sandbox-profile
  'nono-profile
  'nono
  '((mode . proxy-only))
  '((filesystem . scoped)
    (credentials . injected))
  '((startup . zero-latency))
  (lambda (backend-ref)
    (list (cons 'backend 'nono)
          (cons 'profile backend-ref))))
