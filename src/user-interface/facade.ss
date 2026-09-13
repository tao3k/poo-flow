;;; -*- Gerbil -*-
;;; Boundary: compatibility facade for the downstream POO Flow user interface.
;;; Invariant: Loader mechanics flow in from module-system; concrete module
;;; APIs are composed here and never re-exported by the mechanism facade.

(import :poo-flow/src/module-system/facade
        :poo-flow/src/user-interface/entrypoints
        :poo-flow/src/user-interface/presentation
        :poo-flow/src/module-system/observability/module-presentation
        :poo-flow/src/modules/memory-core/durable/policy
        :poo-flow/src/modules/memory-core/durable/store
        :poo-flow/src/modules/memory-core/durable/store-backend
        :poo-flow/src/modules/memory-core/durable/store-operation
        :poo-flow/src/modules/memory-core/durable/store-operation-bridge
        :poo-flow/src/modules/memory-core/durable/recovery-scenario
        :poo-flow/src/modules/session/lifecycle-gate)

(export (import: :poo-flow/src/module-system/facade)
        (import: :poo-flow/src/user-interface/entrypoints)
        (import: :poo-flow/src/user-interface/presentation)
        (import: :poo-flow/src/module-system/observability/module-presentation)
        (import: :poo-flow/src/modules/memory-core/durable/policy)
        (import: :poo-flow/src/modules/memory-core/durable/store)
        (import: :poo-flow/src/modules/memory-core/durable/store-backend)
        (import: :poo-flow/src/modules/memory-core/durable/store-operation)
        (import: :poo-flow/src/modules/memory-core/durable/store-operation-bridge)
        (import: :poo-flow/src/modules/memory-core/durable/recovery-scenario)
        (import: :poo-flow/src/modules/session/lifecycle-gate))
