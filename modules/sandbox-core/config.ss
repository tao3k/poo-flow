;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Canonical module entrypoint; implementation remains in owned factors.
;;; Engineering note: configuration performs no backend discovery or sandbox
;;; execution; it only selects the public sandbox-core object facade.

(import "objects.ss")
(export (import: "objects.ss"))
