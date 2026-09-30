;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Shared bounded observation output. Callers own their observation policy.
(import (only-in :gerbil/core write-substring)
        (only-in :std/format format))

(export poo-flow-write-observation-line!)

;;; Materialize a complete receipt before it reaches the shared native port.
(def (poo-flow-write-observation-line! template . values)
  (let* ((line (apply format template values))
         (record (string-append "\n" line "\n"))
         (port (current-output-port)))
    (write-substring record 0 (string-length record) port)
    (force-output port)))
