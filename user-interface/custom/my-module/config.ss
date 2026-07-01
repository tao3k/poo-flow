;;; -*- Gerbil -*-
;;; Boundary: user-owned custom module body.
;;; Invariant: root init.ss decides whether this module is enabled.

(import (only-in :poo-flow/src/module-system/durable-runtime-store-operation-bridge
                 poo-flow-durable-runtime-store-operations-from-rows
                 poo-flow-durable-runtime-store-rows->marlin-handoff)
        :poo-flow/src/module-system/init-syntax)

(load! "profiles/session")
(load! "profiles/task")
(load! "profiles/cicd")
(load! "profiles/loops")
(load! "profiles/object-extension")
(load! "cases/cicd")
(load! "cases/funflow-cicd")
(load! "cases/loop-engine")
(load! "cases/poo-introspection")
(load! "cases/session-transform")
(load! "cases/session-policy")
(load! "cases/session-registry")
(load! "cases/session-agent-graph")
(load! "cases/session-agent-param")
(load! "cases/session-communication")
(load! "cases/session-selector")
(load! "cases/session-materialization")
(load! "cases/tool-core")
(load! "cases/memory-core")
(load! "cases/session-memory-durable")
(load! "cases/sandbox-durable")
(load! "cases/durable-recovery")
(load! "cases/durable-runtime-store-handoff")
(load! "cases/durable-runtime-store-operations")
(load! "cases/durable-operation-bridge")
