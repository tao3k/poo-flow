;;; -*- Gerbil -*-
;;; Boundary: user-facing session object module facade.
;;; Invariant: session declarations are report-only until a runtime bridge
;;; consumes their handoff receipts.

(import :poo-flow/src/modules/session/objects)

(export (import: :poo-flow/src/modules/session/objects))
