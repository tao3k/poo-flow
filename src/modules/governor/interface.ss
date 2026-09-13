;;; -*- Gerbil -*-
;;; Public governor module interface.
;;; Engineering note: consumers use this stable facade so configuration can be
;;; split internally without exposing its leaf-owner layout.
(import "config.ss")
(export (import: "config.ss"))
