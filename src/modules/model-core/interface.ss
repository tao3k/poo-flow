;;; -*- Gerbil -*-
;;; Public model-core module interface.
;;; Engineering note: the facade keeps model catalog construction behind the
;;; module boundary and does not select a provider or execute inference.
(import "config.ss")
(export (import: "config.ss"))
