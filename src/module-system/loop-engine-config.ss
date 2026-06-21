;;; -*- Gerbil -*-
;;; Boundary: public facade for loop-engine module-system projection.
;;; Invariant: implementation lives in loop-engine-core/runtime leaf owners.

(import :poo-flow/src/module-system/loop-engine-core
        :poo-flow/src/module-system/loop-engine-runtime)

(export (import: :poo-flow/src/module-system/loop-engine-core)
        (import: :poo-flow/src/module-system/loop-engine-runtime))
