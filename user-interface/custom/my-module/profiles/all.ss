;;; -*- Gerbil -*-
;;; Boundary: downstream custom profile aggregate owner.
;;; Invariant: groups reusable profile declarations without loading scenario
;;; cases into the same compiled module.

(import :poo-flow/src/module-system/init-syntax)

(load! "session")
(load! "task")
(load! "cicd")
(load! "loops")
(load! "object-extension")
