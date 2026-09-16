;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: user-owned custom module facade.
;;; Invariant: the facade re-exports focused profile/case owners and does not
;;; load every declaration into one compiled aggregate module.

(import "profiles/all"
        "cases/cicd-owner"
        "cases/loop-engine-owner"
        "cases/session-owner"
        "cases/runtime-owner"
        "cases/durable-owner")

(export (import: "profiles/all")
        (import: "cases/cicd-owner")
        (import: "cases/loop-engine-owner")
        (import: "cases/session-owner")
        (import: "cases/runtime-owner")
        (import: "cases/durable-owner"))
