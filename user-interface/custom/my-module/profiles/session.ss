;;; -*- Gerbil -*-
;;; Boundary: downstream session sandbox profile declarations.
;;; Invariant: included by ../config.ss; it declares data only.

(use-module nono-sandbox
  :config
  (profiles
   (agent/session
    (network :override allowlisted "github.com" "crates.io")
    (capabilities process-run filesystem-read filesystem-write tmpdir)
    (capabilities :remove filesystem-write)
    (capabilities :append cache-mount)
    (resources (cpu . 2) (memory . "4Gi"))
    (resources :append (timeout-ms . 300000))
    (metadata (intent . coding-agent)
              (scope . session))
    (metadata :append (stage . interactive))
    (metadata :remove (scope . session)))))
