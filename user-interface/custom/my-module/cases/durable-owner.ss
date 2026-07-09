;;; -*- Gerbil -*-
;;; Boundary: focused custom durable/artifact scenario owner.
;;; Invariant: durable scenarios stay importable without compiling every custom
;;; user-interface case into one generated C module.

(import (only-in :poo-flow/src/module-system/durable-runtime-store-operation-bridge
                 poo-flow-durable-runtime-store-operations-from-rows
                 poo-flow-durable-runtime-store-rows->marlin-handoff)
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/config
        :poo-flow/src/module-system/init-syntax
        :poo-flow/user-interface/custom/my-module/profiles/all)

(load! "durable-artifact")
(load! "durable-recovery")
(load! "durable-runtime-store-handoff")
(load! "durable-runtime-store-operations")
(load! "durable-operation-bridge")
