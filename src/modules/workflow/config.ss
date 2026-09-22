;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: workflow configuration and user-config projection surface.
;;; Invariant: functional builders stay in funs.ss; this layer only composes
;;; admitted CI/CD objects into User Interface and runtime-handoff receipts.

(import "cicd-config.ss"
        "cicd-pipeline-run-config.ss")

(export (import: "cicd-config.ss")
        (import: "cicd-pipeline-run-config.ss"))
