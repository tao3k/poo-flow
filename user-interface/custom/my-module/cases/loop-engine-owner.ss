;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: standalone loop-engine custom case owner for focused tests.
;;; Invariant: imports only the loop-engine case module, not the full custom
;;; module aggregate.

(import "loop-engine")

(export (import: "loop-engine"))
