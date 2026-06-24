;;; -*- Gerbil -*-
;;; Boundary: public projection facade for module option and runtime receipts.
;;; Invariant: implementation logic stays in focused projection leaf owners.

(import :poo-flow/src/module-system/projection-catalog
        :poo-flow/src/module-system/projection-options
        :poo-flow/src/module-system/projection-runtime)

(export (import: :poo-flow/src/module-system/projection-catalog)
        (import: :poo-flow/src/module-system/projection-options)
        (import: :poo-flow/src/module-system/projection-runtime))
