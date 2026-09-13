;;; -*- Gerbil -*-
;;; Canonical module entrypoint; public workflow flows remain in flows.ss.
;;; Engineering note: this owner fixes the default module entrypoint without
;;; duplicating functional flow construction or runtime handoff behavior.

(import "flows.ss")
(export (import: "flows.ss"))
