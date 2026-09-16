;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: executable scenario for prototype composition cache reuse.

;; Quarantined: recent runtime probes showed this scenario can trigger
;; unbounded Gerbil/POO object lookup memory growth. Keep the benchmark
;; fixture as a design target, but do not execute the unsafe hot path until
;; the underlying object-access regression is isolated.
(exit 0)
