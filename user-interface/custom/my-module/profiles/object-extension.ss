;;; -*- Gerbil -*-
;;; Boundary: downstream POO object slot-operator example.
;;; Invariant: included by ../config.ss; it declares extension data only.

(use-module nono-sandbox
  :config
  (profiles
   (agent/poo-object-extension
    (network :override allowlisted "github.com" "crates.io")
    (capabilities process-run filesystem-read filesystem-write tmpdir)
    (capabilities :remove filesystem-write)
    (capabilities :append cache-mount artifact-cache)
    (resources
     (filesystem . scoped)
     (mounts
      ((path . "/workspace/project")
       (source . ".")
       (target . "/workspace/project")
       (mode . read-write)
       (purpose . project-source))
      ((path . "/workspace/project/.data")
       (source . ".data")
       (target . "/workspace/project/.data")
       (mode . read)
       (purpose . research-checkouts))
      ((path . "/workspace/cache")
       (source . ".cache/agent-semantic-protocol")
       (target . "/workspace/cache")
       (mode . read-write)
       (purpose . semantic-cache))
      ((path . "/workspace/config")
       (source . "user-interface/custom/my-module")
       (target . "/workspace/config")
       (mode . read)
       (purpose . user-config))
      ((path . "/run/secrets")
       (source . "$POO_FLOW_AGENT_SECRETS")
       (target . "/run/secrets")
       (mode . read)
       (purpose . credentials)))
     (cpu . 2))
    (resources :append (memory . "4Gi") (timeout-ms . 300000))
    (metadata (intent . poo-object-extension)
              (scope . demo))
    (metadata :append
              (poo-object . objects.nono-sandbox.profile)
              (slot-operators . (override append remove)))
    (metadata :remove (scope . demo)))))
