;;; Boundary: config-session syntax aggregates the session module macro facade
;;; while keeping category/module configuration separate from runtime state.
;;; Invariant: this owner must preserve the compact init/config shape expected
;;; by the module loader.
(import :poo-flow/src/modules/session/config-session-runtime
        :poo-flow/src/modules/session/config-session-syntax-core
        :poo-flow/src/modules/session/config-session-syntax-communication
        :poo-flow/src/modules/session/config-session-syntax-selector
        :poo-flow/src/modules/session/config-session-syntax-agent)

(export (import: :poo-flow/src/modules/session/config-session-runtime)
        (import: :poo-flow/src/modules/session/config-session-syntax-core)
        (import: :poo-flow/src/modules/session/config-session-syntax-communication)
        (import: :poo-flow/src/modules/session/config-session-syntax-selector)
        (import: :poo-flow/src/modules/session/config-session-syntax-agent))
