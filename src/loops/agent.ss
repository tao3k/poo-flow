;;; -*- Gerbil -*-
;;; Boundary: public loop-agent facade.
;;; Invariant: this facade exports policy descriptors only, not execution.

(import :loops/descriptor
        :loops/strategy
        :loops/governor
        :loops/governor-marlin)

(export (import: :loops/descriptor)
        (import: :loops/strategy)
        (import: :loops/governor)
        (import: :loops/governor-marlin))
