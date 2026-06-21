;;; -*- Gerbil -*-
;;; Boundary: audit-friendly downstream agent sandbox profile declarations.
;;; Invariant: loaded by tests as an independent fragment; it does not execute.

(use-module nono-sandbox
  :config
  (binding native-ffi)
  (profiles
   (agent/audit-base
    (network deny-by-default)
    (capabilities process-run filesystem-read filesystem-write tmpdir)
    (resources (filesystem
                (scope . project-workspace)
                (paths
                 ((role . project-workspace)
                  (source . ".")
                  (project-marker . "gerbil.pkg")
                  (target . "/workspace/project")
                  (mode . read-write)))
                (access . read-write))
               (cpu . 2)
               (memory . "4Gi")
               (timeout-ms . 300000))
    (metadata (intent . agent-audit-base)
              (scope . custom-module)
              (split . project)))
   (agent/audit-session
    (:derive agent/audit-base
             (scope . session)
             (scope-ref . "agent-session"))
    (network allowlisted "github.com")
    (capabilities :append cache-mount)
    (resources :append
               (session-root . ".codex/session")
               (session-mode . shared-worktree))
    (metadata :append
              (intent . agent-audit-session)
              (split . session)))
   (agent/audit-branch
    (:derive agent/audit-session
             (scope . branch)
             (scope-ref . "feature/agent-sandbox-audit"))
    (capabilities :remove filesystem-write)
    (resources :override
               (filesystem
                (scope . branch-worktree)
                (paths
                 ((role . branch-worktree)
                  (source . ".")
                  (project-marker . "gerbil.pkg")
                  (target . "/workspace/project")
                  (mode . read-only)))
                (access . read-only))
               (cpu . 1)
               (memory . "2Gi")
               (timeout-ms . 180000))
    (metadata (intent . agent-audit-branch)
              (scope . custom-module)
              (split . branch)))))
