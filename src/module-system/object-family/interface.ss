;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: public indexed POO object-family feature interface.
;;; Invariant: hygienic family syntax expands to ordinary POO objects.

(import "funcs.ss"
        "indexed.ss"
        "syntax.ss")

(export (import: "indexed.ss")
        (import: "syntax.ss"))
