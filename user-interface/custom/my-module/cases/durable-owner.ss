;;; -*- Gerbil -*-
;;; Boundary: focused custom durable/artifact scenario owner.
;;; Invariant: durable scenarios stay importable without compiling every custom
;;; user-interface case into one generated C module.

(import :poo-flow/user-interface/custom/my-module/cases/durable-artifact
        :poo-flow/user-interface/custom/my-module/cases/durable-recovery
        :poo-flow/user-interface/custom/my-module/cases/durable-runtime-store-handoff
        :poo-flow/user-interface/custom/my-module/cases/durable-runtime-store-operations
        :poo-flow/user-interface/custom/my-module/cases/durable-operation-bridge)

(export (import: :poo-flow/user-interface/custom/my-module/cases/durable-artifact)
        (import: :poo-flow/user-interface/custom/my-module/cases/durable-recovery)
        (import: :poo-flow/user-interface/custom/my-module/cases/durable-runtime-store-handoff)
        (import: :poo-flow/user-interface/custom/my-module/cases/durable-runtime-store-operations)
        (import: :poo-flow/user-interface/custom/my-module/cases/durable-operation-bridge))
