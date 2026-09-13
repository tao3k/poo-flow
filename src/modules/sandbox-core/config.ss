;;; -*- Gerbil -*-
;;; Canonical module entrypoint; implementation remains in owned factors.
;;; Engineering note: configuration performs no backend discovery or sandbox
;;; execution; it only selects the public sandbox-core object facade.

(import "objects.ss")
(export (import: "objects.ss"))
