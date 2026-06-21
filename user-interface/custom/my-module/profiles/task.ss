;;; -*- Gerbil -*-
;;; Boundary: downstream task sandbox profile declarations.
;;; Invariant: included by ../config.ss; it declares data only.

(let ((task-capabilities
       '(process-run filesystem-read tmpdir))
      (cache-capabilities
       '(cache-mount))
      (task-metadata
       '((intent . task-sandbox)
         (stage . task)
         (runtime-executed . #f)))
      (task-cache-metadata
       '((intent . task-cache)
         (stage . task)
         (cache . cargo))))
  (use-module nono-sandbox
    (.def (agent/task @ nono-sandbox-profile)
      network: (deny-network)
      capabilities: task-capabilities
      resources: =>.+ readonly-project-workspace-resources
      metadata: => (lambda (super-metadata)
                     (append super-metadata task-metadata)))

    (.def (agent/task-cache @ agent/task)
      network: (allowlisted-network "github.com")
      capabilities: => (lambda (super-capabilities)
                         (append super-capabilities cache-capabilities))
      resources: =>.+ runtime-volume-resources
      metadata: => (lambda (super-metadata)
                     (append super-metadata task-cache-metadata)))))
