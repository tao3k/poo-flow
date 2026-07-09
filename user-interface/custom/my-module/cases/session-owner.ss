;;; -*- Gerbil -*-
;;; Boundary: focused custom session scenario owner.
;;; Invariant: session cases are grouped without durable/artifact scenarios or
;;; the full custom module aggregate.

(import :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/config
        :poo-flow/src/module-system/init-syntax
        :poo-flow/user-interface/custom/my-module/profiles/all)

(load! "session-transform")
(load! "session-policy")
(load! "session-registry")
(load! "session-agent-graph")
(load! "session-agent-param")
(load! "session-communication")
(load! "session-selector")
(load! "session-materialization")
