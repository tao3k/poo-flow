;;; -*- Gerbil -*-
;;; Public workflow module interface.
;;; Engineering note: the stable facade exposes functional workflow values
;;; while config.ss alone owns the module's default loading entrypoint.
(import "config.ss")
(export (import: "config.ss"))
