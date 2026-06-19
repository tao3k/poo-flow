;;; -*- Gerbil -*-
;;; Boundary: downstream task sandbox profile declarations.
;;; Invariant: included by ../config.ss; it declares data only.

(use-module nono-sandbox
  :config
  (profiles
   (agent/task
    (network deny-by-default)
    (capabilities process-run filesystem-read tmpdir)
    (resources (cpu . 1) (memory . "1Gi") (timeout-ms . 90000))
    (metadata (intent . task-sandbox)
              (stage . task)
              (runtime-executed . #f)))
   (agent/task-cache
    (network allowlisted "github.com")
    (capabilities process-run filesystem-read tmpdir)
    (capabilities :append cache-mount)
    (resources (cpu . 2) (memory . "2Gi"))
    (resources :append (timeout-ms . 180000))
    (metadata (intent . task-cache)
              (stage . task)
              (cache . cargo)))))
