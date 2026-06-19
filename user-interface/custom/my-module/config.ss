;;; -*- Gerbil -*-
;;; Boundary: user-owned custom module body.
;;; Invariant: root init.ss decides whether this module is enabled.

(import :modules/user-config-syntax)

(load! "profiles/session")
(load! "profiles/task")
(load! "profiles/cicd")
