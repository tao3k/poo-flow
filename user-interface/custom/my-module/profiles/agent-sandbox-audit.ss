;;; -*- Gerbil -*-
;;; Boundary: audit-friendly downstream agent sandbox profile declarations.
;;; Invariant: loaded by tests as an independent fragment; it does not execute.

(let ((audit-base-capabilities
       '(process-run filesystem-read filesystem-write tmpdir))
      (audit-branch-capabilities
       '(process-run filesystem-read tmpdir cache-mount))
      (cache-capabilities
       '(cache-mount))
      (audit-base-metadata
       '((intent . agent-audit-base)
         (scope . custom-module)
         (split . project)))
      (audit-session-metadata
       '((intent . agent-audit-session)
         (split . session)))
      (audit-branch-metadata
       '((intent . agent-audit-branch)
         (scope . custom-module)
         (split . branch)))
      (audit-session-name 'agent/audit-session)
      (audit-base-name 'agent/audit-base)
      (audit-branch-name 'agent/audit-branch)
      (session-scope 'session)
      (branch-scope 'branch))
  (use-module nono-sandbox
    (binding native-ffi)

    (.def (agent/audit-base @ nono-sandbox-profile
                            network capabilities resources metadata)
      network: (deny-network)
      capabilities: audit-base-capabilities
      resources: =>.+ readwrite-project-workspace-resources
      metadata: => (lambda (super-metadata)
                     (append super-metadata audit-base-metadata)))

    (.def (agent/audit-session @ agent/audit-base
                               network capabilities resources metadata)
      network: (allowlisted-network "github.com")
      capabilities: => (lambda (super-capabilities)
                         (append super-capabilities cache-capabilities))
      resources: =>.+ runtime-volume-resources
      (metadata (super-metadata)
        (profile-derivation-metadata
         (super-metadata)
         audit-session-name
         audit-base-name
         session-scope
         "agent-session"
         audit-session-metadata)))

    (.def (agent/audit-branch @ agent/audit-session
                              network capabilities resources metadata)
      network: (deny-network)
      capabilities: audit-branch-capabilities
      resources: =>.+ readonly-project-workspace-resources
      (metadata (super-metadata)
        (profile-derivation-metadata
         (super-metadata)
         audit-branch-name
         audit-session-name
         branch-scope
         "feature/agent-sandbox-audit"
         audit-branch-metadata)))))
