;;; -*- Gerbil -*-
;;; Boundary: public Module System facade.
;;; Invariant: each subsystem owns its interface; this file only composes the
;;; public import closure consumed by users and the ASP build API.

(import :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/composition/interface
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/src/module-system/declaration/interface
        :poo-flow/src/module-system/descriptor/interface
        :poo-flow/src/module-system/diagnostics/interface
        :poo-flow/src/module-system/extension/interface
        :poo-flow/src/module-system/loader/interface
        :poo-flow/src/module-system/object-core/interface
        :poo-flow/src/module-system/object-family/interface
        :poo-flow/src/module-system/object-validation/interface
        :poo-flow/src/module-system/observability/interface
        :poo-flow/src/module-system/profile-composition/interface
        :poo-flow/src/module-system/projection/interface
        :poo-flow/src/module-system/semantic-module/interface)

(export (import: :poo-flow/src/module-system/interface)
        (import: :poo-flow/src/module-system/composition/interface)
        (import: :poo-flow/src/module-system/contribution/interface)
        (import: :poo-flow/src/module-system/declaration/interface)
        (import: :poo-flow/src/module-system/descriptor/interface)
        (import: :poo-flow/src/module-system/diagnostics/interface)
        (import: :poo-flow/src/module-system/extension/interface)
        (import: :poo-flow/src/module-system/loader/interface)
        (import: :poo-flow/src/module-system/object-core/interface)
        (import: :poo-flow/src/module-system/object-family/interface)
        (import: :poo-flow/src/module-system/object-validation/interface)
        (import: :poo-flow/src/module-system/observability/interface)
        (import: :poo-flow/src/module-system/profile-composition/interface)
        (import: :poo-flow/src/module-system/projection/interface)
        (import: :poo-flow/src/module-system/semantic-module/interface))
