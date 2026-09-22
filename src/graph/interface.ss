;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Public Graph mechanism boundary. Domain packages contribute graph values
;;; and select algorithms; they do not own a second graph implementation.
(import "types.ss" "algorithms.ss")
(export (import: "types.ss")
        (import: "algorithms.ss"))
