;;; -*- Gerbil -*-
;;; Boundary: use-module config must be inspectable before runtime.
;;; Invariant: presentation is inert; no module descriptors or runtimes execute.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/init-syntax
        :poo-flow/src/modules/agent-sandbox/config)

(load! "../user-interface/custom/my-module/profiles/agent-sandbox-audit")

;; : (-> Symbol Alist MaybeValue)
(def (alist-value key entries)
  (cond
   ((null? entries) #f)
   ((equal? key (caar entries)) (cdar entries))
   (else
    (alist-value key (cdr entries)))))

;; : (-> [Value] Value)
(def (last-value values)
  (if (null? (cdr values))
    (car values)
    (last-value (cdr values))))

(run-tests!
 (test-suite "user-interface config presentation"
   (test-case "shows an independent custom-module profile fragment as user config"
     (let* ((config (pooFlowUserConfig
                     poo-flow-custom-module-agent-sandbox-audit-module
                     (poo-flow-settings)))
            (presentation (pooFlowUserConfigPresentation config))
            (module-row (car (.ref presentation 'modules)))
            (feature-row (car (.ref presentation 'feature-facts)))
            (visible-flags (alist-value 'flags module-row))
            (feature-flags (alist-value 'flags feature-row))
            (selection
             (car poo-flow-custom-module-agent-sandbox-audit-module))
            (internal-flags
             (poo-flow-user-module-selection-flags selection))
            (internal-config-entry
             (alist-value ':config internal-flags))
            (base-profile (car internal-config-entry))
            (session-profile (cadr internal-config-entry))
            (branch-profile (caddr internal-config-entry))
            (branch-metadata
             (poo-flow-sandbox-profile-metadata branch-profile))
            (branch-lineage
             (alist-value 'derivation-path branch-metadata))
            (last-lineage-step (last-value branch-lineage)))
       (check-equal? visible-flags
                     '((:config
                        (binding native-ffi)
                        (profiles
                         (agent/audit-base
                          (network deny-by-default)
                          (capabilities process-run
                                        filesystem-read
                                        filesystem-write
                                        tmpdir)
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
                                    (split . branch)))))))
       (check-equal? feature-flags visible-flags)
       (check-equal? (alist-value ':binding visible-flags) #f)
       (check-equal? (alist-value ':user-config visible-flags) #f)
       (check-equal? (alist-value 'kind (alist-value ':config visible-flags))
                     #f)
       (check-equal? (poo-flow-sandbox-profile? base-profile) #t)
       (check-equal? (poo-flow-sandbox-profile-backend-kind session-profile)
                     'nono)
       (check-equal? (poo-flow-sandbox-profile-name base-profile)
                     'agent/audit-base)
       (check-equal? (poo-flow-sandbox-profile-name session-profile)
                     'agent/audit-session)
       (check-equal? (poo-flow-sandbox-profile-name branch-profile)
                     'agent/audit-branch)
       (check-equal? (poo-flow-sandbox-profile-capabilities branch-profile)
                     '(process-run filesystem-read tmpdir cache-mount))
       (check-equal? (length branch-lineage) 2)
       (check-equal? (alist-value 'parent-profile last-lineage-step)
                     'agent/audit-session)
       (check-equal? (alist-value 'scope last-lineage-step) 'branch)
       (check-equal? (alist-value 'scope-ref last-lineage-step)
                     "feature/agent-sandbox-audit")
       (check-equal? (alist-value ':binding internal-flags) 'native-ffi)))))
