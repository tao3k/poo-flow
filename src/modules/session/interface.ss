;;; -*- Gerbil -*-
;;; Public session module interface.
;;; Engineering note: this facade preserves one import path across the
;;; session object's policy, selector, communication, and receipt leaf owners.
(import "config.ss")
(export (import: "config.ss"))
