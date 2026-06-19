;;; -*- Gerbil -*-
;;; Boundary: public facade for the poo-flow module system.
;;; Invariant: implementation logic stays in the leaf owners below.

(import :poo-flow/src/modules/interface
        :poo-flow/src/modules/source
        :poo-flow/src/modules/descriptor
        :poo-flow/src/modules/context
        :poo-flow/src/modules/diagnostics
        :poo-flow/src/modules/observability
        :poo-flow/src/modules/resolver
        :poo-flow/src/modules/loader
        :poo-flow/src/modules/projection
        :poo-flow/src/modules/doctor
        :poo-flow/src/modules/agent-sandbox/config
        :poo-flow/src/modules/user-config
        :poo-flow/src/modules/user-config-syntax
        :poo-flow/src/modules/user-interface/config
        :poo-flow/src/modules/user-interface-case
        :poo-flow/src/modules/extension
        :poo-flow/src/modules/objects
        :poo-flow/src/modules/nono-sandbox/config
        :poo-flow/src/modules/cubeSandbox/config
        :poo-flow/src/modules/docker-sandbox/config
        :poo-flow/src/modules/syntax)

(export (import: :poo-flow/src/modules/interface)
        (import: :poo-flow/src/modules/source)
        (import: :poo-flow/src/modules/descriptor)
        (import: :poo-flow/src/modules/context)
        (import: :poo-flow/src/modules/diagnostics)
        (import: :poo-flow/src/modules/observability)
        (import: :poo-flow/src/modules/resolver)
        (import: :poo-flow/src/modules/loader)
        (import: :poo-flow/src/modules/projection)
        (import: :poo-flow/src/modules/doctor)
        (import: :poo-flow/src/modules/agent-sandbox/config)
        (import: :poo-flow/src/modules/user-config)
        (import: :poo-flow/src/modules/user-config-syntax)
        (import: :poo-flow/src/modules/user-interface/config)
        (import: :poo-flow/src/modules/user-interface-case)
        (import: :poo-flow/src/modules/extension)
        (import: :poo-flow/src/modules/objects)
        (import: :poo-flow/src/modules/nono-sandbox/config)
        (import: :poo-flow/src/modules/cubeSandbox/config)
        (import: :poo-flow/src/modules/docker-sandbox/config)
        (import: :poo-flow/src/modules/syntax))
