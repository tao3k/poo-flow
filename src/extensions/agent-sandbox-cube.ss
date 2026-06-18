;;; -*- Gerbil -*-
;;; Owner: CubeSandbox profile alignment lives in this backend module.
;;; Boundary: core provides schema, task, envelope, and adapter protocols.
;;; Import contract: users opt in through =:extensions/agent-sandbox-cube=.
;;; Runtime contract: this module emits profile data only.
;;; Runtime contract: Cube API calls stay behind Marlin runtime commands.
;;; Runtime contract: remote snapshot lifecycle stays out of Scheme.
;;; Policy evidence: tests should import this module when they assert Cube defaults.

(import :extensions/agent-sandbox-profile
        :extensions/agent-sandbox-cube-interface)

(export make-cube-agent-sandbox-profile-descriptor
        make-cube-agent-sandbox-profile
        (import: :extensions/agent-sandbox-cube-interface))

;;; Cube profiles model remote or clustered KVM-backed sandboxes. The macro
;;; lets Tencent-specific defaults evolve without making core backend-aware.
;; AgentSandboxBackendProfile <- BackendRef [Alist]
(defagent-sandbox-backend-profile
  make-cube-agent-sandbox-profile-descriptor
  make-cube-agent-sandbox-profile
  'cube-profile
  'cube
  '((mode . egress-filtered))
  '((isolation . kvm)
    (api . e2b-compatible))
  '((snapshot . clone)
    (resume . supported))
  (lambda (backend-ref)
    (list (cons 'backend 'cube)
          (cons 'template backend-ref))))
