;;; -*- Gerbil -*-
;;; Boundary: standalone loop-engine custom case owner for focused tests.
;;; Invariant: loads only the loop-engine case fragment, not the full custom
;;; module aggregate.

(import :poo-flow/src/module-system/init-syntax)

(load! "loop-engine")
