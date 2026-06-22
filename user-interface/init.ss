;;; -*- Gerbil -*-
;;; Boundary: user-owned POO Flow init entrypoint.
;;; Invariant: this file lists enabled modules only; projections live upstream.

(import :poo-flow/src/module-system/root-profile)

;;; Doom-style init shape: module categories and optional feature patches only.
;;; Profile binding, settings, projection, package sync, export wiring, and
;;; runtime loading are upstream concerns.
(poo-flow!
 :workflow
 (funflow
  (+cicd
   (checks +parallel +typed-receipts)
   (artifacts +export)
   (release +manual-gate)
   (webhook +server)
   (runtime +manifest-handoff)))
 (loop-engine)
 :sandbox
 (nono-sandbox +nono +doctor)
 (cubeSandbox +cube +doctor)
 :custom
 (my-module "./custom/my-module" +private +doctor))
