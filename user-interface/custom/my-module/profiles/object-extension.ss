;;; -*- Gerbil -*-
;;; Boundary: downstream POO object slot-operator example.
;;; Invariant: included by ../config.ss; it declares extension data only.

(let ((object-extension-capabilities
       '(process-run filesystem-read tmpdir cache-mount artifact-cache))
      (object-extension-metadata
       '((intent . poo-object-extension)
         (scope . demo)
         (poo-object . objects.nono-sandbox.profile)
         (slot-operators . (override append remove))
         (authoring-style . native-gerbil-poo))))
  (use-module nono-sandbox
    (.def (agent/poo-object-extension @ nono-sandbox-profile)
      network: (allowlisted-network "github.com" "crates.io")
      capabilities: object-extension-capabilities
      resources: =>.+ readwrite-project-workspace-resources
      metadata: => (lambda (super-metadata)
                     (append super-metadata object-extension-metadata)))))
