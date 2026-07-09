;;; -*- Gerbil -*-
;;; Boundary: public facade for loop-engine module-system projection.
;;; Invariant: implementation lives in loop-engine-core/runtime leaf owners.

(import :poo-flow/src/module-system/loop-engine-core
        :poo-flow/src/module-system/loop-engine-policy-extension
        :poo-flow/src/module-system/loop-engine-runtime
        :poo-flow/src/module-system/loop-engine-runtime-projection)

(export (import: :poo-flow/src/module-system/loop-engine-core)
        (import: :poo-flow/src/module-system/loop-engine-policy-extension)
        (import: :poo-flow/src/module-system/loop-engine-runtime)
        (import: :poo-flow/src/module-system/loop-engine-runtime-projection))
