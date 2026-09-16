;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: packaged Python runtime projection smoke flow.

(use-composition wheel-smoke
  (use-module funflow as ff
    (profiles github-ci python-anyio))

  (compose
    (profiles ff github-ci python-anyio))

  (stage default
    (step build
      (run "python" "-m" "build"))
    (step test
      (run "python" "-m" "pytest" "-q"))
    (edges
      (build -> test))))
