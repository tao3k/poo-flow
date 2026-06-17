;;; -*- Gerbil -*-
;;; Boundary: configured entrypoints assemble strategies and runtime adapters.
;;; Invariant: config data selects components but never executes workflow tasks.

(import :core/strategy
        :core/runtime-adapter
        :core/runner)

(export make-run-config
        run-config?
        run-config-name
        run-config-strategy
        run-config-adapter
        run-config-options
        make-request-only-run-config
        make-rust-run-config
        run-config->runner
        run-config-runtime-owner
        run-flow-with-config)

;;; A run config is the inspectable data form of a Funflow-style configured
;;; execution entrypoint.
;; RunConfig <- Symbol Strategy RuntimeAdapter Alist
(defstruct run-config
  (name
   strategy
   adapter
   options)
  transparent: #t)

;;; The request-only config records adapter envelopes for tests without claiming
;;; to run store or external work.
;; RunConfig <- Unit
(def (make-request-only-run-config)
  (make-run-config 'request-only
                   (make-local-eager-strategy)
                   (make-request-only-adapter)
                   '((runtime . request-only))))

;;; The Rust config selects the handoff adapter while Scheme keeps ownership of
;;; declaration, planning, and audit evidence.
;; RunConfig <- Unit
(def (make-rust-run-config)
  (make-run-config 'rust
                   (make-local-eager-strategy)
                   (make-rust-adapter)
                   '((runtime . rust))))

;;; Lowering config through the existing runner keeps validation behavior
;;; identical for configured and direct execution.
;; Runner <- RunConfig
(def (run-config->runner config)
  (make-runner (run-config-strategy config)
               (run-config-adapter config)))

;;; Runtime ownership is derived from the selected adapter instead of copied
;;; into config options.
;; Symbol <- RunConfig
(def (run-config-runtime-owner config)
  (runtime-adapter-name (run-config-adapter config)))

;;; The configured entrypoint mirrors Funflow's run-with-config shape while
;;; reusing the normal runner interpreter and receipt schema.
;; RunResult <- RunConfig Flow Input
(def (run-flow-with-config config flow input)
  (runner-run (run-config->runner config) flow input))
