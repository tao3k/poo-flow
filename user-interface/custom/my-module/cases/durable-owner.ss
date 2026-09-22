;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: focused custom durable/artifact scenario owner.
;;; Invariant: durable scenarios stay importable without compiling every custom
;;; user-interface case into one generated C module.

(import "durable-artifact"
        "durable-recovery"
        "durable-runtime-store-handoff"
        "durable-runtime-store-operations"
        "durable-operation-bridge")

(export (import: "durable-artifact")
        (import: "durable-recovery")
        (import: "durable-runtime-store-handoff")
        (import: "durable-runtime-store-operations")
        (import: "durable-operation-bridge"))
