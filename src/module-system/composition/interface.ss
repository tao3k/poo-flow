;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: public composition-analysis feature interface.
;;; Invariant: lineage and proof projection remain pure module-system data.

(import "lineage.ss"
        "proof-facts.ss")

(export (import: "lineage.ss")
        (import: "proof-facts.ss"))
