;;; -*- Gerbil -*-
;;; Public Funflow module interface.
;;; Engineering note: the facade preserves the established Funflow API while
;;; config.ss remains the single owner of default module selection data.
(import "config.ss"
        "method-combination.ss")
(export (import: "config.ss")
        (import: "method-combination.ss"))
