;;; -*- Gerbil -*-
;;; Boundary: runtime and handoff summaries for validated sandbox profiles.
;;; Invariant: summaries are inert Scheme receipts for Marlin-owned execution.

(import :poo-flow/src/modules/agent-sandbox/alist
        :poo-flow/src/modules/agent-sandbox/profile-data
        :poo-flow/src/modules/agent-sandbox/profile-validation)

(export agent-sandbox-profile-runtime-summary
        agent-sandbox-profile-handoff-summary)

;;; Filesystem summary is the sandbox-owned projection that presentation,
;;; workflow, and runtime-handoff code should consume instead of reparsing the
;;; resource-policy row shape outside this module.
;; : (-> ResourcePolicy Alist)
(def (agent-sandbox-profile-filesystem-runtime-summary resource-policy)
  (let* ((entry
          (agent-sandbox-profile-resource-policy-filesystem-entry
           resource-policy))
         (spec (if (and entry (pair? entry)) (cdr entry) '()))
         (paths (agent-sandbox-alist-ref spec 'paths '()))
         (mounts (agent-sandbox-alist-ref spec 'mounts '()))
         (diagnostics
          (agent-sandbox-profile-resource-policy-filesystem-diagnostics
           resource-policy)))
    (list (cons 'declared? (and entry #t))
          (cons 'structured?
                (agent-sandbox-profile-resource-policy-structured-filesystem-entry?
                 entry))
          (cons 'scope (agent-sandbox-alist-ref spec 'scope #f))
          (cons 'access (agent-sandbox-alist-ref spec 'access #f))
          (cons 'paths paths)
          (cons 'path-count (agent-sandbox-profile-list-count paths))
          (cons 'mounts mounts)
          (cons 'mount-count (agent-sandbox-profile-list-count mounts))
          (cons 'entry entry)
          (cons 'diagnostics diagnostics))))

;;; Runtime summaries are still inert Scheme data. They name the exact sandbox
;;; policy that a Rust/Marlin bridge can consume later, while keeping execution
;;; state and validation evidence visible to agents.
;; : (-> AgentSandboxProfile Alist)
(def (agent-sandbox-profile-runtime-summary profile)
  (let* ((network-policy (agent-sandbox-profile-network-policy profile))
         (capabilities (agent-sandbox-profile-capabilities profile))
         (resource-policy (agent-sandbox-profile-resource-policy profile))
         (metadata (agent-sandbox-profile-metadata profile))
         (validation-errors
          (agent-sandbox-profile-validation-errors profile)))
    (list (cons 'schema +agent-sandbox-profile-runtime-summary-schema+)
          (cons 'kind 'agent-sandbox-profile-runtime-summary)
          (cons 'profile-ref (agent-sandbox-profile-backend-ref profile))
          (cons 'backend-kind (agent-sandbox-profile-backend-kind profile))
          (cons 'backend-ref (agent-sandbox-profile-backend-ref profile))
          (cons 'network-policy network-policy)
          (cons 'capabilities capabilities)
          (cons 'capability-count
                (agent-sandbox-profile-list-count capabilities))
          (cons 'resource-policy resource-policy)
          (cons 'resource-policy-count
                (agent-sandbox-profile-list-count resource-policy))
          (cons 'filesystem
                (agent-sandbox-profile-filesystem-runtime-summary
                 resource-policy))
          (cons 'metadata metadata)
          (cons 'valid? (null? validation-errors))
          (cons 'validation-errors validation-errors)
          (cons 'runtime-owner "marlin-agent-core")
          (cons 'package-management? #f)
          (cons 'dependency-installation? #f)
          (cons 'runtime-executed #f))))

;;; Handoff summaries validate first, then package the normalized profile and
;;; summary. This is the bridge-facing receipt shape for workflow/loop engines.
;; : (-> AgentSandboxProfile Alist)
(def (agent-sandbox-profile-handoff-summary profile)
  (let (validated-profile (agent-sandbox-validate-profile profile))
    (list (cons 'schema +agent-sandbox-profile-handoff-summary-schema+)
          (cons 'kind 'agent-sandbox-profile-handoff-summary)
          (cons 'profile-ref
                (agent-sandbox-profile-backend-ref validated-profile))
          (cons 'backend-kind
                (agent-sandbox-profile-backend-kind validated-profile))
          (cons 'backend-ref
                (agent-sandbox-profile-backend-ref validated-profile))
          (cons 'handoff-target "marlin-agent-core")
          (cons 'handoff-contract
                'poo-flow.agent-sandbox-profile.runtime-handoff.v1)
          (cons 'profile validated-profile)
          (cons 'runtime-summary
                (agent-sandbox-profile-runtime-summary validated-profile))
          (cons 'runtime-executed #f))))

