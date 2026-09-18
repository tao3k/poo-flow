;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: public Loader diagnostics feature interface.
;;; Invariant: diagnostic records and doctor projection never activate modules.

(import "records.ss"
        "doctor.ss")

(export (import: "records.ss")
        (import: "doctor.ss"))
