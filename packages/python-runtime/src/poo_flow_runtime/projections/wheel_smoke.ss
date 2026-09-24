;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: packaged Python runtime projection smoke flow.

(user-composition wheel-smoke
  (compose profiles
    (use-module FunflowProfileModule as ff github-ci python-anyio)
    WheelSmokeScenarioProfile))

wheel-smoke
