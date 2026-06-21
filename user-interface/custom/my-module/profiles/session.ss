;;; -*- Gerbil -*-
;;; Boundary: downstream session sandbox profile declarations.
;;; Invariant: included by ../config.ss; it declares data only.

(let ((session-capabilities
       '(process-run filesystem-read tmpdir cache-mount))
      (session-metadata
       '((intent . coding-agent)
         (scope . session)
         (stage . interactive))))
  (use-module nono-sandbox
    (.def (agent/session @ nono-sandbox-profile)
      network: (allowlisted-network "github.com" "crates.io")
      capabilities: session-capabilities
      resources: =>.+ runtime-volume-resources
      metadata: => (lambda (super-metadata)
                     (append super-metadata session-metadata)))))
