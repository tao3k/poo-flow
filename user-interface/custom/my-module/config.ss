;;; -*- Gerbil -*-
;;; Boundary: user-owned custom module body.
;;; Invariant: root init.ss decides whether this module is enabled.

(import :poo-flow/src/modules/user-config-syntax)

(load! "profiles/session")
(load! "profiles/task")
(load! "profiles/cicd")
(load! "profiles/object-extension")
