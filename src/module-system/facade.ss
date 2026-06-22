;;; -*- Gerbil -*-
;;; Boundary: public facade for the poo-flow module system.
;;; Invariant: implementation logic stays in the leaf owners below.

(import :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/source
        :poo-flow/src/module-system/descriptor
        :poo-flow/src/module-system/context
        :poo-flow/src/module-system/diagnostics
        :poo-flow/src/module-system/observability
        :poo-flow/src/module-system/resolver
        :poo-flow/src/module-system/loader
        :poo-flow/src/module-system/projection
        :poo-flow/src/module-system/doctor
        :poo-flow/src/modules/agent-sandbox/config
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/sandbox-profile-catalog
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/loop-engine-config
        :poo-flow/src/module-system/loop-engine-policy-extension
        :poo-flow/src/module-system/presentation
        :poo-flow/src/module-system/profile-config
        :poo-flow/src/module-system/init-syntax
        :poo-flow/src/module-system/use-module-contract
        :poo-flow/src/module-system/root-profile
        :poo-flow/src/module-system/declaration-case
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/objects
        :poo-flow/src/modules/nono-sandbox/config
        :poo-flow/src/modules/cubeSandbox/config
        :poo-flow/src/modules/docker-sandbox/config
        :poo-flow/src/module-system/descriptor-syntax)

(export (import: :poo-flow/src/module-system/interface)
        (import: :poo-flow/src/module-system/source)
        (import: :poo-flow/src/module-system/descriptor)
        (import: :poo-flow/src/module-system/context)
        (import: :poo-flow/src/module-system/diagnostics)
        (import: :poo-flow/src/module-system/observability)
        (import: :poo-flow/src/module-system/resolver)
        (import: :poo-flow/src/module-system/loader)
        (import: :poo-flow/src/module-system/projection)
        (import: :poo-flow/src/module-system/doctor)
        (import: :poo-flow/src/modules/agent-sandbox/config)
        (import: :poo-flow/src/module-system/base)
        (import: :poo-flow/src/module-system/sandbox-profile-catalog)
        (import: :poo-flow/src/module-system/workflow-cicd-config)
        (import: :poo-flow/src/module-system/loop-engine-config)
        (import: :poo-flow/src/module-system/loop-engine-policy-extension)
        (import: :poo-flow/src/module-system/presentation)
        (import: :poo-flow/src/module-system/profile-config)
        (import: :poo-flow/src/module-system/init-syntax)
        (import: :poo-flow/src/module-system/use-module-contract)
        (import: :poo-flow/src/module-system/root-profile)
        (import: :poo-flow/src/module-system/declaration-case)
        (import: :poo-flow/src/module-system/extension)
        (import: :poo-flow/src/module-system/object-core)
        (import: :poo-flow/src/module-system/objects)
        (import: :poo-flow/src/modules/nono-sandbox/config)
        (import: :poo-flow/src/modules/cubeSandbox/config)
        (import: :poo-flow/src/modules/docker-sandbox/config)
        (import: :poo-flow/src/module-system/descriptor-syntax))
