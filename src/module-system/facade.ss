;;; -*- Gerbil -*-
;;; Boundary: public facade for the poo-flow module system.
;;; Invariant: implementation logic stays in the leaf owners below.

(import :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/source
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/descriptor
        :poo-flow/src/module-system/context
        :poo-flow/src/module-system/diagnostics
        :poo-flow/src/module-system/observability
        :poo-flow/src/module-system/module-registry
        :poo-flow/src/module-system/resolver
        :poo-flow/src/module-system/loader
        :poo-flow/src/module-system/doctor
        :poo-flow/src/module-system/durable-policy
        :poo-flow/src/module-system/durable-runtime-store
        :poo-flow/src/module-system/durable-runtime-store-backend
        :poo-flow/src/module-system/durable-runtime-store-operation
        :poo-flow/src/module-system/durable-recovery-scenario
        :poo-flow/src/module-system/descriptor-syntax
        :poo-flow/src/module-system/projection
        :poo-flow/src/module-system/presentation)

(export (import: :poo-flow/src/module-system/interface)
        (import: :poo-flow/src/module-system/source)
        (import: :poo-flow/src/module-system/base)
        (import: :poo-flow/src/module-system/descriptor)
        (import: :poo-flow/src/module-system/context)
        (import: :poo-flow/src/module-system/diagnostics)
        (import: :poo-flow/src/module-system/observability)
        (import: :poo-flow/src/module-system/module-registry)
        (import: :poo-flow/src/module-system/resolver)
        (import: :poo-flow/src/module-system/loader)
        (import: :poo-flow/src/module-system/doctor)
        (import: :poo-flow/src/module-system/durable-policy)
        (import: :poo-flow/src/module-system/durable-runtime-store)
        (import: :poo-flow/src/module-system/durable-runtime-store-backend)
        (import: :poo-flow/src/module-system/durable-runtime-store-operation)
        (import: :poo-flow/src/module-system/durable-recovery-scenario)
        (import: :poo-flow/src/module-system/descriptor-syntax)
        (import: :poo-flow/src/module-system/projection)
        (import: :poo-flow/src/module-system/presentation))
