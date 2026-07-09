;;; -*- Gerbil -*-
;;; Boundary: focused custom runtime-adjacent scenario owner.
;;; Invariant: tool, memory, and sandbox-durable cases can be imported without
;;; compiling CI/CD, loop-engine, or durable artifact scenarios.

(import :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/config
        :poo-flow/src/module-system/init-syntax
        :poo-flow/user-interface/custom/my-module/profiles/all)

(load! "tool-core")
(load! "memory-core")
(load! "session-memory-durable")
(load! "sandbox-durable")
