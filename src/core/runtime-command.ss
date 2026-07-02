;;; -*- Gerbil -*-
;;; Boundary: public facade for runtime command invocation and descriptors.
;;; Invariant: leaf owners keep command execution separate from manifest data.

(import :poo-flow/src/core/runtime-command-invocation
        :poo-flow/src/core/runtime-command-descriptor)

(export (import: :poo-flow/src/core/runtime-command-invocation)
        (import: :poo-flow/src/core/runtime-command-descriptor))
