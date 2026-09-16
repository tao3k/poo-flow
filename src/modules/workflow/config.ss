;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Canonical module entrypoint; public workflow flows remain in flows.ss.
;;; Engineering note: this owner fixes the default module entrypoint without
;;; duplicating functional flow construction or runtime handoff behavior.

(import "flows.ss")
(export (import: "flows.ss"))
