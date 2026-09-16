;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: downstream custom profile aggregate owner.
;;; Invariant: groups reusable profile declarations without loading scenario
;;; cases into the same compiled module.

(import "session"
        "task"
        "cicd"
        "loops"
        "object-extension")

(export (import: "session")
        (import: "task")
        (import: "cicd")
        (import: "loops")
        (import: "object-extension"))
