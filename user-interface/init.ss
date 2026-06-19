;;; -*- Gerbil -*-
;;; Boundary: user-owned POO Flow init entrypoint.
;;; Invariant: this file lists enabled modules only; projections live upstream.

(import :modules/user-interface/config)

;;; Doom-style init shape: optional module feature patches only.
;;; Profile binding, settings, projection, package sync, and runtime loading
;;; are upstream concerns.
(def poo-flow-user-module-bundles
  (poo-flow-init-module-bundles
   :workflow
   (funflow
    (+cicd
     (checks +parallel +typed-receipts)
     (artifacts +export)
     (release +manual-gate)
     (webhook +server)
     (runtime +manifest-handoff)))
   :sandbox
   (nono-sandbox +nono +doctor)
   (cubeSandbox +cube +doctor)
   :custom
   (my-module "./custom/my-module" +private +doctor)))

(export poo-flow-user-module-bundles)
