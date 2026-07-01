;;; -*- Gerbil -*-
;;; Boundary: public loop-agent facade.
;;; Invariant: this facade exports policy descriptors only, not execution.

(import :poo-flow/src/loops/descriptor
        :poo-flow/src/loops/strategy
        :poo-flow/src/loops/governor
        :poo-flow/src/loops/governor-marlin
        :poo-flow/src/loops/human-audit
        :poo-flow/src/loops/spec-evolution)

(export (import: :poo-flow/src/loops/descriptor)
        (import: :poo-flow/src/loops/strategy)
        (import: :poo-flow/src/loops/governor)
        (import: :poo-flow/src/loops/governor-marlin)
        (import: :poo-flow/src/loops/human-audit)
        (import: :poo-flow/src/loops/spec-evolution))
