;;; -*- Gerbil -*-
;;; Boundary: downstream sandbox durable placement case.
;;; Invariant: pure profile declaration; sandbox execution stays in runtime.

(let ((durable-build-metadata
       '((intent . durable-sandbox-build)
         (scope . custom-module)
         (durable-policy . durable/default)
         (runtime-executed . #f))))
  (use-module nono-sandbox
    (binding native-ffi)

    (.def (agent/durable-build @ nono-sandbox-profile
                               network capabilities resources metadata)
      network: (deny-network)
      capabilities: '(process-run filesystem-read filesystem-write tmpdir)
      resources: =>.+ readwrite-project-workspace-resources
      metadata: => (lambda (super-metadata)
                     (append super-metadata durable-build-metadata)))))
